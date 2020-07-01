/**
 * Created by peteryao on 6/16/20.
 * Tested by: ContractTriggerTest
 */

trigger ContractTrigger on Contract (after update, after insert, after delete, after undelete) {
    if (Util.isDisabled('Disable_ContractTrigger__c')) {
        return;
    }
    CustomerAssignmentService customerAssignmentService = new CustomerAssignmentService();
    ClientReportingService clientReportingService = new ClientReportingService();

    switch on Trigger.operationType {
        when AFTER_INSERT {
            clientReportingService.rollupActiveContractsToAccounts(null, Trigger.newMap);
        }
        when AFTER_UPDATE {
            customerAssignmentService.updateAssignmentAgreements(Trigger.oldMap, Trigger.newMap);
            clientReportingService.rollupActiveContractsToAccounts(Trigger.oldMap, Trigger.newMap);
        }
        when AFTER_DELETE {
            clientReportingService.rollupActiveContractsToAccounts(Trigger.oldMap, null);
        }
        when AFTER_UNDELETE {
            clientReportingService.rollupActiveContractsToAccounts(null, Trigger.newMap);
        }
    }
}