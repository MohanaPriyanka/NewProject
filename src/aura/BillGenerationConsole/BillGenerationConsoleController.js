({
    doInit : function(component, event, helper) {
        helper.refreshTable(component, event, helper, true);
    },

    generateBills : function(component, event, helper) {
        var actionRunBills = component.get("c.runThisMonthsBills");
        component.set("v.generating", true);
        var interval;

        actionRunBills.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                component.set("v.messageText", 'Refreshing every 10 sec');
                interval = window.setInterval(
                    $A.getCallback(function() {
                        helper.refreshTable(component, event, helper, false);
                    }), 10000
                );
                component.set("v.refreshInterval", interval);
            } else {
                helper.logError('BillGenerationConsoleController','runThisMonthsBills','error generating bills','');
            }
        });
        $A.enqueueAction(actionRunBills);
    },

    nextFlowStep : function(component, event, helper){
        var updatedInterval = component.get("v.refreshInterval");
        window.clearInterval(updatedInterval);

        var actionClicked = event.getSource().getLocalId();
        var navigate = component.get('v.navigateFlow');
        navigate(actionClicked);
    }
})