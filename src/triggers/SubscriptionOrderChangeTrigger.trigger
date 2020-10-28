trigger SubscriptionOrderChangeTrigger on Subscription_Order_Change_Event__e (after insert) {
         System.debug('Change Event Trigger caught published events');
        SubscriptionManagementService subscriptionManagementService = new SubscriptionManagementService();
        subscriptionManagementService.handleSubscriptionOrderChangeEvents(Trigger.new);
       
}