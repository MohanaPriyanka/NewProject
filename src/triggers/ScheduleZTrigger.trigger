/**
 * Created by mstackhouse on 5/15/2018.
 */

trigger ScheduleZTrigger on Schedule_Z__c (after insert, after update) {
    if (Util.isDisabled('Disable_ScheduleZTrigger__c')) {
        return;
    }
    ScheduleZTriggerHandler scheduleZTriggerHandler = new ScheduleZTriggerHandler();
    if (Trigger.isInsert && Trigger.isAfter) {
        scheduleZTriggerHandler.insertSubscriptionsForNewALS(Trigger.newMap);
        scheduleZTriggerHandler.handleNewlyEnactedScheduleZ(null, Trigger.new);
    } else if (Trigger.isUpdate && Trigger.isAfter) {
        scheduleZTriggerHandler.handleNewlyEnactedScheduleZ(Trigger.oldMap, Trigger.new);
    }
}