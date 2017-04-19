Trigger UASBTrigger on UASB__c(before insert, after insert, before update, after update ) {
    List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
    if (systemProperties.size() > 0 &&
        systemProperties[0].Disable_UASBTrigger__c) {
        // Don't run trigger
    } else {
        RecurringPaymentsHandler handler = new RecurringPaymentsHandler(Trigger.isExecuting, Trigger.size);
   
        if(Trigger.isInsert && Trigger.isAfter){
            handler.OnAfterInsert(Trigger.new);
        }
    }
}