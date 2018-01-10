({
    handleNavEvent : function(component, event, helper) {
        helper.handleNavEvent(component, event, helper, 'LoanConfirmation');
    },

    checkForEnter : function(component, event, helper) {
        if (event.getParams().keyCode == 13) {
            helper.login(component, event, helper);
        }
    },

    login : function(component, event, helper) {
        helper.login(component, event, helper);
    },

    confirmLoan : function(component, event, helper) {
        component.set('v.page', 'LoanDisclaimer');
    },

    finishStage : function(component, event, helper) {
        helper.finishStage(component, event, helper);
    },
})