/**
 * Created by mstackhouse on 5/15/2018.
 */

trigger ScheduleZTrigger on Schedule_Z__c (after insert, after update) {
    if (Util.isDisabled('Disable_ScheduleZTrigger__c')) {
        return;
    }
    if (Trigger.isInsert && Trigger.isAfter) {
        ScheduleZTriggerHandler.createSubscriptions(Trigger.new);
        ScheduleZTriggerHandler.handleNewlyEnactedScheduleZ(null, Trigger.new);
    } else if (Trigger.isUpdate && Trigger.isAfter) {
        ScheduleZTriggerHandler.handleNewlyEnactedScheduleZ(Trigger.oldMap, Trigger.new);
    }
}