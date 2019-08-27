/**
 * Created by jlugo on 7/3/2019.
 * Description: REST Controller for sending CS Leads to Salesforce
 * Test: CSLeadsRESTControllerV2Test
 */

@RestResource(UrlMapping='/v2/*')

global without sharing class RESTRouterV2 {
    private static CSLeadsRESTControllerV2 controller = new CSLeadsRESTControllerV2();

    @HttpPatch
    global static void patchRequest() {
        String jsonRequest = RestContext.request.requestBody.toString();
        RESTController.ResponseEnvelope envelope = new RESTController.ResponseEnvelope();
        try {
            switch on RestContext.request.requestURI.substring(RestContext.request.requestURI.lastIndexOf('/')) {
                when '/leads' {
                    controller.patchLead(jsonRequest);
                }
                when '/property-accounts' {
                    controller.patchPropertyAccount(jsonRequest);
                }
                when '/utility-account-logs' {
                    controller.patchUtilityAccountLog(jsonRequest);
                }
                when else {
                    envelope.addError('Path not found');
                    RestContext.response.statusCode = 404;
                }
            }
        } catch (Exception e) {
            envelope.addError(e.getMessage());
            envelope.setJSONResponse(RestContext.response);
            RestContext.response.statusCode = 500;
            String errorMessage = 'Error: ' + e.getMessage();
            errorMessage += '. Request: ' + RestContext.request;
            Logger.logNow('RESTRouterV2', 'patchRequest', errorMessage, 'Error');
        }
    }

    @HttpPost
    global static void postRequest() {
        String jsonRequest = RestContext.request.requestBody.toString();
        RESTController.ResponseEnvelope envelope = new RESTController.ResponseEnvelope();
        try {
            switch on RestContext.request.requestURI.substring(RestContext.request.requestURI.lastIndexOf('/')) {
                when '/leads' {
                    controller.postLead(jsonRequest);
                }
                when '/property-accounts' {
                    controller.postPropertyAccount(jsonRequest);
                }
                when '/utility-account-logs' {
                    controller.postUtilityAccountLog(jsonRequest);
                }
                when else {
                    envelope.addError('Path not found');
                    RestContext.response.statusCode = 404;
                }
            }
        } catch (Exception e) {
            envelope.addError(e.getMessage());
            envelope.setJSONResponse(RestContext.response);
            RestContext.response.statusCode = 500;
            String errorMessage = 'Error: ' + e.getMessage();
            errorMessage += '. Request: ' + RestContext.request;
            Logger.logNow('RESTRouterV2', 'postRequest', errorMessage, 'Error');
        }
    }

}