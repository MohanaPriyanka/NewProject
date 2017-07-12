({
	doInit : function(component) {  
       var actionGetTrans = component.get("c.getTransactions"); 
                                  
       actionGetTrans.setParams({
            "accountLookup" : component.get("v.accountLookupId"),
        });
        
        actionGetTrans.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                component.set("v.transactionList", resp.getReturnValue());  
            } else {
            }
        });   
        $A.enqueueAction(actionGetTrans);
        
    },
})