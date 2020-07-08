@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ClientInvoicingMemoSelector {

    public Map<Id,Decimal> getWaivedFeesBySSS(Set<Id> sssIds){
        Map<Id,Decimal> sssIdToTotalWaivedkWMap = new Map<Id,Decimal>();

        List<AggregateResult> waivedKWBySSS = [
            SELECT Sum(Subscription_Order__r.Approved_Change_in_Subscription__c) kWSum,
                Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__c sssId
            FROM Client_Invoicing_Memo__c
            WHERE Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__c IN : sssIds
            GROUP BY Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__c
        ];

        for (AggregateResult aggregateResult : waivedKWBySSS) {
            sssIdToTotalWaivedkWMap.put((Id)aggregateResult.get('sssId'),(Decimal)aggregateResult.get('kWSum'));
        }
        return sssIdToTotalWaivedkWMap;
    }
}