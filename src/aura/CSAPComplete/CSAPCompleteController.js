({
    handleNavEvent : function(component, event, helper) {
        const options = event.getParam("options");
        if (event.getParam("stageName") !== 'NAV_Complete') {
            return;
        }

        helper.handleNavEvent(component, event, helper, "Submitting Application");
        var page = component.get("v.page");
        if (page === 'Submitting Application' && event.getParam("eventType")=== "INITIATED") {
            var finishStage = component.get('c.finishStage');
            $A.enqueueAction(finishStage);
        }
    },

    finishStage : function(component, event, helper) {
        component.set('v.loading', true);
        component.set('v.loadingText', 'Submitting your application...');
        helper.convertLeadFunction(component, event, helper);
    },
})