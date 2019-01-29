//Test: AccountTriggerHandlerTestClass, CSAccountCancellerTest

trigger AccountTrigger on Account (before insert, before update, after update) {
    if (Util.isDisabled('Disable_AccountTrigger__c')) {
        return;
    }
    AccountTriggerHandler accountTriggerHandler = new AccountTriggerHandler(Trigger.isExecuting, Trigger.size);

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            accountTriggerHandler.OnBeforeInsert(Trigger.new);
        } when BEFORE_UPDATE {
            accountTriggerHandler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        } when AFTER_UPDATE {
            List<Utility_Account_Subscription__c> uasesToCancel =
                CSCancellationService.getUASesForManuallyCancelledAccounts(Trigger.newMap, Trigger.oldMap);
            if (!uasesToCancel.isEmpty()) {
                CSCancellationService.processCustomerCancellation(uasesToCancel);
            }
        }
    }
}