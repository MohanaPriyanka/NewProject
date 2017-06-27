trigger CaseTrigger on Case ( before insert, after insert ) {

    if(Trigger.isInsert && Trigger.isBefore){
          CaseEscalationHandler.findContactFromVM(Trigger.new);
    }

    if(Trigger.isInsert && Trigger.isAfter){
          CaseEscalationHandler.linkTaskToCase(Trigger.new);   
    }
}