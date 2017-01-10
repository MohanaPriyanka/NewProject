trigger chargentOrderTrigger on ChargentOrders__ChargentOrder__c (before insert, after insert, before update, after update) {
    PaymentGatewayAssignmentHandler handler = new PaymentGatewayAssignmentHandler(Trigger.isExecuting, Trigger.size);
    /*
    if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.new);
        //EnergyUsageUpdateTriggerHandler.OnAfterInsertAsync(Trigger.newMap.keySet());
    }*/
    
    if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.new);
    }
    //else if(Trigger.isUpdate && Trigger.isBefore){
        //handlerTwo.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    //}
    //if(Trigger.isUpdate && Trigger.isAfter){
        //handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        //EnergyUsageUpdateTriggerHandler.OnAfterUpdateAsync(Trigger.newMap.keySet());
    /*   
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