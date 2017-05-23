trigger LeadTrigger on Lead (before insert, after insert, before update, after update ) {
    LeadTriggerHandler handler = new LeadTriggerHandler(Trigger.isExecuting, Trigger.size);
    AssignServiceTerritoryHandler handler2 = new AssignServiceTerritoryHandler(Trigger.isExecuting, Trigger.size);
    UtilityAccountLogConversionHandler handler4 = new UtilityAccountLogConversionHandler(Trigger.isExecuting, Trigger.size);
    ProductAssignmentHandler handler5 = new ProductAssignmentHandler (Trigger.isExecuting, Trigger.size);
    MapCapacityAvailableHandler handler7 = new MapCapacityAvailableHandler(Trigger.isExecuting, Trigger.size);
    Referralcodehandler referralCodeHandler  = new Referralcodehandler();
    LoanHandler loanHandler = new LoanHandler (Trigger.isExecuting, Trigger.size);

    if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        loanHandler.OnAfterLeadUpdate(Trigger.new, Trigger.old);
    }
   else if(Trigger.isUpdate && Trigger.isBefore){
        handler2.OnBeforeUpdate(Trigger.new);
        handler4.OnBeforeUpdate(Trigger.new);
        handler5.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
        handler7.OnBeforeUpdate(Trigger.new);
        referralCodeHandler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);   
        loanHandler.OnBeforeLeadUpdate(Trigger.newMap, Trigger.oldMap);
    }  
    else if(Trigger.isInsert && Trigger.isBefore){
         handler2.OnBeforeInsert(Trigger.new);   
         handler7.OnBeforeInsert(Trigger.new);    
         referralCodeHandler.OnBeforeInsert(Trigger.new);
    }
}