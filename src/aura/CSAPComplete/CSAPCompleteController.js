({
    handleNavEvent : function(component, event, helper) {
        helper.handleNavEvent(component, event, helper, "AddMore");
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