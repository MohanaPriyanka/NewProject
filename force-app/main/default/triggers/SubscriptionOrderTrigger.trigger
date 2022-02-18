/**
 * @description Created by SarahRenfro on 11/14/2019.
 * Tested By: SubscriptionManagementServiceTest, SubscriptionSizingTestclass
 */
trigger SubscriptionOrderTrigger on Subscription_Order__c (before insert, after insert, before delete) {
    if (Util.isDisabled('Disable_SubscriptionOrder_Trigger__c')) {
        return;
    }
    SubscriptionOrderTriggerHandler handler = new SubscriptionOrderTriggerHandler(Trigger.oldMap, Trigger.newMap, Trigger.new);
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.beforeInsert();
        } when AFTER_INSERT {
            handler.afterInsert();
        } when BEFORE_DELETE {
            handler.beforeDelete();
        }
    }
}