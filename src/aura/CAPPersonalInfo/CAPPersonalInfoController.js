({
    handleNavEvent : function(component, event, helper) {
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            component.set("v.leadRecord", event.getParam("lead"));
            component.set('v.page', 'IndividualOrJoint');
        } else {
            component.set('v.page', '');
        }
    },

    finishStage : function(component, event, helper) {
        helper.finishStage(component, event, helper);
    },
})
