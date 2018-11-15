trigger SRECTrigger on SREC__c (after update) {
    if(Trigger.isUpdate && Trigger.isAfter){
        RecurringSRECHandler.findChargentOrders(Trigger.new);
    }
}