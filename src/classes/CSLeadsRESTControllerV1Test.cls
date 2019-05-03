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
            Name = 'CS Product'
        );
        insert product;
    }

    @IsTest
    public static void testPatchUpdatesPrivacyPolicy() {
        Utility__c utility = new Utility__c(
            Name = 'Utility'
        );
        insert utility;

        Product2 product = new Product2(
            Name = 'CS Product'
        );
        insert product;

        Partner__c partner = new Partner__c(
            Name = 'Mass Renewables',
            CS_Referral_Status__c = 'Default CS Partner',
            Email__c = 'massRenewables@test.com');

        insert partner;

        BSST__c salesRep2 = new BSST__c(
            Name = 'Dianne Martz',
            Partner__c = partner.Id,
            Email__c = 'martz@testemail.com');
        insert salesRep2;

        Contact contactRecord = new Contact(
            FirstName = 'User',
            LastName = 'Swain');
        insert contactRecord;

        Lead leadToPatch = new Lead(
            FirstName = 'marvin',
            LastName = 'testcase',
            Company = 'bluewave',
            Email = 'test@email.com',
            MobilePhone = '1231231234',
            Application_Type__c = 'Residential',
            LASERCA__Home_Address__c = '123 fake st',
            LASERCA__Home_City__c = 'city',
            LASERCA__Home_State__c = 'MA',
            LASERCA__Home_Zip__c = '12345',
            Parcel_Zip__c = '12345',
            LoadZone__c = 'SEMA',
            Utility_relationship__c = utility.Id,
            Product__c = product.Id,
            Partner_Lookup__c = partner.Id,
            bs_Sales_ID__c = salesRep2.Id,
            Customer_Referral__c = contactRecord.Id,
            Application_Complete_Date__c = Date.newInstance(2019, 5, 01)
        );

        insert leadToPatch;

        Lead insertedLead = [
            SELECT Id, Privacy_Policy_Acknowledged__c
            FROM Lead
            WHERE Id = : leadToPatch.Id
            LIMIT 1
        ];

        System.assertEquals(false, insertedLead.Privacy_Policy_Acknowledged__c, 'privacy policy should default to false');

        String jsonRequest = '{' +
            '"id":"' + leadToPatch.Id + '",' +
            '"customerAcknowledgement":true,' +
            '"customerAgreementText":"I Agree"' +
            '}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v1/CSLeads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        CSLeadsRESTControllerV1.patchRequest();

        RestResponse response = RestContext.response;
        System.assertEquals(200, response.statusCode);

        String jsonResponse = response.responseBody.toString();

        ResponseEnvelope patchResponseEnvelope = (ResponseEnvelope) JSON.deserialize(jsonResponse, ResponseEnvelope.class);

        System.assertEquals(leadToPatch.Id, patchResponseEnvelope.data.Id);
        System.assertEquals(true, patchResponseEnvelope.data.customerAcknowledgement);
        System.assertEquals('I Agree', patchResponseEnvelope.data.customerAgreementText);
        System.assertNotEquals(null, patchResponseEnvelope.data.firstName);
        System.assertNotEquals(null, patchResponseEnvelope.data.lastName);
        System.assertNotEquals(null, patchResponseEnvelope.data.email);
        System.assertNotEquals(null, patchResponseEnvelope.data.mobilePhone);
        System.assertNotEquals(null, patchResponseEnvelope.data.applicationType);
        System.assertNotEquals(null, patchResponseEnvelope.data.billingStreetAddress);
        System.assertNotEquals(null, patchResponseEnvelope.data.billingCity);
        System.assertNotEquals(null, patchResponseEnvelope.data.billingState);
        System.assertNotEquals(null, patchResponseEnvelope.data.billingZIPCode);
        System.assertNotEquals(null, patchResponseEnvelope.data.serviceZIPCode);
        System.assertNotEquals(null, patchResponseEnvelope.data.loadZone);
        System.assertNotEquals(null, patchResponseEnvelope.data.partnerId);
        System.assertNotEquals(null, patchResponseEnvelope.data.salesRepId);
        System.assertNotEquals(null, patchResponseEnvelope.data.referralCode);
        System.assertNotEquals(null, patchResponseEnvelope.data.productName);
        System.assertNotEquals(null, patchResponseEnvelope.data.utilityName);
        System.assertNotEquals(null, patchResponseEnvelope.data.applicationCompleteDate);
        System.assertEquals(Date.newInstance(2019, 5, 01), patchResponseEnvelope.data.applicationCompleteDate);
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
    
    @IsTest // apparently you can spell it either acknowledgement or acknowledgment...
    public static void testPatchAcknowledgmentSpelledWithoutAnE() {
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

            String jsonRequest = '{' +
                '"id":"' + leadToPatch.Id + '",' +
                '"customerAcknowledgment":true,' +
                '"customerAgreementText":"I Agree"' +
                '}';

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
        ResponseEnvelope patchResponseEnvelope = (ResponseEnvelope) JSON.deserialize(jsonResponse, ResponseEnvelope.class);

        System.assertEquals(leadToPatch.Id, patchResponseEnvelope.data.id);
        System.assertEquals(true, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(false, patchResponseEnvelope.messages.isEmpty());
        String message = 'Autocorreted the request to update the spelling of ' +
            'acknowledgment to acknowledgement, with an e.';
        System.assertEquals(message, patchResponseEnvelope.messages[0]);

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

        String jsonRequest = '{' +
            '"id":"' + leadToPatch.Id + '",' +
            '"zuoraPaymentRefId":"mock-zuoraId",' +
            '"zuoraPaymentRefIdExpirationDate":"2019-01-05T14:00-05:00"' +
            '}';

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
        ResponseEnvelope patchResponseEnvelope = (ResponseEnvelope) JSON.deserialize(jsonResponse, ResponseEnvelope.class);

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

        String jsonRequest = '{' +
            '"id":"' + leadToPatch.Id + '",' +
            '"Name":"UpdateName"' +
            '}';

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
        ResponseEnvelope patchResponseEnvelope = (ResponseEnvelope) JSON.deserialize(jsonResponse, ResponseEnvelope.class);

        System.assertEquals(null, patchResponseEnvelope.data);
        System.assertEquals(false, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals('Request did not include correct fields to update', patchResponseEnvelope.errors[0]);
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
    }

    @IsTest
    public static void testPatchNoLead() {
        String jsonRequest = '{' +
            '"id":"00Q000000000000",' +
            '"Name":"UpdateName"' +
            '}';

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
        ResponseEnvelope patchResponseEnvelope = (ResponseEnvelope) JSON.deserialize(jsonResponse, ResponseEnvelope.class);

        System.assertEquals(null, patchResponseEnvelope.data);
        System.assertEquals(true, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
    }

    @IsTest
    public static void testPostResiLead() {
        Partner__c partner = new Partner__c(
            Name = 'Bluewave Inside Sales',
            CS_Referral_Status__c = 'Default CS Partner',
            Email__c = 'bluewave@bluewavesolar.com');

        insert partner;

        BSST__c salesRep2 = new BSST__c(
            Name = 'Dianne Martz',
            Partner__c = partner.Id,
            Email__c = 'martz@testemail.com');
        insert salesRep2;
        partner.Default_Sales_Rep__c = salesRep2.Id;
        update partner;

        Contact contactRecord = new Contact(
            FirstName = 'User',
            LastName = 'Swain');
        insert contactRecord;

        String jsonRequest = '{' +
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
            '"loadZone":	"SEMA", ' +
            '"utilityName": "Utility",' +
            '"productName":	"CS Product",' +
            '"partnerId": "' + partner.Id+ '",' +
            '"salesRepId": "' + salesRep2.Id+ '",' +
            '"referralCode": "' + contactRecord.Id+ '"' +
            '}';

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
        ResponseEnvelope patchResponseEnvelope = (ResponseEnvelope) JSON.deserialize(jsonResponse, ResponseEnvelope.class);

        System.assertEquals(true, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());

        System.assertNotEquals(null, patchResponseEnvelope.data.id);
        System.assertEquals(false, patchResponseEnvelope.data.customerAcknowledgement);
        System.assertEquals(null    , patchResponseEnvelope.data.customerAgreementText);
        System.assertNotEquals(null, patchResponseEnvelope.data.firstName);
        System.assertNotEquals(null, patchResponseEnvelope.data.lastName);
        System.assertNotEquals(null, patchResponseEnvelope.data.email);
        System.assertNotEquals(null, patchResponseEnvelope.data.mobilePhone);
        System.assertNotEquals(null, patchResponseEnvelope.data.applicationType);
        System.assertNotEquals(null, patchResponseEnvelope.data.billingStreetAddress);
        System.assertNotEquals(null, patchResponseEnvelope.data.billingCity);
        System.assertNotEquals(null, patchResponseEnvelope.data.billingState);
        System.assertNotEquals(null, patchResponseEnvelope.data.billingZIPCode);
        System.assertNotEquals(null, patchResponseEnvelope.data.serviceZIPCode);
        System.assertNotEquals(null, patchResponseEnvelope.data.loadZone);
        System.assertNotEquals(null, patchResponseEnvelope.data.referralCode);
        System.assertNotEquals(null, patchResponseEnvelope.data.productName);
        System.assertNotEquals(null, patchResponseEnvelope.data.utilityName);
        System.assertNotEquals(null, patchResponseEnvelope.data.partnerId);
        System.assertNotEquals(null, patchResponseEnvelope.data.salesRepId);
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
        ResponseEnvelope patchResponseEnvelope = (ResponseEnvelope) JSON.deserialize(jsonResponse, ResponseEnvelope.class);

        System.assertEquals(null, patchResponseEnvelope.data);
        System.assertEquals(false, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
    }

    @IsTest
    public static void testPostNonResiLead() {
        Partner__c partner = new Partner__c(
            Name = 'Bluewave Inside Sales',
            CS_Referral_Status__c = 'Default CS Partner',
            Email__c = 'bluewave@bluewavesolar.com');

        insert partner;

        BSST__c salesRep2 = new BSST__c(
            Name = 'Dianne Martz',
            Partner__c = partner.Id,
            Email__c = 'martz@testemail.com');
        insert salesRep2;

        partner.Default_Sales_Rep__c = salesRep2.Id;
        update partner;

        Contact contactRecord = new Contact(
            FirstName = 'User',
            LastName = 'Swain');
        insert contactRecord;

        String jsonRequest = '{' +
            '"firstName": "string", ' +
            '"lastName": "string", ' +
            '"email": "test@example.com", ' +
            '"mobilePhone":	"1231231234", ' +
            '"applicationType": "Non-Residential", ' +
            '"billingStreetAddress": "string", ' +
            '"billingCity": "string", ' +
            '"billingState":	"MA", ' +
            '"billingZIPCode":	"12345", ' +
            '"serviceZIPCode":	"12345", ' +
            '"businessName":	"Test CO", ' +
            '"businessTitle":	"Owner", ' +
            '"businessPhone":	"3213124321", ' +
            '"loadZone":	"SEMA", ' +
            '"utilityName": "Utility", ' +
            '"productName":	"CS Product", ' +
            '"partnerId": "' + partner.Id+ '", ' +
            '"salesRepId": "' + salesRep2.Id+ '", ' +
            '"referralCode": "' + contactRecord.Id+ '"' +
            '}';

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
        ResponseEnvelope patchResponseEnvelope = (ResponseEnvelope) JSON.deserialize(jsonResponse, ResponseEnvelope.class);

        System.assertEquals(true, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());

        System.assertNotEquals(null, patchResponseEnvelope.data.id);
        System.assertEquals(false, patchResponseEnvelope.data.customerAcknowledgement);
        System.assertEquals(null, patchResponseEnvelope.data.customerAgreementText);
        System.assertNotEquals(null, patchResponseEnvelope.data.firstName);
        System.assertNotEquals(null, patchResponseEnvelope.data.lastName);
        System.assertNotEquals(null, patchResponseEnvelope.data.email);
        System.assertNotEquals(null, patchResponseEnvelope.data.mobilePhone);
        System.assertNotEquals(null, patchResponseEnvelope.data.applicationType);
        System.assertNotEquals(null, patchResponseEnvelope.data.billingStreetAddress);
        System.assertNotEquals(null, patchResponseEnvelope.data.billingCity);
        System.assertNotEquals(null, patchResponseEnvelope.data.billingState);
        System.assertNotEquals(null, patchResponseEnvelope.data.billingZIPCode);
        System.assertNotEquals(null, patchResponseEnvelope.data.serviceZIPCode);
        System.assertNotEquals(null, patchResponseEnvelope.data.loadZone);
        System.assertNotEquals(null, patchResponseEnvelope.data.referralCode);
        System.assertNotEquals(null, patchResponseEnvelope.data.productName);
        System.assertNotEquals(null, patchResponseEnvelope.data.utilityName);
        System.assertNotEquals(null, patchResponseEnvelope.data.businessName);
        System.assertNotEquals(null, patchResponseEnvelope.data.businessPhone);
        System.assertNotEquals(null, patchResponseEnvelope.data.businessTitle);
        System.assertNotEquals(null, patchResponseEnvelope.data.salesRepId);
        System.assertNotEquals(null, patchResponseEnvelope.data.partnerId);
    }

    @IsTest
    public static void testPostMissingFields() {
        String jsonRequest = '{' +
            '"firstName": "string", ' +
            '"lastName": "string", ' +
            '"email": "test@example.com", ' +
            '"mobilePhone":	"1231231234", ' +
            '"applicationType": "Residential", ' +
            '"serviceZIPCode":	"12345", ' +
            '"loadZone":	"string", ' +
            '"utilityName": "Utility"}';


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
        ResponseEnvelope patchResponseEnvelope = (ResponseEnvelope) JSON.deserialize(jsonResponse, ResponseEnvelope.class);

        System.assertEquals(null, patchResponseEnvelope.data);
        System.assertEquals(false, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals('Request may be missing required fields.', patchResponseEnvelope.errors[0]);
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
        ResponseEnvelope patchResponseEnvelope = (ResponseEnvelope) JSON.deserialize(jsonResponse, ResponseEnvelope.class);

        System.assertEquals(null, patchResponseEnvelope.data);
        System.assertEquals(false, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
    }

    @IsTest
    public static void testRequestLeadClass() {
        CSLeadsRESTControllerV1.RestLead lead = new CSLeadsRESTControllerV1.RestLead();

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
        lead.productName = 'CS Product';
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

    public class ResponseEnvelope {
        public CSLeadsRESTControllerV1.RestLead data;
        public List<String> messages;
        public List<String> errors;
    }
}