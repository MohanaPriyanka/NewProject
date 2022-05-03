/*
 * Tested by: ZuoraUsageServiceTest, ZuoraCreditDebitMemoServiceTest, AdjustmentSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class AdjustmentSelector {
    /**
     * @description Used to get all adjustments to send to Zuora, with no Id filter (used by the Bill Gen Console)
     * @param typeIsUsage  True to select positive Production adjustments
     * @param mode Selects adjustments that are Post When Approved
     * @return QueryLocator of Bill Adjustments to send to Zuora
     */
    public static Database.QueryLocator getAdjustmentsNotYetInZuora(Boolean typeIsUsage, ZuoraCreditMemoBatchSend.AdjustmentType mode) {
        return getAdjustmentsNotYetInZuora(typeIsUsage, mode, new Set<Id>());
    }

    public static Database.QueryLocator getAdjustmentsNotYetInZuora(Boolean typeIsUsage, ZuoraCreditMemoBatchSend.AdjustmentType mode, Set<Id> billAdjustmentIds) {
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
                'Zuora_Id__c, ' +
                'Transfer__r.Date_of_Transfer__c ' +
                'FROM Bill_Adjustment__c ' +
                'WHERE Zuora_Id__c = null ' +
                'AND Approval_Status__c = \'Approved\' ' +
                // handle various UCB and externally serviced permutations
                'AND (' +
                '(Utility_Account_Subscription__r.Shared_Solar_System__r.UCB__c = TRUE AND Utility_Account_Subscription__r.Externally_Serviced_Override__c = \'Internally Serviced\') ' +
                'OR (Utility_Account_Subscription__r.Shared_Solar_System__r.UCB__c = FALSE AND ' +
                '        Utility_Account_Subscription__r.Externally_Serviced__c = FALSE AND ' +
                '        Externally_Serviced__c = FALSE)' +
                ') ' +
                // Ignore Returns, because we'll always create a debit memo for returned payments in Zuora
                'AND Adjustment_Type__c != \'Returned Payment\' ' +
                'AND Adjustment_Type__c != \'Returned Check Payment\' ' +
                'AND Adjustment_Type__c != \'Project Payment Transfer\' ';

        if (typeIsUsage) {
            queryString += 'AND Adjustment_Type__c = \'Production\' ';
            queryString += 'AND Adjustment_Amount__c >= 0 ';
        } else {
            queryString += 'AND(Adjustment_Type__c != \'Production\' ';
            queryString += 'OR Adjustment_Amount__c < 0) ';
        }

        if (mode == ZuoraCreditMemoBatchSend.AdjustmentType.POST_WHEN_APPROVED) {
            queryString += 'AND Effective__c = \'Post When Approved\' ';
        }
        if (!billAdjustmentIds.isEmpty()) {
            queryString += 'AND Id IN :billAdjustmentIds ';
        }

        queryString += ' ORDER BY Utility_Account_Subscription__r.Opportunity__r.AccountId';
        return Database.getQueryLocator(queryString);
    }

    public Map<String, List<Bill_Adjustment__c>> getAdjustmentMapFromExternalIds(Set<String> zuoraIds) {
        Map<String, List<Bill_Adjustment__c>> externalIdToAdjustMap = new Map<String, List<Bill_Adjustment__c>>();
        List<Bill_Adjustment__c> adjustList = [
            SELECT Id, Transfer__c, Discount__c, Zuora_Id__c, Adjustment_Amount__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c IN :zuoraIds
        ];
        for (Bill_Adjustment__c adjust : adjustList) {
            if (externalIdToAdjustMap.containsKey(adjust.Zuora_Id__c)) {
                List<Bill_Adjustment__c> existingList = externalIdToAdjustMap.get(adjust.Zuora_Id__c);
                existingList.add(adjust);
                externalIdToAdjustMap.put(adjust.Zuora_Id__c, existingList);
            } else {
                externalIdToAdjustMap.put(adjust.Zuora_Id__c, new List<Bill_Adjustment__c>{
                    adjust
                });
            }
        }
        return externalIdToAdjustMap;
    }

    public List<Bill_Adjustment__c> getUnservicedWithoutProductionDetail(Integer batchSize) {
        return new List<Bill_Adjustment__c>([
            SELECT Id, Externally_Serviced__c, Transfer__c, Credits_Allocated__c
            FROM Bill_Adjustment__c
            WHERE Externally_Serviced__c = TRUE
            AND Ready_for_Production_Detail__c = TRUE
            LIMIT :batchSize
        ]);
    }

    public List<AggregateResultProxy> selectForReconciliation(List<Bill_Adjustment__c> billAdjustmentsToReconcile) {
        List<AggregateResultProxy> groupedResultProxies = new List<AggregateResultProxy>();
        for (AggregateResult result : [
            SELECT Externally_Serviced_Bill_Adjustment__c, SUM(Amount__c) AMOUNT
            FROM Transfer_Part__c
            WHERE Externally_Serviced_Bill_Adjustment__c IN :billAdjustmentsToReconcile
            AND Type__c != 'Customer Savings'
            GROUP BY Externally_Serviced_Bill_Adjustment__c
        ]) {
            groupedResultProxies.add(new AggregateResultProxy().withAggregateResult(result));
        }
        return groupedResultProxies;
    }
}