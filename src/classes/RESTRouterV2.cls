/**
 * Created by jlugo on 7/3/2019.
 * Description: REST Controller for sending CS Leads to Salesforce
 * Test: CSLeadsRESTControllerV2Test
 */

@RestResource(UrlMapping='/v2/*')

global without sharing class RESTRouterV2 {
    public static CSLeadsRESTControllerV2 controller = new CSLeadsRESTControllerV2();

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
        } catch (Util.AuthorizationBWException abwe) {
            handleException(envelope, 401, 'patchRequest', abwe);
        } catch (Exception e) {
            handleException(envelope, 500, 'patchRequest', e);
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
        } catch (Util.AuthorizationBWException abwe) {
            handleException(envelope, 401, 'postRequest', abwe);
        } catch (Exception e) {
            handleException(envelope, 500, 'postRequest', e);
        }
    }

    @HttpGet
    global static void getRequest() {
        RestRequest req = RestContext.request;
        RESTController.ResponseEnvelope envelope = new RESTController.ResponseEnvelope();
        try {
            switch on RestContext.request.requestURI.substring(RestContext.request.requestURI.lastIndexOf('/')) {
                when '/zip-check' {
                    String zipCode = req.params.get('zipCode');
                    String partnerId = req.params.get('partnerId');
                    controller.performZipCheck(zipCode, (partnerId==null?'':partnerId));
                } when else {
                    envelope.addError('Path not found');
                    RestContext.response.statusCode = 404;
                }
            }
        } catch (Util.AuthorizationBWException abwe) {
            handleException(envelope, 401, 'getRequest', abwe);
        } catch (Exception e) {
            handleException(envelope, 500, 'getRequest', e);
        }
    }

    private static void handleException(RESTController.ResponseEnvelope envelope, Integer statusCode, String methodName, Exception e) {
        envelope.addError(e.getMessage());
        envelope.setJSONResponse(RestContext.response);
        RestContext.response.statusCode = statusCode;
        String errorMessage = 'Error: ' + e.getMessage() + '\n' + e.getStackTraceString();
        errorMessage += '. Request: ' + RestContext.request;
        Logger.logNow('RESTRouterV2', methodName, errorMessage, 'Error');
    }

}