@IsTest
public without sharing class MarketingJourneyEnrollerTest {
    
    @TestSetup
    private static void setConfigs() {
        insert new System_Properties__c(Name='Default', Log_Level__c='Fine');
    }

    @IsTest
    private static void testJourneyEnrollmentSuccess() {
        Integer numberOfEnrollments = 5;
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MarketingJourneyEnrollerSuccess());
            List<MarketingAPI.JourneyEnrollment> enrollments = createEnrollments(numberOfEnrollments);
            MarketingJourneyEnroller.enrollContactsInJourney(enrollments);
        Test.stopTest();

        System.assertEquals(1,
            [SELECT Id FROM Error_Log__c WHERE Class__c = 'MarketingAPIHelper' AND Severity__c = 'Fine'].size(),
            'Should have logged the callout request and response for ' + numberOfEnrollments + ' journey enrollments');

        List<Error_Log__c> successfulLogs = [
            SELECT Id, Message__c FROM Error_Log__c
            WHERE Class__c = 'MarketingJourneyEnroller'
            AND Severity__c = 'Fine'
        ];
        System.assertEquals(1,
            [SELECT Id FROM Error_Log__c WHERE Class__c = 'MarketingJourneyEnroller' AND Severity__c = 'Fine'].size(),
            'Should have logged the callout request and response for ' + numberOfEnrollments + ' journey enrollments');
        System.assertEquals(numberOfEnrollments,
            successfulLogs[0].Message__c.countMatches('Successful Marketing Cloud journey enrollment'),
            'Log should include data for all successfully processed Journey enrollments'
        );
        System.assertEquals(0,
            [SELECT Id FROM Error_Log__c WHERE Class__c = 'MarketingJourneyEnroller' AND Severity__c = 'Error'].size(),
            'Should be no error logs with severity Logger.ERROR for this test');
    }

    @IsTest
    private static void testJourneyEnrollmentFailure() {
        Integer numberOfEnrollments = 5;
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MarketingJourneyEnrollerFailure());
            List<MarketingAPI.JourneyEnrollment> enrollments = createEnrollments(numberOfEnrollments);
            MarketingJourneyEnroller.enrollContactsInJourney(enrollments);
        Test.stopTest();

        List<Error_Log__c> failureLogs = [
            SELECT Id, Message__c FROM Error_Log__c
            WHERE Class__c = 'MarketingJourneyEnroller'
            AND Severity__c = 'Error'
        ];
        System.assert(failureLogs.size() == 1, 'At least one log should exist for MCAPI callout failures');
        System.assertEquals(numberOfEnrollments,
            failureLogs[0].Message__c.countMatches('Error encountered in Marketing Cloud journey enrollment'),
            'Log should include data for all failed Journey enrollments'
        );
        System.assertEquals(0,
            [SELECT Id FROM Error_Log__c WHERE Class__c = 'MarketingJourneyEnroller' AND Severity__c = 'Fine'].size(),
            'Should be no success Logger.FINE logs for ' + numberOfEnrollments + ' journey enrollments');
    }

    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static List<MarketingAPI.JourneyEnrollment> createEnrollments(Integer numOfEnrollments) {
        List<MarketingAPI.JourneyEnrollment> enrollments = new List<MarketingAPI.JourneyEnrollment>();
        for (Integer i=0; i<numOfEnrollments; i++) {
            MarketingAPI.JourneyEnrollment enrollment = new MarketingAPI.JourneyEnrollment();
            enrollment.ContactId = '00305000008GSCcAAO';
            enrollment.EventDefinitionKey = 'APIEvent-d583f5b6-dc29-143b-61b0-38c3cfe07229';
            enrollment.EventProperties = new List<FlowMap>();
            enrollment.EventProperties.add(new FlowMap('Key','Value'));
            enrollments.add(enrollment);
        }
        return enrollments;
    }

    /*  MOCKS */
    private class MarketingJourneyEnrollerSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse httpResponse;
            if (request.getEndpoint() == 'callout:MarketingCloudOAuth') {
                httpResponse = goodOauthResponse();
            } else {
                httpResponse = goodJourneyEnrollerResponse();
            }
            return httpResponse;
        }
    }

    private class MarketingJourneyEnrollerFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse httpResponse;
            if (request.getEndpoint() == 'callout:MarketingCloudOAuth') {
                httpResponse = goodOauthResponse();
            } else {
                httpResponse = badJourneyEnrollerResponse();
            }
            return httpResponse;
        }
    }

    private static HttpResponse goodOauthResponse() {
        HttpResponse httpResponse = new HttpResponse();
        MarketingAPI.AuthResponse authResponse = new MarketingAPI.AuthResponse();
        authResponse.access_token = '123qweasd';
        authResponse.token_type = 'Bearer';
        httpResponse.setBody(JSON.serialize(authResponse));
        return httpResponse;
    }

    private static HttpResponse goodJourneyEnrollerResponse() {
        HttpResponse httpResponse = new HttpResponse();
        httpResponse.setHeader('Content-Type', 'application/json');
        httpResponse.setStatusCode(201);
        httpResponse.setStatus('OK');
        httpResponse.setBody('{"eventInstanceId":"cc0fdd74-fbf1-4018-b611-36d18d807ac4"}');
        return httpResponse;
    }

    private static HttpResponse badJourneyEnrollerResponse() {
        HttpResponse httpResponse = new HttpResponse();
        httpResponse.setHeader('Content-Type', 'application/json');
        httpResponse.setStatusCode(400);
        httpResponse.setBody('{"message":"Invalid data","errorcode":50000,"documentation":""}');
        return httpResponse;
    }
}