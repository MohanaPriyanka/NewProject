/**
 * @description Created by sagar gorakala 03/23/22
 */
trigger EmailMessageTrigger on EmailMessage(after insert, after update) {
    if (Util.isDisabled('Disable_EmailMessageTrigger__c')) { 
        return; 
    }
    EmailMessageTriggerHandler handler = new EmailMessageTriggerHandler(Trigger.oldMap, Trigger.newMap, Trigger.new);
    switch on Trigger.operationType {
        when AFTER_INSERT {
            handler.afterInsert();
        }
    }
}