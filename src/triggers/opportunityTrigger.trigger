trigger opportunityTrigger on opportunity (before insert, after insert, before update, after update) {
    LoanHandler loanAction = new LoanHandler (Trigger.isExecuting, Trigger.size);
    
    if(Trigger.isUpdate && Trigger.isAfter){
        loanAction.onAfterOpportunityUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
        loanAction.createDisbursalsFromOpportunity(Trigger.new, Trigger.old);
    }
    if(Trigger.isUpdate && Trigger.isBefore){
        ChargentOrderCreationhandler.ChargentOrderCreation(Trigger.new, Trigger.old);
    }    
}