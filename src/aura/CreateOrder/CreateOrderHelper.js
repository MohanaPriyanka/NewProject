({  
    insertRecord : function(component, oppId, emailInput, helper){
        $A.util.removeClass(component.find('Confirm'), 'shake slds-has-error');
        component.set("v.showError", false); 
       
       return new Promise(function(resolve, reject) {
            const actionInsert = component.get("c.insertRequest");

            actionInsert.setParams({
                "oppId": oppId,
                "emailInput": emailInput
            }); 

            actionInsert.setCallback(this,function(response) {
                if(response.getState() === "SUCCESS" && response.getReturnValue() === 'emailFailure') { 
                    $A.util.addClass(component.find('Confirm'), 'shake slds-has-error');
                    component.set("v.showError", true); 
                } else if (response.getState() === "SUCCESS") {
                    const retVal = response.getReturnValue();
                    resolve(retVal);
                } else {
                    helper.logError('CreateOrderandPaymentRequest','insertRequest', response.getReturnValue(), '');
                }
            });                                 
            $A.enqueueAction(actionInsert);
        });
    },
    
    checkForLink : function(component, payRequestId, helper){
        const actionGetUrl = component.get("c.checkForLink");
        
        actionGetUrl.setParams({
            "payRequestId": payRequestId
        }); 
        
        actionGetUrl.setCallback(this,function(response) {
            if(response.getState() === "SUCCESS" && response.getReturnValue().ChargentOrders__Pay_Link__c != null) { 
                component.set("v.PaymentLink", response.getReturnValue().ChargentOrders__Pay_Link__c);
                component.set("v.showEmail", false);
            } else {
                helper.logError('CreateOrderandPaymentRequest','checkForLink', response.getReturnValue(), '');
            }
        });                                 
        $A.enqueueAction(actionGetUrl);
    },
})