trigger EnergyUsageUpdateTrigger on Energy_Usage_Update__c (after update) {
    if (Util.isDisabled('Disable_EnergyUsageUpdateTrigger__c')) {
        return;
    }
}