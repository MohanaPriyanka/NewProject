trigger CaseTrigger on Case ( after insert ) {

    if(Trigger.isInsert && Trigger.isAfter){
          CaseEscalationHandler.linkTaskToCase(Trigger.new);   
    }
}