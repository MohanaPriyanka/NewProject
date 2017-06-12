/*************************************************************************************
 * Created By:  Cole Swain
 * 
 * Description: 
 * 
 Tested By: CSCPChartHandlerTestClass
 *************************************************************************************/

public without sharing class CSCPChartHandler {

    public class SolarGenerationSavingsResult {
        @AuraEnabled
            public String[] yearMonth;
        @AuraEnabled
            public Integer[] savings;
        @AuraEnabled
            public Integer[] generation;
    }    

    @AuraEnabled
    public static solarGenerationSavingsResult getGenerationSavingsData() {
		SolarGenerationSavingsResult solarGenerationSavings = new SolarGenerationSavingsResult();
        User u = [Select Id, AccountId, Parent_Account_ID__c, ContactId from User where Id = :UserInfo.getUserId()];

    	if (u.ContactId != null) {
    		for (AggregateResult accountBillAggregation : [SELECT sum(Savings_Rollup__c)savingsSum, sum(Subscription_Production_kWh__c)generationSum, CALENDAR_YEAR(Date_Sent__c), CALENDAR_MONTH(Date_Sent__c)
	    									    FROM Account_Bill__c	
	    									    WHERE Account_Id__c = : u.Parent_Account_ID__c	
	    									    AND Date_Sent__c != null
	    									    GROUP BY CALENDAR_YEAR(Date_Sent__c), CALENDAR_MONTH(Date_Sent__c)
	    									    ORDER BY CALENDAR_YEAR(Date_Sent__c), CALENDAR_MONTH(Date_Sent__c) ASC]) {
    			solarGenerationSavings.yearMonth.add(accountBillAggregation.get('CALENDAR_MONTH(Date_Sent__c)') + ' ' + accountBillAggregation.get('CALENDAR_YEAR(Date_Sent__c))'));
    			solarGenerationSavings.savings.add((Integer)accountBillAggregation.get('savingsSum'));
    			solarGenerationSavings.generation.add((Integer)accountBillAggregation.get('generationSum'));
    		}
    	}
    return solarGenerationSavings;
    } 
}