({
    refreshTableData : function(component, accountId) {
        var actionGetSystemBills = component.get("c.getSystemBills");  
        var actionGetAccountBills = component.get("c.getAccountBills");
        var actionGetTransactions = component.get("c.getTransactions");
        
        actionGetSystemBills.setParams({
            "propertyAccountId" : accountId
        });

       actionGetAccountBills.setParams({
            "propertyAccountId" : accountId
        });

        actionGetTransactions.setParams({
            "propertyAccountId" : accountId
        });

        actionGetSystemBills.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.SystemBills", resp.getReturnValue());
            } else {
                $A.log("Errors", resp.getError());
            }
        }); 
       
        actionGetTransactions.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.PaymentLogs", resp.getReturnValue());
            } else {
                $A.log("Errors", resp.getError());
            }
        }); 
        
        actionGetAccountBills.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.AccountBills", resp.getReturnValue());
                var accountBillList = resp.getReturnValue(); 
                var abStep;
                var totalOutstandingBalance = 0;
                if (accountBillList === undefined || accountBillList.length === 0) {
                    component.set("v.myBill", 0);
                } else {
                    for (abStep = 0; abStep < accountBillList.length; abStep++) {
                        totalOutstandingBalance = totalOutstandingBalance + accountBillList[abStep].Balance_Net_Late_Payments__c;
                    }
                    var roundedBalance = totalOutstandingBalance.toFixed(2);
                    component.set("v.myBill", roundedBalance);
                }
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(actionGetAccountBills);
        $A.enqueueAction(actionGetTransactions); 
        $A.enqueueAction(actionGetSystemBills);
    }
})