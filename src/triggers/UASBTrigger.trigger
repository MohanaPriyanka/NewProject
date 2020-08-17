/**
 * Tested by: ClientReportingServiceTest, UASBSelectorTest
 */

trigger UASBTrigger on UASB__c (before insert, before delete) {
    if (Util.isDisabled('Disable_UASBTrigger__c')) {
        return;
    }

    switch on Trigger.operationType {
        when BEFORE_INSERT{
            ClientReportingService.stampClient(Trigger.new);
            ProductionDetailBillService.setUnservicedUASBReadyForProdDetail(Trigger.new);
        }
        when BEFORE_DELETE {
            new UASBs(Trigger.old).validate();
        }
    }
}