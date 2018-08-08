({  
    doInit : function(component, event, helper) {
        var action = component.get("c.getUser");
        action.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                let brand = resp.getReturnValue().Client_Brand_Key__c;
                component.set("v.logoFile", brand);
                component.set("v.showBW", (brand === 'BluewaveLogo'));
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);

    },
    handleNavigationMenuSelect : function (component, event) {
        var navigateAction = $A.get("e.force:navigateToURL");
        navigateAction.setParams({
          "url": event.getParam("value")
        });
        navigateAction.fire();
    },
})