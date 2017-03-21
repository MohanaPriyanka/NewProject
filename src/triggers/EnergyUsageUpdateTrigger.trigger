trigger EnergyUsageUpdateTrigger on Energy_Usage_Update__c (after insert) {
    EnergyUsageUpdateTriggerHandler handler = new EnergyUsageUpdateTriggerHandler();
    
    if(Trigger.isInsert && Trigger.isAfter){
        handler.createCSBillingLog(Trigger.new);
    }
}