@isTest
public class ZuoraCreditDebitMemoServiceTest {
    @testSetup public static void testDataSetup() {
        MultipleMonthProductionUpdateTest.multipleMonthTest();
        setBillsToUnPublished();

        List<UASB__c> uasbList = [
            SELECT Id, Name, Utility_Account_Subscription__r.Id,
                Opportunity__r.Shared_Solar_System__r.Unique_ID__c
            FROM UASB__c
            ORDER BY Date__c
            LIMIT 2
        ];

        Account clientAccount = [
            SELECT Id, Name, Account_Number__c
            FROM Account
            WHERE Name = 'Test Client'
            LIMIT 1
        ];

        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment',
            Utility_Account_Subscription__c = uasbList[0].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[0].Id,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = -90,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustTwo = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment2',
            Utility_Account_Subscription__c = uasbList[0].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[0].Id,
            Adjustment_Type__c = 'Client Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = -45,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustThree = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment3',
            Utility_Account_Subscription__c = uasbList[1].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[1].Id,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = -15,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustFour = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment4',
            Utility_Account_Subscription__c = uasbList[1].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[1].Id,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = -99,
            Approval_Status__c = 'Approved',
            Zuora_Id__c = 'XXXXXXXXXXXXXXXXXX',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustFive = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment5',
            Utility_Account_Subscription__c = uasbList[1].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[1].Id,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = 12,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustSix = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment6',
            Utility_Account_Subscription__c = uasbList[1].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[1].Id,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = 18,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');


        insert new List<Bill_Adjustment__c>{adjustOne, adjustTwo, adjustThree, adjustFour, adjustFive, adjustSix};

        List<Account> accounts = [
            SELECT Id, Name, Zuora_Id__c
            FROM Account
        ];

        // See ZuoraAPIMock.getOrderByOwnerResponse()
        // If ZuoraId contains CID, mocked subscriptions will be returned for this client/shared solar system pair:
        String accountKey = 'CID' +
            clientAccount.Account_Number__c +
            'SID' +
            uasbList[0].Opportunity__r.Shared_Solar_System__r.Unique_ID__c +
            'END';

        for (Account accts : accounts){
            accts.Zuora_Id__c = accountKey;
        }
        update accounts;
    }

    public static void setBillsToUnPublished() {
        List <Account_Bill__c> listAccountBills = [
            SELECT Id, Published__c
            FROM Account_Bill__c
            WHERE Published__c = TRUE
        ];
        for (Account_Bill__c acctBill : listAccountBills) {
            acctBill.Published__c = FALSE;
            acctBill.Reason_For_Unpublish__c = 'Test reason for unpublishing this bill';
        }
        update listAccountBills;
    }

    @IsTest
    private static void testBatch() {
        // disableTrigger just sets a system property checkbox to true
        Util.disableTrigger('Update_Usage_Records_With_ZuoraId__c');

        // 6 adjustments exist, but one should be excluded, because already has a zuora ID:
        Database.QueryLocator queryLocator = AdjustmentSelector.getAdjustmentsNotYetInZuora(false);
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        List<Bill_Adjustment__c> beforeCallList = new List<Bill_Adjustment__c>();
        Integer i = 0;
        while (iterator.hasNext()) {
            beforeCallList.add((Bill_Adjustment__c) iterator.next());
            i++;
        }
        System.assertEquals(5, i);

        Test.startTest();
        ZuoraCreditMemoBatchSend zSend = new ZuoraCreditMemoBatchSend();
        zSend.executeBatch();
        Test.stopTest();

        // Credit Memos:
        List<Bill_Adjustment__c> creditList = [
            SELECT Id, Name, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c = '2c92c0fa6a3458e1016a45ac238e0d74'
        ];
        System.assertEquals(3, creditList.size());

        // Debit Memos:
        List<Bill_Adjustment__c> debitList = [
            SELECT Id, Name, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c = '2c92c0fa6a3458e1016a45ac238e0d66'
        ];
        System.assertEquals(2, debitList.size());
    }

    // Tests for the case raised in this error log: https://bluewavesolar.my.salesforce.com/a3u0a000000E1zz
    @IsTest
    private static void testBatchWithNoIds() {
        ZuoraAPIMock.createCMWithNoId = true;
        ZuoraAPIMock.createDMWithNoId = true;

        // disableTrigger just sets a system property checkbox to true
        Util.disableTrigger('Update_Usage_Records_With_ZuoraId__c');

        // 6 adjustments exist, but one should be excluded, because already has a zuora ID:
        Database.QueryLocator queryLocator = AdjustmentSelector.getAdjustmentsNotYetInZuora(false);
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        List<Bill_Adjustment__c> beforeCallList = new List<Bill_Adjustment__c>();
        Integer i = 0;
        while (iterator.hasNext()) {
            beforeCallList.add((Bill_Adjustment__c) iterator.next());
            i++;
        }
        System.assertEquals(5, i);

        Test.startTest();
        ZuoraCreditMemoBatchSend zSend = new ZuoraCreditMemoBatchSend();
        zSend.executeBatch();
        Test.stopTest();

        List<Error_Log__c> errorLogs = [
            SELECT Message__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Memo did not successfully create:'));
    }

    @IsTest
    private static void testAPICallWithMock() {
        // disableTrigger just sets a system property checkbox to true
        Util.disableTrigger('Update_Usage_Records_With_ZuoraId__c');

        // 6 adjustments exist, but one should be excluded, because already has a zuora ID:
        Database.QueryLocator queryLocator = AdjustmentSelector.getAdjustmentsNotYetInZuora(false);
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        List<Bill_Adjustment__c> beforeCallList = new List<Bill_Adjustment__c>();
        Integer i = 0;
        while (iterator.hasNext()) {
            beforeCallList.add((Bill_Adjustment__c) iterator.next());
            i++;
        }
        System.assertEquals(5, i);

        List<Bill_Adjustment__c> adjustmentsToUpdate = new List<Bill_Adjustment__c>();

        Test.startTest();
        for (Bill_Adjustment__c adjust : beforeCallList){
            adjustmentsToUpdate.add(ZuoraCreditDebitMemoService.createCreditOrDebitMemo(adjust));
        }
        Test.stopTest();

        System.assertEquals(5,adjustmentsToUpdate.size());
        for (Bill_Adjustment__c adjustment : adjustmentsToUpdate){
            System.assertNotEquals(null, adjustment.Zuora_Id__c);
        }
    }

    @IsTest
    private static void testCallWithoutUpdatingAdjustment() {
        Database.QueryLocator queryLocator = AdjustmentSelector.getAdjustmentsNotYetInZuora(false);
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        List<Bill_Adjustment__c> beforeCallList = new List<Bill_Adjustment__c>();
        Integer i = 0;
        while (iterator.hasNext()) {
            beforeCallList.add((Bill_Adjustment__c) iterator.next());
            i++;
        }
        System.assertEquals(5, i);

        Test.startTest();
        ZuoraCreditMemoBatchSend zSend = new ZuoraCreditMemoBatchSend();
        zSend.executeBatch();
        Test.stopTest();

        List<Bill_Adjustment__c> adjustList = [
            SELECT Id, Name, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c = '2c92c0fa6a3458e1016a45ac238e0d74'
        ];
        System.assertEquals(0, adjustList.size());
    }
}