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

        //reset the modal so that the email confirmation gets removed and the form gets displayed
        helper.addRemoveElements(component, 'emailForm', 'emailConfirmation');

        var modalToggle = event.getParam("openModal");    
        if (modalToggle == "openModal") {                                        
            helper.openModal(component);   
        }           
    },   

    closeEmailCustomerModal: function(component, event, helper) {
        closeModal(component, 'emailCustomerModal'); 
        helper.enableButton(component.find('sendEmailButton', 'Send'));

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

    createLeadAndSendApplication : function(component, event, helper) {  
        var newLead = component.get("v.newLead");
        var errors = helper.errorsInForm(component, helper, newLead);
        if (errors == null) {
            helper.removeButtonsAndShowSpinner(component, event, helper);  
            helper.emailApplication(component, event, helper, newLead);
        } else {
            helper.logError("SLPSendApplicationEmailController", "createLeadAndSendApplication", errors);
            return;
        }                      
    },            
})