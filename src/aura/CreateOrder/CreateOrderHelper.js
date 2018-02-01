({  
    checkOppEmail : function(component, oppId, emailInput, chOrderInput, helper){
        $A.util.removeClass(component.find('Confirm'), 'shake slds-has-error');
        component.set("v.showError", false); 
       
        const actionEmail = component.get("c.checkEmailOnOpp");

        actionEmail.setParams({
            "oppId": oppId,
            "emailInput": emailInput,
        }); 

        actionEmail.setCallback(this,function(response) {
            if(response.getState() === "SUCCESS" && response.getReturnValue() === false) { 
                $A.util.addClass(component.find('Confirm'), 'shake slds-has-error');
                component.set("v.showError", true); 
                component.set("v.errorText", 'Invalid Email'); 
            } else if (response.getState() === "SUCCESS") {
                component.set("v.showEmail", false);
            } else {
                helper.logError('CreateOrderandPaymentRequest','insertRequest', response.getReturnValue(), '');
            }
        });                                 
        $A.enqueueAction(actionEmail);
    },

    insertRecord : function(component, oppId, emailInput, chOrderInput, helper){
        this.resetErrors(component, helper);

        if (component.get("v.chOrder.ChargentOrders__Bank_Routing_Number__c").length != 9) {
            this.logErrorMessage(component, helper, 'Please provide a valid Routing Number', 'routing');
        } else if (component.get("v.chOrder.ChargentOrders__Bank_Account_Number__c").length < 1) {
            this.logErrorMessage(component, helper, 'Please provide a valid Account Number', 'accountnumber');
        } else if (component.get("v.chOrder.ChargentOrders__Bank_Account_Name__c").length < 1 ) {
            this.logErrorMessage(component, helper, 'Please provide a valid Account Name', 'accountname');
        } else if (component.get("v.chOrder.ChargentOrders__Bank_Name__c").length < 1) {
            this.logErrorMessage(component, helper, 'Please provide a valid Bank Name', 'bankname');
        } else if (component.get("v.chOrder.ChargentOrders__Bank_Account_Type__c") === null) {
            this.logErrorMessage(component, helper, 'Please provide a valid Bank Account Type', 'banktype');
        } else {
            const actionInsert = component.get("c.insertRequest");

            actionInsert.setParams({
                "oppId": oppId,
                "emailInput": emailInput,
                "chOrder" : chOrderInput
            }); 

            actionInsert.setCallback(this,function(response) {
                if(response.getState() === "SUCCESS" && response.getReturnValue() === true) { 
                    component.set("v.ShowSuccess", true);
                } else {
                    helper.logError('CreateOrderandPaymentRequest','insertRequest', response.getReturnValue(), '');
                }
            });                                 
            $A.enqueueAction(actionInsert);
        }
    },
    
    resetErrors : function(component, helper){
        $A.util.removeClass(component.find('Confirm'), 'shake slds-has-error');
        $A.util.removeClass(component.find('routing'), 'shake slds-has-error');
        $A.util.removeClass(component.find('accountnumber'), 'shake slds-has-error');
        $A.util.removeClass(component.find('accountname'), 'shake slds-has-error');
        $A.util.removeClass(component.find('bankname'), 'shake slds-has-error');
        $A.util.removeClass(component.find('banktype'), 'shake slds-has-error');
        component.set("v.showError", false); 
    },

    logErrorMessage : function(component, helper, errorMessageText, field){
        component.set("v.errorMessage", errorMessageText); 
        component.set("v.showError", true); 
        $A.util.addClass(component.find(field), 'shake slds-has-error');
    },
})