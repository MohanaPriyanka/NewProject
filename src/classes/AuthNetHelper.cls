public class AuthNetHelper {

    @TestVisible
    private static Long calloutMillis = 0;

    public static HttpResponse callJsonEndpoint(String method, String jsonBody, Boolean flush) {
        if(Limits.getCallouts() >= Limits.getLimitCallouts()){
            throw new Util.BWException('Callout limit exceeded.');
        }
        if (calloutMillis > 105 * 1000) {
            throw new Util.BWException('Not starting ' + method + ' because ' + (Integer) (calloutMillis / 1000) +
                    ' seconds of cumulative callout time has been consumed. Retry in a different transaction.');
        }
        String authNetUrl;
        Organization o = [SELECT IsSandbox FROM Organization LIMIT 1];
        if (o.IsSandbox || Test.isRunningTest()) {
            authNetUrl = 'https://apitest.authorize.net/xml/v1/request.api';
        } else {
            authNetUrl = 'https://api.authorize.net/xml/v1/request.api';
        }

        Http http = new Http();
        HttpResponse response;
        HttpRequest request = new HttpRequest();


        request.setEndpoint(authNetUrl);
        request.setMethod(method);
        if (jsonBody != null) {
            jsonBody = jsonBody.replace('limit_Z', 'limit');
            request.setBody(jsonBody);
        }
        Long start = System.currentTimeMillis();
        response = http.send(request);
        Long finish = System.currentTimeMillis();
        calloutMillis += (finish - start);

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
}