trigger ClientBrandingSubscriptionChangeTrigger on Subscription_Change_Event__e (after insert) {
    ClientBrandingService brandKeyService = new ClientBrandingService();
    brandKeyService.handleEvent(Trigger.new);
}