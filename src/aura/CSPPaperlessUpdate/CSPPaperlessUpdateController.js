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
   
    goPaperless : function(component, event, helper) {
        var setPropertiesToPaperless = component.get("c.setToPaperless");
        let contact = component.get("v.userContact");

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