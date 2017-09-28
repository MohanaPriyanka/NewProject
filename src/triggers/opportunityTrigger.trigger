trigger opportunityTrigger on opportunity (before insert, after insert, before update, after update) {
    LoanHandler loanAction = new LoanHandler (Trigger.isExecuting, Trigger.size);
    DisbursalHandler disbursalHandler = new DisbursalHandler ();
    ChargentOrderCreationhandler chargentOrderAction = new ChargentOrderCreationhandler(Trigger.isExecuting, Trigger.size);

    if(Trigger.isUpdate && Trigger.isAfter){
        loanAction.onAfterOpportunityUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
        disbursalHandler.createDisbursalsFromOpportunity(Trigger.newMap, Trigger.oldMap);
    }
    if(Trigger.isUpdate && Trigger.isBefore){
        chargentOrderAction.onBeforeUpdate(Trigger.new, Trigger.old);
    }    
}