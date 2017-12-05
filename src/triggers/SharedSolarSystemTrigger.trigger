trigger SharedSolarSystemTrigger on Shared_Solar_System__c (before insert, after insert, before update, after update) {
    SharedSolarSystemHandler sharedSolarSystemHandler = new SharedSolarSystemHandler (Trigger.isExecuting, Trigger.size);
    if(Trigger.isUpdate && Trigger.isBefore){
        sharedSolarSystemHandler.OnBeforeUpdate(Trigger.old, Trigger.new);
    }
}
