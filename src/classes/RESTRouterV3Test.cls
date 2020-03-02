/**
 * Created by peteryao on 2/21/20.
 */
@IsTest
public with sharing class RESTRouterV3Test {
    @TestSetup
    public static void testSetup() {
        RESTRouterV2Test.testSetup();
    }

    @IsTest
    public static void testPostResiLeadSuccess() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(RESTRouterV2Test.validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.postRequest();

        RestResponse response = RestContext.response;

        Map<String, Object> requestLead = (Map<String,Object>) JSON.deserializeUntyped(RESTRouterV2Test.validResiJsonRequest);
        List<Object> requestPropertyAccounts = (List<Object>) requestLead.get('propertyAccounts');
        Map<String, Object> requestPropertyAccount = (Map<String,Object>) requestPropertyAccounts[0];
        List<Object> requestUtilityAccountLogs = (List<Object>) requestPropertyAccount.get('utilityAccountLogs');
        Map<String, Object> requestUtilityAccountLog = (Map<String,Object>) requestUtilityAccountLogs[0];

        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseLead = (Map<String,Object>) responseEnvelope.get('data');

        List<Object> responsePropertyAccounts = (List<Object>) responseLead.get('propertyAccounts');
        Map<String, Object> responsePropertyAccount = (Map<String,Object>) responsePropertyAccounts[0];
        List<Object> responseUtilityAccountLogs = (List<Object>) responsePropertyAccount.get('utilityAccountLogs');
        Map<String, Object> responseUtilityAccountLog = (Map<String,Object>) responseUtilityAccountLogs[0];

        System.assertEquals(201, response.statusCode, 'POST should create properly');

        // verify lead request/response fields
        System.assertNotEquals(responseLead.get('id'), null, 'id should be set on POST response');
        for (String key : requestLead.keySet()) {
            if (requestLead.get(key) instanceof String) {
                System.assertEquals(requestLead.get(key), responseLead.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }

        // verify propertyAccount request/response fields
        System.assertEquals(requestLead.get('firstName') + ' ' + requestLead.get('lastName'), responsePropertyAccount.get('name'), 'For resi customers, the name on the prop account should be their first & last name');
        for (String key : requestPropertyAccount.keySet()) {
            if (requestPropertyAccount.get(key) instanceof String) {
                System.assertEquals(requestPropertyAccount.get(key), responsePropertyAccount.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }

        // verify UALs request/response fields
        for (String key : requestUtilityAccountLog.keySet()) {
            if (requestUtilityAccountLog.get(key) instanceof String) {
                System.assertEquals(requestUtilityAccountLog.get(key), responseUtilityAccountLog.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }

    }

    @IsTest
    public static void testPatchLead() {
        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(RESTRouterV2Test.validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        Map<String, Object> postResponseLead = (Map<String, Object>) responseEnvelope.get('data');
        // </setup>

        String patchRequest = '{ "id": "' + postResponseLead.get('id') + '", "applicationCompleteDate": "2019-01-01T01:00" }';

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/leads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        System.assert(!patchRequest.contains('email'), 'V3 of the API requires the request to contain the lead id AND email');
        System.assertEquals(401, response.statusCode, 'We expect a 401 response since email was not submitted');

        patchRequest = '{' +
            '"id": "' + postResponseLead.get('id') + '", ' +
            '"email": "' + postResponseLead.get('email') + '", ' +
            '"applicationCompleteDate": "2019-01-01T01:00" }';

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/leads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseLead = (Map<String,Object>) responseEnvelope.get('data');

        System.assert(patchRequest.contains('email'), 'We pass the email in this patch request');
        System.assertEquals(200, response.statusCode, 'A properly formed PATCH with an email under V3 should succeed');
        System.assertNotEquals(responseLead.get('applicationCompleteDate'), null, 'When patching app complete date, the response\'s app complete date should not be null');

        patchRequest = '{' +
            '"id": "' + postResponseLead.get('id') + '", ' +
            '"email": "nottherightemail@invalid.com", ' +
            '"applicationCompleteDate": "2019-01-01T01:00" }';

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/leads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        System.assert(patchRequest.contains('email'), 'We pass the email in this patch request, but the wrong one');
        System.assertEquals(401, response.statusCode, 'A patch request with the wrong email should fail');
    }

    @IsTest
    public static void testPostPropertyAccountSuccess() {
        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{' + RESTRouterV2Test.validResiLead + '}');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        Map<String, Object> postResponseLead = (Map<String, Object>) responseEnvelope.get('data');

        // </setup>


        req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/property-accounts';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        String propertyAccountJson = '{' +
            RESTRouterV2Test.validPropertyAccount + ',' +
            '"leadId": "' + postResponseLead.get('id') + '",' +
            '"utilityAccountLogs": [{' +
            RESTRouterV2Test.validUtilityAccountLog +
            '}]}';

        req.requestBody = Blob.valueOf(propertyAccountJson);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.postRequest();

        response = RestContext.response;

        Map<String, Object> requestPropertyAccount = (Map<String,Object>) JSON.deserializeUntyped(propertyAccountJson);

        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responsePropertyAccount = (Map<String,Object>) responseEnvelope.get('data');


        System.assertEquals(201, response.statusCode, 'POST should create properly');

        // verify lead request/response fields
        System.assertNotEquals(responsePropertyAccount.get('id'), null, 'id should be set on POST response');
        for (String key : requestPropertyAccount.keySet()) {
            if (requestPropertyAccount.get(key) instanceof String) {
                System.assertEquals(requestPropertyAccount.get(key), responsePropertyAccount.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }
    }

    @IsTest
    public static void testPatchPropertyAccountSuccess() {

        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(RESTRouterV2Test.validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        Map<String, Object> postResponseLead = (Map<String, Object>) responseEnvelope.get('data');
        Map<String, Object> postResponsePropertyAccount = (Map<String, Object>) ((List<Object>) postResponseLead.get('propertyAccounts'))[0];

        // </setup>

        String patchRequest = '{' +
            '"id":"' + postResponsePropertyAccount.get('id')  + '",' +
            '"zuoraPaymentRefId":"mock-zuoraId",' +
            '"zuoraPaymentRefIdExpirationDate":"2019-01-05T14:00-05:00"' +
            '}';

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/property-accounts';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        System.assert(!patchRequest.contains('email'));
        System.assertEquals(401, response.statusCode, 'PATCH without an email should fail');

        patchRequest = '{' +
            '"id":"' + postResponsePropertyAccount.get('id')  + '",' +
            '"leadId":"' + postResponseLead.get('id') + '",' +
            '"email":"' + postResponseLead.get('email') + '",' +
            '"zuoraPaymentRefId":"mock-zuoraId",' +
            '"zuoraPaymentRefIdExpirationDate":"2019-01-05T14:00-05:00"' +
            '}';

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/property-accounts';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responsePropertyAccount = (Map<String,Object>) responseEnvelope.get('data');

        System.assert(patchRequest.contains('email'));
        System.assertEquals(200, response.statusCode, 'PATCH with the correct email should succeed');

        System.assertEquals('mock-zuoraId', responsePropertyAccount.get('zuoraPaymentRefId'));
        System.assertEquals('2019-01-05T19:00:00.000Z', responsePropertyAccount.get('zuoraPaymentRefIdExpirationDate'));
    }

    @IsTest
    public static void testPostUtilityAccountLogSuccess() {
        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        req.requestBody = Blob.valueOf('{' +
            RESTRouterV2Test.validResiLead + ',' +
            '"propertyAccounts": [{' +
            RESTRouterV2Test.validPropertyAccount +
            '}]}'
        );

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();

        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseLead = (Map<String,Object>) responseEnvelope.get('data');

        List<Object> responsePropertyAccounts = (List<Object>) responseLead.get('propertyAccounts');
        Map<String, Object> responsePropertyAccount = (Map<String,Object>) responsePropertyAccounts[0];

        // </setup>


        req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/utility-account-logs';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        String utilityAccountLogJson = '{' +
            '"propertyAccountId": "' + responsePropertyAccount.get('id') + '",' +
            RESTRouterV2Test.validUtilityAccountLog +
            '}';


        req.requestBody = Blob.valueOf(utilityAccountLogJson);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.postRequest();

        response = RestContext.response;

        Map<String, Object> requestUtilityAccountLog = (Map<String, Object>) JSON.deserializeUntyped(utilityAccountLogJson);

        jsonResponse = response.responseBody.toString();

        responseEnvelope = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseUtilityAccountLog = (Map<String, Object>) responseEnvelope.get('data');


        System.assertEquals(201, response.statusCode, 'POST should create properly');

        // verify lead request/response fields
        System.assertNotEquals(responseUtilityAccountLog.get('id'), null, 'id should be set on POST response');
        for (String key : requestUtilityAccountLog.keySet()) {
            if (requestUtilityAccountLog.get(key) instanceof String) {
                System.assertEquals(requestUtilityAccountLog.get(key), responseUtilityAccountLog.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }
    }

    @IsTest
    public static void testPatchUtilityAccountLogSuccess() {

        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(RESTRouterV2Test.validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        Map<String, Object> postResponseLead = (Map<String, Object>) responseEnvelope.get('data');
        Map<String, Object> postResponsePropertyAccount = (Map<String, Object>) ((List<Object>) postResponseLead.get('propertyAccounts'))[0];
        Map<String, Object> postResponseUtilityAccountLog = (Map<String, Object>) ((List<Object>) postResponsePropertyAccount.get('utilityAccountLogs'))[0];

        // </setup>

        String patchRequest = '{' +
            '"id":"' + postResponseUtilityAccountLog.get('id') + '",' +
            '"email":"' + postResponseLead.get('email') + '",' +
            '"annualKWh":8000' +
            '}';

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/utility-account-logs';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        System.assertEquals(401, response.statusCode, 'PATCH without lead Id should fail');

        patchRequest = '{' +
            '"id":"' + postResponseUtilityAccountLog.get('id') + '",' +
            '"leadId":"' + postResponseLead.get('id') + '",' +
            '"email":"' + postResponseLead.get('email') + '",' +
            '"annualKWh":8000' +
            '}';

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/utility-account-logs';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV3.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseUAL = (Map<String,Object>) responseEnvelope.get('data');

        System.assertEquals(200, response.statusCode, 'PATCH wit email should succeed');

        System.assertEquals(8000, responseUAL.get('annualKWh'));
    }

    @IsTest
    public static void testZipCheck() {
        // Instantiate the v3 router to run the static initializer now (that sets RESTRouterV2.controller = new CSLeadsRESTControllerV3())
        RESTRouterV3 routerV3 = new RESTRouterV3();
        // So that we can mock the the v2 controller:
        RESTRouterV2.controller = (CSLeadsRESTControllerV2) Test.createStub(CSLeadsRESTControllerV2.class, new RESTRouterV2Test.MockCSLeadsRESTControllerV2());

        String zipCode = '12345';
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v3/zip-check';
        req.addParameter('zipCode', zipCode);
        req.httpMethod = 'GET';

        RestContext.request = req;
        RESTRouterV3.getRequest();

        Boolean caughtException = false;
        try {
            RestZipCode restZipCode =
                (RestZipCode) JSON.deserialize(RestContext.response.responseBody.toString(), RestZipCode.class);
            System.assertEquals(zipCode, restZipCode.zipCode, 'Expected to get the requested zipCode in the response, got: ' + restZipCode.zipCode);
            System.assertEquals(true, restZipCode.hasCapacity, 'Expected the mock to find capacity');
        } catch (Exception e) {
            caughtException = true;
            System.assert(!caughtException, e.getMessage() + '\n' + e.getStackTraceString());
        }
        System.assertEquals(false, caughtException, 'Did not expect to catch an exception');
    }
}