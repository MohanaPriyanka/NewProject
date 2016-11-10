Trigger UASBTrigger on UASB__c(before insert, after insert, before update, after update ) {
    RecurringPaymentsHandler handler = new RecurringPaymentsHandler(Trigger.isExecuting, Trigger.size);
   
    if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.new);
        //LeadTriggerHandler.OnAfterUpdateAsync(Trigger.newMap.keySet());
    }
   /*else if(Trigger.isUpdate && Trigger.isAfter){
        handler.onAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }*/

    /*
    if(Trigger.isInsert && Trigger.isBefore){
         handler2.OnBeforeInsert(Trigger.new);
        //LeadTriggerHandler.OnAfterInsertAsync(Trigger.newMap.keySet());
    }
    
 
    /*
    else if(Trigger.isUpdate && Trigger.isBefore){
        handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
        else if(Trigger.isDelete && Trigger.isBefore){
        handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
    }
    else if(Trigger.isDelete && Trigger.isAfter){
        handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
        //LeadTriggerHandler.OnAfterDeleteAsync(Trigger.oldMap.keySet());
    }
    
    else if(Trigger.isUnDelete){
        handler.OnUndelete(Trigger.new);    
    }
    */
}