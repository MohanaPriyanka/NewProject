trigger ChargentOrderTrigger on ChargentOrders__ChargentOrder__c (before insert, after insert, before update, after update) {
    List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
    if (systemProperties.size() > 0 &&
        systemProperties[0].Disable_ChargentOrderTrigger__c) {
        // Don't run trigger
    } else {
        PaymentGatewayAssignmentHandler paymentGatewayAssignmentHandler = new PaymentGatewayAssignmentHandler(Trigger.isExecuting, Trigger.size);
        CreditCardFeeUpdateHandler creditCardFeeUpdateHandler = new CreditCardFeeUpdateHandler();
        if(Trigger.isInsert && Trigger.isAfter){
            paymentGatewayAssignmentHandler.OnAfterInsert(Trigger.new);
            RecurringPaymentsHandler.updateAccountAutopay(Trigger.new);
            RecurringPaymentsHandler.closeOrdersWithDuplicateAccountAndEntity(Trigger.new);
        }
        else if(Trigger.isUpdate && Trigger.isBefore){
            creditCardFeeUpdateHandler.OnBeforeUpdate(Trigger.old, Trigger.new);
        }
        else if(Trigger.isUpdate && Trigger.isAfter){
            creditCardFeeUpdateHandler.OnAfterUpdate(Trigger.new);
            RecurringPaymentsHandler.updateAccountAutopay(Trigger.new);
        }
    }
}
