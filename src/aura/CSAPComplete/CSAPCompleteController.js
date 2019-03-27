({
    handleNavEvent : function(component, event, helper) {
        const options = event.getParam("options");
        if (options && options.stageName !== 'NAV_Complete') {
            return;
        }
        helper.handleNavEvent(component, event, helper, "Submitting Application");
        var page = component.get("v.page");
        if (page === 'Submitting Application') {
            console.log("EVENT TYPE: " + event.getParam("eventType"));
            var finishStage = component.get('c.finishStage');
            $A.enqueueAction(finishStage);
        }
    },
    // addResidence : function(component, event, helper) {
    //     helper.addNewLead(component, event, helper,"Residential");
    // },
    // addBusiness : function(component, event, helper) {
    //     helper.addNewLead(component, event, helper,"Non-Residential");
    // },
    finishStage : function(component, event, helper) {
        component.set('v.loading', true);
        component.set('v.loadingText', 'Submitting your application...');
        helper.convertLeadFunction(component, event, helper);
    },
})