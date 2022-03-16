/**
 * Convenience class to call the PerchOne Graph QL API
 * Tested By: PerchOneAPIHelperTest
 */

public without sharing class PerchOneAPIHelper {
    public HttpResponse callGraphQlEndpoint(String method, GraphQLQuery query) {
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint('callout:PerchOne');
        request.setHeader('x-perch-request-id', '{!$Credential.Password}');
        request.setBody(JSON.serialize(query));
        HttpResponse response = new Http().send(request);
        Logger.logLater(
            'PerchOneAPIHelper',
            'callEndpoint',
            'Request Endpoint: ' + request.getEndpoint() + '\n' +
                'Request Body: ' + request.getBody() + '\n\n' +
                'Response Status: ' + response.getStatus() + '\n' +
                'Response Body: ' + response.getBody(),
            Logger.FINE);
        return response;
    }
}