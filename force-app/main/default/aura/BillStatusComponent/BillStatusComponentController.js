({
    doInit : function(component, event, helper) {
        var interValue;
        component.set("v.messageText", 'Refreshing every 10 sec');
        helper.getAccountBillSummary(component, helper);

        interValue = window.setInterval(
            $A.getCallback(function() {
                helper.getAccountBillSummary(component,helper);
            }), 10000
        );

        component.set("v.intervalPoller", interValue);
    },

    goToNextFlowStep : function(component, event, helper){
        window.clearInterval(component.get("v.intervalPoller"));
        var actionClicked = event.getSource().getLocalId();
        var navigate = component.get('v.navigateFlow');
        navigate(actionClicked);
    }
})