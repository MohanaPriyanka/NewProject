@IsTest
private with sharing class PostGLDownloadServiceTest {
    @IsTest
    private static void testExecutePostBatch() {
        UniversalMocker journalEntrySelectorMock = UniversalMocker.mock(JournalEntrySelector.class);
        Journal_Entry__c jeReadyForPD = new Journal_Entry__c(
            Date__c = System.today(),
            External_Id__c = 'foo',
            Customer_Account__c = 'PE-1234',
            Ready_for_Production_Detail__c = true
        );
        // Since the P2B service will update this JE to uncheck Ready for PD, it can't be a mocked object, and we don't
        // want to try to find a SSS, Client, or Customer for this JE.
        Util.disableTrigger('Disable_Journal_Entry_Trigger__c');
        insert jeReadyForPD;
        journalEntrySelectorMock.when('getEntriesWithoutProductionDetail').thenReturn(new List<Journal_Entry__c>{jeReadyForPD});
        ProductionToBillService.journalEntrySelector = (JournalEntrySelector) journalEntrySelectorMock.createStub();

        GenericBatchDMLOperation batchDMLFromZuoraGLService =
            new GenericBatchDMLOperation(new List<Journal_Entry__c>(), 'Update');
        // The method that ZuoraGLService uses to execute the PostGLDownloadService
        batchDMLFromZuoraGLService.setPostBatchOperation('PostGLDownloadService');
        Test.startTest();
        Database.executeBatch(batchDMLFromZuoraGLService);
        Test.stopTest();
        List<Error_Log__c> errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR];
        System.assertEquals(0, errorLogs.size(),
            'Expected no error logs with severity of error, but got this: ' + errorLogs);
    }
}