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
            RestContext.response.responseBody = envelope.asBlob();
            RestContext.response.statusCode = 500;
        }
    }

    @HttpPost
    global static void postRequest() {
        try {
            controller.postRecords();
        } catch(Exception e) {
            CSLeadsRESTControllerV1.ResponseEnvelope envelope =  new CSLeadsRESTControllerV1.ResponseEnvelope();
            envelope.addError(e.getMessage());
            RestContext.response.responseBody = envelope.asBlob();
            RestContext.response.statusCode = 500;
        }
    }

    protected override void patchRecords() {
        String jsonRequest = request.requestBody.toString();
        RequestEnvelope requestEnvelope = new RequestEnvelope(jsonRequest);
        RequestLead requestLead = requestEnvelope.data;
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

        response.addHeader('Content-Type', 'application/json');
        response.responseBody = envelope.asBlob();
     }

    protected override void postRecords() {
        String jsonRequest = request.requestBody.toString();
        RequestEnvelope requestEnvelope = new RequestEnvelope(jsonRequest);
        RequestLead requestLead = requestEnvelope.data;

        System.debug(requestLead.hasRequiredPostFields());
        System.debug(requestLead);
        if (requestLead.hasRequiredPostFields()) {
            Lead newLead = requestLead.asLead();

            insert newLead;

            PatchResponse patchResponse = new PatchResponse(newLead.Id);
            envelope.setData(patchResponse);
            response.statusCode = statusCode.created;
        } else {
            envelope.addError('Request may be missing required fields.');
            response.statusCode = statusCode.badRequest;
        }

        response.addHeader('Content-Type', 'application/json');
        response.responseBody = envelope.asBlob();
    }

    public class RequestEnvelope {
        public RequestLead data;

        public RequestEnvelope(String jsonRequest) {
            RequestEnvelope request = (RequestEnvelope) JSON.deserialize(jsonRequest, RequestEnvelope.class);
            data = request.data;
        }
    }

    public class RequestLead {
        public Id id;
        public Boolean customerAcknowledgement;
        public String zuoraPaymentRefId;
        public DateTime zuoraPaymentRefIdExpirationDate;
        public String firstName;
        public String lastName;
        public String email;
        public String mobilePhone;
        public String businessPhone;
        public String businessName;
        public String businessTitle;
        public String applicationType;
        public String billingStreetAddress;
        public String billingCity;
        public String billingState;
        public String billingZIPCode;
        public String serviceZIPCode;
        public String loadZone;
        public String utilityName;
        public Id partnerId;
        public Id salesRepId;
        public Id referralCode;
        public Id productId;

        public Boolean hasAcknowledgement() {
            return customerAcknowledgement != null;
        }

        public Boolean hasZuoraPaymentInfo() {
            return (zuoraPaymentRefId != null
                && zuoraPaymentRefIdExpirationDate != null);
        }

        public Boolean hasRequiredPostFields() {
            return (hasBasicFields() && hasBusinessFieldsIfRequired());
        }

        public Boolean hasValidApplicationType() {
            List<String> validApplicationTypes = new List<String>{
                'Residential',
                'Non-Residential'
            };

            return validApplicationTypes.contains(applicationType);
        }

        public Boolean hasBasicFields() {
            return (
                firstName != null
                && lastName != null
                && email != null
                && mobilePhone != null
                && billingStreetAddress != null
                && billingCity != null
                && billingState != null
                && billingZIPCode != null
                && serviceZIPCode != null
                && loadZone != null
                && utilityName != null
                && productId != null
                && hasValidApplicationType()
            );
        }

        public Boolean hasBusinessFieldsIfRequired() {
            return (
                applicationType == 'Residential' || (
                    businessPhone != null
                    && businessName != null
                    && businessTitle != null
                )
            );
        }

        public Lead asLead() {
            Lead newLead = new Lead(
                Id = id,
                FirstName = firstName,
                LasTName = lastName,
                Email = email,
                MobilePhone = mobilePhone,
                Company = businessName,
                Application_Type__c = applicationType,
                LASERCA__Home_Address__c = billingStreetAddress,
                LASERCA__Home_City__c = billingCity,
                LASERCA__Home_State__c = billingState,
                LASERCA__Home_Zip__c = billingZIPCode,
                Street = billingStreetAddress,
                City = billingCity,
                State = BlueWaveParent.convertAbbreviationToState(billingState),
                PostalCode = billingZIPCode,
                Parcel_Zip__c = serviceZIPCode,
                LoadZone__c = loadZone,
                Partner_Lookup__c = partnerId,
                bs_Sales_ID__c = salesRepId,
                Customer_Referral__c = referralCode,
                Product__c = productId,
                Product_line__c = 'Community Solar'
            );

            if (partnerId != null) {
                newLead.Application_Source_Phase_1__c = 'Flow with Partner';
            } else {
                newLead.Application_Source_Phase_1__c = 'Flow without Partner';
            }

            if (applicationType == 'Residential') {
                newLead.Company = firstName + ' ' + lastName;
            }

            if (utilityName != null) {
                Utility__c utility = [
                    SELECT Id
                    FROM Utility__c
                    WHERE Name LIKE :'%'+utilityName+'%'
                    LIMIT 1
                ];

                newLead.Utility_Relationship__c = utility.Id;
            }

            String continueApplicationUrl = Util.getCommunitySiteURL('Apply') + '/s/csap-payment?leadId=' + lead.Id;
            newLead.Continue_Application_Link__c = continueApplicationUrl;

            return newLead;
        }
    }

    public class PatchResponse {
        public Id id;

        public PatchResponse(Id id) {
            this.id = id;
        }
    }
}