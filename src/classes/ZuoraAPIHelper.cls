/*************************************************************************************
 * Created By: peteryao on 2019-04-10  
 * Description: 
 * Test: ZuoraAPIHelperTest
 *************************************************************************************/

public with sharing class ZuoraAPIHelper {
    private static Zuora_Setting__mdt zuoraSetting;
    @TestVisible
    private static Long calloutMillis = 0;

    public static HttpResponse callJsonEndpoint(String method, String endpoint, Object jsonBody) {
        return callJsonEndpoint(method, endpoint, jsonBody, true);
    }

    public static HttpResponse callJsonEndpoint(String method, String endpoint, Object jsonBody, Boolean flush) {
        // Since there is a 120 second cumulative timeout for callouts, abort if we don't have a 15 second cushion left
        // (which is arbitrary). Starting the transaction and having Salesforce abort it may end up an with finished or
        // aborted transaction in Zuora
        if (calloutMillis > 105*1000) {
            throw new Util.BWException('Not starting ' + endpoint + ' because ' + (Integer) (calloutMillis/1000) +
                ' seconds of cumulative callout time has been consumed. Retry in a different transaction.');
        }
        Zuora_Setting__mdt zuoraSetting = getZuoraSetting();
        HttpRequest request = new HttpRequest();
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
        HttpResponse response;
        Zuora.zApi zApiInstance = new Zuora.zApi();
        if (Test.isRunningTest()) {
            response = new ZuoraAPIMock().respond(request);
        } else {
            Long start = System.currentTimeMillis();
            response = zApiInstance.sendRequest(request);
            Long finish = System.currentTimeMillis();
            calloutMillis += (finish - start);
        }
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
                SELECT Id, DeveloperName, CC_Payment_Page_Id__c, ACH_Payment_Page_Id__c, Hosted_Payment_Page_URI__c, API_Endpoint_URL__c
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

    public static Boolean zuoraPaymentPageEnabled() {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (systemProperties.size() > 0) {
            return systemProperties[0].Use_Zuora_for_Payment_Capture__c;
        }
        return false;
    }

    public static String query(String queryString) {
        ZuoraAPI.ZuoraQuery zuoraQuery = new ZuoraAPI.ZuoraQuery();
        zuoraQuery.queryString = queryString;
        HttpResponse response = callJsonEndpoint('POST', '/v1/action/query', zuoraQuery);
        System.debug(LoggingLevel.ERROR, response.getBody());
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

}