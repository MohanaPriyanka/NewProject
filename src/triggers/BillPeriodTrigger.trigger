/**
 * Created by SarahRenfro on 11/7/2019.
 */

trigger BillPeriodTrigger on Bill_Period__c (before insert, after insert, before update) {
    if (Util.isDisabled('Disable_BillPeriod_Trigger__c')) {
        return;
    }

    BillPeriodService billPeriodService = new BillPeriodService();
    ClientReportingService clientReportingService = new ClientReportingService();

    if (Trigger.isAfter && Trigger.isInsert) {
        billPeriodService.onAfterInsert(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isInsert){
        clientReportingService.stampClient(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
        billPeriodService.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}