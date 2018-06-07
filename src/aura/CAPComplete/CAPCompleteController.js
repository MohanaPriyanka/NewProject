({
    handleNavEvent : function(component, event, helper) {
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            component.set("v.lead", event.getParam("lead"));
            helper.setContractSent(component, event, helper).then(
                $A.getCallback(function resolve(value) {
                    helper.handleNavEvent(component, event, helper, 'Complete');
                }));
        }
    },
})