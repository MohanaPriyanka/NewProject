/**
* Created by mstackhouse on 5/15/2018.
*/

trigger ScheduleZTrigger on Schedule_Z__c (before insert,before update, after insert, after update) {
    if (Util.isDisabled('Disable_ScheduleZTrigger__c')) {
        return;
    }
   
    switch on Trigger.operationType {
        when BEFORE_INSERT{
            ScheduleZTriggerHandler.onBeforeInsert(Trigger.new); 
        } when BEFORE_UPDATE{
            ScheduleZTriggerHandler.onBeforeUpdate(Trigger.new);
        }  when AFTER_INSERT {
            ScheduleZTriggerHandler.onAfterInsert(Trigger.new);
        }  when AFTER_UPDATE {
            ScheduleZTriggerHandler.onAfterUpdate(Trigger.oldMap,Trigger.new);
        } 
    }
    
}