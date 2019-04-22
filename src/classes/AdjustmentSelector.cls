/* Tested by ZuoraUsageServiceTest, ZuoraCreditDebitMemoServiceTest
 */

public class AdjustmentSelector {
    public static List<Bill_Adjustment__c> getAdjustmentsNotYetInZuora(Boolean typeIsProduction) {
        String queryString =
            'SELECT ' +
                'Id, Name, ' +
                'UASB__r.Date__c, ' +
                'UASB__r.Utility_Account_Subscription__r.SRPC__r.' +
                'Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, ' +
                'UASB__r.Billing_Period_Start_Date__c, ' +
                'UASB__r.Billing_Period_End_Date__c, ' +
                'UASB__r.Utility_Account_Subscription__r.SRPC__r.Zuora__Subscription__r.Name, ' +
                'UASB__r.Utility_Account_Subscription__r.SRPC__r.Zuora__ChargeNumber__c, ' +
                'UASB__r.Utility_Account_Subscription__r.SRPC__r.Zuora__OriginalProductRatePlanChargeId__c, ' +
                'UASB__r.Utility_Account_Subscription__r.SRPC__r.Zuora__Zuora_Id__c, ' +
                'UASB__r.Shared_Solar_System__r.Utility__r.Name, ' +
                'UASB__r.Utility_Account_Subscription__r.Utility_Account_Log__r.Name, ' +
                'UASB__r.Shared_Solar_System__r.Name, ' +
                'UASB__r.Shared_Solar_System__r.SSS_Unique_ID__c, ' +
                'Adjustment_Amount__c, ' +
                'Adjustment_Type__c, ' +
                'Discount__c, ' +
                'Credits_Allocated__c, ' +
                'Zuora_Id__c ' +
            'FROM Bill_Adjustment__c ' +
            'WHERE Zuora_Id__c = null ' +
            'AND Applied_to_Bill__c = true ';

        if (typeIsProduction){
            queryString += 'AND Adjustment_Type__c = \'Production\'';
        } else {
            queryString += 'AND Adjustment_Type__c != \'Production\'';
        }

        return Database.query(queryString);
    }
}