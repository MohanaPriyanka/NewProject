trigger loanTrigger on loan__c (before insert, before update, after insert, after update) {
    LoanTrancheUpdateHandler handler = new LoanTrancheUpdateHandler(Trigger.isExecuting, Trigger.size);
    createResidentialEquipmentHandler handler2 = new createResidentialEquipmentHandler(Trigger.isExecuting, Trigger.size);
    LoanPipelineUpdatehandler handler3 = new LoanPipelineUpdatehandler (Trigger.isExecuting, Trigger.size);
    
    if(Trigger.isInsert && Trigger.isBefore){
        handler.OnBeforeInsert(Trigger.new);
        //EnergyUsageUpdateTriggerHandler.OnAfterInsertAsync(Trigger.newMap.keySet());
    }
    
    if(Trigger.isInsert && Trigger.isAfter){
        handler2.OnAfterInsert(Trigger.new);
        handler3.OnAfterInsert(Trigger.new);
    }
    
    else if(Trigger.isUpdate && Trigger.isBefore){
        handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }/*
    else if(Trigger.isUpdate && Trigger.isAfter){
        handler2.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        //EnergyUsageUpdateTriggerHandler.OnAfterUpdateAsync(Trigger.newMap.keySet());
    }
    
    else if(Trigger.isDelete && Trigger.isBefore){
        handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
    }
    else if(Trigger.isDelete && Trigger.isAfter){
        handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
        //EnergyUsageUpdateTriggerHandler.OnAfterDeleteAsync(Trigger.oldMap.keySet());
    }
    
    else if(Trigger.isUnDelete){
        handler.OnUndelete(Trigger.new);    
    }
    */
}