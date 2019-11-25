/**
 * Created by jlugo on 2019-07-03.
 * Tested by RestLeadTest
 */

public without sharing class RestLead {
    public Id id;
    public String firstName;
    public String lastName;
    public String email;
    public String mobilePhone;
    public String businessPhone;
    public String businessName;
    public String businessTitle;
    public String applicationType;
    public String streetAddress;
    public String city;
    public String state;
    public String zipCode;
    public String loadZone;
    public String productName;
    public Id partnerId;
    public Id salesRepId;
    public Datetime applicationCompleteDate;
    public String eiaId;
    public String continueApplicationLink;
    public List<RestPropertyAccount> propertyAccounts;
    public String campaignId;
    public String referralName;
    public String referralEmail;

    public RestLead() {
    }

    public RestLead(Lead lead) {
        this.id = lead.Id;
        this.firstName = lead.FirstName;
        this.lastName = lead.LastName;
        this.email = lead.Email;
        this.mobilePhone = lead.MobilePhone;
        this.businessName = lead.Company;
        this.applicationType = lead.Application_Type__c;
        this.streetAddress = lead.LASERCA__Home_Address__c;
        this.city = lead.LASERCA__Home_City__c;
        this.state = lead.LASERCA__Home_State__c;
        this.zipCode = lead.LASERCA__Home_Zip__c;
        this.loadZone = lead.LoadZone__c;
        this.partnerId = lead.Partner_Lookup__c;
        this.salesRepId = lead.bs_Sales_ID__c;
        this.productName = lead.Product__r.Name;
        this.businessPhone = lead.Business_Phone__c;
        this.businessTitle = lead.Business_Title__c;
        this.applicationCompleteDate = lead.Application_Complete_Date__c;
        this.eiaId = lead.Utility_relationship__r.EIA_ID__c;
        this.continueApplicationLink = lead.Continue_Application_Link__c;
        this.campaignId = lead.Manual_Campaign_ID__c;
        this.referralName = lead.Referral_Name__c;
        this.referralEmail = lead.Referral_Email__c;
    }

    public void validateCreateFields() {
        validateBasicFields();
        validateBusinessFieldsIfRequired();
        validatePropertyAccounts();
    }

    private void validateBasicFields() {
        Map<String, String> requiredFields = new Map<String, String>{
            'firstName' => firstName, 'lastName' => lastName,
            'email' => email, 'productName' => productName
        };

        Util.validateStrings(requiredFields);
        validateApplicationType();
    }


    private void validateApplicationType() {
        List<String> validApplicationTypes = new List<String>{
            'Residential',
            'Non-Residential'
        };
        if (!validApplicationTypes.contains(applicationType)) {
            throw new Util.BWException('An applicationType of "' + applicationType + '" is not of a supported type: ' + String.join(validApplicationTypes, ', '));
        }
    }

    private void validateBusinessFieldsIfRequired() {
        if (applicationType != 'Residential') {
            Util.validateStrings(new Map<String, String>{
                'businessName' => businessName,
                'businessTitle' => businessTitle
            });
        }
    }

    private void validatePropertyAccounts() {
        if (propertyAccounts != null && !propertyAccounts.isEmpty()) {
            for (RestPropertyAccount propertyAccount : propertyAccounts) {
                propertyAccount.validateCreateFields();
            }
        }
    }

    /**
     * This is used to merge in fields during PATCHes.  Any field that we expect to PATCH should be added to this method.
     *
     * @param fieldNames Set of field names to PATCH
     * @param baseLead Original Lead from the DB that this Lead's values with be patched on top of.
     *
     * @return
     */
    public Lead mergeFields(Set<String> fieldNames, Lead baseLead) {
        if (fieldNames.contains('firstName')) baseLead.FirstName = this.firstName;
        if (fieldNames.contains('lastName')) baseLead.LastName = this.lastName;
        if (fieldNames.contains('email')) baseLead.Email = this.email;
        if (fieldNames.contains('mobilePhone')) {
            baseLead.MobilePhone = this.mobilePhone;
            baseLead.Phone = this.mobilePhone;
        }
        if (fieldNames.contains('businessName')) baseLead.Company = this.businessName;
        if (fieldNames.contains('streetAddress')) baseLead.LASERCA__Home_Address__c = this.streetAddress;
        if (fieldNames.contains('streetAddress')) baseLead.Street = this.streetAddress;
        if (fieldNames.contains('city')) baseLead.LASERCA__Home_City__c = this.city;
        if (fieldNames.contains('city')) baseLead.City = this.city;
        if (fieldNames.contains('state')) baseLead.LASERCA__Home_State__c = this.state;
        if (fieldNames.contains('state')) baseLead.State = BlueWaveParent.convertAbbreviationToState(this.state);
        if (fieldNames.contains('zipCode')) baseLead.LASERCA__Home_Zip__c = this.zipCode;
        if (fieldNames.contains('zipCode')) baseLead.PostalCode = this.zipCode;
        if (fieldNames.contains('zipCode')) baseLead.Parcel_Zip__c = this.zipCode; // TODO: remove once qualification goes off of UAL's zip, instead of the Lead's parcel zip
        if (fieldNames.contains('loadZone')) baseLead.LoadZone__c = this.loadZone;
        if (fieldNames.contains('businessPhone')) baseLead.Business_Phone__c = this.businessPhone;
        if (fieldNames.contains('businessTitle')) baseLead.Business_Title__c = this.businessTitle;
        if (fieldNames.contains('applicationCompleteDate')) baseLead.Application_Complete_Date__c = this.applicationCompleteDate;
        if (fieldNames.contains('campaignId')) baseLead.Manual_Campaign_ID__c = this.campaignId;
        if (fieldNames.contains('referralName')) baseLead.Referral_Name__c = this.referralName;
        if (fieldNames.contains('referralEmail')) baseLead.Referral_Email__c = this.referralEmail;
        if (fieldNames.contains('continueApplicationLink')) baseLead.Continue_Application_Link__c = this.continueApplicationLink;

        updateDerivedFields(new RestLead(baseLead), baseLead);

        if (this.eiaId != null) {
            updateUtility(this.eiaId, baseLead);
        }

        return baseLead;
    }

    public Lead asLead() {
        Lead newLead = new Lead(
            Id = this.id,
            FirstName = this.firstName,
            LastName = this.lastName,
            Email = this.email,
            MobilePhone = this.mobilePhone,
            Phone = this.mobilePhone,
            Company = this.businessName,
            Application_Type__c = this.applicationType,
            LASERCA__Home_Address__c = this.streetAddress,
            LASERCA__Home_City__c = this.city,
            LASERCA__Home_State__c = this.state,
            LASERCA__Home_Zip__c = this.zipCode,
            Street = this.streetAddress,
            City = this.city,
            State = BlueWaveParent.convertAbbreviationToState(this.state),
            PostalCode = this.zipCode,
            Parcel_Zip__c = this.zipCode, // TODO: remove once qualification goes off of UAL's zip, instead of the Lead's parcel zip
            LeadSource = 'Switch',
            LoadZone__c = this.loadZone,
            Product_line__c = 'Community Solar',
            Business_Phone__c = this.businessPhone,
            Business_Title__c = this.businessTitle,
            Customer_type__c = this.applicationType,
            Application_Complete_Date__c = this.applicationCompleteDate,
            Status = 'Sales Qualified',
            Manual_Campaign_ID__c = this.campaignId,
            Referral_Name__c = this.referralName,
            Referral_Email__c = this.referralEmail,
            Continue_Application_Link__c = this.continueApplicationLink
        );

        updateDerivedFields(this, newLead);
        if (this.eiaId != null) {
            updateUtility(this.eiaId, newLead);
        }

        return newLead;
    }

    private void updateDerivedFields(RestLead restLead, Lead newLead) {

        if (restLead.partnerId != null) {
            newLead.Application_Source_Phase_1__c = 'Switch with Partner';
        } else {
            newLead.Application_Source_Phase_1__c = 'Switch without Partner';
        }

        Partner__c customerPartner = new Partner__c();
        try {
            customerPartner = PartnerSelector.selectPartnerByPartnerId(restLead.partnerId);
        } catch (Exception e) {
            customerPartner = PartnerSelector.selectDefaultCSPartner();
            if (restLead.partnerId != null) {
                Logger.logNow('CSLeadsRESTControllerV2', 'asLead', 'Partner not found with Id ' + restLead.partnerId + ' for Lead: ' + newLead.Id);
            }
        }

        newLead.Partner_Lookup__c = customerPartner.Id;
        newLead.Partner_Email__c = customerPartner.Email__c;

        if (restLead.salesRepId != null) {
            newLead.bs_Sales_ID__c = restLead.salesRepId;
        } else if (customerPartner.Default_Sales_Rep__c != null) {
            newLead.bs_Sales_ID__c = customerPartner.Default_Sales_Rep__c;
        }

        if (restLead.applicationType == 'Residential') {
            newLead.Company = restLead.firstName + ' ' + restLead.lastName;
        }

        List<Product2> product = [
            SELECT Id
            FROM Product2
            WHERE Name LIKE :'%' + restLead.productName + '%'
            LIMIT 1
        ];

        if (!product.isEmpty()) {
            newLead.Product__c = product[0].Id;
        }

    }

    private void updateUtility(String eiaId, Lead newLead) {
        List<Utility__c> utilityList = [
            SELECT Id, Name, EIA_ID__c
            FROM Utility__c
            WHERE EIA_ID__c = :eiaId
            LIMIT 1
        ];

        if (!utilityList.isEmpty()) {
            newLead.Utility_relationship__c = utilityList[0].Id;
        } else {
            Logger.logNow('CSLeadsRESTControllerV2', 'asLead', 'No Utilities found with EIA Id: ' + eiaId);
        }
    }

    public class RestPropertyAccount {
        public Id id;
        public Id leadId;
        public String name;
        public String billingStreet;
        public String billingCity;
        public String billingState;
        public String billingPostalCode;
        public String zuoraPaymentRefId;
        public Datetime zuoraPaymentRefIdExpirationDate;
        public List<RestUtilityAccountLog> utilityAccountLogs;

        public RestPropertyAccount() {
        }

        public RestPropertyAccount(Account account) {
            this.id = account.Id;
            this.leadId = account.Lead__c;
            this.name = account.Name;
            this.billingStreet = account.BillingStreet;
            this.billingCity = account.BillingCity;
            this.billingState = account.BillingStateCode;
            this.billingPostalCode = account.BillingPostalCode;
            this.zuoraPaymentRefId = account.Zuora_Payment_Ref_Id__c;
            this.zuoraPaymentRefIdExpirationDate = account.Zuora_Payment_Ref_Id_Expiration_Date__c;
        }

        public Account asAccount(Lead lead) {
            Id recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();

            Account newAccount = new Account(
                Id = id,
                Lead__c = lead.Id,
                Name = lead.Company,
                Product_Line__c = 'Community Solar',
                RecordTypeId = recordType,
                Electricity_Provider__c = lead.Utility_relationship__r.Id,
                BillingStreet = billingStreet,
                BillingCity = billingCity,
                BillingState = BlueWaveParent.convertAbbreviationToState(billingState.toUpperCase()),
                BillingPostalCode = billingPostalCode,
                Zuora_Payment_Ref_Id__c = zuoraPaymentRefId,
                Zuora_Payment_Ref_Id_Expiration_Date__c = zuoraPaymentRefIdExpirationDate
            );

            return newAccount;
        }

        public void validateCreateFields() {
            Map<String, String> requiredFields = new Map<String, String>{
                'billingStreet' => billingStreet, 'billingCity' => billingCity,
                'billingState' => billingState, 'billingPostalCode' => billingPostalCode
            };

            Util.validateStrings(requiredFields);
            validateUtilityAccountLogs();
        }

        private void validateUtilityAccountLogs() {
            if (utilityAccountLogs != null && !utilityAccountLogs.isEmpty()) {
                for (RestUtilityAccountLog utilityAccountLog : utilityAccountLogs) {
                    utilityAccountLog.validateCreateFields();
                }
            }
        }

    }

    public class RestUtilityAccountLog {
        public Id id;
        public Id propertyAccountId;
        public String utilityAccountNumber;
        public String nameOnAccount;
        public String serviceStreet;
        public String serviceCity;
        public String serviceState;
        public String servicePostalCode;
        public Decimal annualKWh;
        public Decimal annualCostOfElectricity;

        public RestUtilityAccountLog() {
        }

        public void validateCreateFields() {
            Util.validateStrings(new Map<String, String>{
                'nameOnAccount' => nameOnAccount, 'serviceStreet' => serviceStreet,
                'serviceCity' => serviceCity, 'serviceState' => serviceState,
                'servicePostalCode' => servicePostalCode
            });
        }

        public RestUtilityAccountLog(Utility_Account_Log__c ual) {
            this.id = ual.Id;
            this.propertyAccountId = ual.Account__c;
            this.utilityAccountNumber = ual.Name;
            this.nameOnAccount = ual.Name_on_Account__c;
            this.serviceStreet = ual.Service_Address__c;
            this.serviceCity = ual.Service_City__c;
            this.serviceState = ual.Service_State__c;
            this.servicePostalCode = ual.Service_Zip_Code__c;
            this.annualKWh = ual.Annual_kWh__c;
            this.annualCostOfElectricity = ual.Annual_Cost_of_Electricity__c;
        }

        public Utility_Account_Log__c asUAL(Account propertyAccount) {
            return new Utility_Account_Log__c(
                Id = id,
                Account__c = propertyAccount.Id,
                Lead__c = propertyAccount.Lead__c,
                Name = utilityAccountNumber,
                Name_on_Account__c = nameOnAccount,
                Service_Address__c = serviceStreet,
                Service_City__c = serviceCity,
                Service_State__c = serviceState,
                Service_Zip_Code__c = servicePostalCode,
                Annual_kWh__c = annualKWh,
                Annual_Cost_of_Electricity__c = annualCostOfElectricity
            );
        }
    }
}