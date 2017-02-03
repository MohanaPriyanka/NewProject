trigger opportunityTrigger on opportunity (before insert, after insert, before update, after update) {
    LoanHandler loanAction = new LoanHandler (Trigger.isExecuting, Trigger.size);
    ChargentOrderCreationhandler chargentOrderAction = new ChargentOrderCreationhandler(Trigger.isExecuting, Trigger.size);

    if(Trigger.isUpdate && Trigger.isAfter){
        loanAction.onAfterOpportunityUpdate(Trigger.new, Trigger.old);
        loanAction.createDisbursalsFromOpportunity(Trigger.new, Trigger.old);
    }
    if(Trigger.isUpdate && Trigger.isBefore){
        chargentOrderAction.onBeforeUpdate(Trigger.new, Trigger.old);
    }    
}