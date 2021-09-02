/**
 * @description Lead trigger
 * Tested By: LeadServiceTestclass, LeadTriggerHandlerTest, CSLeadsDuplicateServiceTest
 */
trigger LeadTrigger on Lead (before insert, after insert, before update, after update ) {
    if (Util.isDisabled('Disable_LeadTrigger__c')) {
        return;
    }
    LeadTriggerHandler handler = new LeadTriggerHandler(Trigger.new, Trigger.oldMap);
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.beforeInsert();
        }
        when AFTER_INSERT {
            handler.afterInsert();
        }
        when BEFORE_UPDATE {
            handler.beforeUpdate();
        }
        when AFTER_UPDATE {
            handler.afterUpdate();
        }
    }
}