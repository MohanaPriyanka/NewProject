({
	refreshAccountMetrics : function(component, propertyAccountId) {
       	var actionGetAccountBills = component.get("c.getAccountBills");

       	actionGetAccountBills.setParams({
			"propertyAccountId" : propertyAccountId
        });
      
        actionGetAccountBills.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                var accountBillList = resp.getReturnValue();       	
       			var abStep;
       			var totalOutstandingBalance = 0;
       			var totalSavings = 0;
       			var totalProduction = 0;
        		if (accountBillList === undefined || accountBillList.length === 0) {
        			component.set("v.myBill", 0);
        			component.set("v.mySavings", 0);
	       			component.set("v.myProduction", 0);
        		} else {
	        		for (abStep = 0; abStep < accountBillList.length; abStep++) {
	       				totalOutstandingBalance = totalOutstandingBalance + accountBillList[abStep].Balance_Net_Late_Payments__c;
	       				totalSavings = totalSavings + accountBillList[abStep].Savings_Rollup__c;
	       				totalProduction = totalProduction + accountBillList[abStep].Subscription_Production_kWh__c;
	       			}
	       			var roundedBalance = totalOutstandingBalance;
	       			var roundedSavings = totalSavings;
	       			component.set("v.myBill", roundedBalance);
	       			component.set("v.mySavings", roundedSavings);
	       			component.set("v.myProduction", totalProduction);
        		}
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(actionGetAccountBills);
	}
})