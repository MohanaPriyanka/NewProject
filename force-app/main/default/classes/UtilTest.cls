/**
 * @description : Tests Util class to ensure methods behave as expected
 */
@SuppressWarnings('PMD.AvoidHardcodingId')
@IsTest
public with sharing class UtilTest {
    @IsTest
    private static void testInsertSObj() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Perch Standard'];

        User u = new User(
            Alias = 'testUtil',
            Email='testUtil@test.test',
            EmailEncodingKey='UTF-8',
            LastName='testUtil',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = profile.Id,
            Country='United States',
            IsActive = true,
            TimeZoneSidKey='America/New_York',
            Username='testUtil@test.test');
        Util.insertSObj(u);

        User newUser = [
            SELECT Id, Alias, Email
            FROM User
            WHERE LastName = 'testUtil'
        ];

        System.assertNotEquals(null, newUser);
    }

    @IsTest
    private static void testDatabaseOperation() {
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        // Shouldn't be any error logs yet
        System.assertEquals(0, errorLogs.size());
        Account foo = new Account(Name = 'foo');
        Account bar = new Account();
        // Datbase insert shouldn't be successful
        System.assertEquals(false, Util.insertAndLog(new List<Account>{foo, bar}, 'UtilTest', 'testDatabaseOperation'));
        // Shouldn't error, and should have a log
        errorLogs = [SELECT Id, Message__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size());

        foo.Name = 'baz';
        System.assertEquals(true, Util.updateAndLog(new List<Account>{foo}, 'UtilTest', 'testDatabaseOperation'));
        // Should be successful
        errorLogs = [SELECT Id, Message__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size());
    }

    @IsTest
    private static void testDatabaseUpdate() {
        Account acct = new Account(Name = 'Account');
        insert acct;

        acct.Name = 'Updated Account';
        Util.updateSObjs(new List<Account>{acct});

        Account updatedAccount = [
            SELECT Id, Name
            FROM Account
            WHERE Id = : acct.Id
        ];

        System.assertEquals('Updated Account',updatedAccount.Name);
    }

    @IsTest
    private static void testNullToZero() {
        Decimal nullToZero;
        System.assertEquals(null, nullToZero);

        nullToZero = Util.nullToZero(nullToZero);
        System.assertEquals(0, nullToZero);
    }

    @IsTest
    private static void testGetCommunitySiteURL() {
        String siteURL = Util.getCommunitySiteURL('Apply');
        System.assert(siteURL.contains('perch'), 'Should contain perch in the domain');
        System.assert(siteURL.contains('apply'), 'Should include apply in the URL');
    }

    @IsTest
    private static void testPrintLimits() {
        Boolean errorCaught = false;
        try {
            Util.printCPULimit('Print CPU Limit');
        } catch (Exception e) {
            errorCaught = true;
        }
        System.assert(!errorCaught);

        try {
            Util.printSOQLLimit('Print SOQL Limit');
        } catch (Exception e) {
            errorCaught = true;
        }
        System.assert(!errorCaught);

        try {
            Util.printHeapLimit('Print Heap Limit');
        } catch (Exception e) {
            errorCaught = true;
        }
        System.assert(!errorCaught);

        try {
            Util.printRowLimit('Print Row Limit');
        } catch (Exception e) {
            errorCaught = true;
        }
        System.assert(!errorCaught);

        try {
            Util.getLimits();
        } catch (Exception e) {
            errorCaught = true;
        }
        System.assert(!errorCaught, 'Util.getLimits() threw an exception');
    }

    @IsTest
    private static void testPrepForCSV() {
        String unprepped = 'this is$_@an \n=+ un\n}pr{e[pp]ed, str)ing(.';
        String expected = 'this is_an  unprepped string.';
        System.assertEquals(expected, Util.prepForCSV(unprepped));
        System.assertEquals('', Util.prepForCSV(null));
    }

    @IsTest
    private static void testTriggerDisable() {
        // By default, if there's no system property, triggers are not disabled
        System.assertEquals(false, Util.isDisabled('Disable_AccountTrigger__c'));
        System_Properties__c property = new System_Properties__c(Name = 'System', Disable_AccountTrigger__c = true);
        insert property;
        // We should be able to manually disable
        System.assertEquals(true, Util.isDisabled('Disable_AccountTrigger__c'));
        // If there's a system property, trigger shouldn't be disabled by default
        System.assertEquals(false, Util.isDisabled('Disable_LeadTrigger__c'));
        Util.disableTrigger('Disable_LeadTrigger__c');
        // We should be able to disable it
        System.assertEquals(true, Util.isDisabled('Disable_LeadTrigger__c'));
        Util.enableTrigger('Disable_LeadTrigger__c');
        // And enable it
        System.assertEquals(false, Util.isDisabled('Disable_LeadTrigger__c'));
        delete property;
        // Back to no System_Property, triggers should be enabled again
        System.assertEquals(false, Util.isDisabled('Disable_LeadTrigger__c'));
        System.assertEquals(false, Util.isDisabled('Disable_AccountTrigger__c'));
        Util.disableTrigger('Disable_LeadTrigger__c');
        // And we should be able to disable it without explicitly creating a System Property
        System.assertEquals(true, Util.isDisabled('Disable_LeadTrigger__c'));
        Util.disableTrigger('Disable_AccountTrigger__c');
        System.assertEquals(true, Util.isDisabled('Disable_AccountTrigger__c'));
        // All this shouldn't use any SOQL queries
        System.assertEquals(0, Limits.getQueries());
    }
    @IsTest
    private static void testAllTriggerToggle() {
        // By default, if there's no system property, triggers are not disabled
        System.assertEquals(false, Util.isDisabled('Disable_AccountTrigger__c'));
        Util.disableAllTriggers();
        System.assertEquals(true, Util.isDisabled('Disable_AccountTrigger__c'));
        System.assertEquals(true, Util.isDisabled('Disable_LeadTrigger__c'));
        Util.enableAllTriggers();
        System.assertEquals(false, Util.isDisabled('Disable_AccountTrigger__c'));
        System.assertEquals(false, Util.isDisabled('Disable_LeadTrigger__c'));
        // And test that it still works with an existing system property
        Util.disableAllTriggers();
        System.assertEquals(true, Util.isDisabled('Disable_AccountTrigger__c'));
        System.assertEquals(true, Util.isDisabled('Disable_LeadTrigger__c'));
    }

    @IsTest
    private static void testGetSystemPropertyString() {
        System.assertEquals('', Util.getSystemPropertyString('Log_Level__c'));
        System_Properties__c property = new System_Properties__c(
            Name = 'System',
            Log_Level__c = 'Fine'
        );
        insert property;
        System.assertEquals('Fine', Util.getSystemPropertyString('Log_Level__c'));
    }

    @IsTest
    private static void testGetSystemPropertyCheckbox() {
        System.assertEquals(false, Util.getSystemPropertyCheckbox('Disable_AccountTrigger__c'));
        System_Properties__c property = new System_Properties__c(Name = 'System', Disable_AccountTrigger__c = true);
        insert property;
        System.assertEquals(true, Util.getSystemPropertyCheckbox('Disable_AccountTrigger__c'));
    }

    @IsTest
    private static void testGetSystemPropertyDecimal() {
        System.assertEquals(0, Util.getSystemPropertyDecimal('System_Bill_Generation_Grace_Period__c'));
        System_Properties__c property = new System_Properties__c(Name = 'System', System_Bill_Generation_Grace_Period__c = 10);
        insert property;
        System.assertEquals(10, Util.getSystemPropertyDecimal('System_Bill_Generation_Grace_Period__c'));
    }

    @IsTest
    private static void testValidateStringsWithNullValue() {
        Map<String, String> requiredFields = new Map<String, String>{'nullField'=>null, 'validString'=>'hello world' };
        try {
            Util.validateStrings(requiredFields);
            System.assert(false, 'This assert should not be called, because an exception should be thrown');
        } catch (Exception e) {
            System.assertEquals(e.getMessage(), 'Required field not provided: nullField', 'Should detect null fields');
        }
    }

    @IsTest
    private static void testValidateStringsWithValidValues() {
        Map<String, String> requiredFields = new Map<String, String>{'validString'=>'hello world', 'anotherValidField'=>'foobar' };
        try {
            Util.validateStrings(requiredFields);
            System.assert(true, 'This assert should be called, because an exception should not be thrown');
        } catch (Exception e) {
            System.assert(false, 'This assert should not be called, because an exception should not be thrown');
        }
    }

    @IsTest
    private static void testGetFakeId() {
        String id = Util.getFakeId(Schema.Account.SObjectType);
        System.assertEquals('001000000000000', id, 'Fake ID should be 15 characters long, and have the proper 3-digit prefix for the entity');
    }
    @IsTest
    private static void testIncrementFakeId() {
        String id = Util.getFakeId(Schema.Account.SObjectType);
        System.assertEquals('001000000000001', Util.incrementFakeId(id), 'Incrementing an id should just add one to the end');
    }

    @IsTest
    private static void testIsSandboxOrTest() {
        System.assert(Util.isSandboxOrTest(), 'Expected isSandboxOrTest to be true for a test!');
    }

    @IsTest
    private static void testCreateAuraExceptionWithMessage(){
        AuraHandledException except = Util.createAuraExceptionWithMessage('This is the message');
        System.assertEquals('This is the message',except.getMessage());
    }

    @IsTest
    private static void testReadCSV(){
        String csvData = 'ColumnOne,ColumnTwo\nDataOne,DataTwo\nDataThree,DataFour';
        Map<Integer, List<String>> mapOfData = Util.readCSV(csvData);
        System.assertEquals('DataOne',mapOfData.get(1)[0]);
        System.assertEquals('DataTwo',mapOfData.get(1)[1]);
        System.assertEquals('DataThree',mapOfData.get(2)[0]);
        System.assertEquals('DataFour',mapOfData.get(2)[1]);
    }

    @IsTest
    private static void testCommitWorkWithRetry() {
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Account.SObjectType});
        Account newAccount = new Account(Name = 'Test');
        uow.registerNew(newAccount);
        Account newAccountTwo = new Account(Name = 'Test Two');
        uow.registerNew(newAccountTwo);

        Util.commitWorkWithRetry(uow,3);

        List<Account> newAccounts = [
            SELECT Id
            FROM Account
        ];
        System.assertEquals(2,newAccounts.size());
    }

    @IsTest
    private static void testRetrieveFromMap() {
        Account acc = new Account(Id = '0010a00001gQ1IEAA0', Name = 'Daniel Goldberg');
        Map<Id, Account> accountMap = new Map<Id, Account>();
        accountMap.put(acc.Id, acc);

        Account accFromUtility = (Account) Util.retrieveOrCreateFromMap(acc.Id, accountMap);
        System.assertEquals(acc, accFromUtility, 'Object retrieved by Util should point to the same reference');

        Account accFromUtilityNotFound = (Account) Util.retrieveOrCreateFromMap('0010a00001gQ2IEAA0', accountMap);
        System.assert(accFromUtilityNotFound != null, 'Account not in map should still return new Account record');
        System.assertEquals(null, accFromUtilityNotFound.Name, 'This Account was not in the map and should have no data');
    }
}