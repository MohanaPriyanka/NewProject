/**
 * Created by mstackhouse on 5/15/2018.
 */

trigger ScheduleZTrigger on Schedule_Z__c (after insert, after update) {
    if (Trigger.isInsert && Trigger.isAfter) {
        ScheduleZTriggerHandler.createSubscriptions(Trigger.new);
    } else if (Trigger.isUpdate && Trigger.isAfter) {
        ScheduleZTriggerHandler.handleDates(Trigger.old, Trigger.new);
    }
}