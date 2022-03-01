/**
 * Test: CommissionPaymentSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class CommissionPaymentSelector {
    public List<Commission_Payment__c> getPendingCommissionPayments(Set<Id> oppIds, String type) {
        List<Commission_Payment__c> commissionPayments = [
            SELECT Id, Opportunity__c, Amount_Due__c, Commission_Structure__c
            FROM Commission_Payment__c
            WHERE Opportunity__c IN : oppIds
            AND Commission_Type__c = : type
            AND Status__c = 'Pending Approval'
            ORDER BY CreatedDate
        ];
        return commissionPayments;
    }

    public Map<Id,List<Commission_Payment__c>> getByOppForVariableCommission(Set<Id> opportunityIds) {
        Map<Id,List<Commission_Payment__c>> returnMap = new Map<Id,List<Commission_Payment__c>>();
        for (Commission_Payment__c payment : [
            SELECT Id, Opportunity__c, Commission_Type__c, Amount_Due__c
            FROM Commission_Payment__c
            WHERE Opportunity__c IN : opportunityIds
            ORDER BY CreatedDate ASC])
        {
            Id oppId = payment.Opportunity__c;
            if (returnMap.keySet().contains(oppId)) {
                List<Commission_Payment__c> payments = returnMap.get(oppId);
                payments.add(payment);
                returnMap.put(oppId, payments);
            } else {
                returnMap.put(oppId, new List<Commission_Payment__c>{payment});
            }
        }
        return returnMap;
    }
}