@isTest
public class ZuoraGLServiceTest {
    @TestSetup
    public static void testSetup(){
        ZuoraAPIHelperTest.testSetup();
        GatewaySelectorTest.testDataSetup();
    }

    @IsTest
    private static void testBuildQueryString() {
        Date startDate = Date.newInstance(2019,03,12);
        Date endDate = Date.newInstance(2019,04,12);

        String invoiceItemsWithDate = ZuoraGLSelector.getInvoiceItems(startDate, endDate);
        String creditMemosWithDate = ZuoraGLSelector.getCreditMemos(startDate, endDate);
        String debitMemosWithDate = ZuoraGLSelector.getDebitMemos(startDate, endDate);
        String paymentPartsDMWithDate = ZuoraGLSelector.getPaymentPartsDM(startDate, endDate);
        String paymentPartsIVWithDate = ZuoraGLSelector.getPaymentPartsIV(startDate, endDate);

        System.assert(invoiceItemsWithDate.length() > 25);
        System.assert(creditMemosWithDate.length() > 25);
        System.assert(debitMemosWithDate.length() > 25);
        System.assert(paymentPartsDMWithDate.length() > 25);
        System.assert(paymentPartsIVWithDate.length() > 25);

        String invoiceItemsNullDate = ZuoraGLSelector.getInvoiceItems(null, null);
        String creditMemosNullDate = ZuoraGLSelector.getCreditMemos(null, null);
        String debitMemosNullDate = ZuoraGLSelector.getDebitMemos(null, null);
        String paymentPartsDMNullDate = ZuoraGLSelector.getPaymentPartsDM(null, null);
        String paymentPartsIVNullDate = ZuoraGLSelector.getPaymentPartsIV(null, null);

        System.assert(invoiceItemsNullDate.length() > 25);
        System.assert(creditMemosNullDate.length() > 25);
        System.assert(debitMemosNullDate.length() > 25);
        System.assert(paymentPartsDMNullDate.length() > 25);
        System.assert(paymentPartsIVNullDate.length() > 25);

        System.assert(invoiceItemsWithDate.contains('TIMESTAMP'));
        System.assert(!invoiceItemsNullDate.contains('TIMESTAMP'));

        System.assert(paymentPartsDMWithDate.contains('effectiveDate'));
        System.assert(paymentPartsIVWithDate.contains('effectiveDate'));
        System.assert(paymentPartsDMWithDate.contains('createddate'));
        System.assert(paymentPartsIVWithDate.contains('createddate'));
    }

    @IsTest
    private static void testCallTogether() {
        List<Zuora_Data_Query__c> originalDataQueries = [
            SELECT Id
            FROM Zuora_Data_Query__c
        ];

        Test.startTest();
        Date startDate = Date.newInstance(2016,01,01);
        Date endDate = Date.newInstance(2017,01,01);
        ZuoraGLService.getAllDataFromZuora(startDate, endDate);
        Test.stopTest();

        List<Zuora_Data_Query__c> dataQueriesQueued = [
            SELECT Id
            FROM Zuora_Data_Query__c
        ];

        System.assertEquals(0,originalDataQueries.size());
        System.assertEquals(1,dataQueriesQueued.size());
    }

