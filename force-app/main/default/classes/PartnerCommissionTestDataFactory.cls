/**
 * @description Created by jeffparlin on 3/3/22.
 */
@IsTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PartnerCommissionTestDataFactory {

    private Product2 defaultProduct;
    private Partner__c legacyPartner;
    private Account partnerAccount;
    private Utility__c utility;
    private Shared_Solar_System__c sharedSolarSystem;
    private fflib_SObjectUnitOfWork unitOfWork;
    private Commission_Structure__c variableStructure;
    private Utility_NMC_Tariff__c tariff;

    public void buildBaseComponents() {
        insertUtility();
        insertLegacyPartner();
        insertPartnerAccount();
        insertProduct();
        insertNMCTariff();
        insertVariableStructure();
        insertSharedSolarSystem();
        insertSharedSolarSystemAccesses();
    }

    public void buildBaseVariableRateDeals(Integer quantity) {
        Map<Id,Opportunity> opportunityMap = createTestVariableOpportunities(quantity);
        insertBaseSubscriptions(opportunityMap);
    }

    private Map<Id,Opportunity> createTestVariableOpportunities(Integer numberOfOpps) {
        unitOfWork = new fflib_SObjectUnitOfWork(new List<SObjectType>{
            Account.SObjectType,
            Opportunity.SObjectType
        });

        for (Integer i=0; i < numberOfOpps; i++) {
            // Insert Property Account
            Account propertyAccount = new Account(
                Name = 'Test Property Account ' + i
            );
            unitOfWork.registerNew(propertyAccount);

            // Insert Opportunity
            Opportunity opp = new Opportunity(
                Name = 'Test Opp ' + i,
                Shared_Solar_System__c = sharedSolarSystem.Id,
                Product__c = sharedSolarSystem.Product__c,
                System_Assigned__c = true,
                NMC_Tariff__c = tariff.Id,
                CloseDate = Date.today(),
                UAS_Created__c = true,
                StageName = 'Complete',
                Partner_tag_lookup__c = legacyPartner.Id,
                Partner_Account__c = partnerAccount.Id,
                Contract_Close_Date__c = Datetime.now().addMonths(-1).date()
            );
            unitOfWork.registerNew(opp, Opportunity.AccountId, propertyAccount);
        }

        unitOfWork.commitWork();

        return new Map<Id,Opportunity>([
            SELECT Id, Name
            FROM Opportunity
        ]);
    }

    private void insertBaseSubscriptions(Map<Id,Opportunity> opportunities) {
        unitOfWork = new fflib_SObjectUnitOfWork(new List<SObjectType>{
            Utility_Account_Log__c.SObjectType,
            Utility_Account_Subscription__c.SObjectType,
            Subscription_Order__c.SObjectType
        });

        for (Opportunity opp : opportunities.values()) {
            Id opportunityId = opp.Id;

            // Insert Utility Account Log
            Utility_Account_Log__c ual = new Utility_Account_Log__c(
                Utility_lookup__c = utility.Id,
                Name_on_Account__c = opp.Name,
                Service_Address__c = '66 Mass Ave',
                Service_City__c = 'Boston',
                Service_State__c = 'MA',
                Service_Zip_Code__c = '02115'
            );
            unitOfWork.registerNew(ual);

            // Insert Utility Account Subscription
            Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
                Name = String.valueOf(Math.random()*100000),
                Name_on_Account__c = 'Test Account',
                Opportunity__c = opportunityId,
                UAS_Number__c = 1,
                Shared_Solar_System__c = sharedSolarSystem.Id,
                Sizing_Method__c = tariff.Id
            );
            unitOfWork.registerNew(uas, Utility_Account_Subscription__c.Utility_Account_Log__c, ual);

            // Insert 'Initial' Subscription Order
            Subscription_Order__c so = new Subscription_Order__c(
                Type__c = 'Initial',
                New_Annual_kWh__c = 10000,
                Effective_Date__c = System.now(),
                Approval_Status__c = 'Approved',
                Product__c = defaultProduct.Id
            );
            unitOfWork.registerNew(so, Subscription_Order__c.Utility_Account_Subscription__c, uas);
        }

        unitOfWork.commitWork();
    }

    private void insertUtility() {
        Utility__c testUtility = new Utility__c(
            Name = 'Eversource Test Utility',
            EIA_ID__c = '1234',
            Number_of_Decimal_Places__c = 4
        );
        insert testUtility;
        utility = testUtility;
    }

    private void insertLegacyPartner() {
        Partner__c partner = new Partner__c(
            Name = 'Solar Test Partner'
        );
        insert partner;
        legacyPartner = partner;
    }

    private void insertPartnerAccount() {
        Account partnerAcc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId(),
            Name = 'Solar Test Partner',
            Partner__c = legacyPartner.Id
        );
        insert partnerAcc;

        legacyPartner.Account__c = partnerAcc.Id;
        update legacyPartner;

        partnerAccount = partnerAcc;
    }

    private void insertProduct() {
        Product2 product = new Product2(
            Name = 'Default CS Product',
            Customer_Subscription_Type__c = 'kWh'
        );
        insert product;
        defaultProduct = product;
    }

    private void insertNMCTariff() {
        Utility_NMC_Tariff__c nmcTariff =  new Utility_NMC_Tariff__c(
            Name = 'Eversource R2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1137,
            Size_Ratio__c = 1.5,
            Current_Billing_Rate__c = true,
            Customer_Type__c = 'Residential'
        );
        insert nmcTariff;
        tariff = nmcTariff;
    }

    private void insertVariableStructure() {
        Commission_Structure__c structure = new Commission_Structure__c(
            Name = 'Solar Test Partner $.05 / $.01 / $.02',
            Type__c = 'Variable by kW',
            Cents_kW_DC_Up_Front__c = .05,
            Cents_kW_DC_First_Bill__c = .01,
            Cents_kW_DC_First_Bill_Paid__c = .02,
            Partner__c = legacyPartner.Id,
            Partner_Account__c = partnerAccount.Id,
            Product__c = defaultProduct.Id
        );
        insert structure;
        variableStructure = structure;
    }

    private void insertSharedSolarSystem() {
        Shared_Solar_System__c sss = new Shared_Solar_System__c(
            Name = 'Project A Oak Road',
            Service_Territory__c = 'SEMA',
            Billing_Method__c = 'NMC',
            Open__c = false,
            Total_System_Size_kWh_DC__c = 1445.86,
            Perch_Acq_Reserved_Small_CS_Capacity__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Credit_Score_Requirement__c = 200,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Utility__c = utility.Id,
            Available_SMB_Underwriting_Method_Docs__c = false,
            Available_SMB_Underwriting_Method_FICO__c = false,
            Do_Not_Underwrite__c = true,
            Public__c = true,
            Product__c = defaultProduct.Id
        );
        insert sss;
        sharedSolarSystem = sss;
    }

    private void insertSharedSolarSystemAccesses() {
        Partner_Shared_Solar_System_Eligibility__c pssa = new Partner_Shared_Solar_System_Eligibility__c(
            Commission_Structure__c = variableStructure.Id,
            Shared_Solar_System__c = sharedSolarSystem.Id,
            Account__c = partnerAccount.Id,
            Start_Date__c = Date.today().addMonths(-1)
        );
        insert pssa;
    }
}