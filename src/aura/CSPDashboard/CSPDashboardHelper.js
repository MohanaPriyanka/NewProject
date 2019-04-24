({  refreshAccountMetrics : function(component, propertyAccountId) {
        var actionGetSystemBills = component.get("c.getSystemBills");  

        actionGetSystemBills.setParams({
            "propertyAccountId" : propertyAccountId
        });

        actionGetSystemBills.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
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
            } else {
                $A.log("Errors", resp.getError());
            }
        });

        var actionGetAccountBills = component.get("c.getAccountBills");

        actionGetAccountBills.setParams({
           "propertyAccountId" : propertyAccountId
        });
      
        actionGetAccountBills.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                var accountBillList = resp.getReturnValue();        
            var abStep;
            var totalSavings = 0;
            if (accountBillList === undefined || accountBillList.length === 0) {
              component.set("v.myBill", 0);
              component.set("v.mySavings", 0);
            } else {
              for (abStep = 0; abStep < accountBillList.length; abStep++) {
                totalSavings = totalSavings + accountBillList[abStep].Savings_Rollup__c;
              }
              var roundedSavings = totalSavings;
              component.set("v.mySavings", roundedSavings);
            }
            }
            else {
                $A.log("Errors", resp.getError());
            }
        }); 
        $A.enqueueAction(actionGetSystemBills);       
        $A.enqueueAction(actionGetAccountBills);
    },
})