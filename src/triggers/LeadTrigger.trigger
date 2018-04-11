trigger LeadTrigger on Lead (before insert, after insert, before update, after update ) {
    LeadTriggerHandler leadTriggerHandler = new LeadTriggerHandler(Trigger.isExecuting, Trigger.size);
    AssignServiceTerritoryHandler assignServiceTerritoryHandler = new AssignServiceTerritoryHandler(Trigger.isExecuting, Trigger.size);
    UtilityAccountLogConversionHandler utilityAccountLogConversionHandler = new UtilityAccountLogConversionHandler(Trigger.isExecuting, Trigger.size);
    MapCapacityAvailableHandler mapCapacityAvailableHandler = new MapCapacityAvailableHandler(Trigger.isExecuting, Trigger.size);
    ReferralCodeHandler referralCodeHandler  = new ReferralCodeHandler();
    LoanHandler loanHandler = new LoanHandler (Trigger.isExecuting, Trigger.size);

    if(Trigger.isUpdate && Trigger.isAfter){
        leadTriggerHandler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        loanHandler.OnAfterLeadUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    }
    else if(Trigger.isUpdate && Trigger.isBefore){
        leadTriggerHandler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        assignServiceTerritoryHandler.OnBeforeUpdate(Trigger.new);
        utilityAccountLogConversionHandler.OnBeforeUpdate(Trigger.new);
        mapCapacityAvailableHandler.OnBeforeUpdate(Trigger.new);
        referralCodeHandler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        loanHandler.OnBeforeLeadUpdate(Trigger.newMap, Trigger.oldMap);
    }  
    else if(Trigger.isInsert && Trigger.isBefore){
        leadTriggerHandler.OnBeforeInsert(Trigger.new);
        assignServiceTerritoryHandler.OnBeforeInsert(Trigger.new);
        mapCapacityAvailableHandler.OnBeforeInsert(Trigger.new);
        referralCodeHandler.OnBeforeInsert(Trigger.new);
    }
}