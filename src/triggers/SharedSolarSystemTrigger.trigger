/*
   Tested By: SharedSolarSystemHandlerTest
 */
trigger SharedSolarSystemTrigger on Shared_Solar_System__c (before insert, after insert, before update, after update) {
    if (Util.isDisabled('Disable_SharedSolarSystemTrigger__c')) {
        return;
    }
    SharedSolarSystemHandler sharedSolarSystemHandler = new SharedSolarSystemHandler();
    SharedSolarSystems sharedSolarSystems = new SharedSolarSystems(Trigger.new);
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            sharedSolarSystems.calculateMaximumSubscriptionCapacityForSMART();
            sharedSolarSystems.updateManagementRevenueStartDateBeforeTrigger();
        } when BEFORE_UPDATE {
            sharedSolarSystemHandler.summarizeCapacityBeforeUpdate(Trigger.newMap);
            sharedSolarSystems.calculateMaximumSubscriptionCapacityForSMART();
            sharedSolarSystems.updateManagementRevenueStartDateBeforeTrigger();
        } when AFTER_UPDATE {
            sharedSolarSystemHandler.uncheckApexContext(Trigger.new);
            sharedSolarSystemHandler.onUpdateCheckForChangedValues(Trigger.oldMap, Trigger.new);
        }
    }
}