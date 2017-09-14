({
    openEmailCustomerModal: function(component, event, helper) {
        var action = component.get("c.getPartnerRecord");        
        action.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                component.set("v.partnerRecord", resp.getReturnValue());
                if (resp.getReturnValue().State__c === 'MA') {
                    if (resp.getReturnValue().Default_Application__c != 'Massachusetts Solar Loan Program') {
                        helper.setWindowToBWSL(component);
                    } else {
                        helper.setWindowToMSLP(component);
                    }                    
                } else {
                    helper.setWindowToBWSL(component);                                 
                }
            } else {
                helper.logError("SLPSendApplicationEmailController", "openEmailCustomerModal", resp.getError());
            }
        });    
        $A.enqueueAction(action);    

        helper.callApexMethod(component, "getActiveStates", ["activeStates"]);

        //reset the modal so that the email confirmation gets removed and the form gets displayed
        $A.util.addClass(component.find('emailConfirmation'), 'noDisplay');  
        $A.util.removeClass(component.find('emailForm'), 'noDisplay'); 

        var modalToggle = event.getParam("openModal");    
        if (modalToggle == "openModal") {                                        
            helper.openModal(component, "emailCustomerModal");   
        }           
    },   

    closeEmailCustomerModal: function(component, event, helper) {
        helper.closeModal(component, 'emailCustomerModal'); 
        helper.enableButton(component, 'sendEmailButton', 'Send');

        var evtCustomerWindow = $A.get("e.c:SLPSendApplicationEmailEvent");
        evtCustomerWindow.setParams({"closeModal": "closeModal"});
        evtCustomerWindow.fire();         
    },    

    changeProductProgram: function(component, event, helper) {
        var newLead = component.get("v.newLead");
        if (newLead.Product_Program__c === "BlueWave Solar Loan") {
            helper.setWindowToMSLP(component);
        } else if (newLead.Product_Program__c === "MSLP") {
            helper.setWindowToBWSL(component);
        }
    },         

    calculateLoanAmount: function(component, event, helper) {
        var systemCost = component.get("v.newLead.System_Cost__c");
        var downPayment = component.get("v.downPayment");
        var loanAmount = systemCost + downPayment;
        component.set("v.newLead.Requested_Loan_Amount__c", loanAmount);
    },                               

    createLeadAndSendApplication : function(component, event, helper) {  
        var newLead = component.get("v.newLead");
        var downPayment = component.get("v.downPayment");
        var errors = helper.errorsInForm(component, helper, newLead);
        if (errors == null) {
            helper.removeButtonsAndShowSpinner(component, event, helper);  
            helper.emailApplication(component, event, helper, downPayment, newLead);
        } else {
            helper.logError("SLPSendApplicationEmailController", "createLeadAndSendApplication", errors);
            return;
        }                      
    },            
})