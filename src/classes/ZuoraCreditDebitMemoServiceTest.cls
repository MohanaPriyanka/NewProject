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
            Name = 'UASoneAdjustment2',
            Utility_Account_Subscription__c = uasbList[1].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[1].Id,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = -15,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustFour = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment2',
            Utility_Account_Subscription__c = uasbList[1].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[1].Id,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = -99,
            Approval_Status__c = 'Approved',
            Zuora_Id__c = 'XXXXXXXXXXXXXXXXXX',
            Reason_For_Adjustment__c = 'Needs adjustment');

        insert new List<Bill_Adjustment__c>{adjustOne, adjustTwo, adjustThree, adjustFour};

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
    private static void testAPICallWithMock() {
        // disableTrigger just sets a system property checkbox to true
        Util.disableTrigger('Update_Usage_Records_With_ZuoraId__c');

        List<Bill_Adjustment__c> beforeCallList = AdjustmentSelector.getAdjustmentsNotYetInZuora(false);
        System.assertEquals(3, beforeCallList.size());

        Test.startTest();
        ZuoraCreditMemoBatchSend zSend = new ZuoraCreditMemoBatchSend();
        zSend.executeBatch();
        Test.stopTest();

        List<Bill_Adjustment__c> adjustList = [
            SELECT Id, Name, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c = '2c92c0fa6a3458e1016a45ac238e0d74'
        ];
        System.assertEquals(3, adjustList.size());
    }

    @IsTest
    private static void testCallWithoutUpdatingAdjustment() {
        List<Bill_Adjustment__c> beforeCallList = AdjustmentSelector.getAdjustmentsNotYetInZuora(false);
        System.assertEquals(3, beforeCallList.size());

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