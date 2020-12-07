/*
 * Tested by: OpportunityTriggerTest,LeadTriggerHandlerTest,CSCancellationServiceTest,DisbursalHandlerTest,LoanHandlerTestClass
 */

trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update, after delete) {
    if (Util.isDisabled('Disable_OpportunityTrigger__c')) {
        return;
    }
    OpportunityTriggerHandler opportunityTriggerHandler = new OpportunityTriggerHandler();
    LoanHandler loanAction = new LoanHandler (Trigger.isExecuting, Trigger.size);
    DisbursalHandler disbursalHandler = new DisbursalHandler ();

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            opportunityTriggerHandler.onBeforeInsert(Trigger.new);
        } when AFTER_INSERT {
            CSApplicationStatusEvaluator.publishEvent(null, Trigger.new);
        } when BEFORE_UPDATE {
            opportunityTriggerHandler.onBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        } when AFTER_UPDATE {
            loanAction.onAfterOpportunityUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
            disbursalHandler.createDisbursalsFromOpportunity(Trigger.newMap, Trigger.oldMap);
            disbursalHandler.setContractDisbursalToReady(Trigger.new, Trigger.newMap, Trigger.oldMap);
            opportunityTriggerHandler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
            opportunityTriggerHandler.queueNMCTariffChange(Trigger.new, Trigger.oldMap);
            CSApplicationStatusEvaluator.publishEvent(Trigger.oldMap, Trigger.new);
        } when AFTER_DELETE {
            CSApplicationStatusEvaluator.publishEventAfterDelete(Trigger.old);
        }
    }
}