    @IsTest
    private static void testSchedule() {
        test.startTest();
        ZuoraGLService scheduledJob = new ZuoraGLService();
        scheduledJob.daysToLookBack = 5;
        Datetime dt = Datetime.now();
        String cronExpress = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
        String jobId = System.schedule('ZuoraGLQuery',cronExpress,scheduledJob);
        test.stopTest();

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

    @IsTest
    private static void testInvoiceInsert() {
        List<Journal_Entry__c> originalJE = [
            SELECT Id
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'InvoiceItem'
        ];

        ZuoraDataQueryService.DataQueryResult result = new ZuoraDataQueryService.DataQueryResult();
        ZuoraDataQueryService.DataQueryData dataResult = new ZuoraDataQueryService.DataQueryData();
        dataResult.Id = '7742a20c-18ea-4fde-b185-4aed364ce22c';
        result.data = dataResult;

        ZuoraDataQueryService.ProcessingParameter methodToRunAfter = new ZuoraDataQueryService.ProcessingParameter();
        methodToRunAfter.className = 'ZuoraGLService';
        methodToRunAfter.methodName = 'InvoiceItem';
        methodToRunAfter.periodCloseDate = Date.newInstance(2016,01,01);

        ZuoraDataQueryService.DataQueryRequest queryRequest = new ZuoraDataQueryService.DataQueryRequest();
        queryRequest.queryString = null;
        queryRequest.numberOfRetries = 0;
        queryRequest.recordId = null;
        queryRequest.method = methodToRunAfter;

        Test.startTest();
        ZuoraDataQueryAsyncService.queueCheckDataQueryStatus(result, queryRequest);
        Test.stopTest();

        List<Journal_Entry__c> updatedJE = [
            SELECT Id, Date__c, Client__c, Project__c, Customer_Account__c,
                Amount__c, External_Id__c
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'InvoiceItem'
            ORDER BY Date__c
        ];

        System.assertEquals(0,originalJE.size());
        System.assertEquals(14,updatedJE.size());

        System.assertEquals(Date.newInstance(2018,12,01),updatedJE[0].Date__c);
        System.assertEquals('BW-0011514',updatedJE[1].Client__c);
        System.assertEquals('SSS-000019',updatedJE[2].Project__c);
        System.assertEquals('BW-0013285',updatedJE[3].Customer_Account__c);
        System.assertEquals(33.89,updatedJE[4].Amount__c);
        System.assertEquals('2c92c0fa6c8aee24016c929406a2570f',updatedJE[5].External_Id__c);
    }

    @IsTest
    private static void testDebitMemoInsert() {
        List<Journal_Entry__c> originalJE = [
            SELECT Id
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'DebitMemo'
        ];

        ZuoraDataQueryService.DataQueryResult result = new ZuoraDataQueryService.DataQueryResult();
        ZuoraDataQueryService.DataQueryData dataResult = new ZuoraDataQueryService.DataQueryData();
        dataResult.Id = '7742a20c-18ea-4fde-b185-4aed364ce22c';
        result.data = dataResult;

        ZuoraDataQueryService.ProcessingParameter methodToRunAfter = new ZuoraDataQueryService.ProcessingParameter();
        methodToRunAfter.className = 'ZuoraGLService';
        methodToRunAfter.methodName = 'DebitMemo';
        methodToRunAfter.periodCloseDate = Date.newInstance(2016,01,01);

        ZuoraDataQueryService.DataQueryRequest queryRequest = new ZuoraDataQueryService.DataQueryRequest();
        queryRequest.queryString = null;
        queryRequest.numberOfRetries = 0;
        queryRequest.recordId = null;
        queryRequest.method = methodToRunAfter;

        Test.startTest();
        ZuoraDataQueryAsyncService.queueCheckDataQueryStatus(result, queryRequest);
        Test.stopTest();

        List<Journal_Entry__c> updatedJE = [
            SELECT Id
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'DebitMemo'
        ];

        System.assertEquals(0,originalJE.size());
        System.assertEquals(14,updatedJE.size());
    }

    @IsTest
    private static void testCreditMemoInsert() {
        List<Journal_Entry__c> originalJE = [
            SELECT Id
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'CreditMemo'
        ];

        ZuoraDataQueryService.DataQueryResult result = new ZuoraDataQueryService.DataQueryResult();
        ZuoraDataQueryService.DataQueryData dataResult = new ZuoraDataQueryService.DataQueryData();
        dataResult.Id = '7742a20c-18ea-4fde-b185-4aed364ce22c';
        result.data = dataResult;

        ZuoraDataQueryService.ProcessingParameter methodToRunAfter = new ZuoraDataQueryService.ProcessingParameter();
        methodToRunAfter.className = 'ZuoraGLService';
        methodToRunAfter.methodName = 'CreditMemo';
        methodToRunAfter.periodCloseDate = Date.newInstance(2016,01,01);

        ZuoraDataQueryService.DataQueryRequest queryRequest = new ZuoraDataQueryService.DataQueryRequest();
        queryRequest.queryString = null;
        queryRequest.numberOfRetries = 0;
        queryRequest.recordId = null;
        queryRequest.method = methodToRunAfter;

        Test.startTest();
        ZuoraDataQueryAsyncService.queueCheckDataQueryStatus(result, queryRequest);
        Test.stopTest();

        List<Journal_Entry__c> updatedJE = [
            SELECT Id
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'CreditMemo'
        ];

        System.assertEquals(0,originalJE.size());
        System.assertEquals(14,updatedJE.size());
    }

    @IsTest
    private static void testPaymentPartInsert() {
        Account bluewaveAccount = [
            SELECT Id, Account_Number__c
            FROM Account
            WHERE Name = 'BlueWave'
            LIMIT 1
        ];

        List<Journal_Entry__c> originalJE = [
            SELECT Id
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'PaymentPart'
        ];

        ZuoraDataQueryService.DataQueryResult result = new ZuoraDataQueryService.DataQueryResult();
        ZuoraDataQueryService.DataQueryData dataResult = new ZuoraDataQueryService.DataQueryData();
        dataResult.Id = '7742a20c-18ea-4fde-b185-4aed364ce22c';
        result.data = dataResult;

        ZuoraDataQueryService.ProcessingParameter methodToRunAfter = new ZuoraDataQueryService.ProcessingParameter();
        methodToRunAfter.className = 'ZuoraGLService';
        methodToRunAfter.methodName = 'PaymentPart_DM';
        methodToRunAfter.periodCloseDate = Date.newInstance(2016,01,01);

        ZuoraDataQueryService.DataQueryRequest queryRequest = new ZuoraDataQueryService.DataQueryRequest();
        queryRequest.queryString = null;
        queryRequest.numberOfRetries = 0;
        queryRequest.recordId = null;
        queryRequest.method = methodToRunAfter;

        Test.startTest();
        ZuoraDataQueryAsyncService.queueCheckDataQueryStatus(result, queryRequest);
        Test.stopTest();

        List<Journal_Entry__c> updatedJE = [
            SELECT Id
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'PaymentPart'
        ];

        System.assertEquals(0,originalJE.size());
        System.assertEquals(14,updatedJE.size());

        List<Journal_Entry__c> checkGoLiveSwitch = [
            SELECT Id, Date__c, External_Id__c, Deposit_Account__c, Paid_To_Client__c
            FROM Journal_Entry__c
            WHERE External_Id__c = '2c92c0fa6c8aee37016c928a815955c0'
            OR External_Id__c = '2c92c0fb6c8afb4e016c926615190872'
            OR External_Id__c = '2c92c0fb6c8afb4e016c926615190873'
            OR External_Id__c = '2c92c0fb6c8afb4e016c926615190874'
            ORDER BY External_Id__c
        ];

        // Post Zuora Go Live, should use different dates for payment parts.
        // Going forward, we will report on payments when they are applied:
        // Historical Migration, we reported on transactions when they were made.

        // Historical Migration, get gateway from ArchivedChargentData:
        System.assertEquals('2c92c0fa6c8aee37016c928a815955c0',checkGoLiveSwitch[0].External_Id__c);
        System.assertEquals(Date.newInstance(2019,05,01),checkGoLiveSwitch[0].Date__c);
        System.assertEquals('Lake Waconia',checkGoLiveSwitch[0].Deposit_Account__c);
        System.assertEquals('BW-00222',checkGoLiveSwitch[0].Paid_To_Client__c);

        // Post Go Live & Electronic Gateway:
        System.assertEquals('2c92c0fb6c8afb4e016c926615190872',checkGoLiveSwitch[1].External_Id__c);
        System.assertEquals(Date.newInstance(2019,10,01),checkGoLiveSwitch[1].Date__c);
        System.assertEquals('BCS Single Gateway',checkGoLiveSwitch[1].Deposit_Account__c);
        System.assertEquals(bluewaveAccount.Account_Number__c,checkGoLiveSwitch[1].Paid_To_Client__c);
        System.assertNotEquals(null,checkGoLiveSwitch[1].Paid_To_Client__c);

        // Post Go Live & BW Lockbox:
        System.assertEquals('2c92c0fb6c8afb4e016c926615190873',checkGoLiveSwitch[2].External_Id__c);
        System.assertEquals('AMPLockbox',checkGoLiveSwitch[2].Deposit_Account__c);
        System.assertEquals('BW-0000333',checkGoLiveSwitch[2].Paid_To_Client__c);

        // Post Go Live & AMP Lockbox:
        System.assertEquals('2c92c0fb6c8afb4e016c926615190874',checkGoLiveSwitch[3].External_Id__c);
        System.assertEquals('BWTrust',checkGoLiveSwitch[3].Deposit_Account__c);
        System.assertEquals('BW-0000111',checkGoLiveSwitch[3].Paid_To_Client__c);
    }

    @IsTest
    private static void testUpdateCreditMemoInClosedAccountingPeriod(){
        Journal_Entry__c attemptedDelete = new Journal_Entry__c();
        attemptedDelete.Amount__c = 10;
        attemptedDelete.Date__c = Date.newInstance(2019,10,12);
        attemptedDelete.Project__c = 'SSS-ValueAlreadyInSF';
        attemptedDelete.Client__c = 'BW-ValueAlreadyInSF';
        attemptedDelete.Customer_Account__c = 'BW-ValueAlreadyInSF';
        attemptedDelete.Paid_To_Client__c = 'BW-ValueAlreadyInSF';
        attemptedDelete.Deposit_Account__c = 'BW_Trust';
        attemptedDelete.Object_Type__c = 'CreditMemo';
        attemptedDelete.Query_Type__c = 'CreditMemo';
        attemptedDelete.External_Id__c = '2c92c0fb6c8afb4e016c926615190811';

        Journal_Entry__c entryInClosedPeriod = new Journal_Entry__c();
        entryInClosedPeriod.Amount__c = 10;
        entryInClosedPeriod.Date__c = Date.newInstance(2019,10,31);
        entryInClosedPeriod.Project__c = 'SSS-ValueAlreadyInSF';
        entryInClosedPeriod.Client__c = 'BW-ValueAlreadyInSF';
        entryInClosedPeriod.Customer_Account__c = 'BW-ValueAlreadyInSF';
        entryInClosedPeriod.Paid_To_Client__c = 'BW-ValueAlreadyInSF';
        entryInClosedPeriod.Deposit_Account__c = 'BW_Trust';
        entryInClosedPeriod.Object_Type__c = 'CreditMemo';
        entryInClosedPeriod.Query_Type__c = 'CreditMemo';
        entryInClosedPeriod.External_Id__c = '2c92c0fb6c8afb4e016c926615190873';

        Journal_Entry__c entryInOpenPeriod = new Journal_Entry__c();
        entryInOpenPeriod.Amount__c = 10;
        entryInOpenPeriod.Date__c = Date.newInstance(2019,11,07);
        entryInOpenPeriod.Project__c = 'SSS-ValueAlreadyInSF';
        entryInOpenPeriod.Client__c = 'BW-ValueAlreadyInSF';
        entryInOpenPeriod.Customer_Account__c = 'BW-ValueAlreadyInSF';
        entryInOpenPeriod.Paid_To_Client__c = 'BW-ValueAlreadyInSF';
        entryInOpenPeriod.Deposit_Account__c = 'BW_Trust';
        entryInOpenPeriod.Object_Type__c = 'CreditMemo';
        entryInOpenPeriod.Query_Type__c = 'CreditMemo';
        entryInOpenPeriod.External_Id__c = '2c92c0fb6c8afb4e016c926615190874';

        insert new List<Journal_Entry__c>{attemptedDelete, entryInOpenPeriod, entryInClosedPeriod};

        List<Case> originalRecItems = [
            SELECT Id, Subject, Description
            FROM Case
            WHERE Subject LIKE 'Attempted Journal Entry%'
        ];

        List<Journal_Entry__c> originalJE = [
            SELECT Id
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'CreditMemo'
        ];

        ZuoraDataQueryService.ProcessingParameter methodToRunAfter = new ZuoraDataQueryService.ProcessingParameter();
        methodToRunAfter.className = 'ZuoraGLService';
        methodToRunAfter.methodName = 'CreditMemo';

        // Get data from 10/1/19 to 11/30/19, but accounting period up to 10/31/2019 is closed
        methodToRunAfter.startDate = Date.newInstance(2019,10,01);
        methodToRunAfter.endDate = Date.newInstance(2019,11,30);
        methodToRunAfter.periodCloseDate = Date.newInstance(2019,10,31);

        // Data Query Returns 4 Records = 2 from closed period, 1 to insert, 1 to update:
        String dataQueryMock = '[' +
            '{"Project":"SSS-000087","Client":"BW-0011514","GLDate":"2019-11-10", "GLDatetime":null, ' +
            '"CRMId":null, "CustomerAccount":"bw-00803","Amount":19.100000, "Gateway":"BCS Single Gateway", ' +
            '"AccountId":"2c92c0f86c858923016c872551192523", ' +
            '"ExternalId":"2c92c0fb6c8afb33016c928738435224"},' +
            ' {"Project":"SSS-000070","Client":"BW-0011514","GLDate":"2019-10-02", "GLDatetime":"2019-11-18T20:49:26-04:00", ' +
            '"CRMId":null, "CustomerAccount":"BW-0013262","Amount":34.000000, "Gateway":"BCS Single Gateway", ' +
            '"AccountId":"2c92c0f86c858922016c871893cd7504", ' +
            '"ExternalId":"2c92c0fb6c8afb4e016c926615190872"}, ' +
            '{"Project":"SSS-000071","Client":"BW-0011514","GLDate":"2019-10-31", "GLDatetime":null, "CRMId":null, ' +
            '"CustomerAccount":"BW-0012690","Amount":33.890000, "Lockbox":"AMPLockbox_BW-0000333", ' +
            '"AccountId":"2c92c0f96c8596ce016c8717ebc26323", ' +
            '"ExternalId":"2c92c0fb6c8afb4e016c926615190873"}, ' +
            '{"Project":"SSS-000068","Client":"BW-0011514","GLDate":"2019-11-07", "GLDatetime":null, "CRMId":null,' +
            ' "CustomerAccount":"BW-0013802","Amount":22.470000, "Lockbox":"BWTrust_BW-0000111",' +
            ' "AccountId":"2c92c0f96c8596ce016c87194923685d", ' +
            '"ExternalId":"2c92c0fb6c8afb4e016c926615190874"}]';

        Test.startTest();
        ZuoraGLService service = new ZuoraGLService();
        service.generalGLRecordInsert(dataQueryMock, methodToRunAfter);
        Test.stopTest();

        List<Journal_Entry__c> updatedJE = [
            SELECT Id, External_Id__c, Customer_Account__c
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'CreditMemo'
        ];

        System.assertEquals(3,originalJE.size());
        System.assertEquals(4,updatedJE.size());

        Integer countOfChecks = 0;
        for (Journal_Entry__c entry : updatedJE){
            if (entry.External_Id__c == '2c92c0fb6c8afb4e016c926615190873'
                || entry.External_Id__c == '2c92c0fb6c8afb4e016c926615190811'){
                // Period is closed, so customer account should NOT change:
                system.debug(entry.External_Id__c);
                System.assertEquals('BW-ValueAlreadyInSF',entry.Customer_Account__c);
                countOfChecks += 1;
            } else if (entry.External_Id__c == '2c92c0fb6c8afb4e016c926615190874'){
                // Period is NOT closed, so customer account SHOULD change:
                System.assertNotEquals('BW-ValueAlreadyInSF',entry.Customer_Account__c);
                countOfChecks += 1;
            }
        }
        System.assertEquals(3,countOfChecks);

        List<Case> recItems = [
            SELECT Id, Subject, Description
            FROM Case
            WHERE Subject LIKE 'Attempted Journal Entry%'
            ORDER BY Subject DESC
        ];

        System.assertEquals(0,originalRecItems.size());
        System.assertEquals(3,recItems.size());

        System.assert(recItems[0].Description.contains('2c92c0fb6c8afb4e016c926615190873'));
        System.assertEquals('Attempted Journal Entry Update in Closed Period',recItems[0].Subject);
        System.assert(recItems[1].Description.contains('2c92c0fb6c8afb4e016c926615190872'));
        System.assertEquals('Attempted Journal Entry Insert in Closed Period',recItems[1].Subject);
        System.assert(recItems[2].Description.contains('2c92c0fb6c8afb4e016c926615190811'));
        System.assertEquals('Attempted Journal Entry Delete in Closed Period',recItems[2].Subject);
    }
}