/**
 * Created by PeterYao on 3/12/2019.
 */
@IsTest
public with sharing class ScheduleZSubscriptionSelectorTest {
    @TestSetup public static void setupData() {
        CSPaymentTest.csPaymentSetupTestData();
    }

    @IsTest
    public static void testGetList() {
        // All of the opportunities loaded are small offtake - let's change two of them to Public Offtake to test
        // that they're excluded
        List<Opportunity> opportunities = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'ABike Shop'
        ];
        System.assertEquals(2, opportunities.size());
        for (Opportunity opportunity : opportunities) {
            opportunity.Customer_Group__c = 'Public Offtake';
        }
        update opportunities;
        Map<Id, Shared_Solar_System__c> sharedSolarSystemMap = new Map<Id, Shared_Solar_System__c>([
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name IN ('Oxford Barrett St. P1', 'Oxford Barrett St. P2')
        ]);
        System.assertEquals(2, sharedSolarSystemMap.values().size());
        for (Shared_Solar_System__c sharedSolarSystem : sharedSolarSystemMap.values()) {
            sharedSolarSystem.Billing_Anchors__c = 'RadianGen';
        }
        update sharedSolarSystemMap.values();

        Map<Id, Schedule_Z__c> scheduleZMap= new Map<Id, Schedule_Z__c>([SELECT Id FROM Schedule_Z__c]);
        List<Schedule_Z_Subscription__c> scheduleZSubscriptions = [
            SELECT Id, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Name,Utility_Account_Subscription__r.Opportunity__c,
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Anchors__c,
                Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c IN : scheduleZMap.keySet()
            AND (Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Anchors__c != 'RadianGen'
            OR Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c = 'Residential'
            OR Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c = 'Non-Residential')
        ];

        List<Schedule_Z_Subscription__c> szsList = ScheduleZSubscriptionSelector.getListForBilling(scheduleZMap.keySet());
        //2 are Externally Serviced
        System.assertEquals(15, szsList.size());
    }

    @IsTest
    public static void testGetSZSFromTransfer() {
        Date todaysDate = Date.today();

        List<Account> accounts = [
            SELECT Id
            FROM Account
        ];
        for (Account acct : accounts) {
            acct.Total_Outstanding_Balance_Zuora__c = 200;
            acct.Last_Bill_Send_Date_New_Charges_Zuora__c = todaysDate.addDays(-60);
        }
        update accounts;

        Map<Id, Shared_Solar_System__c> sharedSolarSystemMap = new Map<Id, Shared_Solar_System__c>([
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name IN ('Oxford Barrett St. P1', 'Oxford Barrett St. P2')
        ]);

        Map<Id, Schedule_Z__c> schZMap = new Map<Id, Schedule_Z__c>([
            SELECT Id
            FROM Schedule_Z__c
            WHERE Shared_Solar_System__c IN : sharedSolarSystemMap.keySet()
        ]);

        List<Utility_Account_Subscription__c> uases = [
            SELECT Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Shared_Solar_System__r.Id IN : sharedSolarSystemMap.keySet()
            ORDER BY Name
        ];

        ScheduleZSubscriptionSelector selector = new ScheduleZSubscriptionSelector();
        List<Schedule_Z_Subscription__c> szsList;

        szsList = selector.getOverdueSZSForBillingOffTransfer(sharedSolarSystemMap.keySet(),null);
        System.assertEquals(14,szsList.size());

        szsList = selector.getOverdueSZSForBillingOffTransfer(sharedSolarSystemMap.keySet(), new Set<Id>{uases[0].Id, uases[1].Id});
        System.assertEquals(12,szsList.size());

        szsList = selector.getOnTimeListForBillingOffTransfer(schZMap.keySet());
        System.assertEquals(14,szsList.size());
    }
}