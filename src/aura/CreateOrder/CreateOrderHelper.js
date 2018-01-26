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
                } else {
                    const appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({"className" : "BlueWaveParentHelper",
                                            "methodName" : "insertSObject",
                                            "errors" : resp.getError(),
                                            "developerInfo" : sObject});
                    appEvent.fire();
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
                component.set("v.showButton", true);
            } else {
                console.log('failfail');
            }
        });                                 
        $A.enqueueAction(actionGetUrl);
    },
})