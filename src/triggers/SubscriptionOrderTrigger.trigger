/**
 * Created by SarahRenfro on 11/14/2019.
 */

trigger SubscriptionOrderTrigger on Subscription_Order__c (before insert) {
    SubscriptionOrderService subscriptionOrderService = new SubscriptionOrderService();

    if (Trigger.isBefore && Trigger.isInsert) {
        subscriptionOrderService.onBeforeInsert(Trigger.new);
    }
}