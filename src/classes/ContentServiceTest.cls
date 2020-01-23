@IsTest
public with sharing class ContentServiceTest {
    @IsTest
    public static void testSetContentVersion() {
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body'),
            Title = 'InvoiceNumber.pdf',
            PathOnClient = '/InvoiceNumber.pdf'
        );
        insert cv;

        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId
            FROM ContentDocument
        ];

        List<ContentVersion> cvBeforeUpdate = [
            SELECT Id, ContentDocumentId, File_Category__c
            FROM ContentVersion
            WHERE Id = : cv.Id
        ];
        System.assertEquals(null,cvBeforeUpdate[0].File_Category__c);

        ContentService.setCategoryOnContentVersion(documents[0].Id, 'Transfer Sheet');

        List<ContentVersion> cvAfterUpdate = [
            SELECT Id, ContentDocumentId, File_Category__c
            FROM ContentVersion
            WHERE Id =: cv.Id
        ];
        System.assertEquals('Transfer Sheet',cvAfterUpdate[0].File_Category__c);
    }
}