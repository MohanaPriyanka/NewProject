({  
    doInit : function(component, event, helper) {
        var action = component.get("c.getUser");
        action.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                component.set("v.logoFile", resp.getReturnValue().Client_Brand_Key__c);
                var brand = component.get("v.logoFile");
                if (brand !== null ){
                    if (brand === 'BluewaveLogo'){
                        component.set("v.showBW", true);
                    } else {
                        component.set("v.showBW", false);
                    }

                } else {
                    component.set("v.showBW", true);
                }
            }
            else {
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