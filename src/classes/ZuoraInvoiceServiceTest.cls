/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 *************************************************************************************/

@IsTest
public with sharing class ZuoraInvoiceServiceTest {
    @TestSetup
    public static void testSetup() {
        List<Zuora__ZInvoice__c> invoices = new List<Zuora__ZInvoice__c>();
        invoices.add(new Zuora__ZInvoice__c(Zuora__ZuoraId__c = '12345'));
        invoices.add(new Zuora__ZInvoice__c(Zuora__ZuoraId__c = '67890'));

        insert invoices;
    }

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
        System.assertEquals(idFor12345, zuoraInvoiceIdToSFDCId.get('12345'));
    }

    @IsTest
    public static void testInsertContentVersions() {
        List<ZuoraAPI.Invoice> zuoraInvoices = new List<ZuoraAPI.Invoice>();
        ZuoraAPI.Invoice zuoraInvoice = new ZuoraAPI.Invoice();
        zuoraInvoice.Body = 'SGVsbG8gV29ybGQ=';
        zuoraInvoice.id = '12345';
        zuoraInvoice.InvoiceNumber = 'INV-12345';
        zuoraInvoices.add(zuoraInvoice);
        ZuoraAPI.Invoice zuoraInvoice2 = new ZuoraAPI.Invoice();
        zuoraInvoice2.Body = 'SGVsbG8gV29ybGQ=';
        zuoraInvoice2.id = '67890';
        zuoraInvoice2.InvoiceNumber = 'INV-67890';
        zuoraInvoices.add(zuoraInvoice2);

        ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(null);
        Map<String, ContentVersion> idToContentVersion = invoiceService.insertContentVersions(zuoraInvoices);

        System.assertEquals('INV-12345.pdf', idToContentVersion.get('12345').Title);
        System.assertEquals('INV-67890.pdf', idToContentVersion.get('67890').Title);
    }

    @IsTest
    public static void testInvoiceUpdate() {
        List<Zuora__ZInvoice__c> sfdcInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(2, sfdcInvoices.size());
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for (Zuora__ZInvoice__c zInvoice : sfdcInvoices) {
            ContentDocumentLink cdl = new ContentDocumentLink(
                LinkedEntityId = zInvoice.Id,
                // Just a dummy Id t
                Id = '06A0a000002SwvOEAS'
            );
            contentDocumentLinks.add(cdl);
        }

        ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(null);
        invoiceService.updateZuoraInvoicesAsDownloaded(contentDocumentLinks);

        sfdcInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(0, sfdcInvoices.size());
    }

    @IsTest
    public static void testDownloadPDFAsync() {
        ZuoraInvoiceAsyncService asyncService = new ZuoraInvoiceAsyncService();
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
}