/**
 * @description Executes Zuora account creation logic when posted from platform event
 * Tested By: CSLeadsRESTControllerV2
 */
trigger ZuoraAccountCreateEventTrigger on Zuora_Account_Create_Event__e (after insert) {
    Set<Id> leadIdsToProcess = new Set<Id>();
    for (Zuora_Account_Create_Event__e event : Trigger.new) {
        leadIdsToProcess.add(event.Lead_Id__c);
    }
    ZuoraAccountService.createAccounts(leadIdsToProcess);
}