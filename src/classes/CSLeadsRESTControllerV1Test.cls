/**
 * Created by mstackhouse on 3/6/2019.
 * Description: 
 * Test: 
 */

@IsTest
public with sharing class CSLeadsRESTControllerV1Test {
    @TestSetup
    public static void testSetup() {
        Utility__c utility = new Utility__c(
            Name = 'Utility'
        );
        insert utility;

        Product2 product = new Product2(
            Name = 'test product'
        );
        insert product;
    }

    @IsTest
    public static void testPatchUpdatesPrivacyPolicy() {
        Lead leadToPatch = new Lead(
            FirstName = 'marvin',
            LastName = 'testcase',
            Company = 'bluewave'
        );

        insert leadToPatch;

        Lead insertedLead = [
            SELECT Id, Privacy_Policy_Acknowledged__c
            FROM Lead
            WHERE Id = : leadToPatch.Id
            LIMIT 1
        ];

        System.assertEquals(false, insertedLead.Privacy_Policy_Acknowledged__c, 'privacy policy should default to false');

        String jsonRequest = '{"data":{' +
            '"id":"' + leadToPatch.Id + '",' +
            '"customerAcknowledgement":true' +
            '}}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v1/CSLeads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        CSLeadsRESTControllerV1.patchRequest();

        RestResponse response = RestContext.response;
        System.assertEquals(200, response.statuscode);

        String jsonResponse = response.responseBody.toString();
        PatchResponseEnvelope patchResponseEnvelope = (PatchResponseEnvelope) JSON.deserialize(jsonResponse, PatchResponseEnvelope.class);

        System.assertEquals(leadToPatch.Id, patchResponseEnvelope.data.id);
        System.assertEquals(true, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());

        Lead patchedLead = [
            SELECT Id, Privacy_Policy_Acknowledged__c
            FROM Lead
            WHERE Id = : leadToPatch.Id
            LIMIT 1
        ];
        System.assertEquals(true, patchedLead.Privacy_Policy_Acknowledged__c, 'privacy policy should be acknowledged');
    }

    @IsTest
    public static void testPatchUpdatesZuoraPaymentInfo() {
        Lead leadToPatch = new Lead(
            FirstName = 'marvin',
            LastName = 'testcase',
            Company = 'bluewave'
        );

        insert leadToPatch;

        Lead insertedLead = [
            SELECT Id, Zuora_Payment_Ref_Id__c, Zuora_Payment_Ref_Id_Expiration_Date__c
            FROM Lead
            WHERE Id = : leadToPatch.Id
            LIMIT 1
        ];

        System.assertEquals(null, insertedLead.Zuora_Payment_Ref_Id__c);
        System.assertEquals(null, insertedLead.Zuora_Payment_Ref_Id_Expiration_Date__c);

        String jsonRequest = '{"data":{' +
            '"id":"' + leadToPatch.Id + '",' +
            '"zuoraPaymentRefId":"mock-zuoraId",' +
            '"zuoraPaymentRefIdExpirationDate":"2019-01-05T14:00-05:00"' +
            '}}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v1/CSLeads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        CSLeadsRESTControllerV1.patchRequest();

        RestResponse response = RestContext.response;
        System.assertEquals(200, response.statuscode);

        String jsonResponse = response.responseBody.toString();
        PatchResponseEnvelope patchResponseEnvelope = (PatchResponseEnvelope) JSON.deserialize(jsonResponse, PatchResponseEnvelope.class);

        System.assertEquals(leadToPatch.Id, patchResponseEnvelope.data.id);
        System.assertEquals(true, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());

        Lead patchedLead = [
            SELECT Id, Zuora_Payment_Ref_Id__c, Zuora_Payment_Ref_Id_Expiration_Date__c
            FROM Lead
            WHERE Id = : leadToPatch.Id
            LIMIT 1
        ];

        System.assertEquals('mock-zuoraId', patchedLead.Zuora_Payment_Ref_Id__c);
        System.assertEquals(Datetime.newInstanceGMT(2019,01,05,19,0,0), patchedLead.Zuora_Payment_Ref_Id_Expiration_Date__c);
    }

    @IsTest
    public static void testPatchUpdatesInvalidFields() {
        Lead leadToPatch = new Lead(
            FirstName = 'marvin',
            LastName = 'testcase',
            Company = 'bluewave'
        );

        insert leadToPatch;

        Lead insertedLead = [
            SELECT Id
            FROM Lead
            WHERE Id = : leadToPatch.Id
            LIMIT 1
        ];

        String jsonRequest = '{"data":{' +
            '"id":"' + leadToPatch.Id + '",' +
            '"Name":"UpdateName"' +
            '}}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v1/CSLeads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        CSLeadsRESTControllerV1.patchRequest();

        RestResponse response = RestContext.response;
        System.assertEquals(400, response.statuscode);
        String jsonResponse = response.responseBody.toString();
        PatchResponseEnvelope patchResponseEnvelope = (PatchResponseEnvelope) JSON.deserialize(jsonResponse, PatchResponseEnvelope.class);

        System.assertEquals(null, patchResponseEnvelope.data);
        System.assertEquals(false, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals('Request did not include correct fields to update', patchResponseEnvelope.errors[0]);
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
    }

    @IsTest
    public static void testPatchNoLead() {
        String jsonRequest = '{"data":{' +
            '"id":"00Q000000000000",' +
            '"Name":"UpdateName"' +
            '}}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v1/CSLeads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        CSLeadsRESTControllerV1.patchRequest();

        RestResponse response = RestContext.response;
        System.assertEquals(404, response.statuscode);
        String jsonResponse = response.responseBody.toString();
        PatchResponseEnvelope patchResponseEnvelope = (PatchResponseEnvelope) JSON.deserialize(jsonResponse, PatchResponseEnvelope.class);

        System.assertEquals(null, patchResponseEnvelope.data);
        System.assertEquals(true, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
    }

    @IsTest
    public static void testPostResiLead() {
        Product2 testProduct = [
            SELECT Id
            FROM Product2
            WHERE Name = 'test product'
        ];

        String jsonRequest = '{' +
            '"data": {' +
            '"firstName": "string", ' +
            '"lastName": "string", ' +
            '"email": "test@example.com", ' +
            '"mobilePhone":	"1231231234", ' +
            '"applicationType": "Residential", ' +
            '"billingStreetAddress": "string", ' +
            '"billingCity": "string", ' +
            '"billingState":	"MA", ' +
            '"billingZIPCode":	"12345", ' +
            '"serviceZIPCode":	"12345", ' +
            '"loadZone":	"string", ' +
            '"utilityName": "Utility",' +
            '"productId":	"' + testProduct.Id + '"}}';

        System.debug(jsonRequest);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v1/CSLeads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        CSLeadsRESTControllerV1.postRequest();

        RestResponse response = RestContext.response;
        System.assertEquals(201, response.statuscode);

        String jsonResponse = response.responseBody.toString();
        PatchResponseEnvelope patchResponseEnvelope = (PatchResponseEnvelope) JSON.deserialize(jsonResponse, PatchResponseEnvelope.class);

        System.assertNotEquals(null, patchResponseEnvelope.data.id);
        System.assertEquals(true, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
    }

    @IsTest
    public static void testPostNonResiLead() {
        Product2 testProduct = [
            SELECT Id
            FROM Product2
            WHERE Name = 'test product'
        ];

        String jsonRequest = '{' +
            '"data": {' +
            '"firstName": "string", ' +
            '"lastName": "string", ' +
            '"email": "test@example.com", ' +
            '"mobilePhone":	"1231231234", ' +
            '"applicationType": "Residential", ' +
            '"billingStreetAddress": "string", ' +
            '"billingCity": "string", ' +
            '"billingState":	"MA", ' +
            '"billingZIPCode":	"12345", ' +
            '"serviceZIPCode":	"12345", ' +
            '"loadZone":	"string", ' +
            '"utilityName": "Utility",' +
            '"productId":	"' + testProduct.Id + '"}}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v1/CSLeads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        CSLeadsRESTControllerV1.postRequest();

        RestResponse response = RestContext.response;
        System.assertEquals(201, response.statuscode);

        String jsonResponse = response.responseBody.toString();
        PatchResponseEnvelope patchResponseEnvelope = (PatchResponseEnvelope) JSON.deserialize(jsonResponse, PatchResponseEnvelope.class);

        System.assertNotEquals(null, patchResponseEnvelope.data.id);
        System.assertEquals(true, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
    }

    @IsTest
    public static void testPostMissingFields() {
        String jsonRequest = '{' +
            '"data": {' +
            '"firstName": "string", ' +
            '"lastName": "string", ' +
            '"email": "test@example.com", ' +
            '"mobilePhone":	"1231231234", ' +
            '"applicationType": "Residential", ' +
            '"serviceZIPCode":	"12345", ' +
            '"loadZone":	"string", ' +
            '"utilityName": "Utility"}}';


        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v1/CSLeads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        CSLeadsRESTControllerV1.postRequest();

        RestResponse response = RestContext.response;
        System.assertEquals(400, response.statuscode);

        String jsonResponse = response.responseBody.toString();
        PatchResponseEnvelope patchResponseEnvelope = (PatchResponseEnvelope) JSON.deserialize(jsonResponse, PatchResponseEnvelope.class);

        System.assertEquals(null, patchResponseEnvelope.data);
        System.assertEquals(false, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals('Request may be missing required fields.', patchResponseEnvelope.errors[0]);
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
    }

    @IsTest
    public static void testRequestLeadClass() {
        CSLeadsRESTControllerV1.RequestLead lead = new CSLeadsRESTControllerV1.RequestLead();

        System.assert(!lead.hasAcknowledgement(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasZuoraPaymentInfo(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasRequiredPostFields(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasBasicFields(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasBusinessFieldsIfRequired(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasValidApplicationType(), 'RequestLead is empty, validations should be false');

        lead.customerAcknowledgement = true;
        System.assert(lead.hasAcknowledgement(), 'RequestLead hasAcknowledgements');
        lead.customerAcknowledgement = false;
        System.assert(lead.hasAcknowledgement(), 'RequestLead hasAcknowledgements');

        lead.zuoraPaymentRefId = 'zuoraId';
        lead.zuoraPaymentRefIdExpirationDate = Datetime.now();
        System.assert(lead.hasZuoraPaymentInfo(), 'RequestLead zuora payment info');

        lead.firstName = 'max';
        lead.lastName = 'testcase';
        lead.email = 'max@email.com';
        System.assert(!lead.hasRequiredPostFields(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasBasicFields(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasBusinessFieldsIfRequired(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasValidApplicationType(), 'RequestLead is empty, validations should be false');

        lead.mobilePhone = '1231231234';
        lead.billingStreetAddress = 'street';
        lead.billingCity = 'city';
        lead.billingState = 'state';
        lead.billingZIPCode = 'zipcode';
        lead.serviceZIPCode = 'zipcode';
        lead.loadZone = 'loadzone';
        lead.utilityName = 'utility name';
        lead.productId = '00Q000000000000';
        lead.applicationType = 'Residential';

        System.assert(lead.hasRequiredPostFields(), 'RequestLead has required fields');
        System.assert(lead.hasBasicFields(), 'RequestLead has basic required fields');
        System.assert(lead.hasBusinessFieldsIfRequired(), 'RequestLead is residential, does not need business fields');
        System.assert(lead.hasValidApplicationType(), 'RequestLead is Residential');

        lead.applicationType = 'Non-Residential';
        System.assert(!lead.hasRequiredPostFields(), 'RequestLead is missing non-residential fields');
        System.assert(lead.hasBasicFields(), 'RequestLead has basic required fields');
        System.assert(!lead.hasBusinessFieldsIfRequired(), 'RequestLead is non-residential, missing fields');
        System.assert(lead.hasValidApplicationType(), 'RequestLead is Non-Residential');

        lead.businessName = 'business';
        lead.businessPhone = '1231231234';
        lead.businessTitle = 'owner';
        System.assert(lead.hasRequiredPostFields(), 'RequestLead has required fields');
        System.assert(lead.hasBasicFields(), 'RequestLead has basic required fields');
        System.assert(lead.hasBusinessFieldsIfRequired(), 'RequestLead is residential, does not need business fields');
        System.assert(lead.hasValidApplicationType(), 'RequestLead is Non-Residential');

        lead.applicationType = 'Loan';
        System.assert(!lead.hasValidApplicationType(), 'RequestLead should be an invalid type');
    }

    @IsTest
    public static void testRequestLeadAsResiLead() {
        CSLeadsRESTControllerV1.RequestLead lead = new CSLeadsRESTControllerV1.RequestLead();

        System.assert(!lead.hasAcknowledgement(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasZuoraPaymentInfo(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasRequiredPostFields(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasBasicFields(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasBusinessFieldsIfRequired(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasValidApplicationType(), 'RequestLead is empty, validations should be false');

        lead.customerAcknowledgement = true;
        System.assert(lead.hasAcknowledgement(), 'RequestLead hasAcknowledgements');
        lead.customerAcknowledgement = false;
        System.assert(lead.hasAcknowledgement(), 'RequestLead hasAcknowledgements');

        lead.zuoraPaymentRefId = 'zuoraId';
        lead.zuoraPaymentRefIdExpirationDate = Datetime.now();
        System.assert(lead.hasZuoraPaymentInfo(), 'RequestLead zuora payment info');

        lead.firstName = 'max';
        lead.lastName = 'testcase';
        lead.email = 'max@email.com';
        System.assert(!lead.hasRequiredPostFields(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasBasicFields(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasBusinessFieldsIfRequired(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasValidApplicationType(), 'RequestLead is empty, validations should be false');

        lead.mobilePhone = '1231231234';
        lead.billingStreetAddress = 'street';
        lead.billingCity = 'city';
        lead.billingState = 'state';
        lead.billingZIPCode = 'zipcode';
        lead.serviceZIPCode = 'zipcode';
        lead.loadZone = 'loadzone';
        lead.utilityName = 'utility name';
        lead.productId = '00Q000000000000';
        lead.applicationType = 'Residential';

        System.assert(lead.hasRequiredPostFields(), 'RequestLead has required fields');
        System.assert(lead.hasBasicFields(), 'RequestLead has basic required fields');
        System.assert(lead.hasBusinessFieldsIfRequired(), 'RequestLead is residential, does not need business fields');
        System.assert(lead.hasValidApplicationType(), 'RequestLead is Residential');

        lead.applicationType = 'Non-Residential';
        System.assert(!lead.hasRequiredPostFields(), 'RequestLead is missing non-residential fields');
        System.assert(lead.hasBasicFields(), 'RequestLead has basic required fields');
        System.assert(!lead.hasBusinessFieldsIfRequired(), 'RequestLead is non-residential, missing fields');
        System.assert(lead.hasValidApplicationType(), 'RequestLead is Non-Residential');

        lead.businessName = 'business';
        lead.businessPhone = '1231231234';
        lead.businessTitle = 'owner';
        System.assert(lead.hasRequiredPostFields(), 'RequestLead has required fields');
        System.assert(lead.hasBasicFields(), 'RequestLead has basic required fields');
        System.assert(lead.hasBusinessFieldsIfRequired(), 'RequestLead is residential, does not need business fields');
        System.assert(lead.hasValidApplicationType(), 'RequestLead is Non-Residential');

        lead.applicationType = 'Loan';
        System.assert(!lead.hasValidApplicationType(), 'RequestLead should be an invalid type');
    }

    @IsTest
    public static void testRequestLeadAsNonResiLead() {
        CSLeadsRESTControllerV1.RequestLead lead = new CSLeadsRESTControllerV1.RequestLead();

        System.assert(!lead.hasAcknowledgement(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasZuoraPaymentInfo(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasRequiredPostFields(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasBasicFields(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasBusinessFieldsIfRequired(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasValidApplicationType(), 'RequestLead is empty, validations should be false');

        lead.customerAcknowledgement = true;
        System.assert(lead.hasAcknowledgement(), 'RequestLead hasAcknowledgements');
        lead.customerAcknowledgement = false;
        System.assert(lead.hasAcknowledgement(), 'RequestLead hasAcknowledgements');

        lead.zuoraPaymentRefId = 'zuoraId';
        lead.zuoraPaymentRefIdExpirationDate = Datetime.now();
        System.assert(lead.hasZuoraPaymentInfo(), 'RequestLead zuora payment info');

        lead.firstName = 'max';
        lead.lastName = 'testcase';
        lead.email = 'max@email.com';
        System.assert(!lead.hasRequiredPostFields(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasBasicFields(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasBusinessFieldsIfRequired(), 'RequestLead is empty, validations should be false');
        System.assert(!lead.hasValidApplicationType(), 'RequestLead is empty, validations should be false');

        lead.mobilePhone = '1231231234';
        lead.billingStreetAddress = 'street';
        lead.billingCity = 'city';
        lead.billingState = 'state';
        lead.billingZIPCode = 'zipcode';
        lead.serviceZIPCode = 'zipcode';
        lead.loadZone = 'loadzone';
        lead.utilityName = 'utility name';
        lead.productId = '00Q000000000000';
        lead.applicationType = 'Residential';

        System.assert(lead.hasRequiredPostFields(), 'RequestLead has required fields');
        System.assert(lead.hasBasicFields(), 'RequestLead has basic required fields');
        System.assert(lead.hasBusinessFieldsIfRequired(), 'RequestLead is residential, does not need business fields');
        System.assert(lead.hasValidApplicationType(), 'RequestLead is Residential');

        lead.applicationType = 'Non-Residential';
        System.assert(!lead.hasRequiredPostFields(), 'RequestLead is missing non-residential fields');
        System.assert(lead.hasBasicFields(), 'RequestLead has basic required fields');
        System.assert(!lead.hasBusinessFieldsIfRequired(), 'RequestLead is non-residential, missing fields');
        System.assert(lead.hasValidApplicationType(), 'RequestLead is Non-Residential');

        lead.businessName = 'business';
        lead.businessPhone = '1231231234';
        lead.businessTitle = 'owner';
        System.assert(lead.hasRequiredPostFields(), 'RequestLead has required fields');
        System.assert(lead.hasBasicFields(), 'RequestLead has basic required fields');
        System.assert(lead.hasBusinessFieldsIfRequired(), 'RequestLead is residential, does not need business fields');
        System.assert(lead.hasValidApplicationType(), 'RequestLead is Non-Residential');

        lead.applicationType = 'Loan';
        System.assert(!lead.hasValidApplicationType(), 'RequestLead should be an invalid type');
    }

    @IsTest
    public static void testPatchServerError() {
        String jsonRequest = 'bogusJSONString';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v1/CSLeads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        CSLeadsRESTControllerV1.patchRequest();

        RestResponse response = RestContext.response;
        System.assertEquals(500, response.statuscode);
        String jsonResponse = response.responseBody.toString();
        PatchResponseEnvelope patchResponseEnvelope = (PatchResponseEnvelope) JSON.deserialize(jsonResponse, PatchResponseEnvelope.class);

        System.assertEquals(null, patchResponseEnvelope.data);
        System.assertEquals(true, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
    }

    @IsTest
    public static void testPostServerError() {
        String jsonRequest = 'bogusJSONString';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v1/CSLeads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        CSLeadsRESTControllerV1.postRequest();

        RestResponse response = RestContext.response;
        System.assertEquals(500, response.statuscode);
        String jsonResponse = response.responseBody.toString();
        PatchResponseEnvelope patchResponseEnvelope = (PatchResponseEnvelope) JSON.deserialize(jsonResponse, PatchResponseEnvelope.class);

        System.assertEquals(null, patchResponseEnvelope.data);
        System.assertEquals(true, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
    }

    public class PatchResponseEnvelope {
        public CSLeadsRESTControllerV1.PatchResponse data;
        public List<String> messages;
        public List<String> errors;
    }
}