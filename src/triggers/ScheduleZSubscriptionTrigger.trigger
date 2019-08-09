/**
 * Created by SarahRenfro on 8/2/2019.
 *
 * As of 7/12/2019, Schedule Z objects are now labeled Allocation Schedule objects while the API Names remain the same.
 * Therefore, when referring to this trigger, it is a trigger for the Allocation Schedule Subscriptions
 *
 * Tested By: ClientReportingService
 */

trigger ScheduleZSubscriptionTrigger on Schedule_Z_Subscription__c (after insert, after update, before delete) {

    if (Util.isDisabled('Disable_Client_Objects_Trigger__c')) {
        return;
    }

    if (Trigger.isInsert) {
        ClientReportingService.insertClientALSS(Trigger.new);
    }

    if (Trigger.isDelete && Trigger.isBefore) {
        ClientReportingService.deleteClientALSS(Trigger.old);
    }
}