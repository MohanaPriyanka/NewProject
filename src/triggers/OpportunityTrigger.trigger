/**
 * @description Created by pyao 11/10/16
 */
trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update, after delete) {
    if (Util.isDisabled('Disable_OpportunityTrigger__c')) {
        return;
    }
    OpportunityTriggerHandler handler = new OpportunityTriggerHandler(Trigger.oldMap, Trigger.newMap, Trigger.new);
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.beforeInsert();
        } when AFTER_INSERT {
            handler.afterInsert();
        } when BEFORE_UPDATE {
            handler.beforeUpdate();
        } when AFTER_UPDATE {
            handler.afterUpdate();
        } when AFTER_DELETE {
            handler.afterDelete();
        }
    }
}