/**
 * Created by jlugo on 2019-07-03.
 * Tested by RestLeadTest
 */

public without sharing class RestLead {
    public Id id;
    public String customerAgreementText; // TODO: not used by switch at all.  Remove? Run by jeff/legal/freeman.  Sarah to discuss w/jeff
    public String firstName;
    public String lastName;
    public String email;
    public String mobilePhone;
    public String businessPhone; // TODO: this currently maps to lead.Phone.  Why there and not (also) lead.Business_Phone__c?  Sarah to dig in
    public String businessName;
    public String businessTitle;
    public String applicationType;
    public String streetAddress;
    public String city;
    public String state;
    public String zipCode;
    public String loadZone;
    public String productName;
    public Id partnerId; //
    public Id salesRepId; //
    public Datetime applicationCompleteDate; //
    public String eiaId; //
    public String continueApplicationLink; //
    public List<RestPropertyAccount> propertyAccounts;

    public RestLead() {
    }

    public RestLead(Lead lead) {
        this.id = lead.Id;
        this.customerAgreementText = lead.Terms_Conditions__c;
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
        this.businessPhone = lead.Phone;
        this.businessTitle = lead.Business_Title__c;
        this.applicationCompleteDate = lead.Application_Complete_Date__c;
        this.eiaId = lead.Utility_relationship__r.EIA_ID__c;
        this.continueApplicationLink = lead.Continue_Application_Link__c;
    }


    public void validateCreateFields() {
        validateBasicFields();
        validateBusinessFieldsIfRequired();
        validatePropertyAccounts();
    }

    private void validateBasicFields() {
        Map<String, String> requiredFields = new Map<String, String>{
            'firstName' => firstName, 'lastName' => lastName,
            'email' => email, 'mobilePhone' => mobilePhone,
            'streetAddress' => streetAddress, 'city' => city,
            'state' => state, 'zipCode' => zipCode,
            'productName' => productName
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
                'businessPhone' => businessPhone,
                'businessName' => businessName,
                'businessTitle' => businessTitle
            });
        }
    }

    private void validatePropertyAccounts() {
        if (propertyAccounts == null || propertyAccounts.isEmpty()) {
            throw new Util.BWException('The propertyAccounts array is required');
        } else {
            for (RestPropertyAccount propertyAccount : propertyAccounts) {
                propertyAccount.validateCreateFields();
            }
        }
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
            LASERCA__Home_Address__c = streetAddress,
            LASERCA__Home_City__c = city,
            LASERCA__Home_State__c = state,
            LASERCA__Home_Zip__c = zipCode,
            Street = streetAddress,
            City = city,
            State = BlueWaveParent.convertAbbreviationToState(state),
            PostalCode = zipCode,
            Parcel_Zip__c = zipCode, // TODO: do we need to set parcel zip on lead?
            LeadSource = 'Switch',
            LoadZone__c = loadZone,
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
                Logger.logNow('CSLeadsRESTControllerV2', 'asLead', 'Partner not found with Id ' + partnerId + ' for Lead: ' + newLead.Id);
            }
        }

        newLead.Partner_Lookup__c = customerPartner.Id;
        newLead.Partner_Email__c = customerPartner.Email__c;

        if (salesRepId != null) {
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
            WHERE Name LIKE :'%' + productName + '%'
            LIMIT 1
        ];

        if (!product.isEmpty()) {
            newLead.Product__c = product[0].Id;
        }

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

        return newLead;
    }

    public class RestPropertyAccount {
        public Id id;
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
            if (utilityAccountLogs == null || utilityAccountLogs.isEmpty()) {
                throw new Util.BWException('At least one item in utilityAccountLogs is required for each property account');
            } else {
                for (RestUtilityAccountLog utilityAccountLog : utilityAccountLogs) {
                    utilityAccountLog.validateCreateFields();
                }
            }
        }

    }

    public class RestUtilityAccountLog {
        public Id id;
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