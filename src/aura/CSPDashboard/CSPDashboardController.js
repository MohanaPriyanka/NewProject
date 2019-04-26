({  doInit : function(component, event, helper) {
        var action = component.get("c.getUser");
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.userName", resp.getReturnValue().FirstName + ' ' + resp.getReturnValue().LastName);
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);

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
        helper.refreshAccountMetrics(component, 'All');
    },

    accountMenuOutput : function(component, event, helper) {    
        component.set("v.menuOpen", false);                                       
        var source = event.getSource();
        var label = source.get("v.label"); 
        var name = source.get("v.class"); 
        if (label === null || label === undefined ) {
            helper.refreshAccountMetrics(component, 'All');                                         
            component.set("v.selectedAccount", "All");
            component.set("v.selectedPropertyAccountId", "All");
        } else {
            helper.refreshAccountMetrics(component, label); 
            component.set("v.selectedAccount", name);
            component.set("v.selectedPropertyAccountId", label);
        }
    },

    openMenu : function(component, event, helper) { 
        component.set("v.menuOpen", true);                                       
    },

    closeMenu : function(component, event, helper) { 
        component.set("v.menuOpen", false);                                       
    },

    navigateToURL : function(component, event, helper) { 
        var btnClicked = event.getSource().get("v.name");
        var btnClickedWithSlash = '/' + btnClicked;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": btnClickedWithSlash
        });
        urlEvent.fire();                         
    },
})