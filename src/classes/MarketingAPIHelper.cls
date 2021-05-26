/**
 * @description: Convenience methods to call Marketing Cloud APIs
 * Tested By: MarketingAPITest, MarketingJourneyEnrollerTest
 */
public without sharing class MarketingAPIHelper {

    public static final Integer ACCESS_TOKEN_TIMEOUT_SECONDS = 18 * 60; // 18 minutes as recommended
    public static final String BASE_URL = 'https://mc68nc16-b6dfhmx3r9080lpklwm.rest.marketingcloudapis.com';
    public static Boolean publishToAPI;
    public static Integer calloutsPerTransaction;
    @TestVisible private static MarketingAPISelector marketingAPISelector = new MarketingAPISelector();

    static {
        List<MCAPI_Config__mdt> configs = marketingAPISelector.getMarketingAPIConfig();
        if (configs.isEmpty()) {
            return;
        }
        publishToAPI = !Util.isSandboxOrTest() || Test.isRunningTest() || configs[0]?.Sandbox_Publish_to_Prod__c;
        calloutsPerTransaction = Integer.valueOf(Util.nullToZero(configs[0]?.Callouts_Per_Transaction__c));
    }

    public String getAccessTokenFromCache() {
        String token = (String) Cache.Org.get('MarketingCloudAuthToken');
        if (token == null) {
            token = queryForToken();
            Cache.Org.put('MarketingCloudAuthToken', token, ACCESS_TOKEN_TIMEOUT_SECONDS);
        }
        return token;
    }

    private String queryForToken() {
        String endpoint = 'callout:MarketingCloudOAuth';
        String body = JSON.serialize(new MarketingAPI.OauthRequest());
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(body);
        HttpResponse response = new Http().send(request);
        MarketingAPI.AuthResponse authResponse = (MarketingAPI.AuthResponse) JSON.deserialize(
            response.getBody(), MarketingAPI.AuthResponse.class
        );
        if (authResponse.access_token == null) {
            throw new Util.BWException('Marketing Cloud API auth token retrieval failure: ' + response.getBody());
        }
        return authResponse.access_token;
    }

    @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
    public HttpResponse callJsonEndpoint(String method, String endpoint, Object body) {
        String token = getAccessTokenFromCache();
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setEndpoint(BASE_URL + endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        if (body != null) {
            request.setBody(JSON.serialize(body));
        }
        HttpResponse response = new Http().send(request);
        Logger.logLater(
            'MarketingAPIHelper',
            'callJsonEndpoint',
            'Request Endpoint: ' + request.getEndpoint() + '\n' +
                'Request Body: ' + request.getBody() + '\n\n' +
                'Response Status: ' + response.getStatus() + '\n' +
                'Response Body: ' + response.getBody(),
            Logger.FINE);
        return response;
    }
}