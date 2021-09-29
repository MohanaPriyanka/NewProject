/**
 * Created by SarahRenfro on 12/2/2020.
 */

@IsTest
private class UALSelectorTest {

    private static UALSelector ualSelector = new UALSelector();

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

        System.assertEquals(2, ualSelector.selectDuplicateUALs(ualNumber).size());
    }

    @IsTest
    static void testSelectOne() {

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Name = '1UAL'
        );

        insert ual;

        System.assertEquals('1UAL', ualSelector.selectOne(ual.Id).Name, 'Query should return the correct ual');
    }

    @IsTest
    static void testSelectAllMap() {

        Utility_Account_Log__c ual1 = new Utility_Account_Log__c(
            Name = '1UAL'
        );

        Utility_Account_Log__c ual2 = new Utility_Account_Log__c(
            Name = '2UAL'
        );

        insert new List<Utility_Account_Log__c>{ual1, ual2};

        Set<Id> ualIds = new Set<Id>{ual1.Id, ual2.Id};

        Map<Id,Utility_Account_Log__c>  queryResult = ualSelector.selectAllMap(ualIds);

        System.assertEquals(2, queryResult.size()); 


    }
}