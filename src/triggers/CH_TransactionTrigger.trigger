trigger CH_TransactionTrigger on ChargentOrders__Transaction__c(before insert, after update) {
    SystemBillPaymentRollUpHandler handler = new SystemBillPaymentRollUpHandler(trigger.isExecuting, Trigger.size);
    
    if(Trigger.isInsert && Trigger.isBefore){
        handler.OnBeforeInsert(Trigger.new);
    }  
    
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.new, Trigger.old);
    }
}