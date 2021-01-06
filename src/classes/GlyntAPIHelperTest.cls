@IsTest
private with sharing class GlyntAPIHelperTest {
    @IsTest
    private static void testGetBasicAccessToken() {
        GlyntAPIHelper.authType = 'Basic';
        GlyntAPIHelper apiHelper = new GlyntAPIHelper();

        Test.startTest();
        System.assertEquals(null, Cache.Org.get('GlyntAuthToken'), 'Expected no token in the org cache');
        Test.setMock(HttpCalloutMock.class, new GlyntMockPositiveAuth());
        String token = apiHelper.getAccessTokenFromCache();
        System.assertEquals(1, GlyntAPIHelper.endpointsCalled.size(), 'Should have called one endpoint');
        System.assert(GlyntAPIHelper.endpointsCalled[0].jsonBody.contains('username'),
            'Since the mocked configuration specifies auth type of Basic, the request should be username/password, but got: ' +
                GlyntAPIHelper.endpointsCalled[0].jsonBody);
        System.assertNotEquals(null, token, 'Expected to get the mock token');
        System.assertEquals(token, Cache.Org.get('GlyntAuthToken'), 'Expected the token in the org cache');

        GlyntAPIHelper.endpointsCalled = new List<GlyntAPIHelper.EndpointCall>();
        token = apiHelper.getAccessTokenFromCache();
        System.assertEquals(0, GlyntAPIHelper.endpointsCalled.size(),
            'We should skip the callout if the token is found in the cache');
        Test.stopTest();
    }

    @IsTest
    private static void testGetOAuthAccessToken() {
        GlyntAPIHelper.authType = 'OAuth';
        GlyntAPIHelper apiHelper = new GlyntAPIHelper();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GlyntMockPositiveAuth());
        String token = apiHelper.getAccessTokenFromCache();
        Test.stopTest();

        System.assertEquals(1, GlyntAPIHelper.endpointsCalled.size(), 'Should have called one endpoint');
        System.assert(GlyntAPIHelper.endpointsCalled[0].jsonBody.contains('client_id'),
            'Since the mocked configuration specifies auth type of OAuth, the request should be client_id/client_secret, but got: ' +
                GlyntAPIHelper.endpointsCalled[0].jsonBody);
        System.assertNotEquals(null, token, 'Expected to get the mock token');
    }

    @IsTest
    private static void testGenericEndpoint() {
        GlyntAPIHelper.authType = 'OAuth';

        Test.startTest();
        Cache.Org.put('GlyntAuthToken', '123qweasd');
        Test.setMock(HttpCalloutMock.class, new GlyntMockPositiveAuth());
        new GlyntAPIHelper().callJsonEndpoint('POST', '/v6/auth/get-token/', new GlyntAPI.BasicAuthRequest(), true);
        Test.stopTest();

        System.assertEquals(1, GlyntAPIHelper.endpointsCalled.size(), 'Should have called one endpoint');
        System.assertEquals(1, [SELECT Id FROM Error_Log__c WHERE Class__c = 'GlyntAPIHelper' AND Severity__c = 'Fine'].size(),
            'Should have logged the callout');
    }

    /*************
      *** MOCKS ***
      *************/
    private class GlyntMockPositiveAuth implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            GlyntAPI.AuthResponse authResponse = new GlyntAPI.AuthResponse();
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