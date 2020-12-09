/**
 * Created by SarahRenfro on 12/2/2020.
 */

@IsTest
private class UALSelectorTest {

    @TestSetup public static void testSetup() {
        Util.disableAllTriggers();
        Test.loadData(Contact.SObjectType, 'TestCSContact');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Test.loadData(Utility_Account_Log__c.SObjectType, 'TestCSUtilityAccountLog');
        Util.enableAllTriggers();
    }
    @IsTest
    static void testSelectDuplicateUALs() {
        String ualNumber = '0000234';
        UALSelector ualSelector = new UALSelector();

        System.assertEquals(2, ualSelector.selectDuplicateUALs(ualNumber).size());
    }
}