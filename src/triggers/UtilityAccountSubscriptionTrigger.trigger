/**
 * @description Created by SarahRenfro on 8/6/2019.
 * Tested By: UtilityAccountSubscriptionHandlerTest and ClientReportingServiceTest
 */
trigger UtilityAccountSubscriptionTrigger on Utility_Account_Subscription__c (
    before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    if (Util.isDisabled('Disable_Client_Objects_Trigger__c')) {
        return;
    }
    UtilityAccountSubscriptionHandler handler = new UtilityAccountSubscriptionHandler(
        Trigger.oldMap, Trigger.new, Trigger.operationType);
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.beforeInsert();
        } when AFTER_INSERT {
            handler.afterInsert();
        } when BEFORE_UPDATE {
            handler.beforeUpdate();
        } when AFTER_UPDATE {
            handler.afterUpdate();
        } when BEFORE_DELETE {
            handler.beforeDelete();
        } when AFTER_DELETE {
            handler.afterDelete();
        } when AFTER_UNDELETE {
            handler.afterUndelete();
        }
    }
}