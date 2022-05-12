/**
 * @description Created by Jordan Pentaleri 5/6/20.
 * Tested By: CommissionPaymentSelectorTest, PartnerCommissionGenerationTest
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

    public List<Commission_Payment__c> getWithSubscriptionOrdersBySingleOpp(Id opportunityId) {
        return [
            SELECT Id, Status__c, Amount_Due__c, Contract_Execution_Amount__c, First_Bill_Sent_Amount__c,
                First_Bill_Paid_Amount__c,
                (SELECT Id, Contract_Close_Estimated_Commission__c, First_Bill_Sent_Estimated_Commission__c,
                    First_Bill_Paid_Estimated_Commission__c
                FROM Subscription_Orders__r),
                (SELECT Id, Contract_Close_Estimated_Commission__c, First_Bill_Sent_Estimated_Commission__c,
                    First_Bill_Paid_Estimated_Commission__c
                FROM First_Bill_Subscription_Orders__r),
                (SELECT Id, Contract_Close_Estimated_Commission__c, First_Bill_Sent_Estimated_Commission__c,
                    First_Bill_Paid_Estimated_Commission__c
                FROM First_Bill_Paid_Subscription_Orders__r)
            FROM Commission_Payment__c
            WHERE Opportunity__c =: opportunityId
        ];
    }

    public List<Commission_Payment__c> getWithSubscriptionOrdersById(Set<Id> paymentIds) {
        return [
            SELECT Id, Status__c, Amount_Due__c, Contract_Execution_Amount__c, First_Bill_Sent_Amount__c,
                First_Bill_Paid_Amount__c,
            (SELECT Id, Contract_Close_Estimated_Commission__c, First_Bill_Sent_Estimated_Commission__c,
                First_Bill_Paid_Estimated_Commission__c, Contract_Close_Commission_Amount__c,
                First_Bill_Sent_Commission_Amount__c, First_Bill_Paid_Commission_Amount__c
            FROM Subscription_Orders__r),
            (SELECT Id, Contract_Close_Estimated_Commission__c, First_Bill_Sent_Estimated_Commission__c,
                First_Bill_Paid_Estimated_Commission__c,Contract_Close_Commission_Amount__c,
                First_Bill_Sent_Commission_Amount__c, First_Bill_Paid_Commission_Amount__c
            FROM First_Bill_Subscription_Orders__r),
            (SELECT Id, Contract_Close_Estimated_Commission__c, First_Bill_Sent_Estimated_Commission__c,
                First_Bill_Paid_Estimated_Commission__c,Contract_Close_Commission_Amount__c,
                First_Bill_Sent_Commission_Amount__c, First_Bill_Paid_Commission_Amount__c
            FROM First_Bill_Paid_Subscription_Orders__r)
            FROM Commission_Payment__c
            WHERE Id IN : paymentIds
        ];
    }
}