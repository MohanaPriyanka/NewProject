trigger CH_TransactionTrigger on ChargentOrders__Transaction__c(before insert, after update) {
    
    if(Trigger.isInsert && Trigger.isBefore){
        SystemBillPaymentRollUpHandler.handleRecurringPayment(Trigger.new);
    } else if(Trigger.isUpdate && Trigger.isAfter){
        SystemBillPaymentRollUpHandler.handleOneTimePayment(Trigger.new, Trigger.oldMap);
    }
}