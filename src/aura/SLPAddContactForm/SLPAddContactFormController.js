({  
    createContact : function(component, event, helper) {
        $A.util.addClass(component.find("buttonLink"), 'noDisplay'); 
        var newContact = component.get("v.contactInfo");
        var errors = helper.errorCheck(component, helper, newContact);        
        if (errors != "") {
            component.set("v.errorText" , errors);
            $A.util.removeClass(component.find("errorTextLine"), 'noDisplay'); 
            $A.util.removeClass(component.find("buttonLink"), 'noDisplay'); 
            return;
        } else {
            $A.util.addClass(component.find("errorTextLine"), 'noDisplay'); 
            newContact.LASERCA__Social_Security_Number__c = newContact.LASERCA__Social_Security_Number__c.replace(/-/g,"");
            var actionInsertContact  = component.get("c.addNewCoApplicant");
            var evtCustomerWindow = $A.get("e.c:SLPafterContactAddEvent");
            evtCustomerWindow.fire();         
            
            actionInsertContact.setParams({
                "newContact" : newContact,
                "mainApplicant" : component.get("v.leadVar") 
            });
            
            actionInsertContact.setCallback(this,function(resp) {       
                if(resp.getState() == "SUCCESS"){       
                    component.set("v.responseMessage" , 'Co-Signer Added Successfully.');
                    component.set("v.responseMessageLineTwo" , 'Please allow 1-2 business days for a credit review.');
                    $A.util.removeClass(component.find("message"), 'noDisplay'); 
                    $A.util.addClass(component.find("formBody"), 'noDisplay'); 
                } else {
                    helper.logError("SLPAddCoApplicant", "addNewCoApplicant", resp.getError());
                }                
           });
                                           
           $A.enqueueAction(actionInsertContact);
        }
    },

    doneButton : function(component, event, helper) {
        window.location.href = "/slportal/s/slpdashboard";
    },
})