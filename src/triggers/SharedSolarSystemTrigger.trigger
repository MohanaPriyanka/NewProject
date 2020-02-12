trigger SharedSolarSystemTrigger on Shared_Solar_System__c (before insert, after insert, before update, after update) {
    if (Util.isDisabled('Disable_SharedSolarSystemTrigger__c')) {
        return;
    }
    SharedSolarSystemHandler sharedSolarSystemHandler = new SharedSolarSystemHandler();

    switch on Trigger.operationType {
        when BEFORE_UPDATE {
            sharedSolarSystemHandler.summarizeCapacity(Trigger.new);
            sharedSolarSystemHandler.queueClientBrandKeyUpdate(Trigger.oldMap, Trigger.new);
        } when AFTER_UPDATE {
            sharedSolarSystemHandler.uncheckApexContext(Trigger.new);
        }
    }
}