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
            public List<String> yearMonth = new List<String>();
        @AuraEnabled
            public List<Decimal> savings = new List<Decimal>();
        @AuraEnabled
            public List<Decimal> totalSavings = new List<Decimal>();             
        @AuraEnabled
            public List<Decimal> generation = new List<Decimal>();    
        @AuraEnabled
            public List<Decimal> totalGeneration = new List<Decimal>();             
    }    

    @AuraEnabled
    public static solarGenerationSavingsResult getGenerationSavingsData() {
        Decimal aggregateSavings = 0;
        Decimal stackedTotalSavings;
        List<Decimal> aggregateSavingsList = new List<Decimal>();
        SolarGenerationSavingsResult solarGenerationSavings = new SolarGenerationSavingsResult();
        User u = [Select Id, AccountId, Parent_Account_ID__c, ContactId from User where Id = :UserInfo.getUserId()];
        if (u.ContactId != null) {
            for (AggregateResult accountBillAggregation : [SELECT sum(Savings_Rollup__c)savingsSum, sum(Subscription_Production_kWh__c)generationSum, CALENDAR_YEAR(Date__c), CALENDAR_MONTH(Date__c)
                                                           FROM Account_Bill__c 
                                                           WHERE Account_Id__c = : u.Parent_Account_ID__c   
                                                           AND Date__c != null
                                                           GROUP BY CALENDAR_YEAR(Date__c), CALENDAR_MONTH(Date__c)
                                                           ORDER BY CALENDAR_YEAR(Date__c), CALENDAR_MONTH(Date__c) ASC]) {

                solarGenerationSavings.savings.add((Decimal)accountBillAggregation.get('savingsSum'));
                solarGenerationSavings.yearMonth.add(accountBillAggregation.get('expr1') + ' ' + accountBillAggregation.get('expr0'));
                solarGenerationSavings.generation.add(Integer.valueOf(accountBillAggregation.get('generationSum')));
                aggregateSavings = aggregateSavings + (Decimal)accountBillAggregation.get('savingsSum');            
                solarGenerationSavings.totalSavings.add(aggregateSavings - (Decimal)accountBillAggregation.get('savingsSum'));
            }

        }
    return solarGenerationSavings;
    } 
}