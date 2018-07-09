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

        actionGetChargentOrder.setParams({
            "propertyAccountId" : accountId
        });

        actionGetSystemBills.setCallback(this,function(resp){
            if(resp.getState() === 'SUCCESS') {
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
                        totalOutstandingBalance = totalOutstandingBalance + Math.round(systemBillList[sbStep].ChargentOrders__Subtotal__c*100);
                    }
                    var roundedBalance = totalOutstandingBalance/100;
                    component.set("v.myBill", roundedBalance);
                }
        }); 
       
        actionGetTransactions.setCallback(this,function(resp){
            if(resp.getState() === 'SUCCESS') {
                component.set("v.PaymentLogs", resp.getReturnValue());
                var transactionList = resp.getReturnValue();
                var tranStep;
                    for (tranStep = 0; tranStep < transactionList.length; tranStep++) {
                        if (transactionList[tranStep].ChargentOrders__Order__r.ChargentOrders__Payment_Status__c === 'Recurring') {
                            component.set("v.recurringCheck", true);
                        }
                    }
            } else {
                $A.log("Errors", resp.getError());
            }
        });

        actionGetChargentOrder.setCallback(this,function(resp){
            component.set("v.recurringCheck", false);
            if(resp.getState() === "SUCCESS") {
                var chargentOrder = resp.getReturnValue();
                if(chargentOrder){
                    if(chargentOrder.ChargentOrders__Bank_Account_Number__c){
                        chargentOrder.ChargentOrders__Bank_Account_Number__c = chargentOrder.ChargentOrders__Bank_Account_Number__c.substr(chargentOrder.ChargentOrders__Bank_Account_Number__c.length - 4)
                    } else if(chargentOrder.ChargentOrders__Card_Number__c){
                        chargentOrder.ChargentOrders__Card_Number__c = chargentOrder.ChargentOrders__Card_Number__c.substr(chargentOrder.ChargentOrders__Card_Number__c.length - 4)
                    }
                    component.set("v.chargentOrder", chargentOrder);
                    component.set("v.recurringCheck", true);
                }
            } else {
                $A.log("Errors", resp.getError());
            }
        });

        actionGetAccountBills.setCallback(this,function(resp){
            if(resp.getState() === 'SUCCESS') {
                component.set("v.AccountBills", resp.getReturnValue());
                var abList = resp.getReturnValue();
                var files = component.get("v.fileNames"); 
                var abStep;
                for (abStep = 0; abStep < abList.length; abStep++) {
                    if (abList[abStep].Bill_Attach_Document__c != null) {
                        var specFile = abList[abStep].Bill_Attach_Document__c;
                        files.push(specFile); 
                    }
                }
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(actionGetAccountBills);
        $A.enqueueAction(actionGetTransactions); 
        $A.enqueueAction(actionGetSystemBills);
        $A.enqueueAction(actionGetChargentOrder);
    }
})