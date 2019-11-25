/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 *************************************************************************************/

@IsTest
public with sharing class ZuoraInvoiceServiceTest {
    @TestSetup
    public static void testSetup() {
        ContentMailerServiceTest.testSetup();
        Zuora__CustomerAccount__c customerAccount = [SELECT Id, Zuora__Account__c FROM Zuora__CustomerAccount__c LIMIT 1];
        List<Zuora__ZInvoice__c> invoices = new List<Zuora__ZInvoice__c>();
        invoices.add(new Zuora__ZInvoice__c(
            Zuora__Account__c = customerAccount.Zuora__Account__c,
            Zuora__BillingAccount__c = customerAccount.Id,
            Zuora__Zuora_Id__c = '2c92c0fb6d1fe1f0016d216a87b54440'
        ));
        invoices.add(new Zuora__ZInvoice__c(
            Zuora__Account__c = customerAccount.Zuora__Account__c,
            Zuora__BillingAccount__c = customerAccount.Id,
            Zuora__Zuora_Id__c = '2c92c0fb6d1fe1f0016d216a87b54441'
        ));
        insert invoices;
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

    @IsTest
    private static void testBatchFailure() {
        List<Zuora__ZInvoice__c> invoices = new List<Zuora__ZInvoice__c>();
        for (Integer i = 0; i < 200; i++) {
            invoices.add(new Zuora__ZInvoice__c());
        }
        ZuoraInvoiceAsyncService asyncService = new ZuoraInvoiceAsyncService(invoices);
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Class__c = 'ZuoraInvoiceAsyncService'
        ];
        System.assertEquals(0, errorLogs.size());

        Test.startTest();
        Database.executeBatch(asyncService, 200);
        Test.stopTest();

        errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Class__c = 'ZuoraInvoiceAsyncService'
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Call downloadPDFs with fewer'));
    }

    @IsTest
    private static void testQueueableFailure() {
        List<Zuora__ZInvoice__c> invoices = new List<Zuora__ZInvoice__c>();
        for (Integer i = 0; i < 200; i++) {
            invoices.add(new Zuora__ZInvoice__c());
        }
        ZuoraInvoiceAsyncService asyncService = new ZuoraInvoiceAsyncService(invoices);
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Class__c = 'ZuoraInvoiceAsyncService'
        ];
        System.assertEquals(0, errorLogs.size());

        Test.startTest();
        System.enqueueJob(asyncService);
        Test.stopTest();

        errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Class__c = 'ZuoraInvoiceAsyncService'
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Call downloadPDFs with fewer'));
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

    /*
     * LetterStream Insert Tests
     */

    @IsTest
    private static void testDecoratedInvoice() {
        String invoiceJson = '{"attributes":{"type":"Zuora__ZInvoice__c","url":"/services/data/v47.0/sobjects/Zuora__ZInvoice__c/a7KS0000000E8d2MAC"},"Id":"a7KS0000000E8d2MAC","Zuora__Account__c":"001S000000yKIPXIA4"}';
        String accountWithTwoOppsJson = '{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001S000000yKIPXIA4"},' +
            '"Id":"001S000000yKIPXIA4","Name":"Ritchie Ho 20","BillingStreet":"1 Main","BillingCity":"Boston",' +
            '"BillingState":"Massachusetts","BillingStateCode":"MA","BillingPostalCode":"12312",' +
            '"BillingCountry":"United States","Send_Bills_Contact__c":"003S0000016Y1znIAC","Client_Brand_Key__c":"BluewaveLogo",' +
            '"Count_of_Large_Offtake_Opps__c":0,"Zuora_Id__c":"2c92c0f86e5e38b0016e5fc9634e0f22",' +
            '"Opportunities":{"totalSize":2,"done":true,"records":[' +
            '{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/006S000000CwOfgIAF"},' +
            '"AccountId":"001S000000yKIPXIA4","Id":"006S000000CwOfgIAF","Shared_Solar_System__c":"a1JS0000003BMvKMAW",' +
            '"Shared_Solar_System__r":{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvKMAW"},' +
            '"Id":"a1JS0000003BMvKMAW","Product__c":"01tS0000005j7AVIAY","Utility__c":"a1MS0000008BldqMAC",' +
            '"Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AVIAY"},' +
            '"Id":"01tS0000005j7AVIAY","Program__c":"SREC - Community Solar"}}},' +
            '{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/006S000000CwOfhIAF"},' +
            '"AccountId":"001S000000yKIPXIA4","Id":"006S000000CwOfhIAF","Shared_Solar_System__c":"a1JS0000003BMvJMAW",' +
            '"Shared_Solar_System__r":{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvJMAW"},' +
            '"Id":"a1JS0000003BMvJMAW","Product__c":"01tS0000005j7AWIAY","Utility__c":"a1MS0000008BldqMAC",' +
            '"Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AWIAY"},' +
            '"Id":"01tS0000005j7AWIAY","Program__c":"SREC - Community Solar"}}}]},' +
            '"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/003S0000016Y1znIAC"},' +
            '"Id":"003S0000016Y1znIAC","Email":"bulk@bluewavesolar.com.disabledagain","FirstName":"Ritchie","LastName":"Ho 20"}}';
        Account account = (Account) JSON.deserialize(accountWithTwoOppsJson, Account.class);
        Zuora__ZInvoice__c invoice = (Zuora__ZInvoice__c) JSON.deserialize(invoiceJson, Zuora__ZInvoice__c.class);

        ZuoraInvoiceAsyncService.DecoratedInvoice decoratedInvoice =
            new ZuoraInvoiceAsyncService.DecoratedInvoice(account, invoice);
        System.assertEquals(0, account.Count_of_Large_Offtake_Opps__c);
        System.assertEquals(false, decoratedInvoice.anchor);
        System.assertEquals(account.Client_Brand_Key__c, decoratedInvoice.clientBrandKey);
        System.assertEquals(account.Opportunities[0].Shared_Solar_System__r.Utility__c, decoratedInvoice.utilityId);
        System.assertEquals(account.Opportunities[0].Shared_Solar_System__r.Utility__c, account.Opportunities[1].Shared_Solar_System__r.Utility__c);
        System.assertEquals(account.Opportunities[0].Shared_Solar_System__r.Product__r.Program__c, decoratedInvoice.program);
        System.assertEquals(account.Opportunities[0].Shared_Solar_System__r.Product__r.Program__c, account.Opportunities[1].Shared_Solar_System__r.Product__r.Program__c);
        System.assertEquals(null, Logger.logs);

        accountWithTwoOppsJson = '{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001S000000yKIPXIA4"},' +
            '"Id":"001S000000yKIPXIA4","Name":"Ritchie Ho 20","BillingStreet":"1 Main","BillingCity":"Boston",' +
            '"BillingState":"Massachusetts","BillingStateCode":"MA","BillingPostalCode":"12312",' +
            '"BillingCountry":"United States","Send_Bills_Contact__c":"003S0000016Y1znIAC","Client_Brand_Key__c":"BluewaveLogo",' +
            '"Count_of_Large_Offtake_Opps__c":1,"Zuora_Id__c":"2c92c0f86e5e38b0016e5fc9634e0f22",' +
            '"Opportunities":{"totalSize":2,"done":true,"records":[' +
            '{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/006S000000CwOfgIAF"},' +
            '"AccountId":"001S000000yKIPXIA4","Id":"006S000000CwOfgIAF","Shared_Solar_System__c":"a1JS0000003BMvKMAW",' +
            '"Shared_Solar_System__r":{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvKMAW"},' +
            '"Id":"a1JS0000003BMvKMAW","Product__c":"01tS0000005j7AVIAY","Utility__c":"a1MS0000008BldqMAD",' +
            '"Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AVIAY"},' +
            '"Id":"01tS0000005j7AVIAY","Program__c":"SMART - Community Solar"}}},' +
            '{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/006S000000CwOfhIAF"},' +
            '"AccountId":"001S000000yKIPXIA4","Id":"006S000000CwOfhIAF","Shared_Solar_System__c":"a1JS0000003BMvJMAW",' +
            '"Shared_Solar_System__r":{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvJMAW"},' +
            '"Id":"a1JS0000003BMvJMAW","Product__c":"01tS0000005j7AWIAY","Utility__c":"a1MS0000008BldqMAC",' +
            '"Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AWIAY"},' +
            '"Id":"01tS0000005j7AWIAY","Program__c":"SREC - Community Solar"}}}]},' +
            '"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/003S0000016Y1znIAC"},' +
            '"Id":"003S0000016Y1znIAC","Email":"bulk@bluewavesolar.com.disabledagain","FirstName":"Ritchie","LastName":"Ho 20"}}';
        account = (Account) JSON.deserialize(accountWithTwoOppsJson, Account.class);
        decoratedInvoice =
            new ZuoraInvoiceAsyncService.DecoratedInvoice(account, invoice);
        System.assertEquals(1, account.Count_of_Large_Offtake_Opps__c);
        System.assertEquals(true, decoratedInvoice.anchor);
        System.assertEquals(account.Client_Brand_Key__c, decoratedInvoice.clientBrandKey);
        System.assertEquals(account.Opportunities[0].Shared_Solar_System__r.Utility__c, decoratedInvoice.utilityId);
        System.assertNotEquals(account.Opportunities[0].Shared_Solar_System__r.Utility__c, account.Opportunities[1].Shared_Solar_System__r.Utility__c);
        System.assertEquals(account.Opportunities[0].Shared_Solar_System__r.Product__r.Program__c, decoratedInvoice.program);
        System.assertNotEquals(account.Opportunities[0].Shared_Solar_System__r.Product__r.Program__c, account.Opportunities[1].Shared_Solar_System__r.Product__r.Program__c);
        System.assertEquals(1, Logger.logs.size());
        System.assertEquals(2, Logger.logs.values()[0].size());
        System.assert(Logger.logs.values()[0][0].message.contains('Multiple programs'));
        System.assert(Logger.logs.values()[0][1].message.contains('Multiple utilities'));
    }

    @IsTest
    private static void testGetDecoratedFirstInvoices() {
        useMocks();

        List<ZuoraInvoiceAsyncService.DecoratedInvoice> firstBillInvoices = ZuoraInvoiceAsyncService.getDecoratedFirstInvoices(new Set<Id>{'001S000000000FIRST'});
        System.assertEquals(1, firstBillInvoices.size());
        firstBillInvoices = ZuoraInvoiceAsyncService.getDecoratedFirstInvoices(new Set<Id>{'001S000000NOTFIRST'});
        System.assertEquals(0, firstBillInvoices.size());
    }

    @IsTest
    private static void testFindFirstInvoiceAndSetInsertsFuture() {
        useMocks();

        ZuoraInvoiceAsyncService.findFirstInvoiceAndSetInsertsFuture(new Set<Id>());
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
        ];
        System.assertEquals(0, errorLogs.size());
    }

    @IsTest
    private static void testZInvoiceTrigger() {
        Account account = new Account(
            Name = 'LetterStreamTest',
            Client_Brand_Key__c = 'AmpRed'
        );
        insert account;
        Zuora__CustomerAccount__c customerAccount = new Zuora__CustomerAccount__c(
            Name = 'LetterStreamTest',
            Zuora__Account__c = account.Id
        );
        insert customerAccount;
        Zuora__ZInvoice__c invoice = new Zuora__ZInvoice__c(
            Zuora__Account__c = account.Id,
            Downloaded_Date__c = System.today(),
            Zuora__BillingAccount__c = customerAccount.Id,
            Ready_for_Paper_Bill_Queue__c = true
        );
        LetterStream_Insert__c letterStreamInsert = new LetterStream_Insert__c(
            Utility__c = null,
            Anchor__c = false,
            Client_Brand_Key__c = 'AmpRed',
            Product_Program__c = null
        );
        insert letterStreamInsert;

        Test.startTest();
        insert invoice;
        Test.stopTest();

        invoice = [SELECT Id, LetterStream_Insert__c FROM Zuora__ZInvoice__c WHERE Id = :invoice.Id];
        System.assertEquals(letterStreamInsert.Id, invoice.LetterStream_Insert__c);
    }

    /*************
      *** MOCKS ***
      *************/
    private static void useMocks() {
        ZuoraInvoiceAsyncService.invoiceSelector = (ZuoraInvoiceSelector) Test.createStub(ZuoraInvoiceSelector.class, new MockZuoraInvoiceSelector());
        ZuoraInvoiceAsyncService.accountSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new MockAccountsSelector());
        ZuoraInvoiceAsyncService.invoiceService = (ZuoraInvoiceService) Test.createStub(ZuoraInvoiceService.class, new MockZuoraInvoiceService());
        ZuoraInvoiceService.insertSelector = (LetterStreamInsertSelector) Test.createStub(LetterStreamInsertSelector.class, new MockLetterStreamInsertSelector());
    }

    public class MockZuoraInvoiceSelector extends MockProvider {
        public MockZuoraInvoiceSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getAll' {
                    List<Id> invoiceIds = new List<Id>((Set<Id>) methodCall.listOfArgs[0]);
                    String invoiceJson = '[';
                    for (Integer i = 0; i < invoiceIds.size(); i++) {
                        String invoiceId = invoiceIds[i];
                        String accountId;
                        if (invoiceId.contains('NOTFIRST')) {
                            accountId = '001S000000NOTFIRST';
                        } else {
                            accountId = '001S000000000FIRST';
                        }
                        invoiceJson +=
                            '{"attributes":{"type":"Zuora__ZInvoice__c","url":"/services/data/v47.0/sobjects/Zuora__ZInvoice__c/a7KS0000000E8d2MAC"},' +
                                '"Id":"'+invoiceIds+'","Zuora__Account__c":"'+accountId+'"}';
                        if (i < invoiceIds.size() - 1) {
                            invoiceJson += ',';
                        }

                    }
                    invoiceJson += ']';
                    List<Zuora__ZInvoice__c> invoices = (List<Zuora__ZInvoice__c>) JSON.deserialize(invoiceJson, List<Zuora__ZInvoice__c>.class);
                    return invoices;
                }
            }
            return null;
        }
    }

    public class MockAccountsSelector extends MockProvider {
        public MockAccountsSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectAll' {
                    Set<Id> accountIds =
                        (Set<Id>) methodCall.listOfArgs[0];
                    String json;
                    if (accountIds.contains('001S000000NOTFIRST')) {
                        // Includes two invoices
                        json = '[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001S000000yKIPXIA4"},' +
                            '"Id":"001S000000yKIPXIA4","Name":"Ritchie Ho 20","BillingStreet":"1 Main","BillingCity":"Boston",' +
                            '"BillingState":"Massachusetts","BillingStateCode":"MA","BillingPostalCode":"12312",' +
                            '"BillingCountry":"United States","Send_Bills_Contact__c":"003S0000016Y1znIAC","Client_Brand_Key__c":"BluewaveLogo",' +
                            '"Count_of_Large_Offtake_Opps__c":0,"Zuora_Id__c":"2c92c0f86e5e38b0016e5fc9634e0f22",' +
                            '"Zuora__Invoices__r":{"totalSize":2,"done":true,"records":[' +
                            '{"attributes":{"type":"Zuora__ZInvoice__c","url":"/services/data/v47.0/sobjects/Zuora__ZInvoice__c/a7KS0000000E8g8MAC"},' +
                            '"Zuora__Account__c":"001S000000yKISFIA4","Id":"a7KS0000000E8g8MAC"},' +
                            '{"attributes":{"type":"Zuora__ZInvoice__c","url":"/services/data/v47.0/sobjects/Zuora__ZInvoice__c/a7KS0000000E8g8MAC"},' +
                            '"Zuora__Account__c":"001S000000yKISFIA4","Id":"a7KS0000000E8g8MAD"}]},' +
                            '"Opportunities":{"totalSize":2,"done":true,"records":[' +
                            '{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/006S000000CwOfgIAF"},' +
                            '"AccountId":"001S000000yKIPXIA4","Id":"006S000000CwOfgIAF","Shared_Solar_System__c":"a1JS0000003BMvKMAW",' +
                            '"Shared_Solar_System__r":{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvKMAW"},' +
                            '"Id":"a1JS0000003BMvKMAW","Product__c":"01tS0000005j7AVIAY","Utility__c":"a1MS0000008BldqMAC",' +
                            '"Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AVIAY"},' +
                            '"Id":"01tS0000005j7AVIAY","Program__c":"SREC - Community Solar"}}},' +
                            '{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/006S000000CwOfhIAF"},' +
                            '"AccountId":"001S000000yKIPXIA4","Id":"006S000000CwOfhIAF","Shared_Solar_System__c":"a1JS0000003BMvJMAW",' +
                            '"Shared_Solar_System__r":{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvJMAW"},' +
                            '"Id":"a1JS0000003BMvJMAW","Product__c":"01tS0000005j7AWIAY","Utility__c":"a1MS0000008BldqMAC",' +
                            '"Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AWIAY"},' +
                            '"Id":"01tS0000005j7AWIAY","Program__c":"SREC - Community Solar"}}}]},' +
                            '"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/003S0000016Y1znIAC"},' +
                            '"Id":"003S0000016Y1znIAC","Email":"bulk@bluewavesolar.com.disabledagain","FirstName":"Ritchie","LastName":"Ho 20"}}]';
                    } else {
                        // Includes one invoice
                        json = '[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001S000000yKIPXIA4"},' +
                            '"Id":"001S000000yKIPXIA4","Name":"Ritchie Ho 20","BillingStreet":"1 Main","BillingCity":"Boston",' +
                            '"BillingState":"Massachusetts","BillingStateCode":"MA","BillingPostalCode":"12312",' +
                            '"BillingCountry":"United States","Send_Bills_Contact__c":"003S0000016Y1znIAC","Client_Brand_Key__c":"BluewaveLogo",' +
                            '"Count_of_Large_Offtake_Opps__c":0,"Zuora_Id__c":"2c92c0f86e5e38b0016e5fc9634e0f22",' +
                            '"Zuora__Invoices__r":{"totalSize":1,"done":true,"records":[' +
                            '{"attributes":{"type":"Zuora__ZInvoice__c","url":"/services/data/v47.0/sobjects/Zuora__ZInvoice__c/a7KS0000000E8g8MAC"},' +
                            '"Zuora__Account__c":"001S000000yKISFIA4","Id":"a7KS0000000E8g8MAC"}]},' +
                            '"Opportunities":{"totalSize":2,"done":true,"records":[' +
                            '{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/006S000000CwOfgIAF"},' +
                            '"AccountId":"001S000000yKIPXIA4","Id":"006S000000CwOfgIAF","Shared_Solar_System__c":"a1JS0000003BMvKMAW",' +
                            '"Shared_Solar_System__r":{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvKMAW"},' +
                            '"Id":"a1JS0000003BMvKMAW","Product__c":"01tS0000005j7AVIAY","Utility__c":"a1MS0000008BldqMAC",' +
                            '"Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AVIAY"},' +
                            '"Id":"01tS0000005j7AVIAY","Program__c":"SREC - Community Solar"}}},' +
                            '{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/006S000000CwOfhIAF"},' +
                            '"AccountId":"001S000000yKIPXIA4","Id":"006S000000CwOfhIAF","Shared_Solar_System__c":"a1JS0000003BMvJMAW",' +
                            '"Shared_Solar_System__r":{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvJMAW"},' +
                            '"Id":"a1JS0000003BMvJMAW","Product__c":"01tS0000005j7AWIAY","Utility__c":"a1MS0000008BldqMAC",' +
                            '"Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AWIAY"},' +
                            '"Id":"01tS0000005j7AWIAY","Program__c":"SREC - Community Solar"}}}]},' +
                            '"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/003S0000016Y1znIAC"},' +
                            '"Id":"003S0000016Y1znIAC","Email":"bulk@bluewavesolar.com.disabledagain","FirstName":"Ritchie","LastName":"Ho 20"}}]';
                    }
                    List<Account> accounts = (List<Account>) System.JSON.deserialize(json, List<Account>.class);
                    return accounts;
                }
            }
            return null;
        }
    }

    public class MockLetterStreamInsertSelector extends MockProvider {
        public MockLetterStreamInsertSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getInsertMap' {
                    String insertMapJson = '{"true~BluewaveLogo~SMART - Community Solar~a1MS0000008BldqMAC":' +
                        '{"attributes":{"type":"LetterStream_Insert__c","url":"/services/data/v47.0/sobjects/LetterStream_Insert__c/a96S00000008qZCIAY"},' +
                        '"Id":"a96S00000008qZCIAY","Anchor__c":true,"Client_Brand_Key__c":"BluewaveLogo","Product_Program__c":"SMART - Community Solar",' +
                        '"Utility__c":"a1MS0000008BldqMAC","Active__c":true},' +
                        '"true~AmpRed~SREC - Community Solar~a1MS0000008BldqMAC":' +
                        '{"attributes":{"type":"LetterStream_Insert__c","url":"/services/data/v47.0/sobjects/LetterStream_Insert__c/a96S00000008qYsIAI"},' +
                        '"Id":"a96S00000008qYsIAI","Anchor__c":true,"Client_Brand_Key__c":"AmpRed","Product_Program__c":"SREC - Community Solar",' +
                        '"Utility__c":"a1MS0000008BldqMAC","Active__c":true},' +
                        '"false~BluewaveLogo~SREC - Community Solar~a1MS0000008BldqMAC":' +
                        '{"attributes":{"type":"LetterStream_Insert__c","url":"/services/data/v47.0/sobjects/LetterStream_Insert__c/a96S00000008qYqIAI"},' +
                        '"Id":"a96S00000008qYqIAI","Anchor__c":false,"Client_Brand_Key__c":"BluewaveLogo","Product_Program__c":"SREC - Community Solar",' +
                        '"Utility__c":"a1MS0000008BldqMAC","Active__c":true},' +
                        '"false~BluewaveLogo~SMART - Community Solar~a1MS0000008BldqMAC":' +
                        '{"attributes":{"type":"LetterStream_Insert__c","url":"/services/data/v47.0/sobjects/LetterStream_Insert__c/a96S00000008qYpIAI"},' +
                        '"Id":"a96S00000008qYpIAI","Anchor__c":false,"Client_Brand_Key__c":"BluewaveLogo","Product_Program__c":"SMART - Community Solar",' +
                        '"Utility__c":"a1MS0000008BldqMAC","Active__c":true},' +
                        '"false~BluewaveLogo~SREC - Community Solar~a1MS0000008BldpMAC":' +
                        '{"attributes":{"type":"LetterStream_Insert__c","url":"/services/data/v47.0/sobjects/LetterStream_Insert__c/a96S00000008qYoIAI"},' +
                        '"Id":"a96S00000008qYoIAI","Anchor__c":false,"Client_Brand_Key__c":"BluewaveLogo","Product_Program__c":"SREC - Community Solar",' +
                        '"Utility__c":"a1MS0000008BldpMAC","Active__c":true},' +
                        '"false~BluewaveLogo~SMART - Community Solar~a1MS0000008BldpMAC":' +
                        '{"attributes":{"type":"LetterStream_Insert__c","url":"/services/data/v47.0/sobjects/LetterStream_Insert__c/a96S00000008qYnIAI"},' +
                        '"Id":"a96S00000008qYnIAI","Anchor__c":false,"Client_Brand_Key__c":"BluewaveLogo","Product_Program__c":"SMART - Community Solar",' +
                        '"Utility__c":"a1MS0000008BldpMAC","Active__c":true}}';
                    Map<String, LetterStream_Insert__c> insertMap = (Map<String, LetterStream_Insert__c>) JSON.deserialize(insertMapJson, Map<String, LetterStream_Insert__c>.class);
                    return insertMap;
                }
            }
            return null;
        }
    }

    public class MockZuoraInvoiceService extends MockProvider {
        public MockZuoraInvoiceService() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'setFirstBillInsert' {
                    List<ZuoraInvoiceAsyncService.DecoratedInvoice> decoratedInvoices =
                        (List<ZuoraInvoiceAsyncService.DecoratedInvoice>) methodCall.listOfArgs[0];
                    if (decoratedInvoices.size() == 0) {
                        throw new Util.BWException('Test Exception');
                    } else {
                        return null;
                    }
                }
            }
            return null;
        }
    }
}