({
    handleNavEvent : function(component, event, helper) {
        if (event.getParam("eventType") === "LORCHANGE") {
            component.set("v.lenderOfRecord", event.getParam("lenderOfRecord"));
        }
    }
})