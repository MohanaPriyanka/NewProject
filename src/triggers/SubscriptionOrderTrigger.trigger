/**
 * Created by SarahRenfro on 11/14/2019.
 *
 * Tested By: SubscriptionManagementServiceTest
 */
trigger SubscriptionOrderTrigger on Subscription_Order__c (before insert, before update) {
    if (Util.isDisabled('Disable_SubscriptionOrder_Trigger__c')) {
        return;
    }
    SubscriptionManagementService subscriptionManagementService = new SubscriptionManagementService();

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            subscriptionManagementService.populateSubscriptionOrder(Trigger.new);
        } when BEFORE_UPDATE {
            subscriptionManagementService.checkSOApproval(Trigger.new, Trigger.oldMap);
        }
    }
}