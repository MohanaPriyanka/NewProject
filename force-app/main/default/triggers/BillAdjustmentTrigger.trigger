/**
 * Created by PeterYao on 3/4/2019.
 * Tested by: ClientReportingServiceTest, AdjustmentSelectorTest
 */

trigger BillAdjustmentTrigger on Bill_Adjustment__c (before insert, before update, before delete) {
    if (Util.isDisabled('Disable_BillAdjustmentTrigger__c')) {
        return;
    }
    ProductionDetailUnservicedService unservicedService = new ProductionDetailUnservicedService();
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            ClientReportingService.stampClient(Trigger.new);
            unservicedService.setUnservicedAdjustReadyForProdDetailBeforeInsert(Trigger.new);
        } when BEFORE_UPDATE {
            ZuoraCreditDebitMemoService.beforeAdjustmentUpdate(Trigger.new);
            unservicedService.setUnservicedAdjustReadyForProdDetailBeforeUpdate(Trigger.oldMap, Trigger.new);
            unservicedService.handleUnservicedAndApprovalUpdateBeforeUpdate(Trigger.oldMap, Trigger.new);
        } when BEFORE_DELETE {
            unservicedService.deletePDsBeforeAdjustmentDelete(Trigger.old);
        }
    }
}