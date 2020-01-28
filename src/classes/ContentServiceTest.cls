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
}