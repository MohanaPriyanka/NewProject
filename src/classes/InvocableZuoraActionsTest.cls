@IsTest
public with sharing class InvocableZuoraActionsTest {
    @TestSetup public static void testData() {
        ZuoraBillEmailHandlerTest.setupTestData();
        ZuoraCreditDebitMemoServiceTest.testDataSetup();
        InvoiceTemplateAssignerTest.setupTestData();

        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body'),
            Title = 'InvoiceNumber.pdf',
            PathOnClient = '/InvoiceNumber.pdf'
        );
        insert cv;

        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id];
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

        List<Zuora__ZInvoice__c> allInvoices = [
            SELECT Id
            FROM Zuora__ZInvoice__c
        ];
        for (Zuora__ZInvoice__c invoice : allInvoices){
            invoice.Ready_for_Paper_Bill_Queue__c = true;
            invoice.Added_to_Paper_Bill_Queue__c = false;
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = contentVersions[0].ContentDocumentId,
                LinkedEntityId = invoice.Id,
                ShareType = 'I'
            );
            invoice.Content_Document_Id__c = contentVersions[0].ContentDocumentId;
            contentDocumentLinks.add(cdl);
            invoice.Zuora__InvoiceDate__c = Date.newInstance(2019,04,20);
            invoice.Downloaded_Date__c = System.today();
        }
        insert contentDocumentLinks;
        update allInvoices;
        TestFactory.insertBWAddress();
        TestFactory.insertLetterStreamSettings();
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
        List<Zuora__ZInvoice__c> allInvoices = [
            SELECT Id
            FROM Zuora__ZInvoice__c
        ];
        for (Zuora__ZInvoice__c invoice : allInvoices){
            invoice.Downloaded_Date__c = null;
        }
        update allInvoices;

        List<AsyncApexJob> beforeJobs = [
            SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
            FROM AsyncApexJob
        ];
        System.assertEquals(0,beforeJobs.size());

        Test.startTest();
            InvocableZuoraInvoiceDownload.invoiceDownload();
        Test.stopTest();

        List<AsyncApexJob> afterJobs = [
            SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
            FROM AsyncApexJob
        ];
        System.assertEquals(1,afterJobs.size());
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
        Date invoiceDate = Date.newInstance(2019,02,15);

        List<Bill_Adjustment__c> adjustmentsBefore = [
            SELECT Id, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c = null
            AND Approval_Status__c = 'Approved'
        ];
        System.assertEquals(5,adjustmentsBefore.size());

        Test.startTest();
            InvocableZuoraMemoUpload.memoUpload(new List<Date>{invoiceDate});
        Test.stopTest();

        List<Bill_Adjustment__c> adjustmentsAfter = [
            SELECT Id, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c = null
            AND Approval_Status__c = 'Approved'
        ];
        System.assertEquals(0,adjustmentsAfter.size());
    }

    @IsTest public static void testPaperMailSend() {
        List<AsyncApexJob> beforeJobs = [
            SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
            FROM AsyncApexJob
        ];
        System.assertEquals(0,beforeJobs.size());

        Test.startTest();
            InvocableZuoraPaperMailSend.paperMailSend();
        Test.stopTest();

        List<AsyncApexJob> afterJobs = [
            SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
            FROM AsyncApexJob
        ];
        System.assertEquals(1,afterJobs.size());
    }

    @IsTest public static void testTemplateAssigner() {
        List<zqu__InvoiceTemplate__c> templates = [
            SELECT Id
            FROM zqu__InvoiceTemplate__c
        ];
        delete templates;

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
        Date invoiceDate = Date.newInstance(2019,02,15);

        List<Error_Log__c> beforeLogs = [
            SELECT Id, Class__c, Message__c, Method__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraUsageService'
        ];
        System.assertEquals(0,beforeLogs.size());

        Test.startTest();
            InvocableZuoraUsageUpload.usageUpload(new List<Date>{invoiceDate});
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id, Class__c, Message__c, Method__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraUsageService'
        ];
        System.assertEquals(1,afterLogs.size());
    }

    @IsTest public static void testBillingBatch() {
        Date invoiceDate = Date.newInstance(2019,02,15);
        List<String> response = InvocableZuoraBillingBatchUpdate.billingBatchUpdate(new List<Date>{invoiceDate});
        System.assertEquals(1,response.size());
    }
}