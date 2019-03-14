/**
 * Created by mstackhouse on 3/6/2019.
 * Description: 
 * Test: 
 */

@IsTest
public with sharing class CSLeadsRESTControllerV1Test {
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
        PatchResponseEnvelope patchResponseEnvelope = (PatchResponseEnvelope) JSON.deserialize(jsonResponse, PatchResponseEnvelope.class);

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
        PatchResponseEnvelope patchResponseEnvelope = (PatchResponseEnvelope) JSON.deserialize(jsonResponse, PatchResponseEnvelope.class);

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
        PatchResponseEnvelope patchResponseEnvelope = (PatchResponseEnvelope) JSON.deserialize(jsonResponse, PatchResponseEnvelope.class);

        System.assertEquals(null, patchResponseEnvelope.data);
        System.assertEquals(true, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
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
        System.assertEquals(false, patchResponseEnvelope.errors.isEmpty());
        System.assertEquals(true, patchResponseEnvelope.messages.isEmpty());
    }

    public class PatchResponseEnvelope {
        public CSLeadsRESTControllerV1.PatchResponse data;
        public List<String> messages;
        public List<String> errors;
    }
}
