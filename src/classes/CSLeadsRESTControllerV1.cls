/**
 * Created by mstackhouse on 3/6/2019.
 * Description: REST Controller for sending CS Leads to Salesforce
 * Test: CSLeadsRESTControllerV1Test
 */

@RestResource(UrlMapping='/v1/CSLeads')

global without sharing class CSLeadsRESTControllerV1 extends RESTController{
    private static CSLeadsRESTControllerV1 controller = new CSLeadsRESTControllerV1();

    private LeadService leadService = new LeadService();
    private AccountService accountService = new AccountService();
    private UALService ualService = new UALService();

    private LeadSelector leadSelector = new LeadSelector();
    private AccountsSelector accountsSelector = new AccountsSelector();
    private UALSelector ualSelector = new UALSelector();

    @HttpPatch
    global static void patchRequest() {
        try {
            controller.patchRecords();
        } catch(Exception e) {
            RESTController.ResponseEnvelope envelope =  new RESTController.ResponseEnvelope();
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
            RESTController.ResponseEnvelope envelope = new RESTController.ResponseEnvelope();
            envelope.addError(e.getMessage());
            envelope.setJSONResponse(RestContext.response);
            RestContext.response.statusCode = 500;
            String errorMessage = 'Error: ' + e.getMessage();
            errorMessage += '. Request: ' + RestContext.request;
            Logger.logNow('CSLeadsRESTControllerV1', 'postRequest', errorMessage, 'Error');
        }
    }

    public override void patchRecords() {
        String jsonRequest = request.requestBody.toString();
        RestLeadV1 requestLead = (RestLeadV1) JSON.deserialize(jsonRequest, RestLeadV1.class);
        List<Lead> leads = leadSelector.selectAll(new Set<Id>{requestLead.Id});
        List<Account> propertyAccounts = accountsSelector.selectPropertyAccountsByLeadIds(new Set<Id>{requestLead.Id});

        if (leads.isEmpty()) {
            response.statusCode = statusCode.notFound;
        } else if (requestLead.isPatch()){
            Lead leadToUpdate = leads[0];
            Account propertyAccountToUpdate;

            // TODO: remove this at some point (added July 2019, so maybe by December 2019, since resuming apps from July will be unlikely then)
            if (propertyAccounts.isEmpty()) {
                // this lead was created in the old model, so we need to create the account and UAL
                propertyAccountToUpdate = accountService.insertAccount(leadService.buildPropertyAccountFromLegacyLead(leadToUpdate));
                ualService.insertUAL(leadService.buildUtilityAccountLogFromLegacyLead(leadToUpdate, propertyAccountToUpdate));
            } else {
                propertyAccountToUpdate = propertyAccounts[0];
            }

            if (requestLead.applicationCompleteDate != null && leadToUpdate.Application_Complete_Date__c == null) {
                leadToUpdate.Application_Complete_Date__c = requestLead.applicationCompleteDate;
                //pull credit
                leadToUpdate.Soft_Pull_Credit_Report__c = true;
            }
            if (requestLead.customerAcknowledgement == true && leadToUpdate.Privacy_Policy_Acknowledged__c == false) {
                leadToUpdate.Privacy_Policy_Acknowledged__c = requestLead.customerAcknowledgement;
                leadToUpdate.Terms_Conditions_Acknowledged__c = Datetime.now();
                leadToUpdate.Terms_Conditions__c = requestLead.customerAgreementText;
            }
            if (requestLead.zuoraPaymentRefId != null && propertyAccountToUpdate.Zuora_Payment_Ref_Id__c == null) {
                leadToUpdate.Zuora_Payment_Ref_Id__c = requestLead.zuoraPaymentRefId;
                leadToUpdate.Zuora_Payment_Ref_Id_Expiration_Date__c = requestLead.zuoraPaymentRefIdExpirationDate;
                propertyAccountToUpdate.Zuora_Payment_Ref_Id__c = requestLead.zuoraPaymentRefId;
                propertyAccountToUpdate.Zuora_Payment_Ref_Id_Expiration_Date__c = requestLead.zuoraPaymentRefIdExpirationDate;
            }

            Lead lead = leadService.updateLead(leadToUpdate);
            accountService.updateAccount(propertyAccountToUpdate);

            RestLeadV1 responseLead = new RestLeadV1(lead);
            envelope.setData(responseLead);
            response.statusCode = statusCode.ok;
        } else {
            envelope.addError('Request did not include correct fields to update');
            response.statusCode = statusCode.badRequest;
        }

        envelope.setJSONResponse(response);
    }

    public override void postRecords() {
        String jsonRequest = request.requestBody.toString();
        RestLeadV1 requestLead = (RestLeadV1) JSON.deserialize(jsonRequest, RestLeadV1.class);

        if (requestLead.hasRequiredPostFields()) {

            Lead newLead = requestLead.asLead();

            Lead createdLead = leadService.createLegacyLead(newLead);
            RestLeadV1 responseLead = new RestLeadV1(createdLead);
            envelope.setData(responseLead);
            response.statusCode = statusCode.created;
        } else {
            envelope.addError('Request may be missing required fields.');
            response.statusCode = statusCode.badRequest;
        }

        envelope.setJSONResponse(response);
    }

    public class RestLeadV1 {
        public Id id;
        public Boolean customerAcknowledgement;
        public String customerAgreementText;
        public String zuoraPaymentRefId;
        public Datetime zuoraPaymentRefIdExpirationDate;
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
        public String productName;
        public Id partnerId;
        public Id salesRepId;
        public Id referralCode;
        public Datetime applicationCompleteDate;
        public String eiaId;
        public String continueApplicationLink;

        public RestLeadV1() {}
        public RestLeadV1(Lead lead) {
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
            this.loadZone = lead.LoadZone__c;
            this.partnerId = lead.Partner_Lookup__c;
            this.salesRepId = lead.bs_Sales_ID__c;
            this.referralCode = lead.Customer_Referral__c;
            this.productName = lead.Product__r.Name;
            this.businessPhone = lead.Phone;
            this.businessTitle = lead.Business_Title__c;
            this.utilityName = lead.Utility_relationship__r.Name;
            this.applicationCompleteDate = lead.Application_Complete_Date__c;
            this.eiaId = lead.Utility_relationship__r.EIA_ID__c;
            this.continueApplicationLink = lead.Continue_Application_Link__c;
        }

        public Boolean isPatch() {
            Boolean isPatch = false;
            if (applicationCompleteDate != null ||
                customerAcknowledgement != null ||
                (zuoraPaymentRefId != null && zuoraPaymentRefIdExpirationDate != null)){
                isPatch = true;
            }
            return isPatch;
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
                    && productName != null
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
                LastName = lastName,
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
                LeadSource = 'Switch',
                LoadZone__c = loadZone,
                Customer_Referral__c = referralCode,
                Product_line__c = 'Community Solar',
                Phone = businessPhone,
                Business_Title__c = businessTitle,
                Customer_type__c = applicationType,
                Application_Complete_Date__c = applicationCompleteDate,
                Status = 'Sales Qualified',
                Continue_Application_Link__c = continueApplicationLink
            );


            if (partnerId != null) {
                newLead.Application_Source_Phase_1__c = 'Switch with Partner';
            } else {
                newLead.Application_Source_Phase_1__c = 'Switch without Partner';
            }

            Partner__c customerPartner = new Partner__c();
            try {
                customerPartner = PartnerSelector.selectPartnerByPartnerId(partnerId);
            } catch (Exception e) {
                customerPartner = PartnerSelector.selectDefaultCSPartner();
                if (partnerId != null) {
                   Logger.logNow('CSLeadsRESTControllerV1', 'asLead', 'Partner not found with Id ' + partnerId + ' for Lead: ' + newLead.Id);
                }
            }

            newLead.Partner_Lookup__c = customerPartner.Id;
            newLead.Partner_Email__c = customerPartner.Email__c;

            if (salesRepId != null){
                newLead.bs_Sales_ID__c = salesRepId;
            } else if (customerPartner.Default_Sales_Rep__c != null) {
                newLead.bs_Sales_ID__c = customerPartner.Default_Sales_Rep__c;
            }

            if (applicationType == 'Residential') {
                newLead.Company = firstName + ' ' + lastName;
            }

            List<Product2> product = [
                SELECT Id
                FROM Product2
                WHERE Name LIKE :'%'+productName+'%'
                LIMIT 1
            ];

            if (!product.isEmpty()) {
                newLead.Product__c = product[0].Id;
            }

            List<Utility__c> utilityList = [
                SELECT Id, Name, EIA_ID__c
                FROM Utility__c
                WHERE EIA_ID__c = :eiaId
                LIMIT 1];

            if (!utilityList.isEmpty()) {
                newLead.Utility_relationship__c = utilityList[0].Id;
            } else {
                Logger.logNow('CSLeadsRESTControllerV1', 'asLead', 'No Utilities found with EIA Id: ' + eiaId );
            }

            return newLead;
        }
    }
}