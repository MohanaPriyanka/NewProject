/**
 * Created by PeterYao on 3/4/2019.
 * Tested by: ClientReportingServiceTest, AdjustmentSelectorTest
 */

trigger BillAdjustmentTrigger on Bill_Adjustment__c (before insert, before update) {
    if (Util.isDisabled('Disable_BillAdjustmentTrigger__c')) {
        return;
    }
    if (Trigger.isInsert && Trigger.isBefore) {
        ClientReportingService.stampClient(Trigger.new);
        ProductionDetailBillService.setUnservicedAdjustReadyForProdDetail(Trigger.new);
    }
    if (Trigger.isUpdate && Trigger.isBefore){
        ZuoraCreditDebitMemoService.beforeAdjustmentUpdate(Trigger.new);
    }
}