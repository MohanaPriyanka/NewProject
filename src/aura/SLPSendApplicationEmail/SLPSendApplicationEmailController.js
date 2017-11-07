({
    openEmailCustomerModal: function(component, event, helper) {
        var action = component.get("c.getPartnerRecord");        
        action.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                var partner = resp.getReturnValue();
                component.set("v.partnerRecord", partner);
                if (partner.Accounts__r[0] &&
                    partner.Accounts__r[0].Disable_New_Loan_Applications_in_Portal__c) {
                    component.set("v.disableOrigination", true);
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
        if (!component.get("v.disableOrigination")) {
            helper.enableButton(component, 'sendEmailButton', 'Send');
        }

        var evtCustomerWindow = $A.get("e.c:SLPSendApplicationEmailEvent");
        evtCustomerWindow.setParams({"closeModal": "closeModal"});
        evtCustomerWindow.fire();         
    },    

    createLeadAndSendApplication : function(component, event, helper) {  
        var newLead = component.get("v.newLead");
        var downPayment = component.get("v.downPayment");
        var availableProducts = component.get("v.availableProducts");
        var errors = helper.errorsInForm(component, helper, newLead);
        if (errors == null) {
            newLead.Product_Program__c = helper.getProductProgram(availableProducts, newLead.Product__c);
            helper.removeButtonsAndShowSpinner(component, event, helper);  
            helper.emailApplication(component, event, helper, downPayment, newLead);
        } else {
            helper.logError("SLPSendApplicationEmailController", "createLeadAndSendApplication", errors, newLead);
            return;
        }                      
    },            

    getAvailableProducts : function(component, event, helper) {
        helper.getAvailableProducts(component, event, helper);
    }
})
