@IsTest
public with sharing class ZuoraBillingAccountServiceTest {
    @TestSetup public static void testSetup() {
        ZuoraAPIHelperTest.testSetup();

        Integer i;
        List<Account> accountsToInsert = new List<Account>();
        List<Zuora__CustomerAccount__c> zAccountsToInsert = new List<Zuora__CustomerAccount__c>();

        for (i = 0; i < 10; i++) {
            Account newSFAccount = new Account(
                Name = 'Account Name' + String.valueOf(i),
                Recurring_Billing__c = false,
                Total_Outstanding_Balance_Zuora__c = 500,
                Max_Overdue_Due_Date_Zuora__c = Date.newInstance(2017,09,20)
            );
            accountsToInsert.add(newSFAccount);
        }
        insert accountsToInsert;

        for (i = 0; i < 10; i++) {
            Zuora__CustomerAccount__c newAccount = new Zuora__CustomerAccount__c(
                Name = 'Account Name',
                Zuora__Account__c = accountsToInsert[i].Id,
                Zuora__Zuora_Id__c = '2c92c0f86b78f56c016b7b0048' + String.valueOf(i),
                Zuora__AutoPay__c = false
            );
            zAccountsToInsert.add(newAccount);
        }
        insert zAccountsToInsert;
    }

    @IsTest public static void testDisableTrigger() {
        List<Account> originalAutopayAccounts = [
            SELECT Id, Recurring_Billing__c
            FROM Account
            WHERE Recurring_Billing__c = true
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
            WHERE Recurring_Billing__c = true
        ];
        System.assertEquals(0,updatedAutopayAccounts.size());
    }

    @IsTest public static void testAutopayUpdate() {
        List<Account> originalAutopayAccounts = [
            SELECT Id, Recurring_Billing__c
            FROM Account
            WHERE Recurring_Billing__c = true
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

        List<Error_Log__c> errors = [SELECT Id, Message__c FROM Error_Log__c];
        system.debug(errors);

        List<Account> updatedAutopayAccounts = [
            SELECT Id, Recurring_Billing__c, Autopay_Date_Last_Enrolled__c
            FROM Account
            WHERE Recurring_Billing__c = true
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

        List<Zuora__CustomerAccount__c> zuoraAccounts = [
            SELECT Id, Name,
                Zuora__Zuora_Id__c,
                Zuora__AutoPay__c,
                Zuora__Account__r.Id,
                Zuora__Account__r.Recurring_Billing__c,
                Zuora__Account__r.Total_Outstanding_Balance_Zuora__c,
                Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c
            FROM Zuora__CustomerAccount__c
        ];
        Set<Id> accountIdSet = new Set<Id>{zuoraAccounts[0].Id, zuoraAccounts[1].Id, zuoraAccounts[2].Id};

        Test.startTest();
            ZuoraBillingAccountService service = new ZuoraBillingAccountService();
            service.startDaysPastDueUpdate(accountIdSet);
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

    @isTest public static void testSummarizeResult(){
        List<Zuora__CustomerAccount__c> oldAccounts = [
            SELECT Id, Name,
                Zuora__Zuora_Id__c,
                Zuora__AutoPay__c,
                Zuora__Account__r.Id,
                Zuora__Account__r.Recurring_Billing__c,
                Zuora__Account__r.Total_Outstanding_Balance_Zuora__c,
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
                Zuora__Account__r.Total_Outstanding_Balance_Zuora__c,
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

        System.assertEquals(500, oldAccounts[0].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);
        System.assertEquals(500, oldAccounts[1].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);
        System.assertEquals(500, oldAccounts[2].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);
        System.assertEquals(500, oldAccounts[3].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);

        System.assertEquals(0, updatedAccounts[0].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);
        System.assertEquals(296.33, updatedAccounts[1].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);
        System.assertEquals(220.00, updatedAccounts[2].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);
        System.assertEquals(313.28, updatedAccounts[3].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);

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

    @isTest public static void testSummarizeResultWithNullValues(){
        List<Zuora__CustomerAccount__c> oldAccounts = [
            SELECT Id, Name,
                Zuora__Zuora_Id__c,
                Zuora__AutoPay__c,
                Zuora__Account__r.Id,
                Zuora__Account__r.Recurring_Billing__c,
                Zuora__Account__r.Total_Outstanding_Balance_Zuora__c,
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
                Zuora__Account__r.Total_Outstanding_Balance_Zuora__c,
                Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c
            FROM Zuora__CustomerAccount__c
            WHERE Id IN : accountIdSet
            ORDER BY Name
        ];

        System.assertEquals(oldAccounts[0].Id, updatedAccounts[0].Id);
        System.assertEquals(oldAccounts[1].Id, updatedAccounts[1].Id);
        System.assertEquals(oldAccounts[2].Id, updatedAccounts[2].Id);
        System.assertEquals(oldAccounts[3].Id, updatedAccounts[3].Id);

        System.assertEquals(500, oldAccounts[0].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);
        System.assertEquals(500, oldAccounts[1].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);
        System.assertEquals(500, oldAccounts[2].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);
        System.assertEquals(500, oldAccounts[3].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);

        System.assertEquals(196.22, updatedAccounts[0].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);
        System.assertEquals(120, updatedAccounts[1].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);
        System.assertEquals(313.25, updatedAccounts[2].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);
        System.assertEquals(0, updatedAccounts[3].Zuora__Account__r.Total_Outstanding_Balance_Zuora__c);

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
}