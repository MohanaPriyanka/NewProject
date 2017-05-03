trigger CaseTrigger on Case (before insert, after insert, before update, after update ) {
    CaseEscalationHandler handler = new CaseEscalationHandler (Trigger.isExecuting, Trigger.size);

    if(Trigger.isInsert && Trigger.isAfter){
          handler.OnAfterInsert(Trigger.new);   
    }
}