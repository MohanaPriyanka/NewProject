/*
   Tested By: SharedSolarSystemHandlerTest
 */
trigger SharedSolarSystemTrigger on Shared_Solar_System__c (before insert, after insert, before update, after update) {
    if (Util.isDisabled('Disable_SharedSolarSystemTrigger__c')) {
        return;
    }
    SharedSolarSystemHandler sharedSolarSystemHandler = new SharedSolarSystemHandler();
    SharedSolarSystemInvoicer invoicer = new SharedSolarSystemInvoicer();
    SharedSolarSystemCapacityCalculator capacityCalculator = new SharedSolarSystemCapacityCalculator();
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            capacityCalculator.calculateMaximumSubscriptionCapacityForSMART(Trigger.new);
            invoicer.updateManagementRevenueStartDateBeforeTrigger(Trigger.new);
        } when BEFORE_UPDATE {
            sharedSolarSystemHandler.summarizeCapacityBeforeUpdate(Trigger.newMap);
            capacityCalculator.calculateMaximumSubscriptionCapacityForSMART(Trigger.new);
            invoicer.updateManagementRevenueStartDateBeforeTrigger(Trigger.new);
        } when AFTER_UPDATE {
            sharedSolarSystemHandler.uncheckApexContext(Trigger.new);
            sharedSolarSystemHandler.onUpdateCheckForChangedValues(Trigger.oldMap, Trigger.new);
        }
    }
}