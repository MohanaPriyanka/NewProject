/**
 * Created by pyao on 2/1/2019.
 */
@IsTest
public with sharing class SystemBillsSelectorTest {
    @TestSetup public static void setupData() {
        CSPaymentTest.CSPaymentSetupTestData();
    }

    @IsTest static void testSelectSystemBillsModifiedAfter() {
        // These bills shouldn't be selected by selectSystemBillsModifiedAfter because they were before testStart
        List<System_Bill__c> systemBills = SystemBillsSelector.selectAllSystemBills();
        System.assert(systemBills.size() >= 21, 'TestCSSystemBill.resource only has ' + systemBills.size() + ' bills');
        // Salesforce doesn't store milliseconds in the database, System.now() will have more precision than SystemModstamp.
        // We need to round the datetime to the second:
        Datetime testStart = Datetime.newInstance((System.now().getTime()/1000)*1000);
        for (System_Bill__c systemBill : systemBills) {
            System.assert(systemBill.SystemModstamp <= testStart,
                'Did not expect to have a SystemModstamp ' + systemBill.SystemModstamp + ' later than the start of this test: ' + testStart);
        }

        List<System_Bill__c> newSystemBills = systemBills.deepClone(false);
        for (System_Bill__c systemBill : newSystemBills) {
            systemBill.Name = 'Modstamp Test';
        }
        // These bills should be selected by selectSystemBillsModifiedAfter because they were created after testStart
        insert newSystemBills;

        List<System_Bill__c> updatedSystemBills = SystemBillsSelector.selectSystemBillsModifiedAfter(testStart);
        System.assertEquals(newSystemBills.size(), updatedSystemBills.size());
        for (System_Bill__c systemBill : updatedSystemBills) {
            System.assertEquals('Modstamp Test', systemBill.Name);
            System.assert(systemBill.SystemModstamp >= testStart,
                'Selected an old system bill testStart: ' + testStart.getTime() + ' modstamp: ' + systemBill.SystemModstamp.getTime());
        }
    }


}