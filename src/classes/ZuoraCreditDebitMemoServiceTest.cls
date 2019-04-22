@isTest
public class ZuoraCreditDebitMemoServiceTest {
    @testSetup public static void testDataSetup() {
        MultipleMonthProductionUpdateTest.multipleMonthTest();
        setBillsToUnPublished();

        List<UASB__c> uasbList = [
            SELECT Id, Name, Utility_Account_Subscription__r.Id
            FROM UASB__c
            ORDER BY Date__c
            LIMIT 2
        ];

        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment',
            Utility_Account_Subscription__c = uasbList[0].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[0].Id,
            Adjustment_Type__c = 'BW Credit',
            Adjustment_Amount__c = 90,
            Credits_Allocated__c = 100,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustTwo = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment2',
            Utility_Account_Subscription__c = uasbList[0].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[0].Id,
            Adjustment_Type__c = 'Client Credit',
            Adjustment_Amount__c = 45,
            Credits_Allocated__c = 50,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustThree = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment2',
            Utility_Account_Subscription__c = uasbList[1].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[1].Id,
            Adjustment_Type__c = 'BW Credit',
            Adjustment_Amount__c = 15,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustFour = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment2',
            Utility_Account_Subscription__c = uasbList[1].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[1].Id,
            Adjustment_Type__c = 'BW Credit',
            Adjustment_Amount__c = 99,
            Approval_Status__c = 'Approved',
            Zuora_Id__c = 'XXXXXXXXXXXXXXXXXX',
            Reason_For_Adjustment__c = 'Needs adjustment');

        insert new List<Bill_Adjustment__c>{adjustOne, adjustTwo, adjustThree, adjustFour};
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

        List<Error_Log__c> errors = [
            SELECT Id, Message__c
            FROM Error_Log__c
        ];
        System.assertEquals(0, errors.size());
    }
}