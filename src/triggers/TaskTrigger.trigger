trigger TaskTrigger on Task (before update, before insert, after insert) {
        UpdateLastContactDateHandler handler = new UpdateLastContactDateHandler (Trigger.isExecuting, Trigger.size);
   
      if(Trigger.isInsert && Trigger.isBefore){
           handler.OnBeforeInsert (Trigger.new);
      }
  
      if(Trigger.isUpdate && Trigger.isBefore){
           handler.OnBeforeUpdate (Trigger.old, Trigger.new);
      }
}