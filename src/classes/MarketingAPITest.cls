@IsTest
public without sharing class MarketingAPITest {

    @IsTest
    private static void testGetOAuthAccessToken() {
        MarketingAPIHelper apiHelper = new MarketingAPIHelper();
        Test.startTest();
            System.assertEquals(null, Cache.Org.get('MarketingCloudAuthToken'), 'Expected no token in the org cache');
            Test.setMock(HttpCalloutMock.class, new MarketingAPIAuthTokenSuccess());
            String token = apiHelper.getAccessTokenFromCache();
        Test.stopTest();
        System.assertNotEquals(null, token, 'Expected to get the mock token');
        System.assertEquals(token, Cache.Org.get('MarketingCloudAuthToken'), 'Expected the token in the org cache');
    }

    @IsTest
    private static void testGenericPost() {
        MarketingAPIHelper apiHelper = new MarketingAPIHelper();
        Test.startTest();
            Cache.Org.put('MarketingCloudAuthToken', '123qweasd');
            Test.setMock(HttpCalloutMock.class, new MarketingAPIAuthTokenSuccess());
            apiHelper.callJsonEndpoint('POST', '/', (Object)'Test JSON');
            Logger.flushLogs();
        Test.stopTest();
        System.assertEquals(1, [SELECT Id FROM Error_Log__c WHERE Class__c = 'MarketingAPIHelper' AND Severity__c = 'Fine'].size(),
            'Should have logged the callout request and response');
    }

    /*  MOCKS */
    private class MarketingAPIAuthTokenSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            MarketingAPI.AuthResponse authResponse = new MarketingAPI.AuthResponse();
            authResponse.access_token = '123qweasd';
            authResponse.token_type = 'Bearer';
            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setHeader('Content-Type', 'application/json');
            httpResponse.setStatusCode(200);
            httpResponse.setBody(JSON.serialize(authResponse));
            return httpResponse;
        }
    }
}