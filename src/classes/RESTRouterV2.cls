/**
 * @description Created by jlugo on 7/3/2019.
 * Description: REST Controller for sending CS Leads to Salesforce
 * Test: CSLeadsRESTControllerV2Test, RESTRouterV2Test
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
                when '/application' {
                    controller.patchApplication(jsonRequest);
                }
                when '/contracts' {
                    controller.patchContract(jsonRequest);
                }
                when else {
                    envelope.addError('Path not found');
                    RestContext.response.statusCode = 404;
                }
            }
        } catch (Util.AuthorizationBWException abwe) {
            handleException(envelope, 401, 'patchRequest', abwe, 'Error');
        } catch (Exception e) {
            handleException(envelope, 500, 'patchRequest', e, 'Error');
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
                when else {
                    envelope.addError('Path not found');
                    RestContext.response.statusCode = 404;
                }
            }
        } catch (Util.AuthorizationBWException abwe) {
            handleException(envelope, 401, 'postRequest', abwe, 'Error');
        } catch (Exception e) {
            handleException(envelope, 500, 'postRequest', e, 'Error');
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
                    String utilityId = req.params.get('utilityId');
                    controller.getZipcodeCapacity(zipCode, (partnerId == null ? '' : partnerId), utilityId);
                } when '/leads' {
                    String leadId = req.params.get('leadId');
                    String email = req.params.get('email');
                    controller.getLead(leadId, email);
                } when else {
                    envelope.addError('Path not found');
                    RestContext.response.statusCode = 404;
                }
            }
        } catch (Util.AuthorizationBWException abwe) {
            handleException(envelope, 401, 'getRequest', abwe, 'Info');
        } catch (Exception e) {
            handleException(envelope, 500, 'getRequest', e, 'Error');
        }
    }

    private static void handleException(RESTController.ResponseEnvelope envelope, Integer statusCode, String methodName, Exception e, String severity) {
        Blob requestBody = RestContext.request.requestBody;
        envelope.addError(e.getMessage());
        envelope.setJSONResponse(RestContext.response);
        RestContext.response.statusCode = statusCode;
        String errorMessage = 'Error: ' + e.getMessage() + '\n' + e.getStackTraceString();
        errorMessage += '. Request: ' + RestContext.request;
        errorMessage += requestBody != null ? '\n\nRequest Body: ' + requestBody.toString() : '{ null }';
        Logger.logNow('RESTRouterV2', methodName, errorMessage, severity);
    }
}