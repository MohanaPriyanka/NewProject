/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 *************************************************************************************/

@IsTest
public with sharing class ZuoraInvoiceServiceTest {
    @TestSetup
    public static void testSetup() {
        List<Zuora__ZInvoice__c> invoices = new List<Zuora__ZInvoice__c>();
        invoices.add(new Zuora__ZInvoice__c(Zuora__Zuora_Id__c = '2c92c0fb6d1fe1f0016d216a87b54440'));
        invoices.add(new Zuora__ZInvoice__c(Zuora__Zuora_Id__c = '2c92c0fb6d1fe1f0016d216a87b54441'));

        insert invoices;
        ContentMailerServiceTest.testSetup();
    }

    /*
     * Download from Zuora tests
     */

    @IsTest
    public static void testQueryForPDF() {
        List<Zuora__ZInvoice__c> sfdcInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(2, sfdcInvoices.size());
        Id idFor12345 = sfdcInvoices[0].Id;

        Map<String, Id> zuoraInvoiceIdToSFDCId = new Map<String, Id>();

        ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(sfdcInvoices);
        List<ZuoraAPI.Invoice> zuoraInvoices = invoiceService.queryZuoraForInvoicePDF(sfdcInvoices, zuoraInvoiceIdToSFDCId);

        // queryZuoraForInvoicePDF only processes a single invoice when running a test, so the map should only have
        // one item, and the zuora invoices returned should have one item (corresponding to the first invoice in the list)
        // and the list of sfdcinvoices should have one left, to query in a subsequent queueable job

        System.assertEquals(1, zuoraInvoices.size());
        System.assertEquals(1, sfdcInvoices.size());
        System.assertEquals(1, zuoraInvoiceIdToSFDCId.values().size());
        System.assertEquals(idFor12345, zuoraInvoiceIdToSFDCId.get('2c92c0fb6d1fe1f0016d216a87b54440'));
    }

    @IsTest
    public static void testInsertContentVersions() {
        List<ZuoraAPI.Invoice> zuoraInvoices = new List<ZuoraAPI.Invoice>();
        ZuoraAPI.Invoice zuoraInvoice = new ZuoraAPI.Invoice();
        zuoraInvoice.Body = 'SGVsbG8gV29ybGQ=';
        zuoraInvoice.id = '2c92c0fb6d1fe1f0016d216a87b54440';
        zuoraInvoice.InvoiceNumber = 'INV-12345';
        zuoraInvoices.add(zuoraInvoice);
        ZuoraAPI.Invoice zuoraInvoice2 = new ZuoraAPI.Invoice();
        zuoraInvoice2.Body = 'SGVsbG8gV29ybGQ=';
        zuoraInvoice2.id = '2c92c0fb6d1fe1f0016d216a87b54441';
        zuoraInvoice2.InvoiceNumber = 'INV-67890';
        zuoraInvoices.add(zuoraInvoice2);

        ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(null);
        Map<String, ContentVersion> idToContentVersion = invoiceService.insertContentVersions(zuoraInvoices);

        System.assertEquals('INV-12345.pdf', idToContentVersion.get('2c92c0fb6d1fe1f0016d216a87b54440').Title);
        System.assertEquals('INV-67890.pdf', idToContentVersion.get('2c92c0fb6d1fe1f0016d216a87b54441').Title);
    }

    @IsTest
    public static void testInvoiceUpdate() {
        List<Zuora__ZInvoice__c> sfdcInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(2, sfdcInvoices.size());

        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        Map<String, ContentVersion> invToContentVersion = new Map<String, ContentVersion>();
        Map<Id, Zuora__ZInvoice__c> invoiceMap = new Map<Id, Zuora__ZInvoice__c>();

        for (Zuora__ZInvoice__c zInvoice : sfdcInvoices) {
            invoiceMap.put(zInvoice.Id, zInvoice);
            ContentDocumentLink cdl = new ContentDocumentLink(
                LinkedEntityId = zInvoice.Id,
                // Just a dummy Id t
                Id = '06A0a000002SwvOEAS',
                ContentDocumentId = '06A0a000002SwvOEAS'
            );
            contentDocumentLinks.add(cdl);
            ContentVersion version = new ContentVersion(
                Id = '0680a000003HjQqAAK'
            );
            invToContentVersion.put(zInvoice.Zuora__Zuora_Id__c, version);
        }

        ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(null);
        invoiceService.updateZuoraInvoicesAsDownloaded(contentDocumentLinks, invToContentVersion, invoiceMap);

        sfdcInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(0, sfdcInvoices.size());

        List<Zuora__ZInvoice__c> invoiceList = [
            SELECT Id, Content_Document_Id__c, Bill_Document_Content_Version_ID__c,
                Ready_For_Email_Send__c, Ready_For_Paper_Bill_Queue__c
            FROM Zuora__ZInvoice__c
            WHERE Id IN : invoiceMap.keySet()
        ];

        System.assertNotEquals(0,invoiceList.size());
        System.assertEquals('0680a000003HjQqAAK',invoiceList[0].Bill_Document_Content_Version_ID__c);
        System.assertEquals('06A0a000002SwvOEAS',invoiceList[0].Content_Document_Id__c);
        System.assert(invoiceList[0].Ready_for_Email_Send__c);
        System.assert(invoiceList[0].Ready_for_Paper_Bill_Queue__c);
    }

    @IsTest
    public static void testDownloadPDFAsync() {
        ZuoraInvoiceAsyncService asyncService = new ZuoraInvoiceAsyncService(ZuoraInvoiceAsyncService.OperationType.DOWNLOAD);
        asyncService.initForDownload();
        System.assertEquals(2, asyncService.allInvoicesToDownload.size());
        Id zuoraInvoiceId = asyncService.allInvoicesToDownload[0].Id;

        Test.startTest();
        Database.executeBatch(asyncService, 2);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraInvoiceService'
            AND Severity__c = :Logger.DEBUG
        ];
        System.assertEquals(1, errorLogs.size());
        System.assertEquals('Queuing 1 invoices to download', errorLogs[0].Message__c);

        List<Zuora__ZInvoice__c> zuoraInvoices = [
            SELECT Id, Downloaded_Date__c, Content_Document_Id__c, (
                SELECT Id, ContentDocumentId
                FROM ContentDocumentLinks
            )
            FROM Zuora__ZInvoice__c
            WHERE Id = :zuoraInvoiceId
        ];
        // There should be one PDF downloaded
        System.assertEquals(1, zuoraInvoices.size());
        System.assertEquals(System.today(), zuoraInvoices[0].Downloaded_Date__c);
        System.assertEquals(1, zuoraInvoices[0].ContentDocumentLinks.size());
    }

    @IsTest
    public static void testQueueableExecution() {
        ZuoraInvoiceAsyncService asyncService =
            new ZuoraInvoiceAsyncService(ZuoraInvoiceSelector.getInvoicesToDownload());
        System.assertEquals(2, asyncService.allInvoicesToDownload.size());
        Id zuoraInvoiceId = asyncService.allInvoicesToDownload[0].Id;

        Test.startTest();
        System.enqueueJob(asyncService);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraInvoiceService'
            AND Severity__c = :Logger.DEBUG
        ];
        System.assertEquals(1, errorLogs.size());
        System.assertEquals('Queuing 1 invoices to download', errorLogs[0].Message__c);

        List<Zuora__ZInvoice__c> zuoraInvoices = [
            SELECT Id, Downloaded_Date__c, Content_Document_Id__c, (
                SELECT Id, ContentDocumentId
                FROM ContentDocumentLinks
            )
            FROM Zuora__ZInvoice__c
            WHERE Id = :zuoraInvoiceId
        ];
        // There should be one PDF downloaded
        System.assertEquals(1, zuoraInvoices.size());
        System.assertEquals(System.today(), zuoraInvoices[0].Downloaded_Date__c);
        System.assertEquals(1, zuoraInvoices[0].ContentDocumentLinks.size());
    }

    /*
     * Upload to Letterstream tests
     */
    @IsTest
    private static void testBatchAndQueue() {
        List<Zuora__ZInvoice__c> invoices = ZuoraInvoiceSelector.getInvoicesToMail();
        Set<Account> accounts = new Set<Account>();
        for (Zuora__ZInvoice__c zInvoice : invoices) {
            Account account = new Account(
                Id = zInvoice.Zuora__BillingAccount__r.Zuora__Account__c,
                Name = 'Test',
                BillingStreet = 'Street',
                BillingCity = 'City',
                BillingState = 'Massachusetts',
                BillingPostalCode = 'PostalCode'
            );
            accounts.add(account);
        }
        update new List<Account>(accounts);

        ZuoraAPIHelper.setZuoraLive(true);
        Test.startTest();
        InvocableCSBillLetterStreamSend.sendLetters();
        Test.stopTest();

        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = 'Error'
        ];
        System.assertEquals(0, errorLogs.size());
        System.assertEquals(1, ContentMailerService.calloutsMade);
    }

    @IsTest
    private static void testGetAllContentParamsToQueueValidAddresses() {
        List<Zuora__ZInvoice__c> invoices = ZuoraInvoiceSelector.getInvoicesToMail();
        System.assert(invoices.size() > 0);
        Set<Account> accounts = new Set<Account>();
        for (Zuora__ZInvoice__c zInvoice : invoices) {
            Account account = new Account(
                Id = zInvoice.Zuora__BillingAccount__r.Zuora__Account__c,
                Name = 'Test',
                BillingStreet = 'Street',
                BillingCity = 'City',
                BillingState = 'Massachusetts',
                BillingPostalCode = 'PostalCode'
            );
            accounts.add(account);
        }
        update new List<Account>(accounts);

        invoices = ZuoraInvoiceSelector.getInvoicesToMail();
        ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(null);
        for (Zuora__ZInvoice__c zInvoice : invoices) {
            System.assert(invoiceService.invoiceAddressValid(zInvoice));
        }

        Test.startTest();
        List<ContentMailerService.Param> params = invoiceService.getAllContentParamsToQueue(invoices);
        Test.stopTest();
        System.assertEquals(invoices.size(), params.size());
        for (ContentMailerService.Param param : params) {
            System.assertEquals('Test', param.recipientName);
            System.assertEquals('Street', param.street);
            System.assertEquals('City', param.city);
            System.assertEquals('Massachusetts', param.state);
            System.assertEquals('PostalCode', param.postalCode);
        }
        List<Case> cases = [
            SELECT Id
            FROM Case
            WHERE Subject = 'Cannot send bill to Community Solar customer.'
        ];
        System.assertEquals(0, cases.size());
    }

    @IsTest
    private static void testGetAllContentParamsToQueueInvalidAddresses() {
        List<Zuora__ZInvoice__c> invoices = ZuoraInvoiceSelector.getInvoicesToMail();
        System.assert(invoices.size() > 0);

        ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(null);
        for (Zuora__ZInvoice__c zInvoice : invoices) {
            System.assert(!invoiceService.invoiceAddressValid(zInvoice));
        }

        Test.startTest();
        List<ContentMailerService.Param> params = invoiceService.getAllContentParamsToQueue(invoices);
        Test.stopTest();
        System.assertEquals(0, params.size());
        List<Case> cases = [
            SELECT Id
            FROM Case
            WHERE Subject = 'Cannot send bill to Community Solar customer.'
        ];
        System.assertEquals(invoices.size(), cases.size());
    }

    @IsTest
    private static void testInvalidAddressAndCaseCreation() {
        List<Zuora__ZInvoice__c> invoices = ZuoraInvoiceSelector.getInvoicesToMail();
        System.assert(invoices.size() > 0);
        System.assertEquals(null, invoices[0].Zuora__BillingAccount__r.Zuora__Account__r.BillingStreet);

        Test.startTest();
        ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(null);
        System.assert(!invoiceService.invoiceAddressValid(invoices[0]));
        Id accountId = invoices[0].Zuora__BillingAccount__r.Zuora__Account__c;
        Account acct = new Account(
            Id = accountId,
            BillingStreet = 'Street',
            BillingCity = 'City',
            BillingState = 'Massachusetts',
            BillingPostalCode = 'PostalCode'
        );
        update acct;
        invoices = ZuoraInvoiceSelector.getInvoicesToMail();
        System.assertEquals(accountId, invoices[0].Zuora__BillingAccount__r.Zuora__Account__c);
        System.assert(invoiceService.invoiceAddressValid(invoices[0]));

        Case c = invoiceService.createCaseForInvalidAddress(invoices[0]);
        insert c;
        System.assertEquals('Cannot send bill to Community Solar customer.', c.Subject);
        Test.stopTest();
    }
}