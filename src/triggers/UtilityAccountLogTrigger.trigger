/**
 * Created by mstackhouse on 12/17/2018.
 * Description: 
 * Test: 
 */


trigger UtilityAccountLogTrigger on Utility_Account_Log__c (before update, after update) {
    if (Util.isDisabled('Disable_UtilityAccountLogTrigger__c')) {
        return;
    }
    if (Trigger.isUpdate && Trigger.isBefore) {
        UtilityAccountLogTriggerHandler.updateProposedkWh(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isUpdate && Trigger.isAfter) {
        List<Utility_Account_Subscription__c> uasesToFinal =
            CSCancellationService.getUASesForFinaledUALs(Trigger.new, Trigger.oldMap);
        if (!uasesToFinal.isEmpty()) {
            CSCancellationService.processFinaledUtilityAccounts(uasesToFinal);
        }
    }
}