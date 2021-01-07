@IsTest
private with sharing class GlyntUploadServiceTest {
    @TestSetup
    private static void testSetup() {
        Cache.Org.put('GlyntAuthToken', '123qweasd');
        Utility_Account_Log__c ual = new Utility_Account_Log__c(Name = '123');
        insert ual;
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('Utility Bill'),
            Title = 'UtilityBill.pdf',
            PathOnClient = '/UtilityBill.pdf'
        );
        insert cv;
        ContentDocument cd = [
            SELECT Id
            FROM ContentDocument
            WHERE LatestPublishedVersionId = :cv.Id
        ];
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = ual.Id,
            Visibility = 'AllUsers',
            ShareType = 'V',
            ContentDocumentId = cd.Id
        );
        insert cdl;
    }
    @IsTest
    private static void testContentAssociationAndQueueingUpload() {
        Utility_Account_Log__c ual = [SELECT Id FROM Utility_Account_Log__c WHERE Name = '123' LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GlyntMockUploadFailure());
        Utility_Data_Request__c udr = new Utility_Data_Request__c(
            Utility_Account_Log__c = ual.Id,
            Service_Provider__c = 'Glynt'
        );
        insert udr;
        Test.stopTest();

        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :udr.Id
        ];
        System.assertEquals(1, contentDocumentLinks.size(), 'Expected the Utility Bill to be linked to the new UDR');

        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'GlyntUploadService'
            AND Severity__c = 'Error'
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected an error when executing the queueable');
        // Between start/stop test, UDRTrigger commits the enqueueJob, but stopTest runs the queueable should should callout
        // to create the document. If it tries, we should get an uncommitted work pending error:
        System.assert(errorLogs[0].Message__c.contains('You have uncommitted work pending'),
            'We expect the queueable to execute which does the createDocument callout resulting in an exception, but got this: ' +
                errorLogs[0].Message__c);
    }

    @IsTest
    private static void testUDRsForESG() {
        Utility_Account_Log__c ual = [SELECT Id FROM Utility_Account_Log__c WHERE Name = '123' LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GlyntMockUploadFailure());
        Utility_Data_Request__c udr = new Utility_Data_Request__c(
            Utility_Account_Log__c = ual.Id,
            Service_Provider__c = 'ESG'
        );
        insert udr;
        Test.stopTest();

        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :udr.Id
        ];
        System.assertEquals(1, contentDocumentLinks.size(), 'Expected the Utility Bill to be linked to the new UDR');

        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'GlyntUploadService'
            AND Severity__c = 'Error'
        ];
        System.assertEquals(0, errorLogs.size(), 'Did not expect to try to upload, so there should be no error about uncommitted work');
    }

    @IsTest
    private static void testUploadAndExtract() {
        GlyntUploadService.extractionService = (GlyntExtractionService) Test.createStub(GlyntExtractionService.class, new MockedGlyntExtractionService());
        // Unfortunately, I wasn't able to mock with VersionData
        Utility_Account_Log__c ual = [SELECT Id FROM Utility_Account_Log__c WHERE Name = '123' LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GlyntMockUploadSuccess());
        GlyntUploadService uploadService = new GlyntUploadService();
        // GlyntUploadService will upload a doc from any object, it doesn't need to be a UDR
        uploadService.utilityDataRequestsToUpload = new Set<Id>{ual.Id};
        uploadService.execute(null);
        Test.stopTest();
        System.assertEquals(1, GlyntAPIHelper.endpointsCalled.size(), 'Expected one callout to createDocument');
        System.assert(GlyntAPIHelper.endpointsCalled[0].endpoint.contains('document'),
            'Expected to post to /v6/data-pools/dataPoolId/documents, but got: ' + GlyntAPIHelper.endpointsCalled[0].endpoint);
        System.assert(GlyntAPIHelper.endpointsCalled[0].jsonBody.contains('content'),
            'Should have sent a GlyntAPI.DocumentUpload, but sent: ' + GlyntAPIHelper.endpointsCalled[0].jsonBody);
        System.assertNotEquals(GlyntUploadService.extractionRetrievalService, null,
            'Should have set a queueable to retrieve the extraction results');
    }

    @IsTest
    private static void testUploadFailure() {
        Utility_Account_Log__c ual = [SELECT Id FROM Utility_Account_Log__c WHERE Name = '123' LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GlyntMockUploadFailure());
        GlyntUploadService uploadService = new GlyntUploadService();
        uploadService.utilityDataRequestsToUpload = new Set<Id>{ual.Id};
        uploadService.execute(null);
        Test.stopTest();
        System.assertEquals(1, GlyntAPIHelper.endpointsCalled.size(), 'Expected one callout to createDocument');
        System.assert(GlyntAPIHelper.endpointsCalled[0].endpoint.contains('document'),
            'Expected to post to /v6/data-pools/dataPoolId/documents, but got: ' + GlyntAPIHelper.endpointsCalled[0].endpoint);
        System.assertEquals(null, GlyntUploadService.extractionRetrievalService,
            'Should have gotten an exception before queueing the retrieval service');
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'GlyntUploadService'
            AND Severity__c = 'Error'
        ];
        System.assertEquals(1, errorLogs.size(), 'Should have gotten one error log');
        System.assert(errorLogs[0].Message__c.contains('Status Code: 415'),
            'Should have gotten the response code and body in the error log, but got: ' + errorLogs[0].Message__c);
    }

    /*************
      *** MOCKS ***
      *************/
    private class GlyntMockUploadFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setHeader('Content-Type', 'application/json');
            httpResponse.setStatusCode(415); // Unsupported Media Type -- Your request payload is in a format not supported by this resource.
            return httpResponse;
        }
    }

    private class GlyntMockUploadSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setHeader('Content-Type', 'application/json');
            httpResponse.setStatusCode(201);
            httpResponse.setBody('{"id":"123qwe"}');
            return httpResponse;
        }
    }

    public class MockedGlyntExtractionService extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            GlyntAPI.ExtractionResponse extractionResponse = new GlyntAPI.ExtractionResponse('Complete', true);
            extractionResponse.id = 'extractionId';
            return extractionResponse;
        }
    }

}