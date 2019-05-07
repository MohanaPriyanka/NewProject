/**
 * Created by mstackhouse on 7/17/2018.
 * Description: Used to test LetterStreamService Methods
 */

@IsTest
public with sharing class LetterStreamServiceTest {
    @IsTest
    public static void testResponseParser() {
        String exampleResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<messages id="86fjkb92">' +
            '<message type="info">' +
            '<code>-100</code>' +
            '<details>Success</details>' +
            '<batch>bw_bills</batch>' +
            '<quantity>2</quantity>' +
            '<cost>2.82</cost>' +
            '<doc><id>0694C000000PskrQAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<doc><id>0694C000000Psl1QAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<doc><id>0694C000000Psm1QAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<doc><id>0694C000000Psx1QAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '</message>' +
            '</messages>';

        LetterStreamService lss = new LetterStreamService();

        LetterStreamJob__c newJob = lss.parseLetterStreamResponse(exampleResponse);

        List<LetterStreamJob__c> jobs = [
            SELECT Id, Batch_Name__c, Cost__c, Details__c, Job_Id__c, Piece_Count__c
            FROM LetterStreamJob__c
        ];

        System.assertEquals(newJob.Id, jobs[0].Id);
        System.assertEquals(1, jobs.size());
        System.assertEquals('Success', jobs[0].Details__c);
        System.assertEquals('bw_bills', jobs[0].Batch_Name__c);
        System.assertEquals(2, jobs[0].Piece_Count__c);
        System.assertEquals(2.82, jobs[0].Cost__c);
        System.assertEquals('1646754', jobs[0].Job_Id__c);

        List<LetterStream_Piece__c> pieces = [
            SELECT Id, LetterStreamJob__c, Object_Id__c, Piece_Cost__c
            FROM LetterStream_Piece__c
        ];

        System.assertEquals(4, pieces.size());
        System.assertEquals('0694C000000PskrQAC', pieces[0].Object_Id__c);
        for (LetterStream_Piece__c piece : pieces) {
            System.assertEquals(jobs[0].Id, piece.LetterStreamJob__c);
            System.assertEquals(1.41, piece.Piece_Cost__c);

        }
    }

    @IsTest
    public static void testResponseParserMixedOrder() {
        String exampleResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<messages id="86fjkb92">' +
            '<message type="info">' +
            '<details>Success</details>' +
            '<code>-100</code>' +
            '<doc><id>0694C000000PskrQAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<batch>bw_bills</batch>' +
            '<quantity>2</quantity>' +
            '<doc><id>0694C000000Psl1QAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<doc><id>0694C000000Psm1QAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<doc><id>0694C000000Psx1QAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<cost>2.82</cost>' +
            '</message>' +
            '</messages>';

        LetterStreamService lss = new LetterStreamService();

        LetterStreamJob__c newJob = lss.parseLetterStreamResponse(exampleResponse);

        List<LetterStreamJob__c> jobs = [
            SELECT Id, Batch_Name__c, Cost__c, Details__c, Job_Id__c, Piece_Count__c
            FROM LetterStreamJob__c
        ];

        System.assertEquals(newJob.Id, jobs[0].Id);
        System.assertEquals(1, jobs.size());
        System.assertEquals('Success', jobs[0].Details__c);
        System.assertEquals('bw_bills', jobs[0].Batch_Name__c);
        System.assertEquals(2, jobs[0].Piece_Count__c);
        System.assertEquals(2.82, jobs[0].Cost__c);
        System.assertEquals('1646754', jobs[0].Job_Id__c);

        List<LetterStream_Piece__c> pieces = [
            SELECT Id, LetterStreamJob__c, Object_Id__c, Piece_Cost__c
            FROM LetterStream_Piece__c
        ];

        System.assertEquals(4, pieces.size());
        System.assertEquals('0694C000000PskrQAC', pieces[0].Object_Id__c);
        for (LetterStream_Piece__c piece : pieces) {
            System.assertEquals(jobs[0].Id, piece.LetterStreamJob__c);
            System.assertEquals(1.41, piece.Piece_Cost__c);

        }
    }

    @IsTest
    public static void testFailedResponseParser() {
        String exampleResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<messages id="86fjkb92">' +
            '<message type="info">' +
            '<code>-900</code>' +
            '<details>Failed: Job name must be 8 to 20 characters (a-zA-Z0-9_-)</details>' +
            '</message>' +
            '</messages>';

        LetterStreamService lss = new LetterStreamService();

        LetterStreamJob__c newJob = lss.parseLetterStreamResponse(exampleResponse);

        System.assertEquals(null, newJob);
    }

    @IsTest
    public static void testCSVBuilder() {
        TestFactory.insertBWAddress();
        TestFactory.insertLetterStreamSettings();

        LetterStreamService lss = new LetterStreamService();

        System.assertEquals('', lss.csv);

        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent = new Account(
            Name = 'Account Parent',
            RecordTypeId = parentAccountRT,
            BillingStreet = '123 Fake St',
            BillingCity = 'City',
            BillingState = 'Colorado',
            BillingPostalCode = '80525'
        );
        insert accountParent;

        Account_Bill__c accountBill = new Account_Bill__c(
            Parent_Account__c = accountParent.Id,
            Bill_PDF_Page_Count__c = 4 // this value gets set by the conga conductor when bill pdfs are createdI
        );

        insert accountBill;

        ContentVersion documentVersion = new ContentVersion(
            Title = 'test document',
            PathOnClient = 'test_Doc.pdf',
            VersionData = Blob.valueOf('testDoc')
        );
        Util.insertSObj(documentVersion);

        accountBill = [
            SELECT Id, Parent_Account__r.Name, Parent_Account__r.BillingStreet, Parent_Account__r.BillingCity,
                Parent_Account__r.BillingState, Parent_Account__r.BillingPostalCode, Bill_PDF_Page_Count__c,
                Calendar_Month__c, Year__c, Bill_Attach_Document__c
            FROM Account_Bill__c
            WHERE Parent_Account__c = : accountParent.Id
            LIMIT 1
        ];

        ContentDocument document = [
            SELECT Id, LatestPublishedVersion.Title
            FROM ContentDocument
            WHERE LatestPublishedVersionId = : documentVersion.Id
            LIMIT 1
        ];

        LetterStreamService.LetterParameters params = new LetterStreamService.LetterParameters();
        params.generateFromAccountBill(accountBill, document);

        System.assertEquals(accountBill.Id, params.fileId);
        System.assertEquals('test_document.pdf', params.fileName);
        System.assertEquals('Account Parent', params.recipientName);
        System.assertEquals('123 Fake St', params.recipientStreet);
        System.assertEquals('City', params.recipientCity);
        System.assertEquals('Colorado', params.recipientState);
        System.assertEquals('80525', params.recipientPostalCode);
        System.assertEquals('4', params.pages);

        lss.addLetterToCSV(params);

        System.assertNotEquals('', lss.csv);

        // Recipient Info
        System.assert(lss.csv.contains('Account Parent'));
        System.assert(lss.csv.contains('test_document.pdf'));
        System.assert(lss.csv.contains('123 Fake St'));
        System.assert(lss.csv.contains('City'));
        System.assert(lss.csv.contains('Colorado'));
        System.assert(lss.csv.contains('80525'));
        System.assert(lss.csv.contains('4'));

        // BW Address info
        System.assert(lss.csv.contains('BlueWave Solar'));
        System.assert(lss.csv.contains('Boston'));

        // LetterStream Headers
        System.assert(lss.csv.contains('UniqueDocId'));
        System.assert(lss.csv.contains('PDFFileName'));
        System.assert(lss.csv.contains('RecipientName1'));
        System.assert(lss.csv.contains('RecipientAddr1'));
        System.assert(lss.csv.contains('RecipientAddr2'));
        System.assert(lss.csv.contains('RecipientCity'));
        System.assert(lss.csv.contains('RecipientState'));
        System.assert(lss.csv.contains('RecipientZip'));
        System.assert(lss.csv.contains('SenderName1'));
        System.assert(lss.csv.contains('SenderName2'));
        System.assert(lss.csv.contains('SenderAddr1'));
        System.assert(lss.csv.contains('SenderAddr2'));
        System.assert(lss.csv.contains('SenderCity'));
        System.assert(lss.csv.contains('SenderState'));
        System.assert(lss.csv.contains('SenderZip'));
        System.assert(lss.csv.contains('PageCount'));
        System.assert(lss.csv.contains('MailType'));
        System.assert(lss.csv.contains('CoverSheet'));
        System.assert(lss.csv.contains('Duplex'));
        System.assert(lss.csv.contains('Ink'));
        System.assert(lss.csv.contains('Paper'));
    }

    @IsTest
    public static void testBWAddress() {
        TestFactory.insertBWAddress();
        // BW Address info
        String bwAddress = 'BlueWave Solar,'; // SenderName1
        bwAddress += ','; //SenderName2 - blank
        bwAddress += '137 Newbury Street,'; //SenderAddr1
        bwAddress += '4th Floor,'; //SenderAddr2
        bwAddress += 'Boston,'; //SenderCity
        bwAddress += 'MA,'; //SenderState
        bwAddress += '02116,'; //SenderZip

        LetterStreamService lss = new LetterStreamService();

        String bwAddressUnderTest = lss.blueWaveAddress();

        System.assertEquals(bwAddress, bwAddressUnderTest);
    }

    @IsTest
    public static void testLetterStreamHeaders() {
        // Per LetterStream docs for authorization
        String uniqueId = '1234567890987654321';
        String apiId = 'BlueWave';
        String apiKey = 'BlueWaveAPIKEY';

        LetterStreamService lss = new LetterStreamService();
        Map<String, String> headers = lss.letterStreamHeaders(uniqueId, apiId, apiKey);


        // Per LetterStream docs for authorization
        // build string format: last 6 of uniqueId + apiKey + first 6 of uniqueId
        String expectedRawHashedId = '654321BlueWaveAPIKEY123456';
        // base64 encode string
        String expectedEncodedHashedId = EncodingUtil.base64Encode(Blob.valueOf(expectedRawHashedId));
        // MD5 encrypt base64 string and convertToHex (php format)
        String expectedHashedId = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(expectedEncodedHashedId)));

        System.assertEquals(apiId, headers.get('apiId'));
        System.assertEquals(uniqueId, headers.get('uniqueId'));
        System.assertEquals(expectedRawHashedId, headers.get('rawHashedId'));
        System.assertEquals(expectedEncodedHashedId, headers.get('encodedHashedId'));
        System.assertEquals(expectedHashedId, headers.get('hashedId'));
    }

    @IsTest
    public static void testLetterStreamRequest() {
        LetterStream_Settings__c ls = new LetterStream_Settings__c(
            Name = 'Global',
            API_Endpoint__c = 'https://secure.letterstream.com/apis/',
            API_Id__c = 'bluewave',
            API_Key__c = 'bluewaveAPIKey'
        );
        insert ls;

        LetterStreamService lss = new LetterStreamService();
        Blob testFile = Blob.valueOf('test file');

        HttpRequest testRequest = lss.buildRequestWithFile(testFile, 'test_file.zip');

        System.assertEquals('https://secure.letterstream.com/apis/', testRequest.getEndpoint());

        String contentType = 'multipart/form-data; boundary=----------------------------741e90d31eff';
        System.assertEquals(contentType, testRequest.getHeader('Content-Type'));
        System.assertEquals('POST', testRequest.getMethod());
    }

    @IsTest
    public static void testSendLetters() {
        TestFactory.insertBWAddress();
        TestFactory.insertLetterStreamSettings();

        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent1 = new Account(
            name = 'Account Parent',
            RecordTypeId = parentAccountRT,
            BillingStreet = '123 Fake St',
            BillingCity = 'City',
            BillingState = 'Colorado',
            BillingPostalCode = '80525'
        );

        Account accountParent2 = new Account(
            name = 'Account Parent',
            RecordTypeId = parentAccountRT,
            BillingStreet = '123 Fake St',
            BillingCity = 'City',
            BillingState = 'Colorado',
            BillingPostalCode = '80525'
        );

        Account accountParent3 = new Account(
            name = 'Account Parent',
            RecordTypeId = parentAccountRT,
            BillingStreet = '123 Fake St',
            BillingCity = 'City',
            BillingState = 'Colorado',
            BillingPostalCode = '80525'
        );
        insert new List<Account>{accountParent1, accountParent2, accountParent3};
        List<Id> accountIds = new List<Id>{accountParent1.Id, accountParent2.Id, accountParent3.Id};

        ContentVersion documentVersion1 = new ContentVersion(
            Title = 'test document',
            PathOnClient = 'test_Doc.pdf',
            VersionData = Blob.valueOf('testDoc')
        );
        ContentVersion documentVersion2 = new ContentVersion(
            Title = 'test document',
            PathOnClient = 'test_Doc.pdf',
            VersionData = Blob.valueOf('testDoc')
        );
        ContentVersion documentVersion3 = new ContentVersion(
            Title = 'test document',
            PathOnClient = 'test_Doc.pdf',
            VersionData = Blob.valueOf('testDoc')
        );
        Util.insertSObjs(new List<ContentVersion>{documentVersion1, documentVersion2, documentVersion3});
        List<Id> contentVersionIds = new List<Id>{documentVersion1.Id, documentVersion2.Id, documentVersion3.Id};

        List<ContentDocument> contentDocuments = [
            SELECT Id, LatestPublishedVersionId
            FROM ContentDocument
            WHERE LatestPublishedVersionId IN : contentVersionIds
        ];

        Account_Bill__c accountBill1 = new Account_Bill__c(
            Parent_Account__c = accountParent1.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Attach_Version__c = contentDocuments[0].LatestPublishedVersionId,
            Bill_Attach_Document__c = contentDocuments[0].Id,
            Bill_PDF_Page_Count__c = 4 // this value gets set by the conga conductor when bill pdfs are createdI
        );

        Account_Bill__c accountBill2 = new Account_Bill__c(
            Parent_Account__c = accountParent2.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Attach_Version__c = contentDocuments[1].LatestPublishedVersionId,
            Bill_Attach_Document__c = contentDocuments[1].Id,
            Bill_PDF_Page_Count__c = 4 // this value gets set by the conga conductor when bill pdfs are createdI
        );

        Account_Bill__c accountBill3 = new Account_Bill__c(
            Parent_Account__c = accountParent3.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Attach_Version__c = contentDocuments[2].LatestPublishedVersionId,
            Bill_Attach_Document__c = contentDocuments[2].Id,
            Bill_PDF_Page_Count__c = 4 // this value gets set by the conga conductor when bill pdfs are createdI
        );
        List<Account_Bill__c> accountBills = new List<Account_Bill__c>{accountBill1, accountBill2, accountBill3};
        insert accountBills;

        Set<Id> documentsToTest = new Set<Id>();
        for (ContentDocument doc : contentDocuments) {
            documentsToTest.add(doc.Id);
        }
        Set<Id> accountBillsToTest = new Set<Id>{accountBill1.Id, accountBill2.Id, accountBill3.Id};

        Datetime now = Datetime.now();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LetterStreamAPIMock(accountBills));
        QueueAccountBillLetterStreamMailer.Params params = new QueueAccountBillLetterStreamMailer.Params();
        params.accountBills = accountBillsToTest;
        params.documentsIds = documentsToTest;
        params.makeCallout = true;
        QueueAccountBillLetterStreamMailer mailer = new QueueAccountBillLetterStreamMailer(params);
        mailer.sendAccountBills();
        Test.stopTest();

        List<Account_Bill__c> accountBillsAfterSend = [
            SELECT Id, Published__c, Ready_For_Paper_Bill_Queue__c, Added_To_Paper_Bill_Queue__c, LetterStreamJob__c
            FROM Account_Bill__c
            WHERE Id IN : accountBillsToTest
        ];


        List<LetterStreamJob__c> jobs = [
            SELECT Id
            FROM LetterStreamJob__c
            WHERE CreatedDate > : now.addSeconds(-5)
        ];

        List<Id> jobIds = new List<Id>();
        for (LetterStreamJob__c job : jobs) {
            jobIds.add(job.Id);
        }

        System.assertEquals(1, jobs.size());

        for (Account_Bill__c accountBill : accountBillsAfterSend) {
            if (accountBill.Published__c) {
                System.assertEquals(false, accountBill.Ready_For_Paper_Bill_Queue__c);
                System.assertEquals(true, accountBill.Added_To_Paper_Bill_Queue__c);
                System.assertNotEquals(null, accountBill.LetterStreamJob__c);
            }
        }

        List<ContentDocument> attachments = [
            SELECT Id, Title, LatestPublishedVersion.FirstPublishLocationId
            FROM ContentDocument
            WHERE LatestPublishedVersion.FirstPublishLocationId IN : jobIds
        ];

        System.assertEquals(jobs.size(), attachments.size());
    }

    @IsTest
    public static void testQueueSendLetters() {
        TestFactory.insertBWAddress();
        TestFactory.insertLetterStreamSettings();


        Datetime now = Datetime.now();

        List<AsyncApexJob> originalAsyncApexJobs = [
            SELECT Id
            FROM AsyncApexJob
            WHERE CreatedDate > : now.addSeconds(-1)
        ];


        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent1 = new Account(
            name = 'Account Parent',
            RecordTypeId = parentAccountRT,
            BillingStreet = '123 Fake St',
            BillingCity = 'City',
            BillingState = 'Colorado',
            BillingPostalCode = '80525'
        );

        Account accountParent2 = new Account(
            name = 'Account Parent',
            RecordTypeId = parentAccountRT,
            BillingStreet = '123 Fake St',
            BillingCity = 'City',
            BillingState = 'Colorado',
            BillingPostalCode = '80525'
        );

        Account accountParent3 = new Account(
            name = 'Account Parent',
            RecordTypeId = parentAccountRT,
            BillingStreet = '123 Fake St',
            BillingCity = 'City',
            BillingState = 'Colorado',
            BillingPostalCode = '80525'
        );

        Account accountParent4 = new Account(
            name = 'Account Parent',
            RecordTypeId = parentAccountRT
        );
        insert new List<Account>{accountParent1, accountParent2, accountParent3, accountParent4};

        ContentVersion documentVersion1 = new ContentVersion(
            Title = 'test document',
            PathOnClient = 'test_Doc.pdf',
            VersionData = Blob.valueOf('testDoc')
        );
        ContentVersion documentVersion2 = new ContentVersion(
            Title = 'test document',
            PathOnClient = 'test_Doc.pdf',
            VersionData = Blob.valueOf('testDoc')
        );
        ContentVersion documentVersion3 = new ContentVersion(
            Title = 'test document',
            PathOnClient = 'test_Doc.pdf',
            VersionData = Blob.valueOf('testDoc')
        );
        Util.insertSObjs(new List<ContentVersion>{documentVersion1, documentVersion2, documentVersion3});
        List<Id> contentVersionIds = new List<Id>{documentVersion1.Id, documentVersion2.Id, documentVersion3.Id};

        List<ContentDocument> contentDocuments = [
            SELECT Id, LatestPublishedVersionId
            FROM ContentDocument
            WHERE LatestPublishedVersionId IN : contentVersionIds
        ];

        Account_Bill__c accountBill1 = new Account_Bill__c(
            Parent_Account__c = accountParent1.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Attach_Version__c = contentDocuments[0].LatestPublishedVersionId,
            Bill_Attach_Document__c = contentDocuments[0].Id,
            Bill_PDF_Page_Count__c = 4 // this value gets set by the conga conductor when bill pdfs are createdI
        );

        Account_Bill__c accountBill2 = new Account_Bill__c(
            Parent_Account__c = accountParent2.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Attach_Version__c = contentDocuments[1].LatestPublishedVersionId,
            Bill_Attach_Document__c = contentDocuments[1].Id,
            Bill_PDF_Page_Count__c = 4 // this value gets set by the conga conductor when bill pdfs are createdI
        );

        Account_Bill__c accountBill3 = new Account_Bill__c(
            Parent_Account__c = accountParent3.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Attach_Version__c = contentDocuments[2].LatestPublishedVersionId,
            Bill_Attach_Document__c = contentDocuments[2].Id,
            Bill_PDF_Page_Count__c = 4 // this value gets set by the conga conductor when bill pdfs are createdI
        );
        Account_Bill__c accountBill4 = new Account_Bill__c(
            Parent_Account__c = accountParent4.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Attach_Version__c = contentDocuments[2].LatestPublishedVersionId,
            Bill_Attach_Document__c = contentDocuments[2].Id,
            Bill_PDF_Page_Count__c = 4 // this value gets set by the conga conductor when bill pdfs are createdI
        );
        List<Account_Bill__c> accountBills = new List<Account_Bill__c>{accountBill1, accountBill2, accountBill3, accountBill4};
        insert accountBills;

        now = Datetime.now();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LetterStreamAPIMock(accountBills));

        AccountBillLetterStreamImpl accountBillController = new AccountBillLetterStreamImpl();
        accountBillController.makeCallout = false;
        // Each document is 7 bytes, for a total of 21 bytes. We allow some overflow on packages
        // this will generate two packages, 1st with 14 bytes and 2nd with 7 bytes.
        accountBillController.maxPackageSize = 10;
        accountBillController.queueAccountBillsToSend(AccountBillSelector.getAccountBillsReadyToBeSent(null));
        Test.stopTest();

        RecordType customerCare = [
            SELECT Id, Name
            FROM RecordType
            WHERE SobjectType = 'Case' AND DeveloperName = 'Customer_Care'
            LIMIT 1
        ];

        // assert case was created for accountParent4 with missing address
        List<Case> cases = [
            SELECT Id, RecordTypeId, AccountId, Product_Line__c, Subject
            FROM Case
        ];

        System.assertEquals(1, cases.size());
        System.assertEquals(accountParent4.Id, cases[0].AccountId);
        System.assertEquals(customerCare.Id, cases[0].RecordTypeId);
        System.assertEquals('Community Solar', cases[0].Product_Line__c);
        System.assertEquals('Cannot send bill to Community Solar customer.', cases[0].Subject);
    }

    @IsTest
    public static void testSendLettersAvoidHeapSize() {
        TestFactory.insertBWAddress();
        TestFactory.insertLetterStreamSettings();


        Datetime now = Datetime.now();

        List<AsyncApexJob> originalAsyncApexJobs = [
            SELECT Id
            FROM AsyncApexJob
            WHERE CreatedDate > : now.addSeconds(-1)
        ];


        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Integer numberOfAccounts = 10;

        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < numberOfAccounts; i++) {
            accounts.add(new Account(
                name = 'Account Parent',
                RecordTypeId = parentAccountRT,
                BillingStreet = '123 Fake St',
                BillingCity = 'City',
                BillingState = 'Colorado',
                BillingPostalCode = '80525'
            ));
        }
        insert accounts;

        Account accountParentInvalid = new Account(
            name = 'Account Parent',
            RecordTypeId = parentAccountRT
        );
        insert accountParentInvalid;

        // try to exceed heap size
        StaticResource static_resource = [SELECT Id, Body
            FROM StaticResource
            WHERE Name = 'LargeFileTest'
            LIMIT 1
        ];
        List<ContentVersion> docs = new List<ContentVersion>();
        for (Integer i = 0; i < numberOfAccounts + 1; i++) {
            docs.add(new ContentVersion(
                Title = 'test document',
                PathOnClient = 'test_Doc.pdf',
                VersionData = static_resource.Body
            ));
        }

        Util.insertSObjs(docs);
        List<Id> contentVersionIds = new List<Id>{};
        for (ContentVersion doc : docs) {
            contentVersionIds.add(doc.Id);
        }

        List<ContentDocument> contentDocuments = [
            SELECT Id, LatestPublishedVersionId
            FROM ContentDocument
            WHERE LatestPublishedVersionId IN : contentVersionIds
        ];

        List<Account_Bill__c> accountBills = new List<Account_Bill__c>();
        for (Integer i = 0; i < numberOfAccounts; i++) {
            accountBills.add(new Account_Bill__c(
                Parent_Account__c = accounts[i].Id,
                Bill_Number__c = 2,
                Published__c = true,
                Ready_For_Paper_Bill_Queue__c = true,
                Bill_Attach_Version__c = contentDocuments[i].LatestPublishedVersionId,
                Bill_Attach_Document__c = contentDocuments[i].Id,
                Bill_PDF_Page_Count__c = 4 // this value gets set by the conga conductor when bill pdfs are createdI
            ));
        }

        accountBills.add(new Account_Bill__c(
            Parent_Account__c = accountParentInvalid.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Attach_Version__c = contentDocuments[numberOfAccounts].LatestPublishedVersionId,
            Bill_Attach_Document__c = contentDocuments[numberOfAccounts].Id,
            Bill_PDF_Page_Count__c = 4 // this value gets set by the conga conductor when bill pdfs are createdI
        ));
        insert accountBills;

        now = Datetime.now();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LetterStreamAPIMock(accountBills));
        InvocableCSBillLetterStreamSend.sendLetters();

        Test.stopTest();

        RecordType customerCare = [
            SELECT Id, Name
            FROM RecordType
            Where SobjectType = 'Case' and DeveloperName = 'Customer_Care'
            LIMIT 1
        ];

        // assert case was created for accountParent4 with missing address
        List<Case> cases = [
            SELECT Id, RecordTypeId, AccountId, Product_Line__c, Subject
            FROM Case
        ];

        System.assertEquals(1, cases.size());
        System.assertEquals(accountParentInvalid.Id, cases[0].AccountId);
        System.assertEquals(customerCare.Id, cases[0].RecordTypeId);
        System.assertEquals('Community Solar', cases[0].Product_Line__c);
        System.assertEquals('Cannot send bill to Community Solar customer.', cases[0].Subject);
    }

    @IsTest
    public static void testCheckAddressBeforeSending() {
        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent1 = new Account(
            name = 'Account With Address',
            RecordTypeId = parentAccountRT,
            BillingStreet = '123 Fake St',
            BillingCity = 'City',
            BillingState = 'Colorado',
            BillingPostalCode = '80525'
        );

        Account accountParent2 = new Account(
            name = 'Account Without Full Address',
            RecordTypeId = parentAccountRT
        );

        Account accountParent3 = new Account(
            name = 'Account With Only Street',
            BillingStreet = '123 Fake St',
            RecordTypeId = parentAccountRT
        );

        Account accountParent4 = new Account(
            name = 'Account With Only City',
            BillingCity = 'City',
            RecordTypeId = parentAccountRT
        );

        Account accountParent5 = new Account(
            name = 'Account With Only State',
            BillingState = 'Colorado',
            RecordTypeId = parentAccountRT
        );

        Account accountParent6 = new Account(
            name = 'Account With Only Zip',
            BillingPostalCode = '80525',
            RecordTypeId = parentAccountRT
        );

        insert new List<Account>{accountParent1, accountParent2, accountParent3, accountParent4, accountParent5, accountParent6};

        Account_Bill__c accountBill1 = new Account_Bill__c(
            Parent_Account__c = accountParent1.Id,
            Bill_Number__c = 1
        );

        Account_Bill__c accountBill2 = new Account_Bill__c(
            Parent_Account__c = accountParent2.Id,
            Bill_Number__c = 2
        );

        Account_Bill__c accountBill3 = new Account_Bill__c(
            Parent_Account__c = accountParent3.Id,
            Bill_Number__c = 3
        );

        Account_Bill__c accountBill4 = new Account_Bill__c(
            Parent_Account__c = accountParent4.Id,
            Bill_Number__c = 4
        );

        Account_Bill__c accountBill5 = new Account_Bill__c(
            Parent_Account__c = accountParent5.Id,
            Bill_Number__c = 5
        );

        Account_Bill__c accountBill6 = new Account_Bill__c(
            Parent_Account__c = accountParent6.Id,
            Bill_Number__c = 6
        );

        insert new List<Account_Bill__c>{accountBill1, accountBill2, accountBill3, accountBill4, accountBill5, accountBill6};

        List<Account_Bill__c> accountBills = [
            SELECT Id, Parent_Account__r.Name, Parent_Account__r.BillingStreet, Parent_Account__r.BillingCity,
                Parent_Account__r.BillingState, Parent_Account__r.BillingPostalCode, Bill_PDF_Page_Count__c,
                Calendar_Month__c, Year__c, Bill_Attach_Document__c
            FROM Account_Bill__c
            ORDER BY Bill_Number__c ASC
        ];

        AccountBillLetterStreamImpl accountBillController = new AccountBillLetterStreamImpl();
        // Return True assertions
        System.assert(accountBillController.checkBillAccountAddressValid(accountBills[0]));
        // Return False assertions
        System.assert(!accountBillController.checkBillAccountAddressValid(accountBills[1]));
        System.assert(!accountBillController.checkBillAccountAddressValid(accountBills[2]));
        System.assert(!accountBillController.checkBillAccountAddressValid(accountBills[3]));
        System.assert(!accountBillController.checkBillAccountAddressValid(accountBills[4]));
        System.assert(!accountBillController.checkBillAccountAddressValid(accountBills[5]));
    }

    @IsTest
    public static void testCreateCaseForInvalidAddress() {
        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent1 = new Account(
            name = 'Account With Address',
            RecordTypeId = parentAccountRT,
            BillingStreet = '123 Fake St',
            BillingCity = 'City',
            BillingState = 'Colorado',
            BillingPostalCode = '80525'
        );
        insert accountParent1;

        Account_Bill__c accountBill1 = new Account_Bill__c(
            Parent_Account__c = accountParent1.Id,
            Bill_Number__c = 1
        );
        insert accountBill1;

        List<Account_Bill__c> accountBills = [
            SELECT Id, Parent_Account__r.Name, Parent_Account__r.BillingStreet, Parent_Account__r.BillingCity,
                Parent_Account__r.BillingState, Parent_Account__r.BillingPostalCode, Bill_PDF_Page_Count__c,
                Calendar_Month__c, Year__c, Bill_Attach_Document__c
            FROM Account_Bill__c
            ORDER BY Bill_Number__c ASC
        ];

        System.assertEquals(1, accountBills.size());

        AccountBillLetterStreamImpl accountBillController = new AccountBillLetterStreamImpl();
        Case testCase = accountBillController.createCaseForInvalidAddress(accountBills[0]);

        RecordType customerCare = [
            SELECT Id, Name
            FROM RecordType
            Where SobjectType = 'Case' and DeveloperName = 'Customer_Care'
            LIMIT 1
        ];

        System.assertEquals('Medium', testCase.Priority);
        String message = 'Description should contain instructions on how to prevent paper bills to be sent';
        System.assert(testCase.Description.contains('Opt Out of Paper Billing'), message);
        System.assertEquals(accountParent1.Id, testCase.AccountId);
        System.assertEquals(customerCare.Id, testCase.RecordTypeId);
    }

    @IsTest
    public static void testHandleFailedResponse() {
        TestFactory.insertBWAddress();
        TestFactory.insertLetterStreamSettings();

        Datetime now = Datetime.now();

        List<AsyncApexJob> originalAsyncApexJobs = [
            SELECT Id
            FROM AsyncApexJob
            WHERE CreatedDate > : now.addSeconds(-1)
        ];

        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent1 = new Account(
            name = 'Account Parent',
            RecordTypeId = parentAccountRT,
            BillingStreet = '123 Fake St',
            BillingCity = 'City',
            BillingState = 'Colorado',
            BillingPostalCode = '80525'
        );
        insert accountParent1;

        ContentVersion documentVersion1 = new ContentVersion(
            Title = 'test document',
            PathOnClient = 'test_Doc.pdf',
            VersionData = Blob.valueOf('testDoc')
        );
        Util.insertSObjs(new List<ContentVersion>{documentVersion1});
        List<Id> contentVersionIds = new List<Id>{documentVersion1.Id};

        List<ContentDocument> contentDocuments = [
            SELECT Id, LatestPublishedVersionId, LatestPublishedVersion.Title
            FROM ContentDocument
            WHERE LatestPublishedVersionId IN : contentVersionIds
        ];

        Account_Bill__c accountBill1 = new Account_Bill__c(
            Parent_Account__c = accountParent1.Id,
            Bill_Number__c = 1,
            Published__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Attach_Version__c = contentDocuments[0].LatestPublishedVersionId,
            Bill_Attach_Document__c = contentDocuments[0].Id,
            Bill_PDF_Page_Count__c = 4 // this value gets set by the conga conductor when bill pdfs are createdI
        );

        List<Account_Bill__c> accountBills = new List<Account_Bill__c>{accountBill1};
        insert accountBills;

        accountBills = [
            SELECT Id, Parent_Account__r.Name, Parent_Account__r.BillingStreet, Parent_Account__r.BillingCity,
                Parent_Account__r.BillingState, Parent_Account__r.BillingPostalCode, Bill_PDF_Page_Count__c,
                Calendar_Month__c, Year__c, Bill_Attach_Document__c
            FROM Account_Bill__c
            ORDER BY Bill_Number__c ASC
        ];

        Map<Id, Account_Bill__c> accountBillsByDocIds = new Map<Id, Account_Bill__c>();
        for (Account_Bill__c accountBill : accountBills) {
            accountBillsByDocIds.put(accountBill.Bill_Attach_Document__c, accountBill);
        }

        Set<Id> documentsToTest = new Set<Id>();
        for (ContentDocument doc : contentDocuments) {
            documentsToTest.add(doc.Id);
        }
        Set<Id> accountBillsToTest = new Set<Id>{accountBill1.Id};

        // need to mock the failed response
        String responseXMLString = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<messages id="86fjkb92">' +
            '<message type="info">' +
            '<code>-900</code>' +
            '<details>Failed: Job name must be 8 to 20 characters (a-zA-Z0-9_-)</details>' +
            '</message>' +
            '</messages>';

        // we don't use the csv on the first failed response, if accountBills.size() > 1
        String csv = '';

        now = Datetime.now();

        Test.startTest();
        QueueAccountBillLetterStreamMailer.handleResponse(responseXMLString, accountBillsToTest, csv);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [
            SELECT Id, Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE CreatedDate > : now.addSeconds(-1)
        ];

        List<AsyncApexJob> asyncApexJobs = [
            SELECT Id
            FROM AsyncApexJob
            WHERE CreatedDate > : now.addSeconds(-1)
        ];

        // sometimes overlaps with other requests
        // should not queue any new jobs, because the original job failed with 1 bill
        System.assertEquals(originalAsyncApexJobs.size(), asyncApexJobs.size());
        System.assertEquals(1, errorLogs.size());
    }
}