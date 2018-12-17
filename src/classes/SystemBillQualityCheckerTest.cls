/**
 * Created by pyao on 12/17/2018.
 */
@IsTest
public with sharing class SystemBillQualityCheckerTest {
    @TestSetup
    public static void setupTestData() {
        CSPaymentTest.CSPaymentSetupTestData();
    }

    @IsTest
    public static void testTooManyDecimalsOnInsert() {
        List<System_Bill__c> systemBills = [
            SELECT Id, Name, Account_Bill__c, Property_Account__c, Opportunity__c, Shared_Solar_System__c, Shared_Solar_System_ID2__c,
                Unique_ID__c, Total_Due__c, Balance_Net_Late_Payments__c, Carry_Over_Balance__c, Due_This_Month__c, Bill_Number__c,
                Date__c, Date_of_Last_Payment__c, Late_Fee_Payments__c, Late_Fees__c, Late_Payments__c,
                Payments_Net_Previous_Balances__c, Previous_Month_Overdue_Balance__c, Total_Payments_This_Month__c,
                Waive_Late_Fees__c, Recurring_Billing__c, Payment_Plan_Balance__c, Payment_Plan_Balance_to_Distribute__c,
                Distribute_This_Balance_as_Payment_Plan__c, Past_Bill_Amount__c, Past_Bill_Payment__c, Refund_this_Balance__c,
                Date_Refunded__c, Adjustments__c, Amount_to_Add__c, Amount_to_Deduct__c, Early_Payments__c,
                Carry_Forward_Adjustments__c, Distribute_This_Balance_12mo__c, Carry_Forward_Payments__c, Balance_Adjustments__c
            FROM System_Bill__c
            LIMIT 1
        ];
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c WHERE Class__c = 'SystemBillQualityChecker'];
        System.assertEquals(0, errorLogs.size());

        Test.startTest();
        System_Bill__c systemBillWithTooManyDecimals = systemBills[0].clone();
        systemBillWithTooManyDecimals.Adjustments__c = .0012345;
        insert systemBillWithTooManyDecimals;
        Test.stopTest();

        errorLogs = [SELECT Id FROM Error_Log__c WHERE Class__c = 'SystemBillQualityChecker'];
        System.assertEquals(1, errorLogs.size());
    }

    @IsTest
    public static void testTooManyDecimalsOnUpdate() {
        List<System_Bill__c> systemBills = [SELECT Id FROM System_Bill__c LIMIT 1];
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c WHERE Class__c = 'SystemBillQualityChecker'];
        System.assertEquals(0, errorLogs.size());

        Test.startTest();
        systemBills[0].Total_Payments_This_Month__c = .0012345;
        update systemBills[0];
        Test.stopTest();

        errorLogs = [SELECT Id FROM Error_Log__c WHERE Class__c = 'SystemBillQualityChecker'];
        System.assertEquals(1, errorLogs.size());
    }

    @IsTest
    public static void testGetSBList() {
        Test.startTest();
        Map<Id, System_Bill__c> systemBillMap = new Map<Id, System_Bill__c>([SELECT Id FROM System_Bill__c]);
        List<SObject> systemBillsWithCurrencyFields = SystemBillQualityChecker.getSystemBillsWithCurrencyFields(new List<Id>(systemBillMap.keySet()));
        System.assertEquals(systemBillMap.values().size(), systemBillsWithCurrencyFields.size());

    }
}