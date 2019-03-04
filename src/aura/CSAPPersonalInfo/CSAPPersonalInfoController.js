({
    doInit: function(component, event, helper) {
        var leadId = component.get("v.leadId");
        if (component.get("v.abbrevStates") && component.get("v.abbrevStates").length === 0) {
            helper.getUSStates(component, "v.abbrevStates", true);
        }
    },
    handleNavEvent : function(component, event, helper) {
        const options = event.getParam("options");
        if (options && options.pageName) {
            helper.handleNavEvent(component, event, helper, options.pageName);
        }else{
            helper.handleNavEvent(component, event, helper, "AboutYourself");
        }
    },
    goToCheckCapacity : function(component, event, helper) {
        if(helper.validatePageFields(component)){
            component.set('v.loading', true);
            component.set("v.loadingText", "Locating your address...");
            helper.processLead(component, event, helper);
            helper.upsertRecords(component, event, helper);
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
})