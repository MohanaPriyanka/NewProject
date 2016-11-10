trigger CH_TransactionTrigger on ChargentOrders__Transaction__c(after update) {
    SystemBillPaymentRollUpHandler handler = new SystemBillPaymentRollUpHandler(trigger.isExecuting, Trigger.size);
    
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.new, Trigger.old);
    }
}