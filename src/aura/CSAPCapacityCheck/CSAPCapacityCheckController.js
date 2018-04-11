({
    handleNavEvent : function(component, event, helper) {
        helper.handleNavEvent(component, event, helper, "CapacityCheck");
        component.set("v.loading", true);
        component.set("v.loadingText", "Checking if there are Community Solar projects in your area...");
        window.setTimeout(function() {
            component.set("v.loadingText", "Checking if there is availability...");
        }, 3000);
        window.setTimeout(function() {
            component.set("v.loadingText", "Just a second...");
            component.set("v.hasCapacity", "");
            var lead = component.get("v.lead");
            if(lead.Id){
                component.set("v.loadingText", "Returning the results...");
                var hasAvailableCapacityAction = component.get("c.hasAvailableCapacity");
                hasAvailableCapacityAction.setParams({
                    "leadId": lead.Id
                });
                hasAvailableCapacityAction.setCallback(this, function(actionResult) {
                    component.set("v.loading", false);
                    if (actionResult.getReturnValue() != null) {
                        var hasAvailableCapacity = actionResult.getReturnValue();
                        if(hasAvailableCapacity){
                            component.set("v.hasCapacity", "Yes");
                            $A.util.addClass(component.find("greatNews"), 'pulse');
                        }else{
                            component.set("v.hasCapacity", "No");
                            helper.saveSObject(component, lead.Id, "Lead", "Status", "Waitlist");
                        }
                    } else {
                        alert("There was an issue. Please go back and verify the information provided is correct.");
                    }
                });
                $A.enqueueAction(hasAvailableCapacityAction);
            }
        }, 6000);
    },
    finishStage : function(component, event, helper) {
        helper.finishStage(component, event, helper);
    },
})