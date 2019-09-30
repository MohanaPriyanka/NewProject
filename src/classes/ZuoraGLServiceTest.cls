@isTest
public class ZuoraGLServiceTest {
    @TestSetup
    public static void testSetup(){
        ZuoraAPIHelperTest.testSetup();
    }

    @IsTest
    private static void testBuildQueryString() {
        ZuoraAPIHelper.setZuoraLive(false);

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
        System.assert(!paymentPartsDMWithDate.contains('createddate'));
        System.assert(!paymentPartsIVWithDate.contains('createddate'));

        // Post Zuora Go Live, should use different dates for payment parts.
        // Going forward, we will report on payments when they are applied:
        // Historical Migration, we reported on transactions when they were made.
        ZuoraAPIHelper.setZuoraLive(true);

        String postGoLiveDM = ZuoraGLSelector.getPaymentPartsDM(startDate, endDate);
        String postGoLiveIV = ZuoraGLSelector.getPaymentPartsIV(startDate, endDate);
        System.assert(postGoLiveDM.contains('createddate'));
        System.assert(postGoLiveIV.contains('createddate'));
        System.assert(!postGoLiveDM.contains('effectiveDate'));
        System.assert(!postGoLiveIV.contains('effectiveDate'));
    }

    @IsTest
    private static void testAllTogether() {
        List<Journal_Entry__c> originalJE = [
            SELECT Id
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'InvoiceItem'
        ];

        Test.startTest();
        Date startDate = Date.newInstance(2016,01,01);
        Date endDate = Date.newInstance(2017,01,01);

        ZuoraGLService.getAllDataFromZuora(startDate, endDate);

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

        ZuoraDataQueryService.MethodToRunAfter methodToRunAfter = new ZuoraDataQueryService.MethodToRunAfter();
        methodToRunAfter.methodName = 'GL_InvoiceItem';

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

        ZuoraDataQueryService.MethodToRunAfter methodToRunAfter = new ZuoraDataQueryService.MethodToRunAfter();
        methodToRunAfter.methodName = 'GL_DebitMemo';

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

        ZuoraDataQueryService.MethodToRunAfter methodToRunAfter = new ZuoraDataQueryService.MethodToRunAfter();
        methodToRunAfter.methodName = 'GL_CreditMemo';

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
        List<Journal_Entry__c> originalJE = [
            SELECT Id
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'PaymentPart'
        ];

        ZuoraDataQueryService.DataQueryResult result = new ZuoraDataQueryService.DataQueryResult();
        ZuoraDataQueryService.DataQueryData dataResult = new ZuoraDataQueryService.DataQueryData();
        dataResult.Id = '7742a20c-18ea-4fde-b185-4aed364ce22c';
        result.data = dataResult;

        ZuoraDataQueryService.MethodToRunAfter methodToRunAfter = new ZuoraDataQueryService.MethodToRunAfter();
        methodToRunAfter.methodName = 'GL_PaymentPartDM';

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
    }
}