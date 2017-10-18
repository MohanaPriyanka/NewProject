({  dashboardMenuOutput : function(component, event, helper) {    
        var label = event.getParam("propertyAccountId");
        if (label === null || label === undefined ) {
            helper.refreshAccountMetrics(component, 'All');                                         
        } else {
            helper.refreshAccountMetrics(component, label); 
        }
    },

    doInit : function(component, event, helper) {
        var actionGetPropertyAccounts = component.get("c.getMenuLabelList");         
        actionGetPropertyAccounts.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.menuLabels", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionGetPropertyAccounts);
        console.log("HELLO!");
        helper.refreshAccountMetrics(component, 'All');
    }
})