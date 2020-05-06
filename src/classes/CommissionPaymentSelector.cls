/**
 * Test: CommissionPaymentSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CommissionPaymentSelector {
    public List<Commission_Payment__c> getPendingCommissionPayments(Set<Id> oppIds, String type) {
        List<Commission_Payment__c> commissionPayments = [
            SELECT Id, Opportunity__c
            FROM Commission_Payment__c
            WHERE Opportunity__c IN : oppIds
            AND Commission_Type__c = : type
            AND Status__c != 'Approved'
            ORDER BY CreatedDate
        ];
        return commissionPayments;
    }
}