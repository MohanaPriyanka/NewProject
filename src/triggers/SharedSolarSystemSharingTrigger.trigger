trigger SharedSolarSystemSharingTrigger on Subscription_Change_Event__e (after insert) {
    SharedSolarSystemSharingService sharingService = new SharedSolarSystemSharingService();
    sharingService.evaluateSharingViaSubscriptionChange(Trigger.new);
}