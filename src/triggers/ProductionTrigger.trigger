/**
 * Created by SarahRenfro on 1/9/2020.
 *
 * Tested By: ClientReportingServiceTest
 */

trigger ProductionTrigger on Production__c (before insert) {
    if (Util.isDisabled('Disable_ProductionTrigger__c')) {
        return;
    }

    ClientReportingService clientReportingService = new ClientReportingService();

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            clientReportingService.stampClient(Trigger.new);
        }
    }
}