({
    sendEmailFunc : function(component, event, helper) {
        component.find("emailstatus").set("v.value", "");
        var email = component.find("email").get("v.value");
        if (email === null || email === "" || email.indexOf("@") === -1 || email.indexOf(".") === -1) {
            component.find("emailstatus").set("v.value", "You must enter a valid email address.");
            return;
        } else {
            var action = component.get("c.sendEmail");
            action.setParams({ emailAddress : component.find("email").get("v.value") });
            action.setCallback(this,function(resp){
                if (resp.getState() == 'SUCCESS') {
                    if (resp.getReturnValue() == 'success') {
                        component.find("emailstatus").set("v.value", "The email was sent successfully.");
                    } else {
                        alert('fail');
                        component.find("emailstatus").set("v.value", resp.getReturnValue());
                    }
                } else {
                    component.find("emailstatus").set("v.value", resp.getError());
                }
            });
            $A.enqueueAction(action);
        }
    },
    doInit : function(component, event, helper) {
        var action = component.get("c.getContactInfo");
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                //component.set("v.referCode", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);
    }

})