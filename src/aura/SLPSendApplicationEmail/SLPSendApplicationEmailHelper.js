({
    errorsInForm : function(component, helper, lead) {
        var errorMessage = "";     
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
        component.set("v.newLead.Product_Program__c","BlueWave Solar Loan"); 
        $A.util.removeClass(component.find('mslpEmailInput'), 'nimbusBackground'); 
        $A.util.addClass(component.find('bwslEmailInput'), 'nimbusBackground');      
    },    

    setWindowToMSLP : function(component) {
        component.set("v.newLead.Product_Program__c","MSLP");           
        $A.util.removeClass(component.find('bwslEmailInput'), 'nimbusBackground');        
        $A.util.addClass(component.find('mslpEmailInput'), 'nimbusBackground');      
    },   

    removeButtonsAndShowSpinner : function(component, event, helper) {
        $A.util.addClass(component.find('sendEmailModalButtons'), 'noDisplay');
        this.startSpinner(component, "emailSpinner");  
    }, 

    emailApplication : function(component, event, helper, downPayment, newLead) {
        var action = component.get("c.sendApplication");   
        var loanAmount = newLead.System_Cost__c - downPayment;
        action.setParams({newLead : newLead,
                          loanAmount : loanAmount});  
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
        $A.util.addClass(component.find('emailForm'), 'noDisplay');         
        $A.util.removeClass(component.find('emailConfirmation'), 'noDisplay');  
        $A.util.removeClass(component.find('sendEmailModalButtons'), 'noDisplay');

        helper.stopSpinner(component, "emailSpinner");
        helper.disableButton(component, 'sendEmailButton', 'Email Sent!');       

        component.set('v.newLead.FirstName', null);          
        component.set('v.newLead.LastName', null);          
        component.set('v.newLead.Email', null);          
        component.set('v.newLead.LASERCA__Home_State__c', null);          
        component.set('v.newLead.Requested_Loan_Amount__c', null);   
        component.set('v.newLead.System_Cost__c', null);   
    },                 
})