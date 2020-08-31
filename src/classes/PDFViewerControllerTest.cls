@isTest
public class PDFViewerControllerTest {
    @IsTest
    public static void getImportantDataPoints() {
        Account newAccount = new Account(Name = 'Test Account');
        insert newAccount;

        ContentVersion version = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body2'),
            Title = 'test2.pdf',
            PathOnClient = '/test2.pdf'
        );
        insert version;

        List<ContentVersion> cvList = [SELECT Id, ContentDocumentId FROM ContentVersion];

        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = cvList[0].ContentDocumentId,
            LinkedEntityId = newAccount.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;

        Map<Id, String> mapToCheck = PDFViewerController.getRelatedFilesByRecordId(newAccount.Id);
        System.assertNotEquals(null, mapToCheck.get(cvList[0].ContentDocumentId));
    }
}