trigger UserTrigger on User (after insert) {
    if (Util.isDisabled('Disable_UserTrigger__c')) {
        return;
    }
	ManagedPackageLicenseHandler.assignChargentLicense(Trigger.new);
}