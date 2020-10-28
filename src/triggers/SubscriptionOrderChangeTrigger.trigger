*	 
 * Tested By: SubscriptionSizingTestclass	 
 */

trigger SubscriptionOrderChangeTrigger on Subscription_Order_Change_Event__e (after insert) {
        SubscriptionManagementService subscriptionManagementService = new SubscriptionManagementService();
        subscriptionManagementService.handleSubscriptionOrderChangeEvents(Trigger.new);
}
