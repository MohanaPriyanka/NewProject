trigger CaseTrigger on Case ( before insert, after insert, after update, after delete, before delete ) {
    
  List<Case> records = trigger.isDelete ? trigger.old : trigger.new;
    
    if(Trigger.isAfter){
      if(Trigger.isInsert || Trigger.isUpdate){
        List<Case_Round_Robin_Queue_Ids__c> caseRRQIds = Case_Round_Robin_Queue_Ids__c.getAll().values();
            RoundRobinHandler rrh = new RoundRobinHandler(records,Trigger.oldMap,'Case',caseRRQIds);
            if(Trigger.isInsert){
              CaseEscalationHandler.linkTaskToCase(Trigger.new);
               rrh.handleRoundRobinAssignments();
            } else {
               rrh.handleRoundRobinAssignments();
            }
      }
    }

 

    if(Trigger.isBefore){
      if(Trigger.isInsert){
        CaseEscalationHandler.findContactFromVM(Trigger.new);
      }      
    }
}