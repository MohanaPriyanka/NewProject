@IsTest
private with sharing class GlyntUploadServiceTest {
    @TestSetup
    private static void testSetup() {
        Cache.Org.put('GlyntAuthToken', '123qweasd');
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Test',
            Email = 'test@test.com',
            Company = 'Test'
        );
        insert lead;
        Utility__c utility = new Utility__c(
            Utility_Data_Collection_Mechanism__c = 'File Upload',
            Use_Glynt__c = true
        );
        insert utility;
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Name = '123',
            Lead__c = lead.Id,
            Utility_lookup__c = utility.Id
        );
        Utility_Account_Log__c ual2 = new Utility_Account_Log__c(
            Name = '456',
            Lead__c = lead.Id,
            Utility_lookup__c = utility.Id
        );
        insert new List<Utility_Account_Log__c>{ual, ual2};
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('Utility Bill'),
            Title = 'UtilityBill.pdf',
            PathOnClient = '/UtilityBill.pdf'
        );
        ContentVersion cv2 = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('Utility Bill2'),
            Title = 'UtilityBill2.pdf',
            PathOnClient = '/UtilityBill2.pdf'
        );
        ContentVersion cv3 = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('Utility Bill'),
            Title = 'UtilityBill3.pdf',
            PathOnClient = '/UtilityBill3.pdf'
        );
        insert new List<ContentVersion>{cv, cv2, cv3};
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
        ContentDocument cd2 = [
            SELECT Id
            FROM ContentDocument
            WHERE LatestPublishedVersionId = :cv2.Id
        ];
        ContentDocumentLink cdl2 = new ContentDocumentLink(
            LinkedEntityId = ual.Id,
            Visibility = 'AllUsers',
            ShareType = 'V',
            ContentDocumentId = cd2.Id
        );
        ContentDocumentLink cdl3 = new ContentDocumentLink(
            LinkedEntityId = ual2.Id,
            Visibility = 'AllUsers',
            ShareType = 'V',
            ContentDocumentId = cd.Id
        );
        insert new List<ContentDocumentLink>{cdl, cdl2, cdl3};
    }
    @IsTest
    private static void systemTest() {
        Lead lead = [SELECT Id FROM Lead WHERE FirstName = 'Test' LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GlyntMockUploadSuccess());
        GlyntAPIHelper.extractionProcessor = 'GlyntExtractionService';
        Chain.callQueueableChain = true;
        UtilityDataRequestBuilder.create(new List<String>{lead.Id});
        // Since finalizers in tests cause this, we'll run the last promise explicitly:
        // https://salesforce.stackexchange.com/questions/336329/apex-tests-using-finalizers-causes-metadata-api-deploy-to-result-in-limit-exceed
        GlyntExtractionService extractionService =
            new GlyntExtractionService(System.now().addMinutes(GlyntAPIHelper.extractionQueryTimeout));
        extractionService.passThrough = new List<String>{'123qwe', '123qwf', '123qwg'};
        extractionService.execute();
        Test.stopTest();
        List<Error_Log__c> infoLogsFromExtractionResults = [
            SELECT Class__c, Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.INFO
        ];
        System.assertEquals(1, infoLogsFromExtractionResults.size(),
            'Three documents uploaded to two UALs should have resulted in one info log with three results, but got this: ' +
                infoLogsFromExtractionResults);
        List<GlyntAPI.ExtractionResult> results =
            (List<GlyntAPI.ExtractionResult>) JSON.deserialize(infoLogsFromExtractionResults[0].Message__c, List<GlyntAPI.ExtractionResult>.class);
        System.assertEquals(3, results.size(),
            'GlyntExtractionService.processExtractions should have logged three results, but logged this: ' +
                infoLogsFromExtractionResults[0].Message__c);
    }

    @IsTest
    private static void testContentAssociationAndQueueingUpload() {
        Lead lead = [SELECT Id FROM Lead WHERE FirstName = 'Test' LIMIT 1];
        List<Utility_Data_Request__c> utilityDataRequests = [SELECT Id FROM Utility_Data_Request__c];
        System.assertEquals(0, utilityDataRequests.size(), 'Should start with no UDRs');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GlyntMockUploadFailure());
        UtilityDataRequestBuilder.create(new List<String>{lead.Id});
        Test.stopTest();

        utilityDataRequests = [SELECT Id FROM Utility_Data_Request__c];
        System.assertEquals(3, utilityDataRequests.size(), 'Wrong number of UDRs created, one for each document in the two UALs');

        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :utilityDataRequests[0].Id
        ];
        System.assertEquals(1, contentDocumentLinks.size(), 'Expected a Utility Bill to be linked to each of new UDRs');
        List<ContentDocumentLink> contentDocumentLinks2 = [
            SELECT Id, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :utilityDataRequests[1].Id
        ];
        System.assertEquals(1, contentDocumentLinks2.size(), 'Expected a Utility Bill to be linked to each of new UDRs');
        System.assertNotEquals(contentDocumentLinks[0].ContentDocument.Title, contentDocumentLinks2[0].ContentDocument.Title,
            'The two UDRs should be linked to content docs that are different');

        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'GlyntUploadService'
            AND Severity__c = 'Error'
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected an error when executing the queueable');
        // Between start/stop test, UDRTrigger commits the enqueueJob, but stopTest runs the queueable should should callout
        // to create the document. If it tries, we should get an uncommitted work pending error. But with Spring 21, the UDR
        // is committed and the callout is attempted.
        System.assert(errorLogs[0].Message__c.contains('You have uncommitted work pending') || errorLogs[0].Message__c.contains('Could not upload document'),
            'We expect the queueable to execute which does the createDocument callout resulting in a callout exception, or ' +
                'attempts the callout which results in an error from the mock, but got this: ' +
                errorLogs[0].Message__c);
    }

    @IsTest
    private static void testUploadAndExtract() {
        GlyntUploadService.extractionService = (GlyntExtractionService) Test.createStub(GlyntExtractionService.class, new MockedGlyntExtractionService());
        // Unfortunately, I wasn't able to mock with VersionData
        Utility_Account_Log__c ual = [SELECT Id FROM Utility_Account_Log__c WHERE Name = '123' LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GlyntMockUploadSuccess());
        // GlyntUploadService will upload a doc from any object, it doesn't need to be a UDR
        GlyntUploadService uploadService = new GlyntUploadService(ual.Id);
        System.enqueueJob(uploadService);
        Test.stopTest();
        System.assertEquals(4, GlyntAPIHelper.endpointsCalled.size(),
            'Expected four callouts, a create document/start extract pair for two documents but got: ' + JSON.serializePretty(GlyntAPIHelper.endpointsCalled));
        System.assert(GlyntAPIHelper.endpointsCalled[0].endpoint.contains('document'),
            'Expected to post to /v6/data-pools/dataPoolId/documents, but got: ' + GlyntAPIHelper.endpointsCalled[0].endpoint);
        System.assert(GlyntAPIHelper.endpointsCalled[0].jsonBody.contains('content'),
            'Should have sent a GlyntAPI.DocumentUpload, but sent: ' + GlyntAPIHelper.endpointsCalled[0].jsonBody);
    }

    @IsTest
    private static void testUploadFailure() {
        Utility_Account_Log__c ual = [SELECT Id FROM Utility_Account_Log__c WHERE Name = '123' LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GlyntMockUploadFailure());
        GlyntUploadService uploadService = new GlyntUploadService(ual.Id);
        System.enqueueJob(uploadService);
        Test.stopTest();
        System.assertEquals(1, GlyntAPIHelper.endpointsCalled.size(),
            'Expected one callout to createDocument that fails');
        System.assert(GlyntAPIHelper.endpointsCalled[0].endpoint.contains('document'),
            'Expected to post to /v6/data-pools/dataPoolId/documents, but got: ' + GlyntAPIHelper.endpointsCalled[0].endpoint);
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
            if (request.getEndpoint().contains('documents')) {
                httpResponse.setHeader('Content-Type', 'application/json');
                httpResponse.setStatusCode(201);
                httpResponse.setBody('{"id":"123qwe"}');
            } else if (request.getEndpoint().contains('extractions')) {
                if (request.getMethod() == 'POST') {
                    httpResponse.setHeader('Content-Type', 'application/json');
                    httpResponse.setStatusCode(201);
                    httpResponse.setBody(JSON.serialize(new GlyntAPI.ExtractionResponse('Success', false)));
                } else {
                    httpResponse.setHeader('Content-Type', 'application/json');
                    httpResponse.setStatusCode(200);
                    httpResponse.setBody(JSON.serialize(new GlyntAPI.ExtractionResponse('Success', true)));
                }
            }
            return httpResponse;
        }
    }

    public class MockedGlyntExtractionService extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            GlyntAPIHelper.EndpointCall endpointCall = new GlyntAPIHelper.EndpointCall(
                GlyntExtractionService.extractionsEndpoint,
                JSON.serialize(new GlyntAPI.ExtractionRequest('documentid', 'linkedentityid')),
                'response body'
            );
            GlyntAPIHelper.endpointsCalled.add(endpointCall);
            GlyntAPI.ExtractionResponse extractionResponse = new GlyntAPI.ExtractionResponse('Complete', true);
            extractionResponse.id = 'extractionId';
            return extractionResponse;
        }
    }

}