({
    doInit : function(component, event, helper) {
        var action = component.get("c.getContactInfo");
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.userContact", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);
    },

    tableEditable : function(component, event, helper) {
        var currentState = component.get("v.isEditable");
        component.set("v.isEditable", !currentState);
    },

    updateContact : function(component, event, helper) {
        var updateAction = component.get("c.updateContactInfo");

        updateAction.setParams({
            "contactToUpdate": component.get("v.userContact")
        });
        
        updateAction.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.userContact", resp.getReturnValue());
                component.set("v.isEditable", false);
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(updateAction);
    },
})