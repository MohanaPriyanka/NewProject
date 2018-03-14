({  doInit : function(component, event, helper) {
        var action = component.get("c.getUser");
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.logoFile", resp.getReturnValue().Client_Brand_Key__c);
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);
    },
})