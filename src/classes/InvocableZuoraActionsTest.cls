@IsTest
public with sharing class InvocableZuoraActionsTest {
    @TestSetup public static void testData() {
        ZuoraBillEmailHandlerTest.setupTestData();
        ZuoraCreditDebitMemoServiceTest.testDataSetup();
        InvoiceTemplateAssignerTest.setupTestData();

        List<Zuora__ZInvoice__c> allInvoices = [
            SELECT Id
            FROM Zuora__ZInvoice__c
        ];
        for (Zuora__ZInvoice__c invoice : allInvoices){
            invoice.Zuora__InvoiceDate__c = Date.newInstance(2019,04,20);
        }
        update allInvoices;
    }

    @IsTest public static void testBillRun() {
        Date invoiceDate = Date.newInstance(2019,02,15);
        List<String> response = InvocableZuoraBillRun.billRun(new List<Date>{invoiceDate});
        System.assert(response[0].contains('{"Success":true'));
    }

    @IsTest public static void testEmailSend() {
        List<Zuora__ZInvoice__c> invoicesToSend = [
            SELECT Id
            FROM Zuora__ZInvoice__c
            WHERE Ready_For_Email_Send__c = true
        ];
        System.assertEquals(5,invoicesToSend.size());

        List<Zuora__ZInvoice__c> doNotSend = [
            SELECT Id
            FROM Zuora__ZInvoice__c
            WHERE Ready_For_Email_Send__c = false
        ];
        System.assertEquals(3,doNotSend.size());

        Test.startTest();
        InvocableZuoraEmailSend.emailSend();
        Test.stopTest();

        List<Zuora__ZInvoice__c> updatedInvoices = [
            SELECT Id
            FROM Zuora__ZInvoice__c
            WHERE Ready_For_Email_Send__c = false
        ];

        System.assertEquals(8,updatedInvoices.size());
    }

    @IsTest public static void testInvoiceDownload() {
        Test.startTest();
            InvocableZuoraInvoiceDownload.invoiceDownload();
        Test.stopTest();
    }

    @IsTest public static void testMemoApply() {
        List<Error_Log__c> beforeLogs = [
            SELECT Id, Class__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraMemoBatchApply'
        ];
        System.assertEquals(0,beforeLogs.size());

        Test.startTest();
            InvocableZuoraMemoApply.memoApply();
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id, Class__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraMemoBatchApply'
        ];

        System.assertEquals('ZuoraMemoBatchApply has finished', afterLogs[0].Message__c);
    }

    @IsTest public static void testMemoUpload() {
        // disableTrigger just sets a system property checkbox to true
        Util.disableTrigger('Update_Usage_Records_With_ZuoraId__c');

        List<Bill_Adjustment__c> adjustmentsBefore = [
            SELECT Id, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c = null
        ];
        System.assertEquals(5,adjustmentsBefore.size());

        Test.startTest();
            InvocableZuoraMemoUpload.memoUpload();
        Test.stopTest();

        List<Bill_Adjustment__c> adjustmentsAfter = [
            SELECT Id, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c = null
        ];
        System.assertEquals(0,adjustmentsAfter.size());
    }

    @IsTest public static void testPaperMailSend() {
        Test.startTest();
            InvocableZuoraPaperMailSend.paperMailSend();
        Test.stopTest();
    }

    @IsTest public static void testTemplateAssigner() {
        List<Error_Log__c> beforeLogs = [
            SELECT Id, Class__c, Message__c, Method__c
            FROM Error_Log__c
            WHERE Class__c = 'InvoiceTemplateAssigner'
        ];
        System.assertEquals(0,beforeLogs.size());

        Test.startTest();
            InvocableZuoraTemplateAssigner.templateAssigner();
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id, Class__c, Message__c, Method__c
            FROM Error_Log__c
            WHERE Class__c = 'InvoiceTemplateAssigner'
            AND Method__c = 'Cannot find template'
        ];
        System.assertEquals(1,afterLogs.size());
    }

    @IsTest public static void testUsageUpload() {
        List<Error_Log__c> beforeLogs = [
            SELECT Id, Class__c, Message__c, Method__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraUsageService'
        ];
        System.assertEquals(0,beforeLogs.size());

        Test.startTest();
            InvocableZuoraUsageUpload.usageUpload();
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id, Class__c, Message__c, Method__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraUsageService'
        ];
        System.assertEquals(1,afterLogs.size());
    }
}