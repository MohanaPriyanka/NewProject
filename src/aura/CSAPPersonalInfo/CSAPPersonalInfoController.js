({
    doInit: function(component, event, helper) {
        component.set("v.STAGENAME", "NAV_Personal_Information");
        component.set("v.page", "AboutYourself");
        var leadId = component.get("v.leadId");

        if (leadId !== null && leadId !== '' && leadId !== undefined) {
            component.set("v.page","Login");
            component.set("v.loading", false);
        }

        if (component.get("v.page") === 'AboutYourself') {
            component.set("v.loading", false);

            if (component.get("v.abbrevStates") && component.get("v.abbrevStates").length === 0) {
                helper.getUSStates(component, "v.abbrevStates", true);
            }
        }
    },
    handleNavEvent : function(component, event, helper) {
        const options = event.getParam("options");
        if (options && options.pageName) {
            helper.handleNavEvent(component, event, helper, options.pageName);
        } else {
            helper.handleNavEvent(component, event, helper, "AboutYourself");
            component.set("v.loading", false);
        }
    },
    goToCheckCapacity : function(component, event, helper) {
        var lead = component.get("v.lead");
        if(helper.validatePageFields(component) && lead.LASERCA__Home_State__c !== null && lead.LASERCA__Home_State__c !== ''){
            component.set('v.loading', true);
            component.set("v.loadingText", "Locating your address...");

            //checks initial Capacity (if there is a project for the ZIP) using Capacity Service
            var action = component.get("c.hasCapacity");
            var serviceZip = lead.Parcel_Zip__c;
            action.setParams({'zipcode': serviceZip});
            action.setCallback(this, function(resp){
                var hasProject = resp.getReturnValue();
                if (resp.getState() === "SUCCESS") {
                    component.set("v.hasProject", hasProject);
                } else {
                    helper.logError("CSAPPersonalInfoHelper", "hasCapacity",
                        "There was an issue checking your zipcode, but has been logged. Please call Customer Care at the number below for assistance.",
                        resp.getError());
                }
            });
            $A.enqueueAction(action);


            helper.processLead(component, event, helper);
            helper.upsertRecords(component, event, helper);

            //Once hasCapacity is processed, we know if we can continue the application (available capacity check is later)

        }
    },
    saveUnsplitZone : function(component, event, helper) {
        let unsplitLeadAction = component.get('c.unsplitLead');
        unsplitLeadAction.setParams({
           'lead': component.get('v.lead')
        });
        unsplitLeadAction.setCallback(this, function(actionResult) {
            if (actionResult.getState() === 'SUCCESS') {
                helper.finishStage(component, event, helper);
            } else {
                helper.raiseError('CSAPPersonalInfoController', 'saveUnsplitZone',
                    'There was an issue saving your utility or load zone. Please call BlueWave at the contact info below',
                    JSON.stringify(component.get('v.lead')));
            }
        });
        $A.enqueueAction(unsplitLeadAction);
    },

    cancelAddProperty : function(component, event, helper) {
        if (confirm("Are you sure you want to cancel adding another Property?")) {
            var lead = component.get('v.lead');
            var stageName = "NAV_Payment_Information";
            helper.closePageFireComplete(component, helper, stageName, lead);
        }
    },

    checkForEnter : function(component, event, helper) {
        if (event.which === 13) {
            event.preventDefault();
            helper.login(component, event, helper);
        }
    },

    login : function(component, event, helper) {
        if(helper.validatePageFields(component)){
            helper.login(component, event, helper);
        }
    },
})