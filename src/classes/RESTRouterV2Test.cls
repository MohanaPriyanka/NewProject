/**
 * Created by jlugo on 2019-07-09.
 */

@IsTest
public with sharing class RESTRouterV2Test {

    private static String validLead =
        '"firstName": "System"' +
            ',"lastName": "Testcase"' +
            ',"email": "test@invalid.bluewavesolar.com"' +
            ',"mobilePhone": "555-555-5555"' +
            ',"streetAddress": "1 Test Street"' +
            ',"city": "Suffern"' +
            ',"state": "NY"' +
            ',"zipCode": "10901"' +
            ',"eiaId": "1234"' +
            ',"continueApplicationLink": "http://switch.bluewavesolar.invalid"' +
            ',"productName": "CS Product"' +
            ',"referralName": "RefFirst RefLast"' +
            ',"referralEmail": "refemail@invalid.bluewavesolar.com"';

    private static String validResiLead = validLead + ',"applicationType": "Residential"';

    private static String validNonResiLead = validLead +
        ',"applicationType": "Non-Residential"' +
        ',"businessName": "My Cool Company"' +
        ',"businessTitle": "Janitor"' +
        ',"businessPhone": "5551239876"';

    private static String validPropertyAccount =
        '   "billingStreet": "Test billing street"' +
        ',  "billingCity": "Test billing city"' +
        ',  "billingState": "NY"' +
        ',  "billingPostalCode": "14472"';

    private static String validUtilityAccountLog =
        '       "nameOnAccount": "Test Accounts Payable"' +
        ',      "serviceStreet": "Test service street"' +
        ',      "serviceCity": "Test service city"' +
        ',      "serviceState": "NY"' +
        ',      "servicePostalCode": "14472"' +
        ',      "utilityAccountNumber": "555555"';

    private static String validResiJsonRequest = '{' +
        validResiLead + ',' +
        '"propertyAccounts": [{' +
        validPropertyAccount + ',' +
        '"utilityAccountLogs": [{' +
        validUtilityAccountLog +
        '}]}]}';

    private static String validNonResiJsonRequest = '{' +
        validNonResiLead + ',' +
        '"propertyAccounts": [{' +
        validPropertyAccount + ',' +
        '"utilityAccountLogs": [{' +
        validUtilityAccountLog +
        '}]}]}';


    @TestSetup
    public static void testSetup() {
        Utility__c utility = new Utility__c(
            Name = 'Utility'
        );
        insert utility;

        Utility__c utilityWithEIA = new Utility__c(
            Name = 'Utility with EIA ID',
            EIA_ID__c = '1234'
        );
        insert utilityWithEIA;

        Product2 product = new Product2(
            Name = 'CS Product'
        );
        insert product;
    }

    /********************
     *** SYSTEM TESTS ***
     ********************/

    /** Leads **/

    @IsTest
    public static void testPostResiLeadSuccess() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;

        Map<String, Object> requestLead = (Map<String,Object>) JSON.deserializeUntyped(validResiJsonRequest);
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
    public static void testPostNonResiLeadSuccess() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validNonResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;

        Map<String, Object> requestLead = (Map<String,Object>) JSON.deserializeUntyped(validNonResiJsonRequest);
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
        System.assertEquals(requestLead.get('businessName'), responsePropertyAccount.get('name'), 'For non-resi customers, the name on the prop account should be the company name');
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
    public static void testPatchLeadSuccess() {

        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        Map<String, Object> postResponseLead = (Map<String, Object>) responseEnvelope.get('data');
        // </setup>

        String patchRequest = '{ "id": "' + postResponseLead.get('id') + '", "applicationCompleteDate": "2019-01-01T01:00" }';

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseLead = (Map<String,Object>) responseEnvelope.get('data');

        System.assertEquals(200, response.statusCode, 'Properly formed PATCH should succeed');
        System.assertNotEquals(responseLead.get('applicationCompleteDate'), null, 'When patching app complete date, the response\'s app complete date should not be null');

    }

    /** Property Accounts **/

    @IsTest
    public static void testPostPropertyAccountSuccess() {
        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{' + validResiLead + '}');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        Map<String, Object> postResponseLead = (Map<String, Object>) responseEnvelope.get('data');

        // </setup>


        req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/property-accounts';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        String propertyAccountJson = '{' +
            validPropertyAccount + ',' +
            '"leadId": "' + postResponseLead.get('id') + '",' +
            '"utilityAccountLogs": [{' +
            validUtilityAccountLog +
            '}]}';

        System.debug(propertyAccountJson);

        req.requestBody = Blob.valueOf(propertyAccountJson);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

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
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

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
        req.requestURI = '/services/apexrest/v2/property-accounts';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responsePropertyAccount = (Map<String,Object>) responseEnvelope.get('data');

        System.assertEquals(200, response.statusCode, 'Properly formed PATCH should succeed');

        System.assertEquals('mock-zuoraId', responsePropertyAccount.get('zuoraPaymentRefId'));
        System.debug(responsePropertyAccount.get('zuoraPaymentRefIdExpirationDate'));
        System.assertEquals('2019-01-05T19:00:00.000Z', responsePropertyAccount.get('zuoraPaymentRefIdExpirationDate'));

    }

    /** Utility Account Logs **/

    @IsTest
    public static void testPostUtilityAccountLogSuccess() {
        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        req.requestBody = Blob.valueOf('{' +
            validResiLead + ',' +
            '"propertyAccounts": [{' +
            validPropertyAccount +
            '}]}'
        );

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();

        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseLead = (Map<String,Object>) responseEnvelope.get('data');

        System.debug(jsonResponse);
        List<Object> responsePropertyAccounts = (List<Object>) responseLead.get('propertyAccounts');
        Map<String, Object> responsePropertyAccount = (Map<String,Object>) responsePropertyAccounts[0];

        // </setup>


        req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/utility-account-logs';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        String utilityAccountLogJson = '{' +
            '"propertyAccountId": "' + responsePropertyAccount.get('id') + '",' +
            validUtilityAccountLog +
            '}';


        req.requestBody = Blob.valueOf(utilityAccountLogJson);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

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
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        Map<String, Object> postResponseLead = (Map<String, Object>) responseEnvelope.get('data');
        Map<String, Object> postResponsePropertyAccount = (Map<String, Object>) ((List<Object>) postResponseLead.get('propertyAccounts'))[0];
        Map<String, Object> postResponseUtilityAccountLog = (Map<String, Object>) ((List<Object>) postResponsePropertyAccount.get('utilityAccountLogs'))[0];

        // </setup>

        String patchRequest = '{' +
            '"id":"' + postResponseUtilityAccountLog.get('id') + '",' +
            '"annualKWh":8000' +
            '}';

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/utility-account-logs';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseUAL = (Map<String,Object>) responseEnvelope.get('data');

        System.assertEquals(200, response.statusCode, 'Properly formed PATCH should succeed');

        System.assertEquals(8000, responseUAL.get('annualKWh'));

    }

    /** General Verb **/

    @IsTest
    public static void testPatchInvalidPath() {
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '"}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/some-invalid-path';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();

        System.assertEquals(404, RestContext.response.statusCode, 'PATCHing to an invalid path should give a 404 - not found');
    }

    @IsTest
    public static void testPatchServerError() {
        String jsonRequest = 'bogusJSONString';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();

        System.assertEquals(500, RestContext.response.statusCode, 'PATCHing with invalid JSON should yield a 500');
    }

    @IsTest
    public static void testPostInvalidPath() {
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '"}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/some-invalid-path';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        System.assertEquals(404, RestContext.response.statusCode, 'POSTing to an invalid path should give a 404 - not found');
    }

    @IsTest
    public static void testPostServerError() {
        String jsonRequest = 'bogusJSONString';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        System.assertEquals(500, RestContext.response.statusCode, 'PATCHing with invalid JSON should yield a 500');
    }

}