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

    @HttpPost
    global static void postRequest() {
        try {
            controller.postRecords();
        } catch(Exception e) {
            CSLeadsRESTControllerV1.ResponseEnvelope envelope = new CSLeadsRESTControllerV1.ResponseEnvelope();
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
        if (jsonRequest.toLowerCase().contains('acknowledgment')) {
            jsonRequest = jsonRequest.replaceAll('(a{1}+|A{1}+)(cknowledgment)', 'acknowledgement');
            envelope.addMessage('Autocorreted the request to update the spelling of acknowledgment to acknowledgement, with an e.');
        }
        RequestLead requestLead = (RequestLead) JSON.deserialize(jsonRequest, RequestLead.class);
        List<Lead> leads = getLeadsById(new Set<Id>{requestLead.Id});

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

            RequestLead responseLead = new RequestLead(leadToUpdate);
            envelope.setData(responseLead);
            response.statusCode = statusCode.ok;
        } else {
            envelope.addError('Request did not include correct fields to update');
            response.statusCode = statusCode.badRequest;
        }

        envelope.setJSONResponse(response);
     }

    protected override void postRecords() {
        String jsonRequest = request.requestBody.toString();
        RequestLead requestLead = (RequestLead) JSON.deserialize(jsonRequest, RequestLead.class);

        System.debug(requestLead.hasRequiredPostFields());
        System.debug(requestLead);
        if (requestLead.hasRequiredPostFields()) {
            Lead newLead = requestLead.asLead();

            insert newLead;

            RequestLead responseLead = new RequestLead(newLead);
            envelope.setData(responseLead );
            response.statusCode = statusCode.created;
        } else {
            envelope.addError('Request may be missing required fields.');
            response.statusCode = statusCode.badRequest;
        }

        envelope.setJSONResponse(response);
    }

    public List<Lead> getLeadsById(Set<Id> leadIds) {
        return [
            SELECT Id, Privacy_Policy_Acknowledged__c, Terms_Conditions__c, Zuora_Payment_Ref_Id__c,
                Zuora_Payment_Ref_Id_Expiration_Date__c, FirstName, LastName, Email, MobilePhone,
                Company, Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c,
                LASERCA__Home_State__c, LASERCA__Home_Zip__c, Parcel_Zip__c, Load_Zone__c,
                Partner_Lookup__c, bs_Sales_ID__c, Customer_Referral__c, Product__c, Phone,
                Business_Title__c, Utility_Relationship__r.Name
            FROM Lead
            WHERE Id = :leadIds
        ];
    }

    public class RequestLead {
        public Id id;
        public Boolean customerAcknowledgement;
        public String customerAgreementText;
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

        public RequestLead() {}
        public RequestLead(Lead lead) {
            this.id = lead.Id;
            this.customerAcknowledgement = lead.Privacy_Policy_Acknowledged__c;
            this.customerAgreementText = lead.Terms_Conditions__c;
            this.zuoraPaymentRefId = lead.Zuora_Payment_Ref_Id__c;
            this.zuoraPaymentRefIdExpirationDate = lead.Zuora_Payment_Ref_Id_Expiration_Date__c;
            this.firstName = lead.FirstName;
            this.lastName = lead.LastName;
            this.email = lead.Email;
            this.mobilePhone = lead.MobilePhone;
            this.businessName = lead.Company;
            this.applicationType = lead.Application_Type__c;
            this.billingStreetAddress = lead.LASERCA__Home_Address__c;
            this.billingCity = lead.LASERCA__Home_City__c;
            this.billingState = lead.LASERCA__Home_State__c;
            this.billingZIPCode = lead.LASERCA__Home_Zip__c;
            this.serviceZIPCode = lead.Parcel_Zip__c;
            this.loadZone = lead.Load_Zone__c;
            this.partnerId = lead.Partner_Lookup__c;
            this.salesRepId = lead.bs_Sales_ID__c;
            this.referralCode = lead.Customer_Referral__c;
            this.productId = lead.Product__c;
            this.businessPhone = lead.Phone;
            this.businessTitle = lead.Business_Title__c;
            this.utilityName = lead.Utility_Relationship__r.Name;
        }

        public Boolean hasAcknowledgement() {
            return (customerAcknowledgement != null);
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
                Product_line__c = 'Community Solar',
                Phone = businessPhone,
                Business_Title__c = businessTitle
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
}