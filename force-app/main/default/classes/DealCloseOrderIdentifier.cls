/**
 * @description Created by jeffparlin on 4/7/22. Identifies Subscription Orders which are a part of a deal
 * Countersignature, needed (at least) in VariableRateCommissionProcessor to correctly identify
 * Subscription Orders to be included in Commission Payments (see W-024422)
 * Tested By: PartnerCommissionGenerationTest
 */

public without sharing class DealCloseOrderIdentifier {

    private static SubscriptionOrderSelector soSelector = new SubscriptionOrderSelector();

    @InvocableMethod(
        Label='Deal Close Order Identifier'
        Description = 'Flags Subscription Orders which are a part of deal close at Countersignature')
    public static void flagOrders(List<List<Opportunity>> opportunities) {
        List<Subscription_Order__c> orders = soSelector.getCurrentSubscriptionOrdersForOpportunities(opportunities[0]);
        for (Subscription_Order__c order : orders) {
            order.Included_in_Contract_Close__c = true;
        }
        update orders;
    }

}