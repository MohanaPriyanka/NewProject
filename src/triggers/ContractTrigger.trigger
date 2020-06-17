/**
 * Created by peteryao on 6/16/20.
 * Tested by: ContractTriggerTest
 */

trigger ContractTrigger on Contract (after update) {
    if (Util.isDisabled('Disable_ContractTrigger__c')) {
        return;
    }
    CustomerAssignmentService customerAssignmentService = new CustomerAssignmentService();

    switch on Trigger.operationType {
        when AFTER_UPDATE {
            customerAssignmentService.updateAssignmentAgreements(Trigger.oldMap, Trigger.newMap);
        }
    }
}