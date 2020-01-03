/**
 * Tested by: ClientReportingServiceTest
 */

trigger UASBTrigger on UASB__c (before insert) {
    if (Util.isDisabled('Disable_UASBTrigger__c')) {
        return;
    }
    if (Trigger.isInsert && Trigger.isBefore) {
        ClientReportingService.stampClient(Trigger.new);
    }
}