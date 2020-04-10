@IsTest
public with sharing class ContentServiceTest {
    @IsTest
    public static void testSetContentVersion() {
        ContentVersion cvOne = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body'),
            Title = 'InvoiceNumber.pdf',
            PathOnClient = '/InvoiceNumber.pdf'
        );
        ContentVersion cvTwo = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body two'),
            Title = 'InvoiceNumberTwo.pdf',
            PathOnClient = '/InvoiceNumberTwo.pdf'
        );
        insert cvOne;
        insert cvTwo;

        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId
            FROM ContentDocument
        ];

        List<ContentVersion> cvBeforeUpdate = [
            SELECT Id, ContentDocumentId, File_Category__c
            FROM ContentVersion
            WHERE Id = : cvOne.Id
            OR Id = : cvTwo.Id
        ];
        System.assertEquals(null,cvBeforeUpdate[0].File_Category__c);
        System.assertEquals(null,cvBeforeUpdate[1].File_Category__c);

        List<Id> docIds = new List<Id>{documents[0].Id, documents[1].Id};
        ContentService.setCategoryOnContentVersion(docIds, 'Transfer Sheet');

        List<ContentVersion> cvAfterUpdate = [
            SELECT Id, ContentDocumentId, File_Category__c
            FROM ContentVersion
            WHERE Id = : cvOne.Id
            OR Id = : cvTwo.Id
        ];
        System.assertEquals('Transfer Sheet',cvAfterUpdate[0].File_Category__c);
        System.assertEquals('Transfer Sheet',cvAfterUpdate[1].File_Category__c);
    }

    @IsTest
    public static void testUploadFileToRecord(){
        Account accountOne = new Account(Name = 'Acct');
        insert accountOne;

        ContentService service = new ContentService();
        ContentDocumentLink link = service.uploadFileToRecordAndShareInternally('FileBody',accountOne.Id,'Filename.txt');

        ContentDocumentLink docLink = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE Id = : link.Id
            LIMIT 1
        ];

        System.assertEquals(accountOne.Id,docLink.LinkedEntityId);
    }

    @IsTest
    public static void testMakeContentDocLinksPrivate() {
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body'),
            Title = 'test1.pdf',
            PathOnClient = '/test1.pdf'
        );
        insert cv;

        Lead l = new Lead(
            FirstName = 'test',
            LastName = 'testerson',
            Company = 'test',
            Email = 'ttesterson@email.com',
            LeadSource = 'Switch'
        );
        insert l;

        ContentDocumentSelector selector = new ContentDocumentSelector();
        Id cdId = selector.getDocumentIdFromVersionId(cv.Id);

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cdId,
            LinkedEntityId = l.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;

        List<ContentDocument> cdList = [
            SELECT
                Id,
                (SELECT
                    Id,
                    Visibility
                FROM
                    ContentDocumentLinks
                WHERE
                    LinkedEntityId = :l.Id
                )
            FROM
                ContentDocument
        ];
        System.assertEquals(1, cdList.size(), 'There should be only one Content Document');
        System.assertEquals(1, cdList[0].ContentDocumentLinks.size(), 'There should be only one Content Document Link');
        System.assertEquals('AllUsers', cdList[0].ContentDocumentLinks[0].Visibility, 'The visibility of the Content Document Link should be AllUsers');

        ContentService service = new ContentService();
        Test.startTest();
            service.makeContentDocLinksPrivate(cdList);
        Test.stopTest();

        List<Error_Log__c> errList = [SELECT Id, Message__c FROM Error_Log__c];
        System.assert(errList.isEmpty(), 'There should be no errors');
        List<ContentDocumentLink> linkList = [SELECT Id, Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :l.Id];
        System.assertEquals(1, linkList.size(), 'There should be only one Content Document Link');
        System.assertEquals('InternalUsers', linkList[0].Visibility, 'The visibility of the Content Document Link should be InternalUsers');
    }
}