({
    handleNavEvent : function(component, event, helper) {
        const options = event.getParam("options");
        if (options && options.stageName !== 'NAV_Complete') {
            return;
        }
        var lead = component.get('v.lead');
        // We don't want to add multiple properties with the same loop. Let's automatically convert the lead
        var finishStage = component.get('c.finishStage');
        $A.enqueueAction(finishStage);
    },
    addResidence : function(component, event, helper) {
        helper.addNewLead(component, event, helper,"Residential");
    },
    addBusiness : function(component, event, helper) {
        helper.addNewLead(component, event, helper,"Non-Residential");
    },
    finishStage : function(component, event, helper) {
        component.set('v.loading', true);
        component.set('v.loadingText', 'Submitting your application...');
        helper.convertLeadFunction(component, event, helper);
        component.set("v.page", "Complete");
    },
})