/**
 * Created by SarahRenfro on 11/14/2019.
 *
 * Tested By: SubscriptionManagementServiceTest
 */
trigger SubscriptionOrderTrigger on Subscription_Order__c (before insert, after update, after insert) {
    if (Util.isDisabled('Disable_SubscriptionOrder_Trigger__c')) {
        return;
    }
    SubscriptionManagementService subscriptionManagementService = new SubscriptionManagementService();

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            subscriptionManagementService.populateSubscriptionOrder(Trigger.new);
        } when AFTER_INSERT {
            subscriptionManagementService.checkSOApproval(Trigger.new, Trigger.oldMap);
        } when AFTER_UPDATE {
            subscriptionManagementService.checkSOApproval(Trigger.new, Trigger.oldMap);
        }
    }
}