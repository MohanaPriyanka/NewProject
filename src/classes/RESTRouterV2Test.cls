/**
 * Created by jlugo on 2019-07-09.
 */

@IsTest
public with sharing class RESTRouterV2Test {

    private static String validJsonRequest = '{' +
        '"firstName": "System",' +
        '"lastName": "Testcase",' +
        '"email": "test@invalid.bluewavesolar.com",' +
        '"mobilePhone": "555-555-5555",' +
        '"applicationType": "Residential",' +
        '"streetAddress": "1 Test Street",' +
        '"city": "Suffern",' +
        '"state": "NY",' +
        '"zipCode": "10901",' +
        '"eiaId": "1234",' +
        '"continueApplicationLink": "http://switch.bluewavesolar.invalid",' +
        '"productName": "CS Product",' +
        '"propertyAccounts": [{' +
        '   "billingStreet": "Test billing street",' +
        '   "billingCity": "Test billing city",' +
        '   "billingState": "NY",' +
        '   "billingPostalCode": "14472",' +
        '   "utilityAccountLogs": [{' +
        '       "nameOnAccount": "Test Accounts Payable",' +
        '       "serviceStreet": "Test service street",' +
        '       "serviceCity": "Test service city",' +
        '       "serviceState": "NY",' +
        '       "servicePostalCode": "14472",' +
        '       "utilityAccountNumber": "555555"' +
        '   }]' +
        '}]}';

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

    @IsTest
    public static void testPostRequestSuccess() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;

        Map<String, Object> requestLead = (Map<String,Object>) JSON.deserializeUntyped(validJsonRequest);
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
    public static void testPostRequestNoFields() {
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '"}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        System.assertEquals(400, RestContext.response.statusCode, 'POST should throw an error when required fields are not provided');
    }

    @IsTest
    public static void testPostRequestInvalidPath() {
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
    public static void testPatchRequestLeadSuccess() {

        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validJsonRequest);

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

    @IsTest
    public static void testPatchLeadNoFields() {
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '"}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();

        System.assertEquals(404, RestContext.response.statusCode, 'PATCH should throw an error when the ID doesn\'t exist');
    }


    @IsTest
    public static void testPatchRequestPropertyAccountSuccess() {

        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validJsonRequest);

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

    @IsTest
    public static void testPatchRequestUtilityAccountLogSuccess() {

        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validJsonRequest);

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


    @IsTest
    public static void testPatchRequestInvalidPath() {
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

}