/*
 * Tested by: OpportunityTriggerTest,LeadTriggerHandlerTest,CSCancellationServiceTest,DisbursalHandlerTest,LoanHandlerTestClass
 */

trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update) {
    if (Util.isDisabled('Disable_OpportunityTrigger__c')) {
        return;
    }
    OpportunityTriggerHandler opportunityTriggerHandler = new OpportunityTriggerHandler();
    LoanHandler loanAction = new LoanHandler (Trigger.isExecuting, Trigger.size);
    DisbursalHandler disbursalHandler = new DisbursalHandler ();

    if (Trigger.isUpdate && Trigger.isAfter) {
        loanAction.onAfterOpportunityUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
        disbursalHandler.createDisbursalsFromOpportunity(Trigger.newMap, Trigger.oldMap);
        disbursalHandler.setContractDisbursalToReady(Trigger.new, Trigger.newMap, Trigger.oldMap);
        opportunityTriggerHandler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }
    
    if (Trigger.isInsert && Trigger.isBefore) {
        opportunityTriggerHandler.OnBeforeInsert(Trigger.new);
    } else if(Trigger.isUpdate && Trigger.isBefore) {
        opportunityTriggerHandler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
}