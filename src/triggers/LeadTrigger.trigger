trigger LeadTrigger on Lead (before insert, after update, before update ) {
    LeadTriggerHandler handler = new LeadTriggerHandler(Trigger.isExecuting, Trigger.size);
    assignServiceTerritoryHandler handler2 = new assignServiceTerritoryHandler(Trigger.isExecuting, Trigger.size);
    mapPCRHandler handler3 = new mapPCRHandler(Trigger.isExecuting, Trigger.size); 
    utilityAccountLogConversionHandler handler4 = new utilityAccountLogConversionHandler(Trigger.isExecuting, Trigger.size);
    
    //utilityAccountLogConversionHandler handler2 = new utilityAccountLogConversionHandler (Trigger.isExecuting, Trigger.size);
    //CoApplicantContactConvertHandler handler3 = new CoApplicantContactConvertHandler (Trigger.isExecuting, Trigger.size);
   
   
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        //LeadTriggerHandler.OnAfterUpdateAsync(Trigger.newMap.keySet());
    }
   else if(Trigger.isUpdate && Trigger.isBefore){
        handler2.OnBeforeUpdate(Trigger.new);
        handler3.OnBeforeUpdate(Trigger.new);
        handler4.OnBeforeUpdate(Trigger.new);        
    }

    
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