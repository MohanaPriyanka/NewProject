({  
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

