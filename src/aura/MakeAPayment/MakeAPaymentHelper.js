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
            var systemBillList = resp.getReturnValue(); 
            var sbStep;
            var totalOutstandingBalance = 0;
                if (systemBillList === undefined || systemBillList.length === 0) {
                    component.set("v.myBill", 0);
                } else {
                    for (sbStep = 0; sbStep < systemBillList.length; sbStep++) {
                        totalOutstandingBalance = totalOutstandingBalance + Math.round(systemBillList[sbStep].carryover*100);
                    }
                    var roundedBalance = totalOutstandingBalance/100;
                    component.set("v.myBill", roundedBalance);
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