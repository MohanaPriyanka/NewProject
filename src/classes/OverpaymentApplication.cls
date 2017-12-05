public with sharing class OverpaymentApplication {
   	public static Map<String, Bill_Adjustment__c> adjustMap;
   	public static List<Adjustment_Application__c> adjustmentsToInsertList;

   	public static void triggerApplication(Map<Id,APXT_BPM__Conductor__c> oldMap, List<APXT_BPM__Conductor__c> newList) {
   		for (APXT_BPM__Conductor__c conductor : newList) {  
   			if (conductor.Apply_Overpay_Adjust__c && !oldMap.get(conductor.Id).Apply_Overpay_Adjust__c) {
   				applyOverpayments();
   			}
   		}
   	}

    public static void applyOverpayments() {  
        List<String> propertyAccountIdList = new List<String>();
        List<String> opportunityIdList = new List<String>();
        Decimal adjustAmount = 0;
        adjustMap = new Map<String, Bill_Adjustment__c>();
        adjustmentsToInsertList = new List<Adjustment_Application__c>();

        for(Bill_Adjustment__c adjustment : [  SELECT Id, Name, Account_Bill__c,
                                                Entity__r.Id, Adjustment_Amount__c,
                                                Account_Bill__r.Bill_Number__c,
                                                Account_Bill__r.Property_Account_ID__c,
                                                Property_Account_ID__c,
                                                Outstanding__c,
                                                Opportunity_ID__c,
                                                Overpayment__c,
                                                UASB__c
                                                FROM Bill_Adjustment__c
                                                WHERE Outstanding__c != 0
                                                ORDER BY Adjustment_Amount__c]){
        	if (adjustment.Account_Bill__c != NULL) {
        		propertyAccountIdList.add(adjustment.Property_Account_ID__c);
				String adjustKey =  adjustment.Entity__r.Id;
		        adjustKey = adjustKey.Substring(0,15) + '_' + adjustment.Property_Account_ID__c;
		        adjustment.Intermediate_Outstanding__c = adjustment.Outstanding__c;
				adjustMap.put(adjustKey, adjustment);
        	} else if (adjustment.UASB__c != NULL) {
				opportunityIdList.add(adjustment.Opportunity_Id__c);
				adjustment.Intermediate_Outstanding__c = adjustment.Outstanding__c;
				adjustMap.put(adjustment.Opportunity_Id__c, adjustment);
        	}
        }

        if (adjustMap.size() > 0) {
	        for (System_Bill__c sbill : [  SELECT Id, Name, Account_Bill__c, Due_This_Month__c,
	                                        Entity_Id__c, Account_Bill__r.Bill_Number__c,
	                                        Balance_Net_Late_Payments__c, Bill_Number__c,
	                                        Property_Account_ID__c, Balance_Adjustments__c,
	                                        Opportunity_ID__c
	                                        FROM System_Bill__c
	                                        WHERE Account_Bill__r.Published__c = false 
	                                        AND (Property_Account_ID__c IN : propertyAccountIdList
	                                        OR Opportunity_ID__c IN : opportunityIdList)] ) {

				adjustAmount = checkForAdjustments(sbill);
				if ( adjustAmount != 0) {
					sbill.Balance_Net_Late_Payments__c = sbill.Balance_Net_Late_Payments__c - adjustAmount;
				} 
				checkForOverpayments(sbill);
			}
	    	if (adjustmentsToInsertList.size() > 0) {
	    		insert adjustmentsToInsertList;
	    	}
    	}
    }

    public static Decimal checkForAdjustments (System_Bill__c sbill) {   
    	if (adjustMap.containsKey(sbill.Opportunity_ID__c)) {
    		Bill_Adjustment__c adjust = adjustMap.get(sbill.Opportunity_ID__c);
    		Decimal adjustmentAmount = 0;
    		Decimal outstanding = adjustMap.get(sbill.Opportunity_ID__c).Intermediate_Outstanding__c;
    		Decimal originalAdjust = adjustMap.get(sbill.Opportunity_ID__c).Adjustment_Amount__c;

			if (sbill.Balance_Net_Late_Payments__c > 0  
				&& originalAdjust > 0 
				&& outstanding > 0){
					adjustmentAmount = outstanding;
			} else if (sbill.Balance_Net_Late_Payments__c > 0  
				&& originalAdjust < 0  
				&& outstanding < 0){
					if (sbill.Due_This_Month__c > Math.Abs(outstanding)) {
						adjustmentAmount = outstanding;
					} else {
						adjustmentAmount = -1 * sbill.Due_This_Month__c;
					}
			}
			if (adjustmentAmount != 0) {
				Adjustment_Application__c adjustApp = createAdjustApp(sbill, adjustmentAmount, adjust, sbill.Opportunity_ID__c);
				adjustmentsToInsertList.add(adjustApp); 
				return adjustmentAmount;
			}
    	}
    	return 0;
    }   

    public static void checkForOverpayments (System_Bill__c sbill) {   
    	String sbKey = sbill.Entity_Id__c + '_' + sbill.Property_Account_ID__c;

    	if (adjustMap.containsKey(sbKey)) {
    		Bill_Adjustment__c adjust = adjustMap.get(sbKey);
    		Decimal balanceOnBill = sbill.Balance_Net_Late_Payments__c;
    		Decimal originalAdjust = adjustMap.get(sbKey).Adjustment_Amount__c;
    		Decimal outstanding = adjustMap.get(sbKey).Intermediate_Outstanding__c;

			if (balanceOnBill > 0 
				&& originalAdjust < 0 
				&& outstanding < 0) {
					if (Math.Abs(outstanding) >= balanceOnBill)  {
						Adjustment_Application__c adjustApp = createAdjustApp(sbill, -1 * balanceOnBill, adjust, sbKey);
						adjustmentsToInsertList.add(adjustApp); 
					} else { 
						Adjustment_Application__c adjustApp = createAdjustApp(sbill, outstanding, adjust, sbKey);
						adjustmentsToInsertList.add(adjustApp); 
					} 
			}
    	}
    }     

    public static Adjustment_Application__c createAdjustApp (System_Bill__c systemBill, Decimal amount, Bill_Adjustment__c adjust, String key) {   
		Adjustment_Application__c newApplication = new Adjustment_Application__c (	Name = adjust.Name,
																					Bill_Adjustment__c = adjust.Id,
																					System_Bill__c = systemBill.Id);
		if (adjust.Overpayment__c){
			newApplication.Overpayment_Amount__c = amount;
		} else {
			newApplication.Adjustment_Amount__c = amount;
		}
		adjustMap.get(key).Intermediate_Outstanding__c = adjustMap.get(key).Intermediate_Outstanding__c - amount;
        return newApplication;
    }   

}