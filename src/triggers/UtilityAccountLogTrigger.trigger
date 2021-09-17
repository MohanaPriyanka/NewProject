/**
 * @description: Created by mstackhouse on 12/17/2018.
 * Tested By: UtilityAccountLogTriggerHandlerTest, CSCancellationServiceTest
 */
trigger UtilityAccountLogTrigger on Utility_Account_Log__c (before insert, before update, after update) {
    if (Util.isDisabled('Disable_UtilityAccountLogTrigger__c')) {
        return;
    }
    UtilityAccountLogTriggerHandler handler = new UtilityAccountLogTriggerHandler(Trigger.oldMap, Trigger.new);
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.beforeInsert();
        } when BEFORE_UPDATE {
            handler.beforeUpdate();
        } when AFTER_UPDATE {
            handler.afterUpdate();
        }
    }
}