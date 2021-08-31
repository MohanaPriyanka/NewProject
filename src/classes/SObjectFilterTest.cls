@IsTest
public with sharing class SObjectFilterTest {

    @IsTest
    private static void testFilterByFieldValueChange() {
        SampleDataWrapper data = constructAccountData();
        SObjectFilter filter;

        // Test 'Name' field change on Account list, where a change is found
        filter = new SObjectFilter(
            data.triggerOldMap, data.triggerNewList, Account.Name, 'Old Account', SObjectFilter.ANY_VALUE
        );
        List<Account> accountList = (List<Account>) filter.get(SObjectFilter.SOBJECT_LIST);
        System.assert(!accountList.isEmpty(), 'Return list should have SObject rows -- all records met change criteria');
        System.assertEquals(9, accountList.size(), '9 records should have been returned which all met change criteria');

        // Test 'Phone' field change on Account list, where no change is recorded
        filter = new SObjectFilter(
            data.triggerOldMap, data.triggerNewList, Account.Phone, '14013343929', SObjectFilter.ANY_VALUE
        );
        accountList = (List<Account>) filter.get(SObjectFilter.SOBJECT_LIST);
        System.assert(accountList.isEmpty(), 'Return list should have no SObject rows -- no records met change criteria');

        // Test 'BillingAddress' field change on Account list, where no BillingAddress is set or updated
        filter = new SObjectFilter(
            data.triggerOldMap, data.triggerNewList, Account.BillingAddress, null, SObjectFilter.ANY_VALUE
        );
        Map<Id, SObject> accountMap = (Map<Id, SObject>) filter.get(SObjectFilter.SOBJECT_MAP);
        System.assert(accountMap.isEmpty(), 'Return map should have no entries -- no records met change criteria');

        // Test 'Name' field change on Account list, where a change is found... And select the SOBJECT_MAP return type
        filter = new SObjectFilter(
            data.triggerOldMap, data.triggerNewList, Account.Name, 'Old Account', 'New Account'
        );
        accountMap = (Map<Id, SObject>) filter.get(SObjectFilter.SOBJECT_MAP);
        System.assertEquals(9, accountMap.size(), '9 entries should exist in the map representing records which met change criteria');

        // Test 'Name' field change on Account list, where a change is found... And select the SOBJECT_ID_SET return type
        filter = new SObjectFilter(
            data.triggerOldMap, data.triggerNewList, Account.Name, 'Old Account', 'New Account'
        );
        Set<Id> accountIdSet = (Set<Id>) filter.get(SObjectFilter.SOBJECT_ID_SET);
        System.assertEquals(9, accountIdSet.size(), '9 entries should exist in the ID set representing records which met change criteria');

        // Test 'Name' field change on account list, but also add additional criteria
        filter = new SObjectFilter(
            data.triggerOldMap, data.triggerNewList, Account.Name, 'Old Account', 'New Account'
        );
        filter.addFilterCriteria(Account.AnnualRevenue, SObjectFilter.GREATER_OR_EQUAL_TO, 10001);
        accountIdSet = (Set<Id>) filter.get(SObjectFilter.SOBJECT_ID_SET);
        System.assertEquals(8, accountIdSet.size(), '8 entries should exist in the ID set representing records which met change criteria and addtl filter');
    }

    @IsTest
    private static void testIsFieldValueChangedExceptions() {
        Integer exceptionsEncountered = 0;
        SObjectFilter filter;

        // Fail to provide Trigger.old (which is required)
        try {
            filter = new SObjectFilter(null, null, null, null, null);
        } catch (Exception e) {
            System.assert(e instanceof SObjectFilter.FilterException, 'Unexpected exception type');
            exceptionsEncountered++;
        }
        System.assertEquals(1, exceptionsEncountered, 'Should have encountered one error at this point in the test method');

        // Fail to provide a fieldName to compare (which is required)
        try {
            filter = new SObjectFilter(new Map<Id, SObject>(), new List<SObject>(), null, null, null);
        } catch (Exception e) {
            System.assert(e instanceof SObjectFilter.FilterException, 'Unexpected exception type');
            exceptionsEncountered++;
        }
        System.assertEquals(2, exceptionsEncountered, 'Should have encountered two errors at this point in the test method');

        // Leave changeFromValue and changeToValue constructor params as identical (not permitted, would result in pointless calculation)
        try {
            filter = new SObjectFilter(new Map<Id, SObject>(), new List<SObject>(), Account.Name, null, null);
        } catch (SObjectFilter.FilterException e) {
            System.assert(e.getMessage() == 'changeFromValue and changeToValue cannot be identical', 'Unexpected err msg');
            exceptionsEncountered++;
        }
        System.assertEquals(3, exceptionsEncountered, 'Should have encountered three errors at this point in the test method');

        // Fail to provide a return object type for the data
        try {
            filter = new SObjectFilter(new Map<Id, SObject>(), new List<SObject>(), Account.Name, 0, null);
            filter.get(null);
        } catch (Exception e) {
            System.assert(e instanceof NullPointerException, 'Unexpected exception type');
            exceptionsEncountered++;
        }
        System.assertEquals(4, exceptionsEncountered, 'Should have encountered four errors at this point in the test method');
    }

    @IsTest
    private static void testMeetsFilterCriteria() {
        SampleDataWrapper data = constructAccountData();

        List<Account> list1 = (List<Account>)
            new SObjectFilter(data.triggerNewList, Account.AnnualRevenue, SObjectFilter.GREATER_THAN, 10000)
                .get(SObjectFilter.SOBJECT_LIST);
        System.assertEquals(8, list1.size());

        List<Account> list2 = (List<Account>)
            new SObjectFilter(data.triggerNewList, Account.AnnualRevenue, SObjectFilter.GREATER_OR_EQUAL_TO, 10000)
                .get(SObjectFilter.SOBJECT_LIST);
        System.assertEquals(9, list2.size());

        List<Account> list3 = (List<Account>)
            new SObjectFilter(data.triggerNewList, Account.AnnualRevenue, SObjectFilter.LESS_THAN, 10001)
                .get(SObjectFilter.SOBJECT_LIST);
        System.assertEquals(1, list3.size());

        List<Account> list4 = (List<Account>)
            new SObjectFilter(data.triggerNewList, Account.AnnualRevenue, SObjectFilter.LESSER_OR_EQUAL_TO, 10002)
                .get(SObjectFilter.SOBJECT_LIST);
        System.assertEquals(3, list4.size());

        List<Account> list5 = (List<Account>)
            new SObjectFilter(data.triggerNewList, Account.Phone, SObjectFilter.EQUAL_TO, '14013343929')
                .get(SObjectFilter.SOBJECT_LIST);
        System.assertEquals(9, list5.size());

        List<Account> list6 = (List<Account>)
            new SObjectFilter(data.triggerNewList, Account.Phone, SObjectFilter.NOT_EQUAL_TO, '14013343929')
                .get(SObjectFilter.SOBJECT_LIST);
        System.assertEquals(0, list6.size());

        List<Account> list7 = (List<Account>)
            new SObjectFilter(new Map<Id, SObject>(), new List<SObject>(), Account.Name, 0, null)
                .get(SObjectFilter.SOBJECT_LIST);
        System.assertEquals(0, list7.size());

        try {
            List<Account> errorList = (List<Account>)
                new SObjectFilter(data.triggerNewList, Account.AnnualRevenue, null, 10000)
                    .get(SObjectFilter.SOBJECT_LIST);
        } catch (Exception e) {
            System.assert(e instanceof NullPointerException, 'Invalid exception type');
        }
    }

    @IsTest
    private static void testDateComparisons() {
        List<Contact> contactsMeetingCriteria;
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Smith',
            Email = 'john.smith@testcase.com',
            Birthdate = Date.newInstance(1990, 05, 25)
        );

        // Test EQUAL TO
        contactsMeetingCriteria = (List<Contact>)
            new SObjectFilter(new List<Contact>{con},Contact.Birthdate, SObjectFilter.EQUAL_TO,  Date.newInstance(1990, 05, 25))
                .get(SObjectFilter.SOBJECT_LIST);
        System.assertEquals(1, contactsMeetingCriteria.size(), 'SObjectFilter should not have filtered out record');

        // Test NOT EQUAL TO
        contactsMeetingCriteria = (List<Contact>)
            new SObjectFilter(new List<Contact>{con},Contact.Birthdate, SObjectFilter.NOT_EQUAL_TO,  Date.newInstance(1990, 05, 25))
                .get(SObjectFilter.SOBJECT_LIST);
        System.assertEquals(0, contactsMeetingCriteria.size(), 'SObjectFilter should have filtered out record');

        // Test GREATER THAN -- will throw exception
        try {
            contactsMeetingCriteria = (List<Contact>)
                new SObjectFilter(new List<Contact>{con},Contact.Birthdate, SObjectFilter.GREATER_THAN,  Date.newInstance(1990, 05, 25))
                    .get(SObjectFilter.SOBJECT_LIST);
        } catch (Exception e) {
            System.assert(e instanceof System.TypeException, 'Unexpected exception type');
        }
    }

    private static SampleDataWrapper constructAccountData() {
        Map<Id, Account> triggerOldMap = new Map<Id, Account>();
        List<Account> triggerNewList = new List<Account>();
        for (Integer i = 0; i < 9; i++) {
            Account oldAccount = new Account(
                Id = Account.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(11) + i,
                Name = 'Old Account',
                Phone = '14013343929',
                AnnualRevenue = 10000 + i
            );
            triggerOldMap.put(oldAccount.Id, oldAccount);
            Account newAccount = oldAccount.clone(true, true);
            newAccount.Name = 'New Account';
            triggerNewList.add(newAccount);
        }
        return new SampleDataWrapper(triggerOldMap, triggerNewList);
    }

    private class SampleDataWrapper {
        public Map<Id, SObject> triggerOldMap;
        public List<SObject> triggerNewList;
        public SampleDataWrapper(Map<Id, SObject> oldMap, List<SObject> newList) {
            triggerOldMap = oldMap;
            triggerNewList = newList;
        }
    }
}