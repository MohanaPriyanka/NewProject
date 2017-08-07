({	
	createContact : function(component, event, helper) {
        var newContact = component.get("v.contactInfo");
        var errors = helper.errorCheck(component, helper, newContact);        
        if (errors != "") {
            component.set("v.errorText" , errors);
            $A.util.removeClass(component.find("errorTextLine"), 'noDisplay'); 
            return;
        } else {
            newContact.LASERCA__Social_Security_Number__c = newContact.LASERCA__Social_Security_Number__c.replace(/-/g,"");
            var actionInsertContact  = component.get("c.addNewCoApplicant");
            
            actionInsertContact.setParams({
                "newContact" : newContact,
                "leadId" : component.get("v.leadId") 
            });
            
            actionInsertContact.setCallback(this,function(resp) {		
                if(resp.getState() == "SUCCESS"){       
                    component.set("v.responseMessage" , 'Co-Applicant Added Successfully');
                    $A.util.removeClass(component.find("message"), 'noDisplay'); 
                    $A.util.addClass(component.find("formBody"), 'noDisplay'); 
                } else {
                    helper.logError("SLPAddCoApplicant", "addNewCoApplicant", resp.getERror());
                }                
           });
                                           
           $A.enqueueAction(actionInsertContact);
        }
	},
})