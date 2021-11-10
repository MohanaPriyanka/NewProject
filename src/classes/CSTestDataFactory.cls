/**
 * Created by jeffparlin on 7/6/21.
 * @description Inserts base system dependencies for Community Solar leads, and generates test lead data
 * Intended for system integration testing of the Acquisition API
 */
@IsTest
public with sharing class CSTestDataFactory {

    public Id leadId;
    public Product2 product;
    public Id contractId;
    public Id partnerId;
    public Id partnerAccountId;
    public Id salesRepId;
    public Id utilityId;
    public Rate_Class__c rateClass;
    public APXTConga4__Conga_Template__c contractCongaTemplate;
    public List<ContentVersion> contractFiles;
    public List<ContentDocumentLink> contractDocumentLinks;
    public RestLead restLead;

    public CSTestDataFactory() {
        insertBaseDependencies();
    }

    public void insertLeadViaAPI(Boolean missingRateClass, String underwritingMethod, Boolean collectPaymentInfo) {
        // Insert a lead into the database using actual methods that would apply to an incoming API request
        restLead = new RestLead();
        restLead.productName = product.Name;
        restLead.utilityId = utilityId;
        restLead.firstName = 'Restlead';
        restLead.lastName = 'Testcase';
        restLead.email = 'restlead.testcase@bluewavesolar.com.invalid';
        restLead.mobilePhone = '555-555-5555';
        restLead.businessPhone = '555-555-1111';
        restLead.businessName = 'Test Business';
        restLead.streetAddress = '1 Test Street';
        restLead.city = 'Suffern';
        restLead.state = 'NY';
        restLead.zipCode = '10901';
        restLead.businessTitle = 'CEO';
        restLead.partnerId = partnerId;
        restLead.salesRepId = salesRepId;
        restLead.noPayment = collectPaymentInfo;
        restLead.underwritingCriteria = underwritingMethod;
        restLead.loadZone = 'SEMA';

        RestLead.RestPropertyAccount restAccount = new RestLead.RestPropertyAccount();
        restAccount.billingStreet = 'Test billing street';
        restAccount.billingCity = 'Test billing city';
        restAccount.billingState = 'NY';
        restAccount.billingPostalCode = '14472';

        RestLead.RestUtilityAccountLog requestUAL1 = new RestLead.RestUtilityAccountLog();
        requestUAL1.serviceStreet = 'Test service street';
        requestUAL1.serviceCity = 'Test service city';
        requestUAL1.serviceState = 'NY';
        requestUAL1.servicePostalCode = '14472';
        requestUAL1.utilityAccountNumber = '555555';
        requestUAL1.rateClass = missingRateClass ? null : 'Rate Class 1';

        restAccount.utilityAccountLogs = new List<RestLead.RestUtilityAccountLog>{requestUAL1};
        restLead.propertyAccounts = new List<RestLead.RestPropertyAccount>{restAccount};

        CSLeadsRESTControllerV2 controller = new CSLeadsRESTControllerV2();
        controller.insertLeadAccountAndUALs(restLead, new RestResponse());
        leadId = [SELECT Id FROM Lead].Id;
        contractId = [SELECT Id FROM Contract WHERE Lead__c =: leadId].Id;
    }

    public void insertContractFiles() {
        // Insert two content versions and link to the Contract (assume Conga generated the following docs)
        ContentVersion content1 = new ContentVersion(
            Title='Community Solar Agreement.pdf',
            PathOnClient ='test',
            VersionData=Blob.valueOf('Community Solar Agreement Data')
        );
        ContentVersion content2 = new ContentVersion(
            Title='Solar Disclosure Form.pdf',
            PathOnClient ='test',
            VersionData=Blob.valueOf('Solar Disclosure Form Data')
        );
        contractFiles = new List<ContentVersion>{content1, content2};
        insert contractFiles;

        // Query for Salesforce-generated ContentDocumentLinks on ContentVersions, add to Contract
        contractFiles = [
            SELECT Id, ContentDocumentId, VersionData, Title FROM ContentVersion
            WHERE Id =: content1.Id OR Id =: content2.Id
        ];
        ContentDocumentLink cdl1 = new ContentDocumentLink(
            LinkedEntityId = contractId,
            ContentDocumentId = contractFiles[0].ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        ContentDocumentLink cdl2 = new ContentDocumentLink(
            LinkedEntityId = contractId,
            ContentDocumentId = contractFiles[1].ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        contractDocumentLinks = new List<ContentDocumentLink>{cdl1, cdl2};
        insert contractDocumentLinks;
    }

    public void insertOpenUCBSystem() {
        Shared_Solar_System__c openUCBSystem = new Shared_Solar_System__c(
            Name = 'Project A Oak Road',
            Service_Territory__c = 'SEMA',
            Billing_Method__c = 'NMC',
            Open__c = true,
            Client_Account__c = getClientAccount(),
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Credit_Score_Requirement__c = 200,
            Assignment_Order__c = '1',
            Utility_NMC_Tariff__c = getTariffForProduct(),
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Product__c = product.Id,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Utility__c = utilityId,
            Available_SMB_Underwriting_Method_Docs__c = false,
            Available_SMB_Underwriting_Method_FICO__c = false,
            Do_Not_Underwrite__c = true,
            Public__c = true // ignore partner eligibilities
        );
        openUCBSystem.BWC_Project_Entity_Manual__c = getEntity(openUCBSystem.Client_Account__c);
        insert openUCBSystem;

        Partner_Shared_Solar_System_Eligibility__c psssa = new Partner_Shared_Solar_System_Eligibility__c(
            Shared_Solar_System__c = openUCBSystem.Id,
            Start_Date__c = System.today().addDays(-1),
            Account__c = partnerAccountId
        );
        insert psssa;
    }

    public void setRateClassToSuppressDisclosureForm() {
        rateClass.Suppress_Disclosure_Form__c = true;
        update rateClass;
    }

    public void resetRateClass() {
        rateClass.Suppress_Disclosure_Form__c = false;
        update rateClass;
    }

    public void setProductDisclosureTemplateToNull() {
        product.Disclosure_Form_Conga_Template__c = null;
        update product;
    }

    private void insertBaseDependencies() {
        // Insert partner and partner account
        Partner__c partner = new Partner__c(Name='default test');
        insert partner;
        partnerId = partner.Id;
        Account partnerAccount = new Account(
            Name = 'Partner Account',
            Partner__c = partnerId,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND Name = 'Partner Account'].Id
        );
        insert partnerAccount;
        partnerAccountId = partnerAccount.Id;

        // Update partner with default sales rep
        BSST__c salesRep = new BSST__c(Name = 'default rep', Partner__c = partner.Id);
        insert salesRep;
        salesRepId = salesRep.Id;
        partner.Default_Sales_Rep__c = salesRep.Id;
        update partner;

        // Insert System Properties configuration with default partner set and fine logging enabled
        insert new System_Properties__c(
            Name = 'test',
            Default_CS_Partner__c = partner.Id,
            Log_Level__c = 'Fine'
        );

        // Insert Conga template for CS contracts
        contractCongaTemplate = new APXTConga4__Conga_Template__c();
        insert contractCongaTemplate;

        // Find and update a product to use for tests (tests need to provide this record)
        product = [SELECT Id,Name FROM Product2 LIMIT 1];
        product.Product_Type__c = 'Community Solar';
        product.Disclosure_Form_Conga_Template__c = contractCongaTemplate.Id;
        product.Ignore_Load_Zones_When_Qualifying__c = true;
        product.Customer_Subscription_Type__c = 'kWh';
        update product;

        // Find and set a utility for tests (tests need to provide this record)
        utilityId = [SELECT Id FROM Utility__c WHERE Name = 'Utility with EIA ID'].Id;

        // Insert a rate class
        rateClass = new Rate_Class__c(
            Name                        = 'Rate Class 1',
            Suppress_Disclosure_Form__c = false,
            Utility__c                  = utilityId
        );
        insert rateClass;
    }

    private Id getEntity(Id clientAccountId) {
        Entity__c entity = new Entity__c(
            Name = 'Project A Oak Road',
            Client_Account__c = clientAccountId
        );
        insert entity;
        return entity.Id;
    }

    private Id getTariffForProduct() {
        Utility_NMC_Tariff__c eversourceG1 =  new Utility_NMC_Tariff__c(
            Value_of_Net_Metering_Credit__c = .70578,
            Name = 'Eversource G1',
            Utility_Relationship__c = utilityId,
            Customer_Type__c = 'Non-Residential',
            Maximum_kWh__c = 10000,
            Date__c = Date.today()
        );
        insert eversourceG1;
        return eversourceG1.Id;
    }

    private Id getClientAccount() {
        Account clientAccount = new Account(Name = 'Test Client');
        insert clientAccount;
        return clientAccount.Id;
    }
}