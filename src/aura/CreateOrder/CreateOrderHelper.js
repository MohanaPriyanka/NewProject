({  
    insertRecord : function(component, oppId){
        return new Promise(function(resolve, reject) {
            const actionInsert = component.get("c.insertRequest");

            actionInsert.setParams({
                "oppId": oppId
            }); 

            actionInsert.setCallback(this,function(response) {
                if(response.getState() == "SUCCESS") { 
                    const retVal = response.getReturnValue();
                    resolve(retVal);
                    console.log('SUCCESS');
                } else {
                    console.log('ERROR');
                    console.log(response.getReturnValue());
                }
            });                                 
            $A.enqueueAction(actionInsert);
        });
    },
    
    checkForLink : function(component, payRequestId){
        const actionGetUrl = component.get("c.checkForLink");
        
        actionGetUrl.setParams({
            "payRequestId": payRequestId
        }); 
        
        actionGetUrl.setCallback(this,function(response) {
            if(response.getState() == "SUCCESS" && response.getReturnValue().ChargentOrders__Pay_Link__c != null) { 
                component.set("v.PaymentLink", response.getReturnValue().ChargentOrders__Pay_Link__c);
                component.set("v.showEmail", false);
            } else {
                console.log('failfail');
            }
        });                                 
        $A.enqueueAction(actionGetUrl);
    },

    checkID : function(component, oppId, emailInput){
        return new Promise(function(resolve, reject) {
            const actionCheckID = component.get("c.checkEmail");
            
            actionCheckID.setParams({
                "oppId": oppId,
                "emailInput": emailInput
            }); 
            
            actionCheckID.setCallback(this,function(response) {
                if(response.getState() == "SUCCESS" && response.getReturnValue() == true) { 
                    const retVal = response.getReturnValue();
                    resolve(retVal);
                } else {
                    $A.util.addClass(component.find('Confirm'), 'shake slds-has-error');
                    component.set("v.showError", true); 
                }
            });                                 
            $A.enqueueAction(actionCheckID);
        });
    },
})