trigger SharedSolarSystemTrigger on Shared_Solar_System__c (before insert, after insert, before update, after update) {
    if (Util.isDisabled('Disable_SharedSolarSystemTrigger__c')) {
        return;
    }
    SharedSolarSystemHandler sharedSolarSystemHandler = new SharedSolarSystemHandler();
    if(Trigger.isUpdate && Trigger.isBefore){
        sharedSolarSystemHandler.summarizeCapacity(Trigger.new);
    }
}