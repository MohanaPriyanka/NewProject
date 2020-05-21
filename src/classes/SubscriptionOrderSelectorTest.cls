@IsTest
public inherited sharing class SubscriptionOrderSelectorTest {
    @TestSetup
    public static void setupTestData() {
        UASSelectorTest.testSetup();
    }

    @IsTest
    public static void testSelectUnenactedByUASId(){
        FeatureService featureService = new FeatureService();

        List<Subscription_Order__c> subOrders = [
            SELECT Id, Utility_Account_Subscription__c
            FROM Subscription_Order__c
            ORDER BY Utility_Account_Subscription__r.Name
        ];

        List<Utility_Account_Subscription__c> uases = [
            SELECT Id
            FROM Utility_Account_Subscription__c
            WHERE Id IN (SELECT Utility_Account_Subscription__c FROM Subscription_Order__c)
        ];
        Set<Id> uasIds;
        if (featureService.isEnabled('Subscription_Orders')) {
            uasIds = new Set<Id>{uases[0].Id, uases[1].Id, uases[2].Id};
        } else {
            uasIds = new Set<Id>();
        }

        SubscriptionOrderSelector selector = new SubscriptionOrderSelector();
        List<Subscription_Order__c> queriedOrders = selector.selectUnenactedByUASId(uasIds);

        if (featureService.isEnabled('Subscription_Orders')) {
            System.assert(subOrders.size() > 0);
            System.assert(queriedOrders.size() >= 3);
        }
    }
}