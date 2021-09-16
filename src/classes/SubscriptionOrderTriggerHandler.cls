/**
 * @description  Created by jeffparlin on 09/13/2021.
 * Tested By: SubscriptionManagementServiceTest, SubscriptionSizingTestclass
 */
public without sharing class SubscriptionOrderTriggerHandler {

    private SubscriptionManagementService subscriptionManagementService = new SubscriptionManagementService();
    private Map<Id, Subscription_Order__c> oldMap;
    private Map<Id, Subscription_Order__c> newMap;
    private List<Subscription_Order__c> newList;

    public SubscriptionOrderTriggerHandler(Map<Id, Subscription_Order__c> oldMap, Map<Id, Subscription_Order__c> newMap,
        List<Subscription_Order__c> newList)
    {
        this.oldMap = oldMap;
        this.newMap = newMap;
        this.newList = newList;
    }

    public void beforeInsert() {
        subscriptionManagementService.populateSubscriptionOrder(newList);
    }

    public void afterInsert() {
        subscriptionManagementService.evaluateApprovedSubscriptionOrders(newMap);
    }

    public void beforeDelete() {
        subscriptionManagementService.publishSubscriptionOrderChangeEventsOnDelete(oldMap.values(), null);
    }
}