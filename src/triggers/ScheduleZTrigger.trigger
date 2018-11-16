/**
 * Created by mstackhouse on 5/15/2018.
 */

trigger ScheduleZTrigger on Schedule_Z__c (after insert) {
    ScheduleZTriggerHandler.createSubscriptions(Trigger.new);
}