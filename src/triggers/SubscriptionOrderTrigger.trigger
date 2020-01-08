/**
 * Created by SarahRenfro on 11/14/2019.
 *
 * Tested By: SubscriptionOrderServiceTest
 */

trigger SubscriptionOrderTrigger on Subscription_Order__c (before insert) {
    if (Util.isDisabled('Disable_SubscriptionOrder_Trigger__c')) {
        return;
    }

    SubscriptionManagementService subscriptionManagementService = new SubscriptionManagementService();

    if (Trigger.isBefore && Trigger.isInsert) {
        subscriptionManagementService.populateSubscriptionOrder(Trigger.new);
    }
}