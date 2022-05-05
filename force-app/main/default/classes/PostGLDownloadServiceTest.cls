@IsTest
private with sharing class PostGLDownloadServiceTest {
    @IsTest
    private static void testExecutePostBatch() {
        PostGLDownloadService postGLDownloadService = new PostGLDownloadService();
        Test.startTest();
        postGLDownloadService.executePostBatch();
        Test.stopTest();
        List<Error_Log__c> errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR];
        System.assertEquals(0, errorLogs.size(),
            'Expected no error logs with severity of error, but got this: ' + errorLogs);
    }
}