/**
 * @description Created by jeffparlin on 5/9/22.
 * Tested By: PartnerCommissionGenerationTest
 */
public without sharing class CommissionPaymentTriggerHandler {

    @TestVisible private static CommissionPaymentSelector paymentSelector = new CommissionPaymentSelector();
    @TestVisible private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{
            Subscription_Order__c.SObjectType
        }
    );

    private Map<Id, Commission_Payment__c> oldMap;
    private List<Commission_Payment__c> newList;

    public CommissionPaymentTriggerHandler(Map<Id, Commission_Payment__c> oldMap, List<Commission_Payment__c> newList) {
        this.oldMap = oldMap;
        this.newList = newList;
    }

    public void afterUpdate() {
        finalizeCommissionAmountsOnSubscriptionOrders();
    }

    /**
     * @description Stamps Amount fields on Subscription Orders related to "Approved" Commission Payments
     */
    private void finalizeCommissionAmountsOnSubscriptionOrders() {
        Set<Id> approvedPayments = (Set<Id>) new SObjectFilter(
            oldMap, newList, Commission_Payment__c.Status__c, SObjectFilter.ANY_VALUE, 'Approved'
        ).get(SObjectFilter.SOBJECT_ID_SET);
        if (approvedPayments != null && !approvedPayments.isEmpty()) {
            stampOrders(approvedPayments);
        }
    }

    private void stampOrders(Set<Id> paymentIds) {
        List<Commission_Payment__c> payments = paymentSelector.getWithSubscriptionOrdersById(paymentIds);
        for (Commission_Payment__c payment : payments) {
            for (Subscription_Order__c order : payment.Subscription_Orders__r) {
                order.Contract_Close_Commission_Amount__c = order.Contract_Close_Estimated_Commission__c;
                uow.registerDirty(order, new List<SObjectField>{Subscription_Order__c.Contract_Close_Commission_Amount__c});
            }
            for (Subscription_Order__c order : payment.First_Bill_Subscription_Orders__r) {
                order.First_Bill_Sent_Commission_Amount__c = order.First_Bill_Sent_Estimated_Commission__c;
                uow.registerDirty(order, new List<SObjectField>{Subscription_Order__c.First_Bill_Sent_Commission_Amount__c});
            }
            for (Subscription_Order__c order : payment.First_Bill_Paid_Subscription_Orders__r) {
                order.First_Bill_Paid_Commission_Amount__c = order.First_Bill_Paid_Estimated_Commission__c;
                uow.registerDirty(order, new List<SObjectField>{Subscription_Order__c.First_Bill_Paid_Commission_Amount__c});
            }
        }
        uow.commitWork();
    }

}