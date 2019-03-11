/**
 * Created by mstackhouse on 3/6/2019.
 * Description: REST Controller for sending CS Leads to Salesforce
 * Test: CSLeadsRESTControllerV1Test
 */

@RestResource(UrlMapping='/v1/CSLeads')
global with sharing class CSLeadsRESTControllerV1 extends RESTController{
    private static CSLeadsRESTControllerV1 controller = new CSLeadsRESTControllerV1();

    @HttpPatch
    global static void patchRequest() {
        try {
            controller.patchRecords();
        } catch(Exception e) {
            CSLeadsRESTControllerV1.ResponseEnvelope envelope =  new CSLeadsRESTControllerV1.ResponseEnvelope();
            envelope.addError(e.getMessage());
            envelope.setJSONResponse(RestContext.response);
            RestContext.response.statusCode = 500;
            String errorMessage = 'Error: ' + e.getMessage();
            errorMessage += '. Request: ' + RestContext.request;
            Logger.logNow('CSLeadsRESTControllerV1', 'patchRequest', errorMessage, 'Error');
        }
    }


    protected override void patchRecords() {
        String jsonRequest = request.requestBody.toString();
        RequestLead requestLead = (RequestLead) JSON.deserialize(jsonRequest, RequestLead.class);
        List<Lead> leads = [
            SELECT Id, Privacy_Policy_Acknowledged__c
            FROM Lead
            WHERE Id = : requestLead.id
            LIMIT 1
        ];

        if (leads.isEmpty()) {
            response.statusCode = statusCode.notFound;
        } else if (requestLead.hasAcknowledgement() || requestLead.hasZuoraPaymentInfo()) {
            Lead leadToUpdate = leads[0];
            if (requestLead.hasAcknowledgement()) {
                leadToUpdate.Privacy_Policy_Acknowledged__c = requestLead.customerAcknowledgement;
                leadToUpdate.Terms_Conditions_Acknowledged__c = Datetime.now();
                leadToUpdate.Terms_Conditions__c = requestLead.customerAgreementText;
            }
            if (requestLead.hasZuoraPaymentInfo()) {
                leadToUpdate.Zuora_Payment_Ref_Id__c = requestLead.zuoraPaymentRefId;
                leadToUpdate.Zuora_Payment_Ref_Id_Expiration_Date__c = requestLead.zuoraPaymentRefIdExpirationDate;
            }

            update leadToUpdate;

            PatchResponse patchResponse = new PatchResponse(leadToUpdate.Id);
            envelope.setData(patchResponse);
            response.statusCode = statusCode.ok;
        } else {
            envelope.addError('Request did not include correct fields to update');
            response.statusCode = statusCode.badRequest;
        }

        envelope.setJSONResponse(response);
    }

    public class RequestLead {
        public Id id;
        public Boolean customerAcknowledgement;
        public String customerAgreementText;
        public String zuoraPaymentRefId;
        public DateTime zuoraPaymentRefIdExpirationDate;

        public Boolean hasAcknowledgement() {
            return (customerAcknowledgement != null);
        }

        public Boolean hasZuoraPaymentInfo() {
            return (zuoraPaymentRefId != null
                && zuoraPaymentRefIdExpirationDate != null);
        }
    }

    public class PatchResponse {
        public Id id;

        public PatchResponse(Id id) {
            this.id = id;
        }
    }
}