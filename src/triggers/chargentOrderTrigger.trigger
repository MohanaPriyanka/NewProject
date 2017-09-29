trigger chargentOrderTrigger on ChargentOrders__ChargentOrder__c (before insert, after insert, before update, after update) {
    PaymentGatewayAssignmentHandler handler = new PaymentGatewayAssignmentHandler(Trigger.isExecuting, Trigger.size);
    CreditCardFeeUpdateHandler handler2 = new CreditCardFeeUpdateHandler();

    if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.new);
    }

    else if(Trigger.isUpdate && Trigger.isBefore){
        handler2.OnBeforeUpdate(Trigger.old, Trigger.new);
    }

    else if(Trigger.isUpdate && Trigger.isAfter){
        handler2.OnAfterUpdate(Trigger.new);
    }
    
}