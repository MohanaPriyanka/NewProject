/*
   Tested By: SharedSolarSystemHandlerTest
 */
trigger SharedSolarSystemTrigger on Shared_Solar_System__c (before insert, after insert, before update, after update) {
    if (Util.isDisabled('Disable_SharedSolarSystemTrigger__c')) {
        return;
    }
    SharedSolarSystemHandler sharedSolarSystemHandler = new SharedSolarSystemHandler();

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            new SharedSolarSystems(Trigger.new).calculateMaximumSubscriptionCapacityForSMART();
        } when BEFORE_UPDATE {
            sharedSolarSystemHandler.summarizeCapacity(Trigger.new);
            new SharedSolarSystems(Trigger.new).calculateMaximumSubscriptionCapacityForSMART();
        } when AFTER_UPDATE {
            sharedSolarSystemHandler.uncheckApexContext(Trigger.new);
            sharedSolarSystemHandler.onUpdateCheckForChangedValues(Trigger.oldMap, Trigger.new);
        }
    }
}