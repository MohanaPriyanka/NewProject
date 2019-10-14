/*
 * Created by: Joey Chan
 * Tested by: BatchAuthNetReturnedTransactionsTest
  */

public without sharing class AuthNetHelper {
    @TestVisible
    private static Long calloutMillis = 0;
    @TestVisible
    private static List<EndpointCall> endpointsCalled = new List<EndpointCall>();

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static HttpResponse callJsonEndpoint(String method, String jsonBody, Boolean flush) {
        if(Limits.getCallouts() >= Limits.getLimitCallouts()){
            throw new Util.BWException('Callout limit exceeded.');
        }
        if (calloutMillis > 105 * 1000) {
            throw new Util.BWException('Not starting ' + method + ' because ' + (Integer) (calloutMillis / 1000) +
                    ' seconds of cumulative callout time has been consumed. Retry in a different transaction.');
        }
        String authNetUrl;
        // TODO: Move this into a selector and don't suppress ApexCRUDViolation
        Organization o = [SELECT IsSandbox FROM Organization LIMIT 1];
        if (o.IsSandbox || Test.isRunningTest()) {
            authNetUrl = 'https://apitest.authorize.net/xml/v1/request.api';
        } else {
            authNetUrl = 'https://api.authorize.net/xml/v1/request.api';
        }
        Http http = new Http();
        HttpResponse response;
        HttpRequest request = new HttpRequest();

        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setEndpoint(authNetUrl);
        request.setMethod(method);

        if (jsonBody != null) {
            jsonBody = jsonBody.replace('Zlimit_Z', 'limit');
            jsonBody = jsonBody.replace('ZorderBy', 'orderBy');
            jsonBody = jsonBody.replace('Zname', 'name');
            jsonBody = jsonBody.replace('MAfirstSettlementDate', 'firstSettlementDate');
            jsonBody = jsonBody.replace('DmerchantAuthentication', 'merchantAuthentication');
            jsonBody = jsonBody.replace('CbatchId', 'batchId');
            jsonBody = jsonBody.replace('Bsorting', 'sorting');
            jsonBody = jsonBody.replace('Apaging', 'paging');

            request.setBody(jsonBody);
        }

        Long start = System.currentTimeMillis();
        response = http.send(request);
        Long finish = System.currentTimeMillis();
        calloutMillis += (finish - start);
        if (Test.isRunningTest()) {
            endpointsCalled.add(new EndpointCall(request.getEndpoint(), request.getBody(), response.getBody()));
        }

        Logger.logLater(
                'AuthNetHelper',
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