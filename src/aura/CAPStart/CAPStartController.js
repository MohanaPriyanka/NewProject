({
    doInit : function(component, event, helper) {
        var leadId = helper.getParameterByName(component ,event,'leadId');
        component.set('v.leadId', leadId);
    },

    handleNavEvent : function(component, event, helper) {
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            component.set("v.leadRecord", event.getParam("lead"));
            component.set('v.page', 'LoanConfirmation');
        } else {
            component.set('v.page', '');
        }
    },

    login : function(component, event, helper) {
        var action = component.get('c.getLead');
        action.setParams({
            "leadId": component.get('v.leadId'),
            "email" : component.get('v.leadEmail')
        });
        action.setCallback(this, function(actionResult) {
            if (actionResult.getReturnValue() != null) {
                var lead = actionResult.getReturnValue();
                if (lead.CAP_Stage__c !== '') {
                    component.set('v.page', '');
                    var stageChangeEvent = $A.get("e.c:CAPNavigationEvent");
                    stageChangeEvent.setParams({"stageName": lead.CAP_Stage__c});
                    stageChangeEvent.setParams({"eventType": "COMPLETED"});
                    stageChangeEvent.setParams({"lead": lead});
                    stageChangeEvent.fire();
                } else {
                    component.set('v.page', 'LoanConfirmation');
                    component.set('v.leadRecord', lead);
                }
            } else {
                alert('Incorrect email address. Please verify your email address.');
            }
        });

        $A.enqueueAction(action);
    },

    confirmLoan : function(component, event, helper) {
        // If MSLP:
        component.set('v.page', 'LoanDisclaimer');
        // Otherwise:
        // confirmDisclaimer(component, event, helper);
    },

    finishStage : function(component, event, helper) {
        helper.finishStage(component, event, helper);
    },
})
