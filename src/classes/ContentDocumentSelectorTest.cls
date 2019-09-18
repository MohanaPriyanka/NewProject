/*************************************************************************************
 * Created By: peteryao on 9/12/19  
 *************************************************************************************/
@IsTest
public with sharing class ContentDocumentSelectorTest {
    @IsTest
    private static void testSelectById() {
        // I couldn't figure out how to mock the ContentDocumentSelector which returns a ContentDocument with
        // ContentVersion data. Deserializing JSON would results in various JSONExceptions.
        // So this will need to create the data
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body'),
            Title = 'InvoiceNumber.pdf',
            PathOnClient = '/InvoiceNumber.pdf'
        );
        insert cv;
        ContentVersion cv2 = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('longer invoice body should be sorted first'),
            Title = 'InvoiceNumber2.pdf',
            PathOnClient = '/InvoiceNumber2.pdf'
        );
        insert cv2;
        cv = [SELECT Id, ContentDocumentId, ContentDocument.ContentSize FROM ContentVersion WHERE Id = :cv.Id];
        cv2 = [SELECT Id, ContentDocumentId, ContentDocument.ContentSize FROM ContentVersion WHERE Id = :cv2.Id];

        ContentDocumentSelector documentSelector = new ContentDocumentSelector();
        Test.startTest();
        List<ContentDocument> contentDocuments =
            documentSelector.selectById(new Set<Id>{cv.ContentDocumentId, cv2.ContentDocumentId});
        Test.stopTest();
        System.assertEquals(2, contentDocuments.size());
        System.assertEquals('InvoiceNumber2.pdf', contentDocuments[0].LatestPublishedVersion.Title);
        System.assertEquals('InvoiceNumber.pdf', contentDocuments[1].LatestPublishedVersion.Title);
    }
}