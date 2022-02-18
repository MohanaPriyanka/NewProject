/**
 * @description Trigger on Shared_Solar_System__c
 * Tested By: SharedSolarSystemHandlerTest
 */
trigger SharedSolarSystemTrigger on Shared_Solar_System__c (before insert, before update, after update) {
    if (Util.isDisabled('Disable_SharedSolarSystemTrigger__c')) {
        return;
    }
    SharedSolarSystemHandler handler = new SharedSolarSystemHandler(Trigger.oldMap, Trigger.newMap, Trigger.new);
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