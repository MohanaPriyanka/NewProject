@IsTest
public with sharing class ZuoraBillingAccountServiceTest {
    @TestSetup public static void testSetup() {
        ZuoraAPIHelperTest.testSetup();

        Integer i;
        List<Account> propertyAccountsToInsert = new List<Account>();
        List<Account> parentAccountsToInsert = new List<Account>();
        List<Zuora__CustomerAccount__c> zAccountsToInsert = new List<Zuora__CustomerAccount__c>();
        List<Case> collectionCasesToInsert = new List<Case>();

        for (i = 0; i < 10; i++) {
            Account newSFAccount = new Account(
                Name = 'Parent Account Name' + String.valueOf(i)
            );
            parentAccountsToInsert.add(newSFAccount);
        }
        insert parentAccountsToInsert;



        for (i = 0; i < 10; i++) {
            Account newSFAccount = new Account(
                Name = 'Prop Account Name' + String.valueOf(i),
                Recurring_Billing__c = false,
                Max_Overdue_Due_Date_Zuora__c = Date.newInstance(2017,09,20),
                Parent_Account__c = parentAccountsToInsert[i].Id
            );
            propertyAccountsToInsert.add(newSFAccount);
        }

        Account extraPropAccount1 = new Account(
            Name = 'Prop Account Name11',
            Recurring_Billing__c = false,
            Max_Overdue_Due_Date_Zuora__c = Date.newInstance(2017,09,20),
            Parent_Account__c = parentAccountsToInsert[0].Id
        );

        propertyAccountsToInsert.add(extraPropAccount1);

        Account extraPropAccount2 = new Account(
            Name = 'Prop Account Name12',
            Recurring_Billing__c = false,
            Max_Overdue_Due_Date_Zuora__c = Date.newInstance(2017,09,20),
            Parent_Account__c = parentAccountsToInsert[1].Id
        );

        propertyAccountsToInsert.add(extraPropAccount2);

        insert propertyAccountsToInsert;

        for (i = 0; i < 12; i++) {
            Zuora__CustomerAccount__c newAccount = new Zuora__CustomerAccount__c(
                Name = 'Billing Account Name' + String.valueOf(i),
                Zuora__Account__c = propertyAccountsToInsert[i].Id,
                Zuora__Zuora_Id__c = '2c92c0f86b78f56c016b7b0048' + String.valueOf(i),
                Zuora__AutoPay__c = false,
                Zuora__Balance__c = 500
            );
            zAccountsToInsert.add(newAccount);
        }
        insert zAccountsToInsert;

        for (i = 0; i < 10; i++) {
            Case collectionsCase = (ZuoraBillingAccountService.caseFactory).getCase('Collections');
            collectionsCase.Subject = 'Collections Call: ' + String.valueOf(i);
            collectionsCase.AccountId = parentAccountsToInsert[i].Id;

            collectionCasesToInsert.add(collectionsCase);
        }
        insert collectionCasesToInsert;

    }

    @IsTest public static void testDisableTrigger() {
        List<Account> originalAutopayAccounts = [
            SELECT Id, Recurring_Billing__c
            FROM Account
            WHERE Recurring_Billing__c = TRUE
        ];
        System.assertEquals(0,originalAutopayAccounts.size());

        List<Zuora__CustomerAccount__c> zuoraAccounts = [
            SELECT Id, Zuora__AutoPay__c
            FROM Zuora__CustomerAccount__c
            LIMIT 5
        ];

        for (Zuora__CustomerAccount__c acct : zuoraAccounts){
            acct.Zuora__AutoPay__c = true;
        }

        Test.startTest();
        Util.disableAllTriggers();
        update zuoraAccounts;
        Test.stopTest();

        List<Account> updatedAutopayAccounts = [
            SELECT Id, Recurring_Billing__c
            FROM Account
            WHERE Recurring_Billing__c = TRUE
        ];
        System.assertEquals(0,updatedAutopayAccounts.size());
    }

    @IsTest public static void testAutopayUpdate() {
        List<Account> originalAutopayAccounts = [
            SELECT Id, Recurring_Billing__c
            FROM Account
            WHERE Recurring_Billing__c = TRUE
        ];
        System.assertEquals(0,originalAutopayAccounts.size());

        List<Zuora__CustomerAccount__c> zuoraAccounts = [
            SELECT Id, Zuora__AutoPay__c
            FROM Zuora__CustomerAccount__c
            LIMIT 5
        ];

        for (Zuora__CustomerAccount__c acct : zuoraAccounts){
            acct.Zuora__AutoPay__c = true;
        }

        Test.startTest();
        update zuoraAccounts;
        Test.stopTest();

        List<Account> updatedAutopayAccounts = [
            SELECT Id, Recurring_Billing__c, Autopay_Date_Last_Enrolled__c
            FROM Account
            WHERE Recurring_Billing__c = TRUE
        ];
        System.assertEquals(5,updatedAutopayAccounts.size());
        System.assertEquals(Date.today(),updatedAutopayAccounts[0].Autopay_Date_Last_Enrolled__c);
    }

    @IsTest public static void testDataQuerySubmitted() {
        List<Zuora_Data_Query__c> originalQueries = [
            SELECT Id, Status__c, Output_Rows__c, Data_From_Zuora__c
            FROM Zuora_Data_Query__c
        ];

        System.assertEquals(0,originalQueries.size());

        Test.startTest();
            ZuoraBillingAccountService service = new ZuoraBillingAccountService();
            service.startDaysPastDueUpdate();
        Test.stopTest();

        List<Zuora_Data_Query__c> queries = [
            SELECT Id, Status__c, Output_Rows__c, Data_From_Zuora__c
            FROM Zuora_Data_Query__c
        ];
        System.assertEquals(1,queries.size());
    }

    @IsTest public static void testScheduledJob() {
        List<Zuora_Data_Query__c> originalQueries = [
            SELECT Id, Status__c, Output_Rows__c, Data_From_Zuora__c
            FROM Zuora_Data_Query__c
        ];

        System.assertEquals(0,originalQueries.size());

        Test.startTest();
            ZuoraBillingAccountService scheduledJob = new ZuoraBillingAccountService();
            Datetime dt = Datetime.now();
            String cronExpress = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
            String jobId = System.schedule('DaysPastDueUpdate',cronExpress,scheduledJob);
        Test.stopTest();

        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE Id = : jobId
        ];

        System.assertEquals(dt.minute(), ct.NextFireTime.minute());
        System.assertEquals(dt.hour(), ct.NextFireTime.hour());
        System.assertEquals(dt.day(), ct.NextFireTime.day());
        System.assertEquals(dt.month(), ct.NextFireTime.month());
    }

    @IsTest public static void testSummarizeResult(){
        List<Zuora__CustomerAccount__c> oldAccounts = [
            SELECT Id, Name,
                Zuora__Zuora_Id__c,
                Zuora__AutoPay__c,
                Zuora__Account__r.Id,
                Zuora__Account__r.Recurring_Billing__c,
                Zuora__Account__r.Total_Outstanding_Balance_Merge__c,
                Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c
            FROM Zuora__CustomerAccount__c
            ORDER BY Name
            LIMIT 4
        ];

        Set<Id> accountIdSet = new Set<Id>{
            oldAccounts[0].Id,
            oldAccounts[1].Id,
            oldAccounts[2].Id,
            oldAccounts[3].Id
        };

        String expectedResponse =
            '{"MemoBalance":100.110000,"MemoDueDate":"2016-09-18",' +
            '"LastBillSendDate":"2019-09-20",' +
            '"InvoiceBalance":196.220000,"InvoiceDueDate":"2019-10-20",' +
            '"AccountId":"' + oldAccounts[1].Zuora__Zuora_Id__c + '"}' +
            '{"MemoBalance":120.000000,"MemoDueDate":"2018-07-15",' +
            '"LastBillSendDate":"2019-06-20",' +
            '"InvoiceBalance":100.000000,"InvoiceDueDate":"2018-07-14",' +
            '"AccountId":"' + oldAccounts[2].Zuora__Zuora_Id__c + '"}' +
            '{"MemoBalance":0.030000,"MemoDueDate":"2018-06-15",' +
            '"LastBillSendDate":"2019-05-20",' +
            '"InvoiceBalance":313.250000,"InvoiceDueDate":"2018-06-15",' +
            '"AccountId":"' + oldAccounts[3].Zuora__Zuora_Id__c + '"}';
        expectedResponse = new ZuoraDataQueryAsyncService().convertDataQueryResponseToJSON(expectedResponse);

        Test.startTest();
            ZuoraDataQueryService.ProcessingParameter finishMethod = new ZuoraDataQueryService.ProcessingParameter();
            finishMethod.className = 'ZuoraBillingAccountService';
            finishMethod.methodName = 'updateDaysPastDue';
            finishMethod.recordIds = accountIdSet;
            ZuoraDataQueryService.handlePostQueryJob(expectedResponse,finishMethod);
        Test.stopTest();

        List<Zuora__CustomerAccount__c> updatedAccounts = [
            SELECT Id, Name,
                Zuora__Zuora_Id__c,
                Zuora__AutoPay__c,
                Zuora__Account__r.Id,
                Zuora__Account__r.Recurring_Billing__c,
                Zuora__Account__r.Total_Outstanding_Balance_Merge__c,
                Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c,
                Zuora__Account__r.Last_Bill_Send_Date_New_Charges_Zuora__c
            FROM Zuora__CustomerAccount__c
            WHERE Id IN : accountIdSet
            ORDER BY Name
        ];

        System.assertEquals(oldAccounts[0].Id, updatedAccounts[0].Id);
        System.assertEquals(oldAccounts[1].Id, updatedAccounts[1].Id);
        System.assertEquals(oldAccounts[2].Id, updatedAccounts[2].Id);
        System.assertEquals(oldAccounts[3].Id, updatedAccounts[3].Id);

        System.assertEquals(500, oldAccounts[0].Zuora__Account__r.Total_Outstanding_Balance_Merge__c);
        System.assertEquals(500, oldAccounts[1].Zuora__Account__r.Total_Outstanding_Balance_Merge__c);
        System.assertEquals(500, oldAccounts[2].Zuora__Account__r.Total_Outstanding_Balance_Merge__c);
        System.assertEquals(500, oldAccounts[3].Zuora__Account__r.Total_Outstanding_Balance_Merge__c);



        Date oldDate = Date.newInstance(2017,09,20);

        System.assertEquals(oldDate, oldAccounts[0].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
        System.assertEquals(oldDate, oldAccounts[1].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
        System.assertEquals(oldDate, oldAccounts[2].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
        System.assertEquals(oldDate, oldAccounts[3].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);

        System.assertEquals(null, updatedAccounts[0].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
        System.assertEquals(Date.newInstance(2016,09,18), updatedAccounts[1].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
        System.assertEquals(Date.newInstance(2018,07,14), updatedAccounts[2].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
        System.assertEquals(Date.newInstance(2018,06,15), updatedAccounts[3].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);

        System.assertEquals(null, updatedAccounts[0].Zuora__Account__r.Last_Bill_Send_Date_New_Charges_Zuora__c);
        System.assertEquals(Date.newInstance(2019,09,20), updatedAccounts[1].Zuora__Account__r.Last_Bill_Send_Date_New_Charges_Zuora__c);
        System.assertEquals(Date.newInstance(2019,06,20), updatedAccounts[2].Zuora__Account__r.Last_Bill_Send_Date_New_Charges_Zuora__c);
        System.assertEquals(Date.newInstance(2019,05,20), updatedAccounts[3].Zuora__Account__r.Last_Bill_Send_Date_New_Charges_Zuora__c);
    }

    @IsTest public static void testSummarizeResultWithNullValues(){
        List<Zuora__CustomerAccount__c> oldAccounts = [
            SELECT Id, Name,
                Zuora__Zuora_Id__c,
                Zuora__AutoPay__c,
                Zuora__Account__r.Id,
                Zuora__Account__r.Recurring_Billing__c,
                Zuora__Account__r.Total_Outstanding_Balance_Merge__c,
                Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c
            FROM Zuora__CustomerAccount__c
            ORDER BY Name
            LIMIT 4
        ];

        Set<Id> accountIdSet = new Set<Id>{
            oldAccounts[0].Id,
            oldAccounts[1].Id,
            oldAccounts[2].Id,
            oldAccounts[3].Id
        };

        String expectedResponse =
            '{"MemoBalance":null,"MemoDueDate":null,' +
                '"InvoiceBalance":196.220000,"InvoiceDueDate":"2019-10-20",' +
                '"AccountId":"' + oldAccounts[0].Zuora__Zuora_Id__c + '"}' +
                '{"MemoBalance":120.000000,"MemoDueDate":"2018-07-15",' +
                '"InvoiceBalance":null,"InvoiceDueDate":null,' +
                '"AccountId":"' + oldAccounts[1].Zuora__Zuora_Id__c + '"}' +
                '{"MemoBalance":0.000000,"MemoDueDate":null,' +
                '"InvoiceBalance":313.250000,"InvoiceDueDate":"2018-06-15",' +
                '"AccountId":"' + oldAccounts[2].Zuora__Zuora_Id__c + '"}';
        expectedResponse = new ZuoraDataQueryAsyncService().convertDataQueryResponseToJSON(expectedResponse);

        Test.startTest();
            ZuoraDataQueryService.ProcessingParameter finishMethod = new ZuoraDataQueryService.ProcessingParameter();
            finishMethod.className = 'ZuoraBillingAccountService';
            finishMethod.methodName = 'updateDaysPastDue';
            finishMethod.recordIds = accountIdSet;
            ZuoraDataQueryService.handlePostQueryJob(expectedResponse,finishMethod);
        Test.stopTest();

        List<Zuora__CustomerAccount__c> updatedAccounts = [
            SELECT Id, Name,
                Zuora__Zuora_Id__c,
                Zuora__AutoPay__c,
                Zuora__Account__r.Id,
                Zuora__Account__r.Recurring_Billing__c,
                Zuora__Account__r.Total_Outstanding_Balance_Merge__c,
                Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c
            FROM Zuora__CustomerAccount__c
            WHERE Id IN : accountIdSet
            ORDER BY Name
        ];

        List<Error_Log__c> errorLogs = [SELECT Message__c, Severity__c, Class__c, Method__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size(), 'Expected one error log but got these: ' + JSON.serialize(errorLogs));
        System.assert(errorLogs[0].Message__c.contains('Limits: CPU'), 'Expected an Info error log about limits but got these: ' + JSON.serialize(errorLogs));

        System.assertEquals(oldAccounts[0].Id, updatedAccounts[0].Id);
        System.assertEquals(oldAccounts[1].Id, updatedAccounts[1].Id);
        System.assertEquals(oldAccounts[2].Id, updatedAccounts[2].Id);
        System.assertEquals(oldAccounts[3].Id, updatedAccounts[3].Id);

        System.assertEquals(500, oldAccounts[0].Zuora__Account__r.Total_Outstanding_Balance_Merge__c);
        System.assertEquals(500, oldAccounts[1].Zuora__Account__r.Total_Outstanding_Balance_Merge__c);
        System.assertEquals(500, oldAccounts[2].Zuora__Account__r.Total_Outstanding_Balance_Merge__c);
        System.assertEquals(500, oldAccounts[3].Zuora__Account__r.Total_Outstanding_Balance_Merge__c);



        Date oldDate = Date.newInstance(2017,09,20);

        System.assertEquals(oldDate, oldAccounts[0].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
        System.assertEquals(oldDate, oldAccounts[1].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
        System.assertEquals(oldDate, oldAccounts[2].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
        System.assertEquals(oldDate, oldAccounts[3].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);

        System.assertEquals(Date.newInstance(2019,10,20), updatedAccounts[0].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
        System.assertEquals(Date.newInstance(2018,07,15), updatedAccounts[1].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
        System.assertEquals(Date.newInstance(2018,06,15), updatedAccounts[2].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
        System.assertEquals(null, updatedAccounts[3].Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c);
    }

    @IsTest public static void testSetBillingAccount() {
        List<Account> accounts = [
            SELECT Id, Billing_Account__c, (SELECT Id FROM Zuora__R00N40000001kyLcEAI__r) FROM Account WHERE Parent_Account__c != NULL
        ];
        System.assertEquals(12, accounts.size(), 'Expected 12 accounts inserted by test setup');
        for (Account account : accounts) {
            System.assertEquals(1, account.Zuora__R00N40000001kyLcEAI__r.size(), 'Expected one billing account for each account');
            System.assertEquals(account.Zuora__R00N40000001kyLcEAI__r[0].Id, account.Billing_Account__c, 'Expected Billing Account on Account to be set');
        }
    }

    @IsTest private static void testDaysPastDueCases() {
        Util.mockDML = true;
        ZuoraBillingAccountService billingAccountService = new ZuoraBillingAccountService();
        ZuoraBillingAccountService.BalanceQueryResult queryResult = new ZuoraBillingAccountService.BalanceQueryResult();
        List<ZuoraBillingAccountService.BalanceQueryResult> queryResults = new List<ZuoraBillingAccountService.BalanceQueryResult>{queryResult};

        queryResult.InvoiceBalance = 100;
        queryResult.InvoiceDueDate = System.today()+30;
        queryResult.AccountId = '000001';
        ZuoraBillingAccountService.zuoraAcctSelector =
            (ZuoraAccountSelector) Test.createStub(ZuoraAccountSelector.class, new MockZuoraAccountSelector('000001', 67, Util.getFakeId(Account.SObjectType)));
        ZuoraBillingAccountService.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Case.SObjectType}, new FFLibHelperTest.MockDML());
        billingAccountService.updateDaysPastDue(JSON.serialize(queryResults));
        System.assertEquals(1, FFLibHelperTest.getRegisterNewListFromUnitOfWork(ZuoraBillingAccountService.uow, 'Case').size(),
            'Expected a case for a 67 days past due account that now only has outstanding items due in the future');

        queryResult.InvoiceBalance = 100;
        queryResult.InvoiceDueDate = System.today();
        queryResult.AccountId = '000001';
        ZuoraBillingAccountService.zuoraAcctSelector =
            (ZuoraAccountSelector) Test.createStub(ZuoraAccountSelector.class, new MockZuoraAccountSelector('000001', 67, Util.getFakeId(Account.SObjectType)));
        ZuoraBillingAccountService.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Case.SObjectType}, new FFLibHelperTest.MockDML());
        billingAccountService.updateDaysPastDue(JSON.serialize(queryResults));
        System.assertEquals(1, FFLibHelperTest.getRegisterNewListFromUnitOfWork(ZuoraBillingAccountService.uow, 'Case').size(),
            'Expected a case for a 67 days past due account that now only has outstanding items due today');

        queryResult.InvoiceBalance = 100;
        queryResult.InvoiceDueDate = System.today()-1;
        queryResult.AccountId = '000001';
        ZuoraBillingAccountService.zuoraAcctSelector =
            (ZuoraAccountSelector) Test.createStub(ZuoraAccountSelector.class, new MockZuoraAccountSelector('000001', 67, Util.getFakeId(Account.SObjectType)));
        ZuoraBillingAccountService.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Case.SObjectType}, new FFLibHelperTest.MockDML());
        billingAccountService.updateDaysPastDue(JSON.serialize(queryResults));
        System.assertEquals(0, FFLibHelperTest.getRegisterNewListFromUnitOfWork(ZuoraBillingAccountService.uow, 'Case').size(),
            'Did not expect a case for a 67 days past due account that still has an overdue item');

        queryResult.InvoiceBalance = 100;
        queryResult.InvoiceDueDate = System.today();
        queryResult.AccountId = '000001';
        ZuoraBillingAccountService.zuoraAcctSelector =
            (ZuoraAccountSelector) Test.createStub(ZuoraAccountSelector.class, new MockZuoraAccountSelector('000001', 91, Util.getFakeId(Account.SObjectType)));
        ZuoraBillingAccountService.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Case.SObjectType}, new FFLibHelperTest.MockDML());
        billingAccountService.updateDaysPastDue(JSON.serialize(queryResults));
        System.assertEquals(0, FFLibHelperTest.getRegisterNewListFromUnitOfWork(ZuoraBillingAccountService.uow, 'Case').size(),
            'Did not expect a case for a 91 days past due account that is fully paid');

        queryResult.AccountId = '000002';
        ZuoraBillingAccountService.zuoraAcctSelector =
            (ZuoraAccountSelector) Test.createStub(ZuoraAccountSelector.class, new MockZuoraAccountSelector('000001', 91, Util.getFakeId(Account.SObjectType)));
        ZuoraBillingAccountService.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Case.SObjectType}, new FFLibHelperTest.MockDML());
        billingAccountService.updateDaysPastDue(JSON.serialize(queryResults));
        System.assertEquals(0, FFLibHelperTest.getRegisterNewListFromUnitOfWork(ZuoraBillingAccountService.uow, 'Case').size(),
            'Did not expect a case for a 91 days past due account that has no outstanding items');
    }

    @IsTest private static void testUnsetCollections() {
        ZuoraBillingAccountService billingAccountService = new ZuoraBillingAccountService();
        Account propertyAccount = new Account();

        propertyAccount.Max_Overdue_Due_Date_Zuora__c = System.today();
        propertyAccount.Suppress_Collections__c = ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_TEMPORARILY;
        System.assertEquals(
            null,
            billingAccountService.unsetSuppressCollections(propertyAccount).Suppress_Collections__c,
            'A property with an overdue date of today is not overdue, so Suppress Collections should get unset'
        );

        propertyAccount.Max_Overdue_Due_Date_Zuora__c = null;
        propertyAccount.Suppress_Collections__c = ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_TEMPORARILY;
        System.assertEquals(
            null,
            billingAccountService.unsetSuppressCollections(propertyAccount).Suppress_Collections__c,
            'A property with no overdue date has nothing due, so Suppress Collections should get unset'
        );

        propertyAccount.Max_Overdue_Due_Date_Zuora__c = System.today() + 7;
        propertyAccount.Suppress_Collections__c = ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_TEMPORARILY;
        System.assertEquals(
            null,
            billingAccountService.unsetSuppressCollections(propertyAccount).Suppress_Collections__c,
            'A property with an overdue date of next week is not overdue, so Suppress Collections should get unset'
        );

        propertyAccount.Max_Overdue_Due_Date_Zuora__c = System.today() - 7;
        propertyAccount.Suppress_Collections__c = ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_TEMPORARILY;
        System.assertEquals(
            ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_TEMPORARILY,
            billingAccountService.unsetSuppressCollections(propertyAccount).Suppress_Collections__c,
            'A property with an overdue date of last week is overdue, so Suppress Collections should stay set'
        );

        propertyAccount.Max_Overdue_Due_Date_Zuora__c = System.today();
        propertyAccount.Suppress_Collections__c = ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_PERMANENTLY;
        System.assertEquals(
            ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_PERMANENTLY,
            billingAccountService.unsetSuppressCollections(propertyAccount).Suppress_Collections__c,
            'A property with an overdue date of today is not overdue, but Suppress Collections Permanently should stay set'
        );

        propertyAccount.Max_Overdue_Due_Date_Zuora__c = null;
        propertyAccount.Suppress_Collections__c = ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_PERMANENTLY;
        System.assertEquals(
            ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_PERMANENTLY,
            billingAccountService.unsetSuppressCollections(propertyAccount).Suppress_Collections__c,
            'A property with no overdue date has nothing due, but Suppress Collections Permanently should stay set'
        );

        propertyAccount.Max_Overdue_Due_Date_Zuora__c = System.today() + 7;
        propertyAccount.Suppress_Collections__c = ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_PERMANENTLY;
        System.assertEquals(
            ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_PERMANENTLY,
            billingAccountService.unsetSuppressCollections(propertyAccount).Suppress_Collections__c,
            'A property with an overdue date of next week is not overdue, but Suppress Collections Permanently should stay set'
        );

        propertyAccount.Max_Overdue_Due_Date_Zuora__c = System.today() - 7;
        propertyAccount.Suppress_Collections__c = ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_PERMANENTLY;
        System.assertEquals(
            ZuoraBillingAccountService.SUPPRESS_COLLECTIONS_PERMANENTLY,
            billingAccountService.unsetSuppressCollections(propertyAccount).Suppress_Collections__c,
            'A property with an overdue date of last week is overdue, so Suppress Collections Permanently should stay set'
        );
    }

    @IsTest public static void testCollectionsCaseClosedMultiProp(){
        Set<Id> parentAccountIds = new Set<Id>();

        List<Zuora__CustomerAccount__c> oldAccounts = [
            SELECT Id, Name,
                Zuora__Zuora_Id__c, Zuora__Account__r.Parent_Account__c
            FROM Zuora__CustomerAccount__c
            ORDER BY Id
            LIMIT 12
        ];

        for (Zuora__CustomerAccount__c acc : oldAccounts) {
            parentAccountIds.add(acc.Zuora__Account__r.Parent_Account__c);
        }

        List<Account> parentAccounts = [SELECT Id, Name, (SELECT Id, Status, Type, Resolution__c FROM Cases) FROM Account WHERE Id IN :parentAccountIds ORDER BY Name];

        for (Account account : parentAccounts) {
            System.assertEquals(1, account.Cases.size(), 'Expected one case for each account');
            System.assertEquals('New', account.Cases[0].Status, 'Expected case to be open');
            System.assertEquals('Collections', account.Cases[0].Type, 'Expected case type to be collections');
        }

        Set<Id> accountIdSet = new Set<Id>{
            oldAccounts[0].Id,
            oldAccounts[1].Id,
            oldAccounts[2].Id,
            oldAccounts[3].Id,
            oldAccounts[10].Id,
            oldAccounts[11].Id
        };

        String expectedResponse =
            '{"MemoBalance":100.110000,"MemoDueDate":"2016-09-18",' +
                '"LastBillSendDate":"2019-09-20",' +
                '"InvoiceBalance":196.220000,"InvoiceDueDate":"2019-10-20",' +
                '"AccountId":"' + oldAccounts[2].Zuora__Zuora_Id__c + '"}' +
                '{"MemoBalance":120.000000,"MemoDueDate":"2018-07-15",' +
                '"LastBillSendDate":"2019-06-20",' +
                '"InvoiceBalance":100.000000,"InvoiceDueDate":"2018-07-14",' +
                '"AccountId":"' + oldAccounts[10].Zuora__Zuora_Id__c + '"}';
        expectedResponse = new ZuoraDataQueryAsyncService().convertDataQueryResponseToJSON(expectedResponse);

        Test.startTest();
        ZuoraDataQueryService.ProcessingParameter finishMethod = new ZuoraDataQueryService.ProcessingParameter();
        finishMethod.className = 'ZuoraBillingAccountService';
        finishMethod.methodName = 'updateDaysPastDue';
        finishMethod.recordIds = accountIdSet;
        ZuoraDataQueryService.handlePostQueryJob(expectedResponse,finishMethod);
        Test.stopTest();

        List<Account> updatedParentAccounts = [SELECT Id, Name, (SELECT Id, Status, Resolution__c FROM Cases), (SELECT Id, Name, Max_Overdue_Due_Date_Merge__c, Total_Outstanding_Balance_Merge__c FROM Accounts__r ORDER BY Name) FROM Account WHERE Id IN :parentAccountIds ORDER BY Id];

        List<Case> parentAccount0Cases = updatedParentAccounts[0].Cases;
        List<Account> parentAccount0PropAcc = updatedParentAccounts[0].Accounts__r;

        System.assertEquals(2, parentAccount0PropAcc.size(), 'Expected two child property accounts');
        System.assertEquals(null, parentAccount0PropAcc[0].Max_Overdue_Due_Date_Merge__c, 'Expected child property account to have no overdue date');
        System.assertNotEquals(null, parentAccount0PropAcc[1].Max_Overdue_Due_Date_Merge__c, 'Expected child property account to have an overdue date');
        System.assert(parentAccount0PropAcc[1].Total_Outstanding_Balance_Merge__c > 1, 'Expected child property account to have a balance');
        System.assertEquals(1, parentAccount0Cases.size(), 'Expected 1 case');
        System.assertEquals('New', parentAccount0Cases[0].Status, 'Expected case to still be open because one child prop is still overdue');


        List<Case> parentAccount1Cases = updatedParentAccounts[1].Cases;
        List<Account> parentAccount1PropAcc = updatedParentAccounts[1].Accounts__r;

        System.assertEquals(2, parentAccount1PropAcc.size(), 'Expected two child property accounts');
        System.assertEquals(null, parentAccount1PropAcc[0].Max_Overdue_Due_Date_Merge__c, 'Expected child property account to have no overdue date');
        System.assertEquals(null, parentAccount1PropAcc[1].Max_Overdue_Due_Date_Merge__c, 'Expected child property account to have no overdue date');
        System.assertEquals(1, parentAccount1Cases.size(), 'Expected 1 case');
        System.assertEquals('Closed', parentAccount1Cases[0].Status, 'Expected case to be closed');
    }

    @IsTest public static void testCollectionsCaseClosedNoChange(){
        Zuora__CustomerAccount__c oldAccount = [
            SELECT Id, Name,
                Zuora__Zuora_Id__c, Zuora__Account__r.Parent_Account__c, Zuora__Balance__c, Zuora__Account__c
            FROM Zuora__CustomerAccount__c
            WHERE Name = 'Billing Account Name3'
            LIMIT 1
        ];

        oldAccount.Zuora__Balance__c = 0;
        update oldAccount;

        Account propAccount = [
            SELECT Id, Name,
                Max_Overdue_Due_Date_Zuora__c, Last_Bill_Send_Date_New_Charges_Zuora__c
            FROM Account
            WHERE Id = :oldAccount.Zuora__Account__c
            LIMIT 1
        ];

        propAccount.Max_Overdue_Due_Date_Zuora__c = Date.newInstance(2099, 09, 18);
        propAccount.Last_Bill_Send_Date_New_Charges_Zuora__c = Date.newInstance(2099, 09, 20);

        update propAccount;

        Account parentAccount = [SELECT Id, Name, (SELECT Id, Status, Type, Resolution__c FROM Cases) FROM Account WHERE Id = :oldAccount.Zuora__Account__r.Parent_Account__c LIMIT 1];

        System.assertEquals(1, parentAccount.Cases.size(), 'Expected one case');
        System.assertEquals('New', parentAccount.Cases[0].Status, 'Expected case to be open');
        System.assertEquals('Collections', parentAccount.Cases[0].Type, 'Expected case type to be collections');

        Set<Id> accountIdSet = new Set<Id>{
            oldAccount.Id
        };

        String expectedResponse = '{"MemoBalance":0.000000,"MemoDueDate":"2099-09-18",' +
            '"LastBillSendDate":"2099-09-20",' +
            '"InvoiceBalance":0.000000,"InvoiceDueDate":"2099-10-20",' +
            '"AccountId":"' + oldAccount.Zuora__Zuora_Id__c + '"}';
        expectedResponse = new ZuoraDataQueryAsyncService().convertDataQueryResponseToJSON(expectedResponse);

        Test.startTest();
        ZuoraDataQueryService.ProcessingParameter finishMethod = new ZuoraDataQueryService.ProcessingParameter();
        finishMethod.className = 'ZuoraBillingAccountService';
        finishMethod.methodName = 'updateDaysPastDue';
        finishMethod.recordIds = accountIdSet;
        ZuoraDataQueryService.handlePostQueryJob(expectedResponse,finishMethod);
        Test.stopTest();

        Account updatedParentAccount = [SELECT Id, Name, (SELECT Id, Status, Resolution__c FROM Cases), (SELECT Id, Name, Days_Past_Due__c, Total_Outstanding_Balance_Merge__c FROM Accounts__r ORDER BY Name) FROM Account WHERE Id = :parentAccount.Id LIMIT 1];
        List<Account> childAccounts = updatedParentAccount.Accounts__r;
        List<Case> childCases = updatedParentAccount.Cases;

        System.assertEquals(1, childAccounts.size(), 'Expected one child property account');
        System.assertEquals(0, childAccounts[0].Days_Past_Due__c, 'Expected 0 days past due');
        System.assertEquals(0, childAccounts[0].Total_Outstanding_Balance_Merge__c, 'Expected no outstanding balance');
        System.assertEquals(1, childCases.size(), 'Expected 1 case');
        System.assertEquals('New', childCases[0].Status, 'Expected case to be open since there was no change to the account');

    }

    private class MockZuoraAccountSelector implements StubProvider {
        private String zuoraId;
        private Integer daysPastDue;
        private String parentAccountId;
        public MockZuoraAccountSelector(String zuoraId, Integer daysPastDue, String parentAccountId) {
            this.zuoraId = zuoraId;
            this.daysPastDue = daysPastDue;
            this.parentAccountId = parentAccountId;
        }
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'getAllBillingAccounts' {
                    return new List<Zuora__CustomerAccount__c>{getCustomerAccount()};
                }
            }
            return null;
        }
        private Zuora__CustomerAccount__c getCustomerAccount() {
            Map<SObjectField, Object> customerAccountValues = new Map<SObjectField, Object> {
                Zuora__CustomerAccount__c.Id => Util.getFakeId(Zuora__CustomerAccount__c.SObjectType),
                Zuora__CustomerAccount__c.Name => 'Joshua Phillips',
                Zuora__CustomerAccount__c.Zuora__Zuora_Id__c => zuoraId,
                Zuora__CustomerAccount__c.Zuora__Autopay__c => false,
                Zuora__CustomerAccount__c.Zuora__Batch__c => 'Batch1',
                Zuora__CustomerAccount__c.Zuora__Account__c => Util.getFakeId(Account.SObjectType)
            };
            Map<SObjectField, Object> propertyAccountValues = new Map<SObjectField, Object> {
                Account.Id => Util.getFakeId(Account.SObjectType),
                Account.Recurring_Billing__c => false,
                Account.Total_Outstanding_Balance_Merge__c => 10,
                Account.Max_Overdue_Due_Date_Zuora__c => System.today()-daysPastDue,
                Account.Last_Bill_Send_Date_New_Charges_Zuora__c => Date.newInstance(2020,5,20),
                Account.Days_Past_Due__c => daysPastDue,
                Account.Parent_Account__c => parentAccountId
            };

            sfab_FabricatedSObject fabricatedCustomerAccount = new sfab_FabricatedSObject(Zuora__CustomerAccount__c.class, customerAccountValues);
            fabricatedCustomerAccount.setParent('Zuora__Account__r', new sfab_FabricatedSObject(Account.class, propertyAccountValues));
            Zuora__CustomerAccount__c customerAccount = (Zuora__CustomerAccount__c) fabricatedCustomerAccount.toSObject();
            return customerAccount;
        }

    }
}