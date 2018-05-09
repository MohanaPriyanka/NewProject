trigger ChargentOrderTrigger on ChargentOrders__ChargentOrder__c (before insert, after insert, before update, after update) {
    PaymentGatewayAssignmentHandler paymentGatewayAssignmentHandler = new PaymentGatewayAssignmentHandler(Trigger.isExecuting, Trigger.size);
    CreditCardFeeUpdateHandler creditCardFeeUpdateHandler = new CreditCardFeeUpdateHandler();
    if(Trigger.isInsert && Trigger.isAfter){
        paymentGatewayAssignmentHandler.OnAfterInsert(Trigger.new);
        RecurringPaymentsHandler.updateAccountAutopay(Trigger.new);
    }
    else if(Trigger.isUpdate && Trigger.isBefore){
        creditCardFeeUpdateHandler.OnBeforeUpdate(Trigger.old, Trigger.new);
    }
    else if(Trigger.isUpdate && Trigger.isAfter){
        creditCardFeeUpdateHandler.OnAfterUpdate(Trigger.new);
        RecurringPaymentsHandler.updateAccountAutopay(Trigger.new);
    }
}
