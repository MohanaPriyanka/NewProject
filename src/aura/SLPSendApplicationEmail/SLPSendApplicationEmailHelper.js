({
    openModal : function(component) {
        $A.util.removeClass(component.find('emailCustomerModal'), 'slds-fade-in-hide');
        $A.util.addClass(component.find('emailCustomerModal'), 'slds-fade-in-open');     
    },  

    errorsInForm : function(component, helper, lead) {
        var errorMessage = "";
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.FirstName, "firstNameElement", "shake", null, true, false, true, "Please enter the Applicants's First Name without any special characters.", "standard");        
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LastName, "lastNameElement", "shake", null, true, false, true, "Please enter the Applicants's Last Name without any special characters.", "standard");        
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Email, "emailAddressElement", "shake", null, true, true, false, "Please enter a valid email address. The email you entered is: " + lead.Email, "email");        
        if (lead.LASERCA__Home_State__c == "Select") {
            helper.setInputToError(component, "stateElement", "shake");
            errorMessage = errorMessage + "Please enter a valid State" + "\n" + "\n";                          
        } else {
            helper.setInputToCorrect(component, "stateElement" );
        }     
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Requested_Loan_Amount__c, "loanAmountElement", "shake", null, false, false, false, "Please enter this Applicant's requested loan amount", "standard");        
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.System_Cost__c, "systemCostElement", "shake", null, false, false, false, "Please enter this Applicant's system installation cost", "standard");                
        console.log(errorMessage);
        if (errorMessage.length > 0) {
            return errorMessage;
        } 
    }, 

    setWindowToBWSL : function(component) {
        console.log("yo");
        component.set("v.newLead.Product_Program__c","BlueWave Solar Loan");           
        $A.util.removeClass(component.find('mslpEmailInput'), 'nimbusBackground'); 
        $A.util.addClass(component.find('bwslEmailInput'), 'nimbusBackground');      
    },    

    setWindowToMSLP : function(component) {
        console.log("heyr");
        component.set("v.newLead.Product_Program__c","MSLP");           
        $A.util.removeClass(component.find('bwslEmailInput'), 'nimbusBackground');        
        $A.util.addClass(component.find('mslpEmailInput'), 'nimbusBackground');      
    },   

    removeButtonsAndShowSpinner : function(component, event, helper) {
        $A.util.addClass(component.find('sendEmailModalButtons'), 'noDisplay');
        this.startSpinner(component, "emailSpinner");  
    }, 

    emailApplication : function(component, event, helper, newLead) {
        var action = component.get("c.sendApplication");   
        action.setParams({customerEmail : newLead.Email,
                          productProgram : newLead.Product_Program__c});  
        action.setCallback(this,function(resp){ 
            if (resp.getState() == 'SUCCESS') {
                helper.handleSuccessfulEmail(component, helper);              
            } else {
                helper.logError("SLPSendApplicationEmailEvent", "sendCustomerApplication", resp.getError());
                $A.log("Errors", resp.getError());                      
            }
        });                                                   
        $A.enqueueAction(action);   
    },        

    handleSuccessfulEmail : function(component, helper) {
        helper.stopSpinner(component, "emailSpinner");
        $A.util.removeClass(component.find('sendEmailModalButtons'), 'noDisplay');
        helper.disableButton(component, 'sendEmailButton', 'Email Sent!');       
        component.set('v.newLead.FirstName', null);          
        component.set('v.newLead.LastName', null);          
        component.set('v.newLead.Email', null);          
        component.set('v.newLead.LASERCA__Home_State__c', null);          
        component.set('v.newLead.Requested_Loan_Amount__c', 0);   
        component.set('v.newLead.System_Cost__c', 0);   
    },                 
})