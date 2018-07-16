trigger UserTrigger on User (after insert) {
	ManagedPackageLicenseHandler.assignChargentLicense(Trigger.new);
}