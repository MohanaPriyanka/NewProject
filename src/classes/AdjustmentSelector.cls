/* Tested by ZuoraUsageServiceTest, ZuoraCreditDebitMemoServiceTest
 */

public class AdjustmentSelector {
    public static Database.QueryLocator getAdjustmentsNotYetInZuora(Boolean typeIsUsage) {
        String queryString =
            'SELECT ' +
                'Id, Name, ' +
                'UASB__r.Date__c, ' +
                'Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Utility__r.Name, ' +
                'Utility_Account_Subscription__r.Utility_Account_Log__r.Name, ' +
                'Client__r.Account_Number__c, ' +
                'UASB__r.System_Bill__r.Account_Bill__c, ' +
                'Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c, ' +
                'Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c, ' +
                'Adjustment_Amount__c, ' +
                'Adjustment_Type__c, ' +
                'Discount__c, ' +
                'Credits_Allocated__c, ' +
                'Zuora_Id__c ' +
                'FROM Bill_Adjustment__c ' +
                'WHERE Zuora_Id__c = null ' +
                'AND Applied_to_Bill__c = true ' +
                // Ignore Returns, because we'll always create a debit memo for returned payments in Zuora
                'AND Adjustment_Type__c != \'Returned Payment\' ' +
                'AND Adjustment_Type__c != \'Returned Check Payment\' ';

        if (typeIsUsage){
            queryString += 'AND Adjustment_Type__c = \'Production\' ';
            queryString += 'AND Adjustment_Amount__c > 0';
        } else {
            queryString += 'AND(Adjustment_Type__c != \'Production\' ';
            queryString += 'OR Adjustment_Amount__c < 0)';
        }

        queryString += ' ORDER BY UASB__r.Opportunity__r.AccountId';

        return Database.getQueryLocator(queryString);
    }
}