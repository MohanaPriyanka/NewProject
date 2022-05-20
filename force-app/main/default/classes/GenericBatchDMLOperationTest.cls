@IsTest
private with sharing class GenericBatchDMLOperationTest {
    @TestSetup
    private static void setupTestData() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Test',
            Company = 'Test'
        );
        insert testLead;
        Account newSFAccountOne = new Account(
            Name = 'Account One',
            Recurring_Billing__c = false,
            Zuora_Id__c = '222222222222222222222'
        );
        Account newSFAccountTwo = new Account(
            Name = 'Account Two',
            Recurring_Billing__c = false,
            Zuora_Id__c = '333333333333333333333'
        );
        insert new List<Account>{
            newSFAccountOne, newSFAccountTwo
        };
        Zuora__CustomerAccount__c newZuoraAccountOne = new Zuora__CustomerAccount__c(
            Name = 'Account Name',
            Zuora__Account__c = newSFAccountOne.Id,
            Zuora__Zuora_Id__c = '222222222222222222222',
            Zuora__AutoPay__c = false
        );
        Zuora__CustomerAccount__c newZuoraAccountTwo = new Zuora__CustomerAccount__c(
            Name = 'Account Name',
            Zuora__Account__c = newSFAccountTwo.Id,
            Zuora__Zuora_Id__c = '333333333333333333333',
            Zuora__AutoPay__c = false
        );
        List<Zuora__CustomerAccount__c> zAccounts = new List<Zuora__CustomerAccount__c>{
            newZuoraAccountOne, newZuoraAccountTwo
        };
        insert zAccounts;
    }

    @IsTest
    static void testBatchUpdateFailure() {
        System.assertEquals(0, [SELECT Id FROM Error_Log__c WHERE Severity__c = :Logger.ERROR].size(),
            'Should start with no error logs');
        List<Lead> leads = [
            SELECT Id
            FROM Lead
        ];
        Test.startTest();
        for (Lead lead : leads) {
            lead.Company = null;
        }
        Database.executeBatch(new GenericBatchDMLOperation(leads, 'Update'));
        Test.stopTest();
        List<Error_Log__c> errorLogs = [
            SELECT Id, Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size(),
            'Should have gotten one error log about a failure, but got: ' + JSON.serialize(errorLogs));
    }

    @IsTest
    static void testBatchInsertFailures() {
        List<Lead> leadList = new List<Lead>();
        Lead lead = new Lead(FirstName = 'Test',
            LastName = 'Tester');
        leadList.add(lead);
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());
        Test.startTest();
        Database.executeBatch(new GenericBatchDMLOperation(leadList, 'Insert'));
        Test.stopTest();
        errorLogs = [SELECT Id FROM Error_Log__c WHERE Class__c = 'GenericBatchDMLOperation' AND Severity__c = :Logger.ERROR];
        System.assertEquals(1, errorLogs.size());
    }

    @IsTest
    static void testGenericBatchDMLTriggerOff() {
        List<Error_Log__c> triggerOffWarning = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'BillingAccountTrigger'
            AND Method__c = 'TriggerDisabled'
        ];
        System.assertEquals(0, triggerOffWarning.size());
        List<Zuora__CustomerAccount__c> zAccounts = [
            SELECT Id
            FROM Zuora__CustomerAccount__c
        ];
        for (Zuora__CustomerAccount__c customerAccount : zAccounts) {
            customerAccount.Zuora__AutoPay__c = true;
        }
        Test.startTest();
        GenericBatchDMLOperation batchDML = new GenericBatchDMLOperation(zAccounts, 'Update');
        batchDML.triggersToDisable = new List<String>{
            'Disable_Billing_Account_Trigger__c',
            'Disable_AccountTrigger__c'
        };
        Database.executeBatch(batchDML);
        Test.stopTest();
        List<Zuora__CustomerAccount__c> billingAccounts = [
            SELECT Id, Zuora__AutoPay__c
            FROM Zuora__CustomerAccount__c
            WHERE Id IN :zAccounts
        ];
        System.assertEquals(true, billingAccounts[0].Zuora__AutoPay__c);
        System.assertEquals(true, billingAccounts[0].Zuora__AutoPay__c);
        List<Error_Log__c> updatedTriggerOffWarning = [
            SELECT Id, Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraBillingAccountTrigger'
            AND Method__c = 'TriggerDisabled'
        ];
        System.assertEquals(2, updatedTriggerOffWarning.size(),
            'Expected two errors logged, one before insert and one after insert, but got these: ' + updatedTriggerOffWarning);
    }

    @IsTest
    static void testInvocableGenericBatch() {
        List<Account> acctList = [
            SELECT Id, Name
            FROM Account
            LIMIT 2
        ];
        for (Account acct : acctList) {
            acct.Name = 'SomeUnique AccountNameB';
        }
        Test.startTest();
        List<List<SObject>> sobjList = new List<List<SObject>>{
            acctList
        };
        GenericBatchDMLOperation.callUpdateFromFlow(sobjList);
        Test.stopTest();

        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Name = 'SomeUnique AccountNameB'
        ];
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    private static void testBatchLeadConvert() {
        // Limiting to one lead because InvocableBatchLeadConverter converts one lead
        // at a time, and no more than one executeBatch can be called from within a
        // test method.
        List<Lead> leads = [SELECT Id FROM Lead WHERE IsConverted = FALSE LIMIT 1];
        leads[0].Status = 'Qualified';
        update leads[0];

        Test.startTest();
        InvocableBatchLeadConverter.startLeadConversionBatch(new List<List<Lead>>{
            leads
        });
        Test.stopTest();

        leads = [SELECT Id FROM Lead WHERE Id IN :leads AND IsConverted = TRUE];
        System.assertEquals(1, leads.size());
    }

    @IsTest
    private static void testPostBatchOperation() {
        List<Lead> leads = [
            SELECT Id
            FROM Lead
        ];
        GenericBatchDMLOperation batchDMLOperation = new GenericBatchDMLOperation(leads, 'Delete');
        batchDMLOperation.setPostBatchOperation('PostGLDownloadService');

        UniversalMocker mocker = UniversalMocker.mock(JournalEntrySelector.class);
        ProductionToBillService.journalEntrySelector = (JournalEntrySelector) mocker.createStub();

        Test.startTest();
        Database.executeBatch(batchDMLOperation);
        Test.stopTest();

        // getEntriesWithoutProductionDetail should be called when the PostGLDownloadService runs, via ProductionToBillService
        mocker.assertThat().method('getEntriesWithoutProductionDetail').wasCalled(1, UniversalMocker.Times.EXACTLY);
    }

    @IsTest
    private static void testUpsert() {
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(
            Name = 'Updated Account 222',
            Zuora_Id__c = '222222222222222222222'
        ));
        accounts.add(new Account(
            Name = 'Updated Account 333',
            Zuora_Id__c = '333333333333333333333'
        ));
        GenericBatchDMLOperation batchDMLOperation = new GenericBatchDMLOperation(accounts, 'Upsert');
        batchDMLOperation.externalIdForUpsert = Account.Zuora_Id__c;
        Test.startTest();
        Database.executeBatch(batchDMLOperation);
        Test.stopTest();
        accounts = [
            SELECT Id, Name
            FROM Account
        ];
        for (Account account : accounts) {
            System.assert(account.Name.contains('Updated'), 'Expected account named to be upserted, but got: ' + account.Name);
        }
    }
}