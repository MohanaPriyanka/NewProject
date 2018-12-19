({
    handleNavEvent : function(component, event, helper) {
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            component.set("v.lead", event.getParam("lead"));
            component.set("v.page", 'CapacityCheck');
            component.set("v.supressWaiting", false);
            component.set("v.loading", true);
            component.set("v.loadingText", "Checking if there are Community Solar projects in your area...");
            component.set("v.hasCapacity", "");
            var lead = component.get("v.lead");
            if (lead && lead.Loan_System_Information__c === 'Yes' && lead.LASERCA__Home_State__c === 'NY') {
                component.set("v.loading", false);
                component.set("v.hasCapacity", "No");
                component.set("v.noCapacityReason", "NYHasSolar");
            } else if (lead && lead.LASERCA__Home_State__c === 'NY' && lead.Application_Type__c === 'Non-Residential') {
                component.set("v.loading", false);
                component.set("v.hasCapacity", "No");
                component.set("v.noCapacityReason", "NYNonResidential");
            } else if (lead && lead.Id) {
                component.set("v.loadingText", "Returning the results...");
                var hasAvailableCapacityAction = component.get("c.hasAvailableCapacity");
                hasAvailableCapacityAction.setParams({
                    "leadId": lead.Id
                });
                hasAvailableCapacityAction.setCallback(this, function(actionResult) {
                    if (actionResult.getReturnValue() != null) {
                        var hasAvailableCapacity = actionResult.getReturnValue();
                        if (hasAvailableCapacity) {
                            helper.saveSObject(component, lead.Id, "Lead", "Status", "Qualified").then(
                                $A.getCallback(function resolve() {
                                    component.set("v.loading", false);
                                    component.set("v.hasCapacity", "Yes");
                                    $A.util.addClass(component.find("greatNews"), 'pulse');
                                }));
                        } else {
                            helper.saveSObject(component, lead.Id, "Lead", "Status", "Waitlist").then(
                                $A.getCallback(function resolve() {
                                    component.set("v.loading", false);
                                    component.set("v.hasCapacity", "No");
                                }));
                        }
                    } else {
                        alert("There was an issue. Please go back and verify the information provided is correct.");
                    }
                });
                $A.enqueueAction(hasAvailableCapacityAction);
            }
        }
    },

    finishStage : function(component, event, helper) {
        var lead = component.get("v.lead");
        helper.saveSObject(component, lead.Id, "Lead", null, null, lead);

        if (lead.Application_Source_Phase_2__c === 'CSAP Additional Property') {
            component.set('v.page', 'Done');
            var stageChangeEvent = $A.get("e.c:CSAPNavigationEvent");
            stageChangeEvent.setParams({"stageName": "NAV_Credit_Check"});
            stageChangeEvent.setParams({"options": {"pageName": "CreditAlreadyRun"}});
            stageChangeEvent.setParams({"eventType": "INITIATED"});
            stageChangeEvent.setParams({"lead": lead});
            stageChangeEvent.fire();
        } else {
            helper.finishStage(component, event, helper);
        }
    },

    skipToEnd : function(component, event, helper) {
        component.set('v.page', 'Done');
        //Skip to the Add More or Finish page
        var stageChangeEvent = $A.get("e.c:CSAPNavigationEvent");
        stageChangeEvent.setParams({"stageName": "NAV_Energy_Information"});
        stageChangeEvent.setParams({"options": {"pageName": "AddMore"}});
        stageChangeEvent.setParams({"eventType": "INITIATED"});
        stageChangeEvent.setParams({"lead": component.get('v.lead')});
        stageChangeEvent.fire();
    }
})