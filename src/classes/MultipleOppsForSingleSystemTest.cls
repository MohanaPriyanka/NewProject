/**
 * Created by PeterYao on 7/1/2019.
 */
@IsTest
public with sharing class MultipleOppsForSingleSystemTest {
    @TestSetup public static void testSetup() {
        TestBillCreationandPayment.csTestRecordWarehouse(true);
    }

    // As of June 2019, the Unique ID for a System Bill was based on the Opportunity Name, which happened to be unique.
    // When we started having opportunities with the same name and project, the System Bill would be related to one
    // of the opportunities, indeterminately. That would affect the Bill Number (bill numbers are sequenced by opportunity)
    // and thus carryover balance. Thus, the carryover balance from month to month could be wrong if the System Bill
    // for that project switched from one opportunity to another.
    // Each System Bill, before this change, if it was for multiple opportunities, would also have multiple UASBs, and the
    // UASB Opportunity would be different from the System Bill opportunity. This test checks that the UASB Opportunity
    // is always the same as the System Bill Opportunity
    @IsTest public static void testUniqueSystemBillsPerOpp() {
        Test.startTest();
        List<System_Bill__c> systemBillList = SystemBillsSelector.selectAllSystemBills();
        System.assertEquals(4, systemBillList.size());
        for (System_Bill__c systemBill : systemBillList) {
            for (UASB__c uasb : systemBill.Utility_Account_Subscription_Bills__r) {
                System.assertEquals(systemBill.Opportunity__c, uasb.Opportunity__c);
            }
        }
        Test.stopTest();
    }
}