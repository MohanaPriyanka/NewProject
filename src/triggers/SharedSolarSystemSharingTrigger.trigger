trigger SharedSolarSystemSharingTrigger on Subscription_Change_Event__e (after insert) {
    if (Util.isDisabled('Disable_SharedSolarSystemSharingTrigger__c')) {
        return;
    }
    SharedSolarSystemSharingService sharingService = new SharedSolarSystemSharingService();
    sharingService.evaluateSharingViaSubscriptionChange(Trigger.new);
}