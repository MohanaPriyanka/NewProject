/*************************************************************************************
 * Created By: peteryao on 2019-04-10  
 * Description: 
 * Test: ZuoraAPIHelperTest
 *************************************************************************************/

public with sharing class ZuoraAPIHelper {
    private static Zuora_Setting__mdt zuoraSetting;
    @TestVisible
    private static Long calloutMillis = 0;
    private static Integer maxCalloutMillis = 105*1000;
    // Because we use the Zuora.zApi package, we can't use Limits.getCallouts to know how many callouts that namespace
    // consumes. So we need to manage it ourselves.
    @TestVisible
    private static Integer numberCalloutsForZuoraNamespace = 0;
    // If Salesforce ever increases the limit again:
    @TestVisible
    private static Integer maxCalloutsForZuoraNamespace = 100;
    @TestVisible
    private static List<EndpointCall> endpointsCalled = new List<EndpointCall>();

    public static HttpResponse callJsonEndpoint(String method, String endpoint, Object jsonBody) {
        return callJsonEndpoint(method, endpoint, jsonBody, true);
    }

    public static Integer getCalloutsRemaining() {
        return maxCalloutsForZuoraNamespace - numberCalloutsForZuoraNamespace;
    }

    public static Long getCalloutSecondsRemaining() {
        return (maxCalloutMillis - calloutMillis)/1000;
    }

    public static HttpResponse callJsonEndpoint(String method, String endpoint, Object jsonBody, Boolean flush) {
        // Since there is a 120 second cumulative timeout for callouts, abort if we don't have a 15 second cushion left
        // (which is arbitrary). Starting the transaction and having Salesforce abort it may end up an with finished or
        // aborted transaction in Zuora
        if (calloutMillis > maxCalloutMillis) {
            throw new Util.BWException('Not starting ' + endpoint + ' because ' + (Integer) (calloutMillis/1000) +
                ' seconds of cumulative callout time has been consumed. Retry in a different transaction.');
        }
        // Since apex can't catch a limit exception, we have to check and throw a custom one before it's hit
        if (numberCalloutsForZuoraNamespace + 1 > maxCalloutsForZuoraNamespace) {
            throw new Util.BWException('Not starting ' + endpoint + ' because ' + numberCalloutsForZuoraNamespace +
                ' callouts of ' + maxCalloutsForZuoraNamespace + ' have been consumed');
        }
        Zuora_Setting__mdt zuoraSetting = getZuoraSetting();
        HttpRequest request = new HttpRequest();
        request.setTimeout(60000); // Set a 60 second timeout (default is 10) to avoid recovering from read timed out
        request.setMethod(method);
        request.setEndpoint(zuoraSetting.API_Endpoint_URL__c + endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('zuora-version', '224.0'); // Version 224.0 includes settlement object (credit memos, etc)
        if (jsonBody != null) {
            String jsonString = JSON.serialize(jsonBody, true);
            jsonString = jsonString.replace('_Zcustom','__c');
            jsonString = jsonString.replace('_Zreserved','');
            request.setBody(jsonString);
        }
        return sendHttpRequest(request, endpoint, flush, true);
    }

    public static HttpResponse sendHttpRequest(HttpRequest request, String endpoint, Boolean flush, Boolean useZAPI){
        HttpResponse response;
        if (Test.isRunningTest()) {
            response = new ZuoraAPIMock().respond(request);
            endpointsCalled.add(new EndpointCall(endpoint, request.getBody(), response.getBody()));
        } else {
            Long start = System.currentTimeMillis();
            if (useZAPI){
                Zuora.zApi zApiInstance = new Zuora.zApi();
                response = zApiInstance.sendRequest(request);
            } else {
                response =  new Http().send(request);
            }
            Long finish = System.currentTimeMillis();
            calloutMillis += (finish - start);
        }
        numberCalloutsForZuoraNamespace++;
        Logger.logLater(
            'ZuoraAPIHelper',
            'callJsonEndpoint',
            'Request Endpoint: ' + request.getEndpoint() + '\n' +
                'Request Body: ' + request.getBody() + '\n\n' +
                'Response Status: ' + response.getStatus() + '\n' +
                'Response Body: ' + response.getBody() + '\n' +
                'Cumulative Time: ' + calloutMillis,
            Logger.FINE);
        if (flush) {
            Logger.flushLogs();
        }
        return response;
    }

    public static Zuora_Setting__mdt getZuoraSetting() {
        if (zuoraSetting != null) {
            return zuoraSetting;
        }
        Organization o = [SELECT IsSandbox FROM Organization];
            List<Zuora_Setting__mdt> zuoraSettings = [
                SELECT Id, DeveloperName, CC_Payment_Page_Id__c, ACH_Payment_Page_Id__c,
                    Hosted_Payment_Page_URI__c, API_Endpoint_URL__c, Zuora_Is_Live__c
                FROM Zuora_Setting__mdt
            WHERE Is_Sandbox__c = :o.IsSandbox
            ];
            if (zuoraSettings.size() == 1) {
                zuoraSetting = zuoraSettings[0];
            } else {
            throw new Util.BWException('Wrong number of Zuora Settings found: ' + zuoraSettings.size());
        }
        return zuoraSetting;
    }

    public static API_Credential__c getOAuthCredential(String credentialName){
         API_Credential__c credential = [
            SELECT Id, Credential_Id__c, Credential_Secret__c
            FROM API_Credential__c
            WHERE Name = : credentialName
            LIMIT 1
        ];
        return credential;
    }

    public static Boolean zuoraPaymentPageEnabled() {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (systemProperties.size() > 0) {
            return systemProperties[0].Use_Zuora_for_Payment_Capture__c;
        }
        return false;
    }

    public static String query(String queryString, Boolean flush) {
        ZuoraAPI.ZuoraQuery zuoraQuery = new ZuoraAPI.ZuoraQuery();
        zuoraQuery.queryString = queryString;
        HttpResponse response = callJsonEndpoint('POST', '/v1/action/query', zuoraQuery, flush);
        return response.getBody();
    }

    public static String deleteObjects(List<String> objectIds, String objectType, Boolean flush) {
        ZuoraAPI.ZuoraDelete zuoraDelete = new ZuoraAPI.ZuoraDelete();
        zuoraDelete.ids = objectIds;
        zuoraDelete.type = objectType;
        HttpResponse response = callJsonEndpoint('POST', '/v1/action/delete', zuoraDelete, flush);
        System.debug(LoggingLevel.ERROR, response.getBody());
        return response.getBody();
    }

    public static String cleanJSON(String json) {
        return json.replace('__c', '_Zcustom')
            .replace('"currency" :', '"currency_Zreserved" :')
            .replace('"type" :', '"type_Zreserved" :');
    }

    public static String generateOAuthToken() {
        String token = (String) Cache.org.get('ZuoraOAuthToken');
        if (token == null) {
            API_Credential__c credential = getOAuthCredential('Zuora_O_Auth');
            String oAuthCredential =
                'client_id=' + credential.Credential_Id__c +
                '&grant_type=client_credentials' +
                '&client_secret=' + credential.Credential_Secret__c;

            HttpResponse response = ZuoraAPIHelper.callURLEncodedEndpoint('POST','/oauth/token',oAuthCredential,false);
            ZuoraAPI.OAuthResponse zAuthorization = new ZuoraAPI.OAuthResponse();
            zAuthorization = (ZuoraAPI.OAuthResponse)JSON.deserialize(response.getBody(), ZuoraAPI.OAuthResponse.class);
            Cache.Org.put('ZuoraOAuthToken', zAuthorization.access_token, zAuthorization.expires_in);
            return zAuthorization.access_token;
        } else {
            return token;
        }
    }

    public static HttpResponse callURLEncodedEndpoint(String method, String endpoint, String urlBody, Boolean flush) {
        Zuora_Setting__mdt zuoraSetting = getZuoraSetting();
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(zuoraSetting.API_Endpoint_URL__c + endpoint);
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        if (urlBody != null) {
            request.setBody(urlBody);
        }
        return sendHttpRequest(request, endpoint, flush, true);
    }

    public static HttpResponse callJSONEndpointWithOAuth(String method, String endpoint, Object jsonBody, Boolean flush) {
        String zAuthToken = ZuoraAPIHelper.generateOAuthToken();
        Zuora_Setting__mdt zuoraSetting = getZuoraSetting();
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(zuoraSetting.API_Endpoint_URL__c + endpoint);
        request.setHeader('Authorization', 'Bearer ' + zAuthToken);
        request.setHeader('Content-Type', 'application/json');

        if (jsonBody != null) {
            String jsonString = JSON.serialize(jsonBody, true);
            jsonString = jsonString.replace('_Zcustom','__c');
            jsonString = jsonString.replace('_Zreserved','');
            request.setBody(jsonString);
        }
        return sendHttpRequest(request, endpoint, flush, false);
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