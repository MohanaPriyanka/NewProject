/**
 * Tested by: ClientReportingServiceTest, UASBSelectorTest
 */

trigger UASBTrigger on UASB__c (before insert, before delete, before update) {
    if (Util.isDisabled('Disable_UASBTrigger__c')) {
        return;
    }
    ProductionDetailUnservicedService unservicedService = new ProductionDetailUnservicedService();
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            ClientReportingService.stampClient(Trigger.new);
            unservicedService.setUnservicedUASBReadyForProdDetailBeforeInsert(Trigger.new);
        } when BEFORE_DELETE {
            new UASBs(Trigger.old).validate();
            unservicedService.deletePDsBeforeUASBDelete(Trigger.old);
        } when BEFORE_UPDATE {
            unservicedService.handleUnservicedUASBUpdateBeforeUpdate(Trigger.oldMap, Trigger.new);
        }
    }
}