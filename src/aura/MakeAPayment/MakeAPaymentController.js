({  accountMenuOutput : function(component, event, helper) {    
        var source = event.getSource();
        var label = source.get("v.label"); 
        if (label === null || label === undefined ) {
            helper.refreshTableData(component, 'All');                                         
        } else {
            helper.refreshTableData(component, label); 
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
        helper.refreshTableData(component, 'All');
    }
})