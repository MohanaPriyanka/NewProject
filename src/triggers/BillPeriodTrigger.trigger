/**
 * Created by SarahRenfro on 11/7/2019.
 */

trigger BillPeriodTrigger on Bill_Period__c (after insert, before update) {
    if (Util.isDisabled('Disable_BillPeriod_Trigger__c')) {
        return;
    }

    BillPeriodService billPeriodService = new BillPeriodService();

    if (Trigger.isAfter && Trigger.isInsert) {
        billPeriodService.onAfterInsert(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
        billPeriodService.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}