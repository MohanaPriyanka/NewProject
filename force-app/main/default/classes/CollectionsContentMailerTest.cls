@IsTest
private with sharing class CollectionsContentMailerTest {
    @TestSetup
    private static void testSetup() {
        TestFactory.insertBWAddress();
        TestFactory.insertLetterStreamSettings();

        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Account.SObjectType,
                Contact.SObjectType,
                ContentVersion.SObjectType
            }
        );
        List<Account> propertyAccounts = new List<Account>();
        Account propertyOne = new Account(
            Name = 'Property One',
            BillingStreet = '1 Main',
            BillingCity = 'Boston',
            BillingState = 'Massachusetts',
            BillingPostalCode = '02117'
        );
        propertyAccounts.add(propertyOne);
        uow.registerNew(propertyOne);
        Contact sendBillsContactOne = new Contact(
            FirstName = 'Test',
            LastName = 'Contact'
        );
        uow.registerNew(sendBillsContactOne, Contact.AccountId, propertyOne);
        ContentVersion cvOne = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('collections body'),
            Title = 'Certified Collections.pdf',
            PathOnClient = '/Collections.pdf',
            Ready_for_Paper_Bill_Queue__c = true,
            Mail_Type__c = 'certified'
        );
        uow.registerNew(cvOne);

        Account propertyTwo = new Account(
            Name = 'Property Two',
            BillingStreet = '1 Main',
            BillingCity = 'Boston',
            BillingState = 'Massachusetts',
            BillingPostalCode = '02117'
        );
        propertyAccounts.add(propertyTwo);
        uow.registerNew(propertyTwo);
        Contact sendBillsContactTwo = new Contact(
            FirstName = 'Test',
            LastName = 'Contact'
        );
        uow.registerNew(sendBillsContactTwo, Contact.AccountId, propertyTwo);
        ContentVersion cvTwo = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('collections body'),
            Title = 'Firstclass Collections.pdf',
            PathOnClient = '/Collections.pdf',
            Ready_for_Paper_Bill_Queue__c = true
        );
        uow.registerNew(cvTwo);

        Account propertyThree = new Account(
            Name = 'Property Three',
            BillingStreet = '1 Main',
            BillingCity = 'Boston',
            BillingState = 'Massachusetts',
            BillingPostalCode = '02117'
        );
        propertyAccounts.add(propertyThree);
        uow.registerNew(propertyThree);
        Contact sendBillsContactThree = new Contact(
            FirstName = 'Test',
            LastName = 'Contact'
        );
        uow.registerNew(sendBillsContactThree, Contact.AccountId, propertyThree);
        ContentVersion cvThree = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('collections body'),
            Title = 'Collections.pdf',
            PathOnClient = '/Collections.pdf',
            Added_to_Paper_Bill_Queue__c = true
        );
        uow.registerNew(cvThree);

        ContentVersion cvFour = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('collections body'),
            Title = 'Collections unlinked to account.pdf',
            PathOnClient = '/Collections.pdf',
            Ready_for_Paper_Bill_Queue__c = true
        );
        uow.registerNew(cvFour);

        uow.commitWork();
        propertyOne.Send_Bills_Contact__c = sendBillsContactOne.Id;
        propertyTwo.Send_Bills_Contact__c = sendBillsContactTwo.Id;
        propertyThree.Send_Bills_Contact__c = sendBillsContactThree.Id;
        update propertyAccounts;

        List<ContentVersion> contentVersions = [
            SELECT Id, ContentDocumentId, Title
            FROM ContentVersion
            WHERE Title != 'Collections unlinked to account.pdf'
        ];
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for (ContentVersion contentVersion : contentVersions) {
            Id linkedEntityId;
            switch on contentVersion.Title {
                when 'Certified Collections.pdf' {
                    linkedEntityId = propertyOne.Id;
                } when 'Firstclass Collections.pdf' {
                    linkedEntityId = propertyTwo.Id;
                } when else {
                    linkedEntityId = propertyThree.Id;
                }
            }
            contentDocumentLinks.add(new ContentDocumentLink(
                ContentDocumentId = contentVersion.ContentDocumentId,
                LinkedEntityId = linkedEntityId,
                ShareType = 'I'
            ));
        }
        insert contentDocumentLinks;
    }

    @IsTest
    private static void testSendCollectionsLetters() {
        Test.setMock(HttpCalloutMock.class, new LetterStreamAPIMock());

        List<ContentVersion> contentVersions = [
            SELECT Id, Title, Mail_Type__c, Added_to_Paper_Bill_Queue__c
            FROM ContentVersion
            WHERE Ready_for_Paper_Bill_Queue__c = TRUE
        ];
        System.assertEquals(3, contentVersions.size(), 'TestSetup should have three letters to send, but set up these: ' + contentVersions);

        Test.startTest();
        new CollectionsContentMailer().execute(null);
        Test.stopTest();

        List<String> csvLines = ContentMailerService.lss.csv.split('\n');
        System.assertEquals(3, csvLines.size(), 'Expected three lines in the csv sent to LetterStream: the header and two documents');
        for (String csvLine : csvLines) {
            if (csvLine.contains('Certified_Collections.pdf')) {
                System.assert(csvLine.contains(',certified,'), 'The certified letter should be mailed certified, but got this: ' + csvLine);
            } else if (csvLine.contains('Firstclass_Collections.pdf')) {
                System.assert(csvLine.contains(',firstclass,'), 'The letter with no Mail Type should be mailed firstclass, but got this: ' + csvLine);
            }
        }

        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'CollectionsContentMailer'
            AND Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size(), errorLogs);
        System.assert(errorLogs[0].Message__c.contains('Did not find an Account related to Content Doc'),
            'Expected an error about not finding an account related to a Content Document, but got this: ' + errorLogs[0].Message__c);

        contentVersions = [
            SELECT Id, Title, Mail_Type__c, Added_to_Paper_Bill_Queue__c
            FROM ContentVersion
            WHERE Ready_for_Paper_Bill_Queue__c = TRUE
        ];
        System.assertEquals(1, contentVersions.size(),
            'After mailing, there should be one content still ready for the paper bill queue (the one not linked to an account), but got these: ' + contentVersions);
    }
}