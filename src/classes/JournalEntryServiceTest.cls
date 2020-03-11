@isTest
public class JournalEntryServiceTest {
    @isTest
    public static void testTrigger() {
        List<Error_Log__c> beforeLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'JournalEntrySelector'
        ];
        System.assertEquals(0, beforeLogs.size());

        List<Journal_Entry__c> beforeEntries = [
            SELECT Id
            FROM Journal_Entry__c
        ];
        System.assertEquals(0, beforeEntries.size());

        Test.startTest();
            List<Journal_Entry__c> entries = getJournalEntries();
            insert entries;
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'JournalEntryService'
        ];
        System.assert(afterLogs.size() > 0);

        // Even if it hits failure, entries should still be inserted:
        List<Journal_Entry__c> afterEntries = [
            SELECT Id
            FROM Journal_Entry__c
        ];
        System.assertEquals(6, afterEntries.size());
    }

    @isTest
    public static void testDisabledTrigger() {
        Util.disableTrigger('Disable_Journal_Entry_Trigger__c');
        List<Error_Log__c> beforeLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'JournalEntrySelector'
        ];
        System.assertEquals(0, beforeLogs.size());

        List<Journal_Entry__c> beforeEntries = [
            SELECT Id
            FROM Journal_Entry__c
        ];
        System.assertEquals(0, beforeEntries.size());

        Test.startTest();
        List<Journal_Entry__c> entries = getJournalEntries();
        insert entries;
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'JournalEntryService'
        ];
        System.assertEquals(0,afterLogs.size());

        // Even if it hits failure, entries should still be inserted:
        List<Journal_Entry__c> afterEntries = [
            SELECT Id
            FROM Journal_Entry__c
        ];
        System.assertEquals(6, afterEntries.size());
    }

    @isTest
    public static void testPopulateLookups() {
        useMocks();
        List<Journal_Entry__c> entries = getJournalEntries();

        System.assertEquals(6,entries.size());
        for (Journal_Entry__c entry : entries){
            System.assertEquals(null,entry.Customer_Lookup__c);
            System.assertEquals(null,entry.Client_Lookup__c);
            System.assertEquals(null,entry.Project_Lookup__c);
        }

        JournalEntryService jeService = new JournalEntryService();
        List<Journal_Entry__c> entriesToUpdate = jeService.populateLookups(entries);

        System.assertEquals(6,entriesToUpdate.size());

        for (Journal_Entry__c entry : entriesToUpdate){
            switch on entry.Customer_Account__c {
                when 'bw-00524' {
                    System.assertEquals('0015400000SajzCAAA',entry.Customer_Lookup__c);
                }
                when 'bw-05268' {
                    System.assertEquals('0015400000SajzCCCC',entry.Customer_Lookup__c);
                }
                when 'bw-05956' {
                    System.assertEquals('0015400000SajzCDDD',entry.Customer_Lookup__c);
                }
                when 'bw-04202' {
                    System.assertEquals('0015400000SajzCBBB',entry.Customer_Lookup__c);
                }
                when else {
                    System.assert(false);
                }
            }
        }

        for (Journal_Entry__c entry : entriesToUpdate){
            switch on entry.Project__c {
                when 'SSS-000001' {
                    System.assertEquals('a1J3K0000000AMUUA2',entry.Project_Lookup__c);
                    System.assertEquals('0015400000SajzCEEE',entry.Client_Lookup__c);
                }
                when 'SSS-000002' {
                    System.assertEquals('a1J3K0000000AMUUA4',entry.Project_Lookup__c);
                    System.assertEquals('0015400000SajzCEEE',entry.Client_Lookup__c);
                }
                when 'SSS-000022' {
                    System.assertEquals('a1J3K0000000AMUUA3',entry.Project_Lookup__c);
                    System.assertEquals('0015400000SajzCEEE',entry.Client_Lookup__c);
                }
                when 'SSS-000045' {
                    System.assertEquals('a1J3K0000000AMUUA5',entry.Project_Lookup__c);
                    System.assertEquals('0015400000SajzCFFF',entry.Client_Lookup__c);
                }
                when else {
                    System.assert(false);
                }
            }
        }
    }

    private static void useMocks() {
        JournalEntryService.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockSSSselector());
        JournalEntryService.accountSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new MockAccountSelector());
    }

    public class MockSSSselector extends MockProvider {
        public MockSSSselector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String sssMapAsString = '{' +
                '"SSS-000001":{"Id":"a1J3K0000000AMUUA2", "Name":"Project A","Unique_ID__c":"SSS-000001"},' +
                '"SSS-000022":{"Id":"a1J3K0000000AMUUA3", "Name":"Project B","Unique_ID__c":"SSS-000022"},' +
                '"SSS-000002":{"Id":"a1J3K0000000AMUUA4", "Name":"Project C","Unique_ID__c":"SSS-000002"},' +
                '"SSS-000045":{"Id":"a1J3K0000000AMUUA5", "Name":"Project D","Unique_ID__c":"SSS-000045"}' +
                '}';
            switch on methodCall.stubbedMethodName {
                when 'getSSSByUniqueId' {
                    return (Map<String, Shared_Solar_System__c>)JSON.deserialize(sssMapAsString, Map<String, Shared_Solar_System__c>.class);
                }
            }
            return null;
        }
    }

    public class MockAccountSelector extends MockProvider {
        public MockAccountSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String accountMapString = '{' +
                '"bw-00524":{"Id":"0015400000SajzCAAA", "Name":"Account A","Account_Number__c":"bw-00524"},' +
                '"bw-04202":{"Id":"0015400000SajzCBBB", "Name":"Account B","Account_Number__c":"bw-04202"},' +
                '"bw-05268":{"Id":"0015400000SajzCCCC", "Name":"Account C","Account_Number__c":"bw-05268"},' +
                '"bw-05956":{"Id":"0015400000SajzCDDD", "Name":"Account D","Account_Number__c":"bw-05956"},' +
                '"BW-0009470":{"Id":"0015400000SajzCEEE", "Name":"Client Account One","Account_Number__c":"BW-0009470"},' +
                '"BW-0009186":{"Id":"0015400000SajzCFFF", "Name":"Client Account Two","Account_Number__c":"BW-0009186"}' +
                '}';
            switch on methodCall.stubbedMethodName {
                when 'selectByBlueWaveId' {
                    return (Map<String, Account>)JSON.deserialize(accountMapString, Map<String, Account>.class);
                }
            }
            return null;
        }
    }

    private static List<Journal_Entry__c> getJournalEntries() {
        Date mayBillDate = Date.newInstance(2019,05,20);
        Date juneBillDate = Date.newInstance(2019,06,20);

        Journal_Entry__c entryOne = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 252.73,
            External_Id__c = '2c92c0fa6e3a9391016e3df87b1f687a',
            Customer_Account__c = 'bw-00524',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryTwo = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 135.06,
            External_Id__c = '2c92c0fa6e3a9391016e3e30d48066d2',
            Customer_Account__c = 'bw-00524',
            Date__c = juneBillDate
        );
        Journal_Entry__c entryThree = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000022',
            Client__c = 'BW-0009470',
            Amount__c = 255.63,
            External_Id__c = '2c92c0fb6e3aa321016e3df574337a9b',
            Customer_Account__c = 'bw-05268',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryFour = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000045',
            Client__c = 'BW-0009186',
            Amount__c = 1997.03,
            External_Id__c = '2c92c0fa6e3a938d016e3dfdc93450b2',
            Customer_Account__c = 'bw-05956',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryFive = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000002',
            Client__c = 'BW-0009470',
            Amount__c = 37.23,
            External_Id__c = '2c92c0fb6e3aa322016e3df698ff7e9f',
            Customer_Account__c = 'bw-04202',
            Date__c = mayBillDate
        );
        Journal_Entry__c entrySix = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000002',
            Client__c = 'BW-0009470',
            Amount__c = 62.55,
            External_Id__c = '2c92c0fa6e3a938d016e3e2ed1f832aa',
            Customer_Account__c = 'bw-04202',
            Date__c = juneBillDate
        );
        List<Journal_Entry__c> entries = new List<Journal_Entry__c>{
            entryOne, entryTwo, entryThree, entryFour, entryFive, entrySix
        };
        return entries;
    }

}