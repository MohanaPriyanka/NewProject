trigger CH_TransactionTrigger on ChargentOrders__Transaction__c(after insert, after update, before insert) {
    
    if (Trigger.isInsert && Trigger.isAfter){
        SystemBillPaymentRollUpHandler.handleRecurringPayment(Trigger.new);
    } else if(Trigger.isUpdate && Trigger.isAfter){
        SystemBillPaymentRollUpHandler.handleOneTimePayment(Trigger.new, Trigger.oldMap);
    }
}