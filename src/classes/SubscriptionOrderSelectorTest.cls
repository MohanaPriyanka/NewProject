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

    @IsTest
    public static void testSelectApprovedByOppIds() {
        try {
            new SubscriptionOrderSelector().selectApprovedByOppIds(new Set<Id>());
        } catch (Exception e) {
            System.assert(false, 'Selector should not have thrown an exception: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @IsTest
    public static void testSelectApprovedByContractIds() {
        try {
            new SubscriptionOrderSelector().selectApprovedByContractIds(new Set<Id>());
        } catch (Exception e) {
            System.assert(false, 'Selector should not have thrown an exception: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @IsTest
    public static void testGetAcquisitionOrdersBySSS(){
        FeatureService featureService = new FeatureService();

        List<Shared_Solar_System__c> sssList = [
            SELECT Id
            FROM Shared_Solar_System__c
            ORDER BY Name
            LIMIT 2
        ];

        Date reacDate = System.today().addDays(-6);

        SubscriptionOrderSelector selector = new SubscriptionOrderSelector();
        Map<Id,Subscription_Order__c> queriedOrdersOne = selector.getAcquisitionOrdersBySSS(sssList[0].Id, reacDate);
        Map<Id,Subscription_Order__c> queriedOrdersTwo = selector.getAcquisitionOrdersBySSS(sssList[1].Id, reacDate);

        if (featureService.isEnabled('Subscription_Orders')) {
            System.assertEquals(9,queriedOrdersOne.values().size());
            System.assertEquals(6,queriedOrdersTwo.values().size());
        }

        reacDate = System.today().addDays(2);

        Map<Id,Subscription_Order__c> queriedFutureOrdersOne = selector.getAcquisitionOrdersBySSS(sssList[0].Id, reacDate);
        Map<Id,Subscription_Order__c> queriedFutureOrdersTwo = selector.getAcquisitionOrdersBySSS(sssList[1].Id, reacDate);

        if (featureService.isEnabled('Subscription_Orders')) {
            System.assertEquals(0,queriedFutureOrdersOne.values().size());
            System.assertEquals(0,queriedFutureOrdersTwo.values().size());
        }
    }

    @IsTest
    public static void testGetSubscriptionOrdersAssignedToClient(){
        Set<Id> uasIds = new Set<Id>();

        Account clientAccount = new Account(Name = 'Client Account');
        insert clientAccount;

        RecordType clientRT = [SELECT Id FROM RecordType WHERE Name = 'Client Contract' LIMIT 1];

        Contract contractA = new Contract(
            Name = 'Client Contract A',
            AccountId = clientAccount.Id,
            RecordTypeId = clientRT.Id
        );
        insert contractA;
        contractA.Status = 'Sent';
        update contractA;

        List<Utility_Account_Subscription__c> uases = [
            SELECT Id
            FROM Utility_Account_Subscription__c
            WHERE (Opportunity__r.Name = 'OppOne' OR
            Opportunity__r.Name = 'OppTwo' OR
            Opportunity__r.Name = 'OppThree')
            ORDER BY Opportunity__r.Name
        ];

        for (Utility_Account_Subscription__c uas : uases){
            uasIds.add(uas.Id);
        }

        List<Subscription_Order__c> orders = [
            SELECT Id, Utility_Account_Subscription__c, Approved_Change_in_Subscription__c
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__c IN : uasIds
        ];

        for (Subscription_Order__c order : orders){
            order.Client_Assignment_Agreement__c = contractA.Id;
        }
        update orders;

        SubscriptionOrderSelector selector = new SubscriptionOrderSelector();
        Map<Id,Decimal> uasToAssignedCapacityMap = selector.getSubscriptionOrdersAssignedToClient(uasIds);

        System.assertEquals(16.62739,uasToAssignedCapacityMap.get(uases[0].Id));
        System.assertEquals(7.518472,uasToAssignedCapacityMap.get(uases[1].Id));
        System.assertEquals(25.013378,uasToAssignedCapacityMap.get(uases[2].Id));
    }
}