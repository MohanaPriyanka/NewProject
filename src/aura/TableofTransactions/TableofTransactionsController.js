({
	doInit : function(component) {  
       var actionGetTrans = component.get("c.getTransactions"); 
                                  
       actionGetTrans.setParams({
            "accountLookup" : component.get("v.accountLookupId"),
        });
        
        actionGetTrans.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                component.set("v.transactionList", resp.getReturnValue());  
            } else {
                var appEvent = $A.get("e.c:ApexCallbackError");
				appEvent.setParams({"className" : "PreviewProductionUpdateResults",
				"methodName" : "getTransactions",
				"errors" : "No Transactions Exist"});
				appEvent.fire();   
            }
        });   
        $A.enqueueAction(actionGetTrans);
        
    },
})