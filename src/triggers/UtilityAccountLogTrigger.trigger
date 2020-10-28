/**
 * Created by mstackhouse on 12/17/2018.
 * Description: 
 * Test: UtilityAccountLogTriggerHandler, CSCancellationService
 */


trigger UtilityAccountLogTrigger on Utility_Account_Log__c (before insert, before update, after update) {
    if (Util.isDisabled('Disable_UtilityAccountLogTrigger__c')) {
        return;
    }
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            UtilityAccountLogTriggerHandler.setCleanedUtilityAccountNumberBeforeSave(Trigger.new);
        } when BEFORE_UPDATE {
            UtilityAccountLogTriggerHandler.setCleanedUtilityAccountNumberBeforeSave(Trigger.new);
            UtilityAccountLogTriggerHandler.updateProposedkWh(Trigger.new, Trigger.oldMap);
        } when AFTER_UPDATE {
            UtilityAccountLogTriggerHandler.onAfterUpdate(Trigger.oldMap, Trigger.new);
        }
    }
}