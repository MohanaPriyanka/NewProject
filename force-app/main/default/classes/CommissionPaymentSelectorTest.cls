@IsTest
public with sharing class CommissionPaymentSelectorTest {

    @IsTest
    public static void testGetPendingCommissionPayments() {
        CommissionPaymentSelector selector = new CommissionPaymentSelector();
        selector.getPendingCommissionPayments(new Set<Id>{Util.getFakeId(Opportunity.SObjectType)}, 'Contract Execution');
    }

    @IsTest
    public static void testGetByOppForVariableCommission() {
        CommissionPaymentSelector selector = new CommissionPaymentSelector();
        selector.getByOppForVariableCommission(new Set<Id>{Util.getFakeId(Opportunity.SObjectType)});
    }

    @IsTest
    public static void testGetWithSubscriptionOrdersBySingleOpp() {
        CommissionPaymentSelector selector = new CommissionPaymentSelector();
        selector.getWithSubscriptionOrdersBySingleOpp(Util.getFakeId(Opportunity.SObjectType));
    }

    @IsTest
    public static void testGetWithSubscriptionOrdersById() {
        CommissionPaymentSelector selector = new CommissionPaymentSelector();
        selector.getWithSubscriptionOrdersById(new Set<Id>{Util.getFakeId(Commission_Payment__c.SObjectType)});
    }

}