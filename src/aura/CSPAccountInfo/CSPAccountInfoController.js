({
    doInit : function(component, event, helper) {
        var action = component.get("c.getContactInfo");
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.userContact", resp.getReturnValue());
                var checkPaperless = component.get("c.isPaperless");
                checkPaperless.setParams({
                    "parentAccountId": resp.getReturnValue().AccountId
                });
                checkPaperless.setCallback(this,function(response){
                    if(response.getState() == 'SUCCESS') {
                        component.set("v.paperlessBill",response.getReturnValue());
                    }
                    else {
                        $A.log("Errors", response.getError());
                    }
                });
                $A.enqueueAction(checkPaperless);
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

    goPaperless : function(component, event, helper) {
        var setPropertiesToPaperless = component.get("c.setToPaperless");
        let contact = component.get("v.userContact");
        console.log(contact.AccountId);
        console.log('goPaperless');

        setPropertiesToPaperless.setParams({
            "parentAccountId": contact.AccountId
        });

        setPropertiesToPaperless.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.paperlessBill",true);
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(setPropertiesToPaperless);
    },
})