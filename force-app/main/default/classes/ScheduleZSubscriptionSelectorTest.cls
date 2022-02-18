/**
 * Created by PeterYao on 3/12/2019.
 */
@IsTest
public with sharing class ScheduleZSubscriptionSelectorTest {
    @TestSetup public static void setupData() {
        CSPaymentTest.csPaymentSetupTestData();

        Account parentAccount = new Account(Name = 'Parent Account');
        insert parentAccount;

        Zuora__CustomerAccount__c billingAccount = new Zuora__CustomerAccount__c(Zuora__Account__c = parentAccount.Id, Zuora__Balance__c = 200.00);
        insert billingAccount;
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
            opportunity.Customer_Sub_Group__c = 'Public Offtake';
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

        List<Schedule_Z_Subscription__c> szsList = ScheduleZSubscriptionSelector.getListForBilling(scheduleZMap.keySet());
        //2 are Externally Serviced
        System.assertEquals(15, szsList.size());
    }

    @IsTest
    public static void testGetSZSFromTransfer() {
        Date todaysDate = Date.today();

        Zuora__CustomerAccount__c billingAccount = [SELECT Id FROM Zuora__CustomerAccount__c WHERE Zuora__Balance__c = 200.00 LIMIT 1];

        List<Account> accounts = [
            SELECT Id
            FROM Account
        ];
        for (Account acct : accounts) {
            acct.Billing_Account__c = billingAccount.Id;
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

    @IsTest
    public static void testGetSZSFromTransferWithNonBillingSZSes() {
        Date todaysDate = Date.today();

        Zuora__CustomerAccount__c billingAccount = [SELECT Id FROM Zuora__CustomerAccount__c WHERE Zuora__Balance__c = 200.00 LIMIT 1];

        List<Account> accounts = [
            SELECT Id
            FROM Account
        ];
        for (Account acct : accounts) {
            acct.Billing_Account__c = billingAccount.Id;
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
            ORDER BY Name
        ]);

        Schedule_Z__c szToUpdate = schZMap.values()[0];
        szToUpdate.Status__c = 'Submitted to Utility';
        update szToUpdate;

        List<Utility_Account_Subscription__c> uases = [
            SELECT Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Shared_Solar_System__r.Id IN : sharedSolarSystemMap.keySet()
            ORDER BY Name
        ];

        ScheduleZSubscriptionSelector selector = new ScheduleZSubscriptionSelector();
        List<Schedule_Z_Subscription__c> szsList;

        szsList = selector.getOverdueSZSForBillingOffTransfer(sharedSolarSystemMap.keySet(),null);
        System.assertEquals(
            5,
            szsList.size(),
            'Even though there are 14 szs, we not expect to pull in ones from the SZ with status = Submitted to Utility'
        );

        szsList = selector.getOverdueSZSForBillingOffTransfer(sharedSolarSystemMap.keySet(), new Set<Id>{uases[0].Id, uases[1].Id});
        System.assertEquals(3, szsList.size());
    }

    @IsTest
    public static void testGetALSSFromALS() {
        Schedule_Z__c als = [SELECT Id FROM Schedule_Z__c WHERE Name = '18-0515 Oxford Barrett St. P1' LIMIT 1];
        System.assertNotEquals(null, als);
        List<Schedule_Z_Subscription__c> szsList = ScheduleZSubscriptionSelector.getALSSFromALS(new List<Id>{als.Id});
        System.assertEquals(9, szsList.size());

        Set<Id> szsIds = new Set<Id>();
        for (Schedule_Z_Subscription__c szs : szsList) {
            szsIds.add(szs.Id);
        }

        List<Schedule_Z_Subscription__c> testSZSList =  ScheduleZSubscriptionSelector.getScheduleZSubscriptionsList(szsIds);
        System.assertEquals(9, testSZSList.size());
    }

    @IsTest
    public static void testGetRetiredSZS() {
        Utility_Account_Subscription__c uas = [
            SELECT Id, Date_Removed_from_Project__c,
            (SELECT Id, Schedule_Z__c FROM Schedule_Z_Subscriptions__r)
            FROM Utility_Account_Subscription__c
            LIMIT 1
        ];
        Id scheduleZId;
        for (Schedule_Z_Subscription__c szs : uas.Schedule_Z_Subscriptions__r) {
            scheduleZId = szs.Schedule_Z__c;
        }

        uas.Date_Removed_from_Project__c = System.today();
        update uas;
        System.assertNotEquals(null, new ScheduleZSubscriptionSelector().getRetiredALSSFromALS(scheduleZId));
    }
}