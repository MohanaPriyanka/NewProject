/* Tested by ZuoraUsageServiceTest, ZuoraCreditDebitMemoServiceTest, AdjustmentSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class AdjustmentSelector {
    public static Database.QueryLocator getAdjustmentsNotYetInZuora(Boolean typeIsUsage, ZuoraCreditMemoBatchSend.AdjustmentType mode) {
        String queryString =
            'SELECT ' +
                'Id, Name, ' +
                'Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Utility__r.Name, ' +
                'Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Name, ' +
                'Utility_Account_Subscription__r.Utility_Account_Log__r.Name, ' +
                'Client__r.Account_Number__c, ' +
                'Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c, ' +
                'Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c, ' +
                'Adjustment_Amount__c, ' +
                'Adjustment_Type__c, ' +
                'Discount__c, ' +
                'Credits_Allocated__c, ' +
                'Zuora_Id__c ' +
                'FROM Bill_Adjustment__c ' +
                'WHERE Zuora_Id__c = null ' +
                'AND Approval_Status__c = \'Approved\' ' +
                'AND Externally_Serviced__c = false ' +
                // Ignore Returns, because we'll always create a debit memo for returned payments in Zuora
                'AND Adjustment_Type__c != \'Returned Payment\' ' +
                'AND Adjustment_Type__c != \'Returned Check Payment\' ' +
                'AND Adjustment_Type__c != \'Project Payment Transfer\' ';

        if (typeIsUsage){
            queryString += 'AND Adjustment_Type__c = \'Production\' ';
            queryString += 'AND Adjustment_Amount__c > 0 ';
        } else {
            queryString += 'AND(Adjustment_Type__c != \'Production\' ';
            queryString += 'OR Adjustment_Amount__c < 0) ';
        }

        if (mode == ZuoraCreditMemoBatchSend.AdjustmentType.PostWhenApproved){
            queryString += 'AND Effective__c = \'Post When Approved\' ';
        }

        queryString += ' ORDER BY Utility_Account_Subscription__r.Opportunity__r.AccountId';

        return Database.getQueryLocator(queryString);
    }

    public Map<String,List<Bill_Adjustment__c>> getAdjustmentMapFromExternalIds(Set<String> zuoraIds){
        Map<String,List<Bill_Adjustment__c>> externalIdToAdjustMap = new Map<String,List<Bill_Adjustment__c>>();
        List<Bill_Adjustment__c> adjustList = [
            SELECT Id, Transfer__c, Discount__c, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c IN : zuoraIds
        ];
        for (Bill_Adjustment__c adjust : adjustList) {
            if (externalIdToAdjustMap.containsKey(adjust.Zuora_Id__c)){
                List<Bill_Adjustment__c> existingList = externalIdToAdjustMap.get(adjust.Zuora_Id__c);
                existingList.add(adjust);
                externalIdToAdjustMap.put(adjust.Zuora_Id__c,existingList);
            } else {
                externalIdToAdjustMap.put(adjust.Zuora_Id__c,new List<Bill_Adjustment__c>{adjust});
            }
        }
        return externalIdToAdjustMap;
    }

    public List<Bill_Adjustment__c> getAdjustmentsFromExternalIds(Set<String> zuoraIds){
        List<Bill_Adjustment__c> adjustments = [
            SELECT Id, Transfer__c, Discount__c, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c IN : zuoraIds
        ];
        return adjustments;
    }

    public List<Bill_Adjustment__c> getUnservicedWithoutProductionDetail(Integer batchSize){
        return new List<Bill_Adjustment__c>([
            SELECT Id, Externally_Serviced__c, Transfer__c, Credits_Allocated__c
            FROM Bill_Adjustment__c
            WHERE Externally_Serviced__c = true
            AND Ready_for_Production_Detail__c = true
            LIMIT : batchSize
        ]);
    }
}