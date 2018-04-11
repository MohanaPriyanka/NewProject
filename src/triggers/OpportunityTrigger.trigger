trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update) {
    OpportunityTriggerHandler opportunityTriggerHandler = new OpportunityTriggerHandler(Trigger.isExecuting, Trigger.size);
    LoanHandler loanAction = new LoanHandler (Trigger.isExecuting, Trigger.size);
    DisbursalHandler disbursalHandler = new DisbursalHandler ();

    if(Trigger.isUpdate && Trigger.isAfter){
        loanAction.onAfterOpportunityUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
        disbursalHandler.createDisbursalsFromOpportunity(Trigger.newMap, Trigger.oldMap);
        disbursalHandler.setContractDisbursalToReady(Trigger.new, Trigger.newMap, Trigger.oldMap);
    }
    
    if(Trigger.isUpdate && Trigger.isBefore){
        ChargentOrderCreationhandler.createChargentOrder(Trigger.new, Trigger.old);
    }

    if(Trigger.isInsert && Trigger.isBefore){
        opportunityTriggerHandler.OnBeforeInsert(Trigger.new);
    }
    else if(Trigger.isUpdate && Trigger.isBefore){
        opportunityTriggerHandler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
}
