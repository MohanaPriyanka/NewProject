/**
 * Created by PeterYao on 3/4/2019.
 * Tested by: ClientReportingServiceTest
 */

trigger BillAdjustmentTrigger on Bill_Adjustment__c (before update) {
    if (Util.isDisabled('Disable_BillAdjustmentTrigger__c')) {
        return;
    }
    if (Trigger.isUpdate && Trigger.isBefore){
        ClientReportingService.beforeAdjustmentUpdate(Trigger.new);
        ZuoraCreditDebitMemoService.beforeAdjustmentUpdate(Trigger.new);
    }
}