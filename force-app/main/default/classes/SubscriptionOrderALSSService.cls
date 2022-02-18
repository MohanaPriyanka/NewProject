// Tested By: SubscriptionOrderALSSServiceTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class SubscriptionOrderALSSService{
    @TestVisible
    private static SubscriptionOrderSelector soSelector = new SubscriptionOrderSelector();

    public void setAllocationScheduleSubscription(List<Schedule_Z_Subscription__c> newALSSes){
        List<Subscription_Order__c> subscriptionOrdersToUpdate = getAllocationScheduleSubscription(newALSSes);
        update subscriptionOrdersToUpdate;
    }

    @TestVisible
    private List<Subscription_Order__c> getAllocationScheduleSubscription(List<Schedule_Z_Subscription__c> newALSSes){
        Map<Id,Id> uasToALSSMap = new Map<Id,Id>();

        for (Schedule_Z_Subscription__c alss : newALSSes){
            Id alssId = uasToALSSMap.get(alss.Utility_Account_Subscription__c);
            if (alssId != null){
                Logger.logNow(
                    'SubscriptionOrderALSSService',
                    'setAllocationScheduleSubscription',
                    'More than 1 ALSS for a given UAS: ' + JSON.serialize(alss) + ' ' + JSON.serialize(alssId)
                );
            }
            uasToALSSMap.put(alss.Utility_Account_Subscription__c, alss.Id);
        }

        List<Subscription_Order__c> subscriptionOrders = soSelector.selectUnenactedByUASId(uasToALSSMap.keySet());

        for (Subscription_Order__c subOrder : subscriptionOrders){
            subOrder.Allocation_Schedule_Subscription__c = uasToALSSMap.get(subOrder.Utility_Account_Subscription__c);
        }
        return subscriptionOrders;
    }
}