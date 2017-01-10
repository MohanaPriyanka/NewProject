trigger LeadTrigger on Lead (before insert, after insert, before update, after update ) {
    LeadTriggerHandler handler = new LeadTriggerHandler(Trigger.isExecuting, Trigger.size);
    assignServiceTerritoryHandler handler2 = new assignServiceTerritoryHandler(Trigger.isExecuting, Trigger.size);
  //  mapPCRHandler handler3 = new mapPCRHandler(Trigger.isExecuting, Trigger.size); 
    utilityAccountLogConversionHandler handler4 = new utilityAccountLogConversionHandler(Trigger.isExecuting, Trigger.size);
    ProductAssignmentHandler handler5 = new ProductAssignmentHandler (Trigger.isExecuting, Trigger.size);
   // PartnerAssignmentHandler handler6 = new PartnerAssignmentHandler(Trigger.isExecuting, Trigger.size);
    mapCapacityAvailableHandler handler7 = new mapCapacityAvailableHandler(Trigger.isExecuting, Trigger.size);
    referralcodehandler handler8 = new referralcodehandler(Trigger.isExecuting, Trigger.size);

    //utilityAccountLogConversionHandler handler2 = new utilityAccountLogConversionHandler (Trigger.isExecuting, Trigger.size);
    //CoApplicantContactConvertHandler handler3 = new CoApplicantContactConvertHandler (Trigger.isExecuting, Trigger.size);
   
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);

        //LeadTriggerHandler.OnAfterUpdateAsync(Trigger.newMap.keySet());
    }
   else if(Trigger.isUpdate && Trigger.isBefore){
        handler2.OnBeforeUpdate(Trigger.new);
     //   handler3.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
        handler4.OnBeforeUpdate(Trigger.new);
        handler5.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
     //   handler6.OnBeforeInsertOrUpdate(Trigger.new);  
        handler7.OnBeforeUpdate(Trigger.new);
        handler8.OnBeforeUpdate(Trigger.old, Trigger.new);   
    }  
    else if(Trigger.isInsert && Trigger.isBefore){
         handler2.OnBeforeInsert(Trigger.new);   
      //   handler6.OnBeforeInsertOrUpdate(Trigger.new); 
         handler7.OnBeforeInsert(Trigger.new);    
         handler8.OnBeforeInsert(Trigger.new);
        //LeadTriggerHandler.OnAfterInsertAsync(Trigger.newMap.keySet());
    }
    /*else if(Trigger.isInsert && Trigger.isAfter){
         
        //LeadTriggerHandler.OnAfterInsertAsync(Trigger.newMap.keySet());
    }  */  
    
 
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