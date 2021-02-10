/**
 * @description: Convenience methods to call Glynt APIs
 * Tested By: GlyntAPIHelperTest
 */
public without sharing class GlyntAPIHelper {
    private static final String BASE_URL = 'https://api.glynt.ai';
    private static GlyntSelector glyntSelector = new GlyntSelector();
    public static String dataPoolId;
    public static String extractionProcessor;
    public static Integer extractionQueryTimeout;
    @TestVisible private static String authType;
    private static final Integer ACCESS_TOKEN_TIMEOUT_SECONDS = 60*60*12; // 12 hours
    @TestVisible private static List<EndpointCall> endpointsCalled;

    static {
        List<Glynt_Configuration__mdt> glyntConfigurations = glyntSelector.getGlyntConfiguration();
        if (glyntConfigurations.isEmpty()) {
            return;
        }
        dataPoolId = glyntConfigurations[0]?.Data_Pool_Id__c;
        extractionProcessor = glyntConfigurations[0]?.Extraction_Processor__c;
        extractionQueryTimeout = Integer.valueOf(glyntConfigurations[0]?.Extraction_Query_Timeout__c);
        authType = glyntConfigurations[0]?.Authorization_Type__c;
        endpointsCalled = new List<EndpointCall>();
    }

    /**
     * @description Gets an Access Token to use for subsequent api calls. Assumes credentials are in Named User records
     * (GlyntBasic or GlyntOAuth) and the authorization type is set in the Glynt Configuration custom metadata (Basic or OAuth
     * @return An access token
     */
    public String getAccessTokenFromCache() {
        String token = (String) Cache.Org.get('GlyntAuthToken');
        if (token == null) {
            token = queryForToken();
            Cache.Org.put('GlyntAuthToken', token, ACCESS_TOKEN_TIMEOUT_SECONDS);
        }
        return token;
    }

    private String queryForToken() {
        String endpoint;
        String body;
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        if (authType == 'Basic') {
            endpoint = 'callout:GlyntBasic';
            body = JSON.serialize(new GlyntAPI.BasicAuthRequest());
        } else {
            endpoint = 'callout:GlyntOAuth';
            body = JSON.serialize(new GlyntAPI.OauthRequest());
        }
        request.setEndpoint(endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setBody(body);

        HttpResponse response = new Http().send(request);
        if (Test.isRunningTest()) {
            endpointsCalled.add(new EndpointCall(endpoint, request.getBody(), response.getBody()));
        }
        Logger.logLater(
            'GlyntAPIHelper',
            'queryForToken',
            'Request Endpoint: ' + request.getEndpoint() + '\n' +
                'Request Body: ' + request.getBody() + '\n' +
                'Response Status: ' + response.getStatus() + '\n' +
                'Response Body: ' + response.getBody() + '\n\n',
            Logger.FINE);
        GlyntAPI.AuthResponse authResponse = (GlyntAPI.AuthResponse) JSON.deserialize(response.getBody(), GlyntAPI.AuthResponse.class);
        if (authResponse.access_token == null) {
            throw new Util.BWException('Could not get access token:\n' + response.getBody());
        }
        return authResponse.access_token;
    }

    /**
     * @description Executes a Glynt API endpoint as defined in https://api.glynt.ai/v6/docs#definitions
     * @param method e.g. POST, GET
     * @param endpoint The endpoint, not including the BASE_URL, e.g. /v6/data-pools/pRvt5/documents/
     * @param body An object to be serialized to JSON
     * @param flush If true, commits error logs to the database (which implies no subsequent callouts can happen)
     * @return The HttpResponse from the callout
     */
    @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
    public HttpResponse callJsonEndpoint(String method, String endpoint, Object body, Boolean flush) {
        String token = getAccessTokenFromCache();
        HttpRequest request = new HttpRequest();
        request.setTimeout(60000); // Set a 60 second timeout (default is 10) to avoid recovering from read timed out
        request.setMethod(method);
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setEndpoint(BASE_URL + endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        if (body != null) {
            request.setBody(JSON.serialize(body));
        }
        HttpResponse response = new Http().send(request);
        if (Test.isRunningTest()) {
            endpointsCalled.add(new EndpointCall(endpoint, request.getBody(), response.getBody()));
        }
        Logger.logLater(
            'GlyntAPIHelper',
            'callJsonEndpoint',
            'Request Endpoint: ' + request.getEndpoint() + '\n' +
                'Request Body: ' + request.getBody() + '\n\n' +
                'Response Status: ' + response.getStatus() + '\n' +
                'Response Body: ' + response.getBody(),
            Logger.FINE);
        if (flush) {
            Logger.flushLogs();
        }
        return response;
    }

    @TestVisible
    private class EndpointCall {
        public String endpoint;
        public String jsonBody;
        public String response;
        public EndpointCall(String endpoint, String jsonBody, String response) {
            this.endpoint = endpoint;
            this.jsonBody = jsonBody;
            this.response = response;
        }
    }


}