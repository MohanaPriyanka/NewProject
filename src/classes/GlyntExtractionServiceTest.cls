@IsTest
private with sharing class GlyntExtractionServiceTest {
    @IsTest
    private static void testRetrieveCompletedExtractions() {
        GlyntExtractionService extractionService = new GlyntExtractionService(System.now());
        extractionService.passThrough = new List<String>{'123', '456'};
        Test.startTest();
        Cache.Org.put('GlyntAuthToken', '123qweasd');
        Test.setMock(HttpCalloutMock.class, new GlyntMockCompleteExtractions());
        System.enqueueJob(extractionService);
        Test.stopTest();
        System.assertEquals(2, GlyntAPIHelper.endpointsCalled.size(), 'Expected two callouts to retrieve two extractions');
        System.assert(GlyntAPIHelper.endpointsCalled[0].endpoint.contains('extractions'),
            'Expected to post to /v6/data-pools/dataPoolId/extractions, but got: ' + GlyntAPIHelper.endpointsCalled[0].endpoint);
    }

    @IsTest
    private static void testRetrieveIncompleteExtractions() {
        GlyntExtractionService extractionService = new GlyntExtractionService(System.now().addMinutes(5));
        extractionService.passThrough = new List<String>{'123', '456'};
        Test.startTest();
        Cache.Org.put('GlyntAuthToken', '123qweasd');
        Test.setMock(HttpCalloutMock.class, new GlyntMockIncompleteExtractions());
        System.enqueueJob(extractionService);
        Test.stopTest();
        System.assertEquals(2, GlyntAPIHelper.endpointsCalled.size(), 'Expected two callouts to retrieve two extractions');
        System.assert(GlyntAPIHelper.endpointsCalled[0].endpoint.contains('extractions'),
            'Expected to post to /v6/data-pools/dataPoolId/extractions, but got: ' + GlyntAPIHelper.endpointsCalled[0].endpoint);
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'GlyntExtractionService'
            AND Severity__c = 'Info'
        ];
        System.assertEquals(0, errorLogs.size(),
            'Should have not logged anything because extractions were not complete: ' + errorLogs);
        System.assertNotEquals(null, GlyntExtractionService.extractionRetryService,
            'Should have an extractionRetryService to retrieve the extractions again');
    }

    @IsTest
    private static void testRetrievalTimeout() {
        GlyntExtractionService extractionService = new GlyntExtractionService(System.now().addMinutes(-5));
        extractionService.passThrough = new List<String>{'123', '456'};
        Test.startTest();
        Cache.Org.put('GlyntAuthToken', '123qweasd');
        Test.setMock(HttpCalloutMock.class, new GlyntMockIncompleteExtractions());
        System.enqueueJob(extractionService);
        Test.stopTest();
        System.assertEquals(null, GlyntExtractionService.extractionRetryService,
            'Should have an extractionRetryService to retrieve the extractions again');
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'GlyntExtractionService'
            AND Severity__c = 'Error'
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected an error log about retrieval timing out');
        System.assert(errorLogs[0].Message__c.contains('Giving up'),
            'Expected a message about giving up, but got: ' + errorLogs[0].Message__c);
    }

    @IsTest
    private static void testCreateExtraction() {
        Test.startTest();
        Cache.Org.put('GlyntAuthToken', '123qweasd');
        Test.setMock(HttpCalloutMock.class, new GlyntMockSuccessfulCreateExtraction());
        GlyntExtractionService extractionService = new GlyntExtractionService();
        GlyntAPI.ExtractionResponse extractionResponse =
            extractionService.createExtraction(new GlyntAPI.ExtractionRequest('123', 'tag'));
        Test.stopTest();
        System.assertNotEquals(null, extractionResponse, 'Expected an response from the extraction request');
        System.assertEquals(1, GlyntAPIHelper.endpointsCalled.size(), 'Expected a callout to create the extraction');
    }

    @IsTest
    private static void testUnsuccessfulCreateExtraction() {
        Test.startTest();
        Cache.Org.put('GlyntAuthToken', '123qweasd');
        Test.setMock(HttpCalloutMock.class, new GlyntMockUnsuccessfulCreateExtraction());
        GlyntExtractionService extractionService = new GlyntExtractionService();
        try {
            extractionService.createExtraction(new GlyntAPI.ExtractionRequest('123', 'tag'));
            System.assert(false, 'Expected createExtraction to throw an exception before this');
        } catch (Util.BWException bwe) {
            System.assert(bwe.getMessage().contains('Could not create an extraction'),
                'Expected to get an exception about not creating an exception, but got: ' + bwe.getMessage());
        }
        Test.stopTest();
    }

    /*************
      *** MOCKS ***
      *************/
    private class GlyntMockCompleteExtractions implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setHeader('Content-Type', 'application/json');
            httpResponse.setStatusCode(200);
            httpResponse.setBody(JSON.serialize(new GlyntAPI.ExtractionResponse('Success', true)));
            return httpResponse;
        }
    }

    private class GlyntMockIncompleteExtractions implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setHeader('Content-Type', 'application/json');
            httpResponse.setStatusCode(200);
            httpResponse.setBody(JSON.serialize(new GlyntAPI.ExtractionResponse('In Progress', false)));
            return httpResponse;
        }
    }

    private class GlyntMockSuccessfulCreateExtraction implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setHeader('Content-Type', 'application/json');
            httpResponse.setStatusCode(201);
            httpResponse.setBody(JSON.serialize(new GlyntAPI.ExtractionResponse('Success', false)));
            return httpResponse;
        }
    }

    private class GlyntMockUnsuccessfulCreateExtraction implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setHeader('Content-Type', 'application/json');
            httpResponse.setStatusCode(500);
            httpResponse.setBody('{"error":"Unsuccessful"}');
            return httpResponse;
        }
    }

}