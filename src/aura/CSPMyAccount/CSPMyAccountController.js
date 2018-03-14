({  accountMenuOutput : function(component, event, helper) {    
        component.set("v.menuOpen", false);                                       
        var source = event.getSource();
        var label = source.get("v.label"); 
        var name = source.get("v.class"); 
        if (label === null || label === undefined ) {
            helper.refreshTableData(component, 'All');  
            component.set("v.selectedAccount", "All");                                       
        } else {
            helper.refreshTableData(component, label); 
            component.set("v.selectedAccount", name);                                       
        }
    },

    openMenu : function(component, event, helper) { 
        component.set("v.menuOpen", true);                                       
    },

    closeMenu : function(component, event, helper) { 
        component.set("v.menuOpen", false);                                       
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