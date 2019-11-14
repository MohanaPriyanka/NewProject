/*
 * Tested by: AccountTriggerHandlerTestClass, CSCancellationServiceTest, ZuoraAccountServiceTest
 */

trigger AccountTrigger on Account (before insert, before update, after update, before delete) {
    if (Util.isDisabled('Disable_AccountTrigger__c')) {
        return;
    }
    AccountTriggerHandler accountTriggerHandler = new AccountTriggerHandler();

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            accountTriggerHandler.onBeforeInsert(Trigger.new);
        } when BEFORE_UPDATE {
            accountTriggerHandler.onBeforeUpdate(Trigger.new);
        } when AFTER_UPDATE {
            accountTriggerHandler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
        } when BEFORE_DELETE {
            accountTriggerHandler.preventZuoraAccountsFromDelete(Trigger.old);
        }
    }
}