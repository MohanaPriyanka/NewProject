({
    handleNavEvent : function(component, event, helper) {
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            component.set("v.lead", event.getParam("lead"));
            component.set("v.page", 'CapacityCheck');
            component.set("v.supressWaiting", false);
            component.set("v.loading", true);
            component.set("v.loadingText", "Checking if there are Community Solar projects in your area...");
            window.setTimeout(function() {
                component.set("v.loadingText", "Checking if there is availability...");
            }, 3000);
            window.setTimeout(function() {
                component.set("v.loadingText", "Just a second...");
                component.set("v.hasCapacity", "");
                var lead = component.get("v.lead");
                if (lead && lead.Id){
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
            }, 6000);
        }
    },
    finishStage : function(component, event, helper) {
        var lead = component.get("v.lead");
        if(lead.Personal_Credit_Report__c == null){
            helper.finishStage(component, event, helper);
        }else{
            //Skip to the Energy Use page
            var stageChangeEvent = $A.get("e.c:CSAPNavigationEvent");
            stageChangeEvent.setParams({"stageName": "NAV_Energy_Information"});
            stageChangeEvent.setParams({"options": {"pageName": "UtilityAccountInformation"}});
            stageChangeEvent.setParams({"eventType": "INITIATED"});
            stageChangeEvent.setParams({"lead": lead});
            stageChangeEvent.fire();

        }
        
    },
})