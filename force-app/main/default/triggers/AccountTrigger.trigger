/*
 * Tested by: AccountTriggerHandlerTestClass, CSCancellationServiceTest, ZuoraAccountServiceTest
 */

trigger AccountTrigger on Account (after insert, before update, after update, before delete) {
    if (Util.isDisabled('Disable_AccountTrigger__c')) {
        return;
    }
    AccountTriggerHandler accountTriggerHandler = new AccountTriggerHandler();

    switch on Trigger.operationType {
        when AFTER_INSERT {
            accountTriggerHandler.onAfterInsert(Trigger.oldMap, Trigger.newMap);
        } when BEFORE_UPDATE {
            accountTriggerHandler.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        } when AFTER_UPDATE {
            accountTriggerHandler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
        } when BEFORE_DELETE {
            accountTriggerHandler.preventZuoraAccountsFromDelete(Trigger.old);
        }
    }
}