/*************************************************************************************
 * Created By: peteryao on 9/12/19  
 *************************************************************************************/
@IsTest
public with sharing class ContentMailerServiceTest {
    @TestSetup
    public static void testSetup() {
        LetterStreamJob__c letterStreamJob = new LetterStreamJob__c();
        insert letterStreamJob;

        // Our jobs usually have 11 bills in them.
        Account account = new Account(Name = 'Test');
        insert account;
        Zuora__CustomerAccount__c customerAccount = new Zuora__CustomerAccount__c(
            Name = 'Test',
            Zuora__Account__c = account.Id
        );
        insert customerAccount;
        // ContentMailerService sends Content attached to an SObject, so while it's not specific to ZInvoice, we need
        // some SObject to use for testing (that has a Letterstreamjob__c field). Right now, that's only Account Bill
        // and ZInvoice.
        List<Zuora__ZInvoice__c> invoices = new List<Zuora__ZInvoice__c>();
        for (Integer i = 0; i < 20; i++) {
            Zuora__ZInvoice__c invoice = new Zuora__ZInvoice__c(
                Zuora__Account__c = account.Id,
                Downloaded_Date__c = System.today(),
                Zuora__BillingAccount__c = customerAccount.Id,
                Ready_for_Paper_Bill_Queue__c = true
            );
            invoices.add(invoice);
        }
        insert invoices;
        invoices = [
            SELECT Id, Ready_for_Paper_Bill_Queue__c, Added_to_Paper_Bill_Queue__c, LetterStreamJob__c
            FROM Zuora__ZInvoice__c
            WHERE Id = :invoices
        ];

        // I couldn't figure out how to mock the ContentDocumentSelector which returns a ContentDocument with
        // ContentVersion data. Deserializing JSON would results in various JSONExceptions.
        // So this will need to create the data
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (Zuora__ZInvoice__c invoice : invoices) {
            ContentVersion cv = new ContentVersion(
                ContentLocation = 'S',
                VersionData = EncodingUtil.base64Decode('invoice body'),
                Title = 'InvoiceNumber.pdf',
                PathOnClient = '/InvoiceNumber.pdf'
            );
            contentVersions.add(cv);
        }
        insert contentVersions;

        contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: contentVersions];

        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for (Integer i = 0; i < invoices.size(); i++) {
            System.assertEquals(true, invoices[i].Ready_for_Paper_Bill_Queue__c);
            System.assertEquals(false, invoices[i].Added_to_Paper_Bill_Queue__c);
            System.assertEquals(null, invoices[i].LetterStreamJob__c);
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = contentVersions[i].ContentDocumentId,
                LinkedEntityId = invoices[i].Id,
                ShareType = 'I'
            );
            invoices[i].Content_Document_Id__c = contentVersions[i].ContentDocumentId;
            contentDocumentLinks.add(cdl);
        }
        insert contentDocumentLinks;
        update invoices;
        TestFactory.insertBWAddress();
        TestFactory.insertLetterStreamSettings();
    }

    @IsTest
    public static void testMailContent() {
        Test.setMock(HttpCalloutMock.class, new LetterStreamAPIMock());

        ContentDocument cd = [SELECT Id FROM ContentDocument LIMIT 1];
        List<Zuora__ZInvoice__c> invoices = [SELECT Id FROM Zuora__ZInvoice__c LIMIT 2];

        ContentMailerService mailerService = new ContentMailerService();
        List<ContentMailerService.Param> params = new List<ContentMailerService.Param>();
        // This content should fit
        ContentMailerService.Param param = getParam();
        param.contentDocumentId = cd.Id;
        param.contentSize = mailerService.maxPackageSize + 10;
        param.linkedEntityId = invoices[0].Id;
        params.add(param);
        // But we won't want to add this to the package, it should remain for the next queue
        ContentMailerService.Param param2 = getParam();
        param2.contentDocumentId = cd.Id;
        param2.contentSize = 256;
        param2.linkedEntityId = invoices[1].Id;
        params.add(param2);
        mailerService.remainingContentToSend = params;
        Zuora__ZInvoice__c invoice1 = [SELECT Id, Added_to_Paper_Bill_Queue__c FROM Zuora__ZInvoice__c WHERE Id = :invoices[0].Id];
        Zuora__ZInvoice__c invoice2 = [SELECT Id, Added_to_Paper_Bill_Queue__c FROM Zuora__ZInvoice__c WHERE Id = :invoices[1].Id];
        System.assertEquals(false, invoice1.Added_to_Paper_Bill_Queue__c);
        System.assertEquals(false, invoice2.Added_to_Paper_Bill_Queue__c);

        Test.startTest();
        // Should mail the first document and queue the second
        mailerService.mailContent();
        invoice1 = [SELECT Id, Added_to_Paper_Bill_Queue__c FROM Zuora__ZInvoice__c WHERE Id = :invoices[0].Id];
        invoice2 = [SELECT Id, Added_to_Paper_Bill_Queue__c FROM Zuora__ZInvoice__c WHERE Id = :invoices[1].Id];
        System.assertEquals(true, invoice1.Added_to_Paper_Bill_Queue__c);
        System.assertEquals(false, invoice2.Added_to_Paper_Bill_Queue__c);
        Test.stopTest();

        // After executing the queue, both should now be sent
        invoice1 = [SELECT Id, Added_to_Paper_Bill_Queue__c FROM Zuora__ZInvoice__c WHERE Id = :invoices[0].Id];
        invoice2 = [SELECT Id, Added_to_Paper_Bill_Queue__c FROM Zuora__ZInvoice__c WHERE Id = :invoices[1].Id];
        System.assertEquals(true, invoice1.Added_to_Paper_Bill_Queue__c);
        System.assertEquals(true, invoice2.Added_to_Paper_Bill_Queue__c);

        Logger.flushLogs();
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ContentMailerService'
            AND Severity__c = :Logger.ERROR
        ];
        System.assertEquals(0, errorLogs.size());
    }

    private static ContentMailerService.Param getParam() {
        ContentMailerService.Param param = new ContentMailerService.Param();
        param.fileName = 'foo';
        param.recipientName = 'name';
        param.street = 'street';
        param.city = 'city';
        param.state = 'state';
        param.postalCode = 'postalCode';
        param.extraInserts = '1234';
        return param;
    }

    @IsTest
    public static void testGetContentForPackage() {
        ContentMailerService mailerService = new ContentMailerService();
        List<ContentMailerService.Param> params = new List<ContentMailerService.Param>();
        // This content should fit
        ContentMailerService.Param param = new ContentMailerService.Param();
        param.contentDocumentId = Util.getFakeId(ContentDocument.SObjectType);
        param.contentSize = mailerService.maxPackageSize + 10;
        params.add(param);
        // But we won't want to add this to the package, it should remain for the next queue
        ContentMailerService.Param param2 = new ContentMailerService.Param();
        param2.contentDocumentId = Util.getFakeId(ContentDocument.SObjectType);
        param2.contentSize = 256;
        params.add(param2);
        mailerService.remainingContentToSend = params;

        Test.startTest();
        List<ContentMailerService.Param> contentToSend = mailerService.getContentForPackage();
        Test.stopTest();
        System.assertEquals(1, contentToSend.size());
        System.assertEquals(mailerService.maxPackageSize + 10, contentToSend[0].contentSize);
        System.assertEquals(1, mailerService.remainingContentToSend.size());
        System.assertEquals(256, mailerService.remainingContentToSend[0].contentSize);
    }

    @IsTest
    public static void testGetContentWithVersionData() {
        ContentDocument cd = [
            SELECT Id
            FROM ContentDocument
            LIMIT 1
        ];
        List<ContentMailerService.Param> params = new List<ContentMailerService.Param>();
        ContentMailerService.Param param = new ContentMailerService.Param();
        param.contentDocumentId = cd.Id;
        params.add(param);
        Test.startTest();
        ContentMailerService mailerService = new ContentMailerService();
        Map<Id, ContentDocument> contentDocumentMap = mailerService.getContentMapWithVersionData(params);
        Test.stopTest();
        System.assertEquals(1, contentDocumentMap.values().size());
    }

    @IsTest
    public static void testHandleResponse() {
        String responseXMLString = '<?xml version="1.0" encoding="UTF-8"?><messages id="ft5eh41g_test"></messages>';
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ContentMailerService'
        ];
        System.assertEquals(0, errorLogs.size());

        Test.startTest();
        ContentMailerService mailerService = new ContentMailerService();
        mailerService.handleResponse(responseXMLString, new Set<Id>(), 'csv');
        Logger.flushLogs();
        Test.stopTest();

        errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ContentMailerService'
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Job post failed'), 'Expected a Job post failed error');
    }


    @IsTest
    public static void testMarkObjectAsMailed() {
        LetterStreamJob__c letterStreamJob = [SELECT Id FROM LetterStreamJob__c LIMIT 1];
        Map<Id, Zuora__ZInvoice__c> invoiceMap = new Map<Id, Zuora__ZInvoice__c>([
            SELECT Id FROM Zuora__ZInvoice__c
        ]);

        Test.startTest();
        ContentMailerService mailerService = new ContentMailerService();
        mailerService.markObjectAsMailed(invoiceMap.keySet(), letterStreamJob.Id);
        Test.stopTest();

        List<Zuora__ZInvoice__c> invoices = [
            SELECT Id, Ready_for_Paper_Bill_Queue__c, Added_to_Paper_Bill_Queue__c, LetterStreamJob__c
            FROM Zuora__ZInvoice__c
        ];
        System.assertEquals(20, invoices.size(), 'Expected 20 invoices');
        for (Zuora__ZInvoice__c zInvoice : invoices) {
            System.assertEquals(false, zInvoice.Ready_for_Paper_Bill_Queue__c);
            System.assertEquals(true, zInvoice.Added_to_Paper_Bill_Queue__c);
            System.assertEquals(letterStreamJob.Id, zInvoice.LetterStreamJob__c);
        }
    }
    @IsTest
    private static void testErrorHandling() {
        Test.setMock(HttpCalloutMock.class, new LetterStreamAPIMock());

        ContentDocument cd = [SELECT Id FROM ContentDocument LIMIT 1];
        List<Zuora__ZInvoice__c> invoices = [SELECT Id FROM Zuora__ZInvoice__c LIMIT 2];

        List<ContentMailerService.Param> params = new List<ContentMailerService.Param>();
        // This param should fail, since Accounts don't have the fields (Ready for Paper Bill Queue, etc) to send Content
        ContentMailerService.Param param = getParam();
        param.contentDocumentId = cd.Id;
        param.contentSize = 256;
        param.linkedEntityId = Util.getFakeId(Account.SObjectType);
        params.add(param);

        Test.startTest();
        ContentMailerAsyncService asyncService = new ContentMailerAsyncService(params);
        System.enqueueJob(asyncService);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Invalid field'));
    }
}