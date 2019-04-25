/*************************************************************************************
 * Created By: peteryao on 2019-04-10  
 * Description: 
 * Test: ZuoraAPIHelperTest
 *************************************************************************************/

public with sharing class ZuoraAPIHelper {
    private static Zuora_Setting__mdt zuoraSetting;

    public static HttpResponse callJsonEndpoint(String method, String endpoint, Map<String, Object> jsonBody) {
        return callJsonEndpoint(method, endpoint, jsonBody, true);
    }

    public static HttpResponse callJsonEndpoint(String method, String endpoint, Map<String, Object> jsonBody, Boolean flush) {
        String jsonString;
        if (jsonBody != null && jsonBody.size() > 0) {
            jsonString = System.JSON.serialize(jsonBody);
        }
        return callJsonEndpoint(method, endpoint, jsonString, flush);
    }

    public static HttpResponse callJsonEndpoint(String method, String endpoint, String jsonString, Boolean flush) {
        Zuora_Setting__mdt zuoraSetting = getZuoraSetting();
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(zuoraSetting.API_Endpoint_URL__c + endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('zuora-version', '224.0'); // Version 224.0 includes settlement object (credit memos, etc)
        if (jsonString != null) {
            request.setBody(jsonString);
        }
        HttpResponse response;
        Zuora.zApi zApiInstance = new Zuora.zApi();
        if (Test.isRunningTest()) {
            response = new Http().send(request);
        } else {
            response = zApiInstance.sendRequest(request);
        }
        Logger.logLater(
            'ZuoraAPIHelper',
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

    public static Zuora_Setting__mdt getZuoraSetting() {
        if (zuoraSetting == null) {
            List<Zuora_Setting__mdt> zuoraSettings = [
                SELECT Id, DeveloperName, CC_Payment_Page_Id__c, ACH_Payment_Page_Id__c, Hosted_Payment_Page_URI__c, API_Endpoint_URL__c
                FROM Zuora_Setting__mdt
                WHERE Active__c = TRUE
            ];
            // In case all zuora settings are disabled (which would be if we the case if we're still using Chargent), we'll
            // use a fake setting
            if (Test.isRunningTest() && zuoraSettings.size() == 0) {
                Zuora_Setting__mdt zuoraSetting = new Zuora_Setting__mdt(
                    DeveloperName = 'TestSetting',
                    CC_Payment_Page_Id__c = 'CCPaymentPageId',
                    ACH_Payment_Page_Id__c = 'ACHPaymentPageId',
                    Hosted_Payment_Page_URI__c = 'HostedPaymentPageURI',
                    API_Endpoint_URL__c = 'https://rest.zuora.com/'
                );
                zuoraSettings.add(zuoraSetting);
            }
            if (zuoraSettings.size() == 1) {
                Organization o = [SELECT IsSandbox FROM Organization LIMIT 1];
                if (!Test.isRunningTest() &&
                    (o.IsSandbox && zuoraSettings[0].DeveloperName != 'Sandbox') ||
                    (!o.IsSandbox && zuoraSettings[0].DeveloperName != 'Production')) {
                    throw new Util.BWException('Wrong Zuora setting is activated');
                }
                zuoraSetting = zuoraSettings[0];
            } else {
                throw new Util.BWException('No active, or multiple active, Zuora Settings found');
            }
        }
        return zuoraSetting;
    }

    public static Boolean zuoraEnabled() {
        try {
            getZuoraSetting();
        } catch (Util.BWException bwe) {
            return false;
        }
        return true;
    }
}