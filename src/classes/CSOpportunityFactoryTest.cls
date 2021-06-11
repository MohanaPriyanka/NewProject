/**
 * Created by mstackhouse on 12/14/2018.
 * Description: 
 * Test: 
 */

@IsTest
public without sharing class CSOpportunityFactoryTest {
    @SuppressWarnings('PMD.AvoidDmlStatementsInLoops')
    private static Shared_Solar_System__c getSharedSolarSystem(Utility_NMC_Tariff__c nmcRate, Product2 csProduct,
        Utility__c utility, String name) {
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = name,
            Service_Territories__c = 'WCMA; SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = utility.Id,
            Credit_Score_Requirement__c = 700,
            Assignment_Order__c = '1',
            Utility_NMC_Tariff__c = nmcRate.Id,
            Product__c = csProduct.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Available_SMB_Underwriting_Method_Docs__c = true,
            Available_SMB_Underwriting_Method_FICO__c = true
        );
        return sss1;
    }
   
    @IsTest
    public static void testCanSetDefaultOppFieldsFromLeadWhenNull() {
        // This tests that we can set the map fields from a lead to an opp, even if the values on the lead are null
        Lead lead = new Lead();
        Opportunity opp = new Opportunity();

        Boolean hasErrored = false;

        try {
            Opportunity updatedOpp = CSOpportunityFactory.setDefaultOppFields(lead, opp);
        } catch (Exception e) {
            hasErrored = true;
        }

        System.assert(!hasErrored, 'CSOpportunityFactory.setDefaultOppFields hit an error');
    }
   

    @IsTest
    public static void testCanGenerateCSOpportunitiesForLeadByCost() {
  

        Utility_NMC_Tariff__c nmcRate =  new Utility_NMC_Tariff__c(
            Value_of_Net_Metering_Credit__c = .1848,
            Name = 'Nation Grid WCMA Class 2 - S/F 2016',
            Sizing_Rate__c = true,
            Date__c = Date.today()
        );
        insert nmcRate;

        Product2 csProduct = new Product2( Name = 'Community Solar - SREC 16-01',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            Monthly_Late_Fee__c = 1);
        insert csProduct;

        Utility__c eversource = new Utility__c(Name = 'Eversource', Number_of_Decimal_Places__c = 2);
        insert eversource;

        Shared_Solar_System__c sss1 = getSharedSolarSystem(nmcRate, csProduct, eversource, 'Eversource P1');
        Shared_Solar_System__c sss2 = getSharedSolarSystem(nmcRate, csProduct, eversource, 'Eversource P2');

        List<Shared_Solar_System__c> availableSSS = new List<Shared_Solar_System__c>{sss1, sss2};

        insert availableSSS;

        availableSSS = [
            SELECT Id, Maximum_Subscription_Cost__c, Expected_Yield_kWh_kW__c,
                Reserved_Capacity_kW_DC__c, Project_Capacity_Available_kW_DC__c, Product__c, Product__r.Sizing_Method__c,
                Utility_NMC_Tariff__c, Maximum_Subscription_Capacity_kWDC__c, Credit_Score_Requirement__c, Product__r.Customer_Subscription_Type__c
            FROM Shared_Solar_System__c
            WHERE Id IN : availableSSS
            ORDER BY Name
        ];
        sss1 = availableSSS[0];
        sss2 = availableSSS[1];

        Decimal costToAssign = 10000;
        Decimal kWhToAssign = 0;
        CSSubscriptionEnroller.AnnualEnergyTotal annualTotals = new CSSubscriptionEnroller.AnnualEnergyTotal(costToAssign, kWhToAssign);

        Account parentAccount = new Account(Name = 'Parent');
        insert parentAccount;

        Account propertyAccount = new Account(Name = 'Property');
        insert propertyAccount;

        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Testcase',
            Email = 'test@test.com',
            Electricity_Provider__c = 'Eversource',
            Utility_1__c = 'Eversource',
            LoadZone__c = 'WCMA',
            Company = 'Test',
            Status = 'Qualified',
            Product_line__c = 'Community Solar',
            Product__c = csProduct.Id,
            Custom_ID__c = 'partner',
            System_Assignment__c = 'Automatic - Assignment Order',
            Parent_Account__c = parentAccount.Id
        );
        insert lead;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = lead.Id,
            LASERCA__Credit_Score_TransUnion__c = '720'
        );
        insert pcr;
        lead.Personal_Credit_Report__c = pcr.Id;
        update lead;

        lead = [
            SELECT Id, LASER_Credit_Score__c, ConvertedAccountId, FirstName, LastName, Application__c, Acquired_By_Client_Closed_By_BlueWave__c,
                Application_Type__c, Avidia_Checking_Account__c, Business_Title__c, Customer_Referral__c, Customer_Type__c,
                Customer_Type_Formula__c, LeadSource, Date_Of_Application__c, DOER_Solar_Loan__c, Email_Re_Enter__c, LASERCA__Home_State__c,
                Is_Loan_Secured__c, Lead_ID__c, Loan_Program_Class__c, Maximum_Monthly_Disbursement2__c, Company,
                Number_of_Years_at_Location__c, Number_of_Years_in_Business__c, Parcel_Zip__c, Partner_lookup__c, Partner_Account__c, Partner_Contact__c, 
                Partner_Email__c, Personal_Credit_Report__c, Phone2__c, Product_Line__c, Referral_Email__c, bs_Sales_ID__c,
                Security_Type__c, LoadZone__c, System_Assignment__c, Utility__c, OwnerId, Loan_System_Information__c, Underwriting_Criteria__c
            FROM Lead
            WHERE Id =: lead.Id
        ];

        List<Opportunity> generatedOpps = CSOpportunityFactory.generateCSOpportunities(lead, availableSSS, annualTotals, propertyAccount.Id);

        Opportunity opp1 = generatedOpps[0];
        Opportunity opp2 = generatedOpps[1];
        System.assertEquals(2, generatedOpps.size());

        System.assertEquals(sss1.Id, opp1.Shared_Solar_System__c);
        System.assertEquals(sss1.Maximum_Subscription_Cost__c, opp1.Annual_Electricity_Cost__c);
        System.assertEquals(0, opp1.Annual_Consumption_kWh__c);
        System.assertEquals('Contract Pending', opp1.StageName);

        System.assertEquals(sss2.Id, opp2.Shared_Solar_System__c);
        System.assertEquals(annualTotals.cost - opp1.Annual_Electricity_Cost__c, opp2.Annual_Electricity_Cost__c);
        System.assertEquals(0, opp2.Annual_Consumption_kWh__c);
        System.assertEquals('Contract Pending', opp2.StageName);

    }

    @IsTest
    public static void testCanGenerateCSOpportunitiesForLeadBykWh() {
        Utility_NMC_Tariff__c nmcRate =  new Utility_NMC_Tariff__c(
            Value_of_Net_Metering_Credit__c = .1848,
            Name = 'Nation Grid WCMA Class 2 - S/F 2016',
            Sizing_Rate__c = true,
            Date__c = Date.today()
        );
        insert nmcRate;

        Product2 csProduct = new Product2( Name = 'Community Solar - SREC 16-01',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            Monthly_Late_Fee__c = 1);
        insert csProduct;

        Utility__c eversource = new Utility__c(Name = 'Eversource', Number_of_Decimal_Places__c = 2);
        insert eversource;

        Shared_Solar_System__c sss1 = getSharedSolarSystem(nmcRate, csProduct, eversource, 'Eversource P1');
        Shared_Solar_System__c sss2 = getSharedSolarSystem(nmcRate, csProduct, eversource, 'Eversource P2');

        List<Shared_Solar_System__c> availableSSS = new List<Shared_Solar_System__c>{sss1, sss2};

        insert availableSSS;

        availableSSS = [
            SELECT Id, Maximum_Subscription_Cost__c, Expected_Yield_kWh_kW__c,
                Reserved_Capacity_kW_DC__c, Project_Capacity_Available_kW_DC__c, Product__c, Product__r.Sizing_Method__c,
                Utility_NMC_Tariff__c, Credit_Score_Requirement__c, Maximum_Subscription_Capacity_kWDC__c,
                Product__r.Customer_Subscription_Type__c
            FROM Shared_Solar_System__c
            WHERE Id IN : availableSSS
            ORDER BY Name
        ];
        sss1 = availableSSS[0];
        sss2 = availableSSS[1];

        Decimal costToAssign = 0;
        Decimal kWhToAssign = 50000;
        CSSubscriptionEnroller.AnnualEnergyTotal annualTotals = new CSSubscriptionEnroller.AnnualEnergyTotal(costToAssign, kWhToAssign);

        Account parentAccount = new Account(Name = 'Parent');
        insert parentAccount;

        Account propertyAccount = new Account(Name = 'Property');
        insert propertyAccount;

        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Testcase',
            Email = 'test@test.com',
            Electricity_Provider__c = 'Eversource',
            Utility_1__c = 'Eversource',
            LeadSource = 'Switch',
            LoadZone__c = 'WCMA',
            Company = 'Test',
            Status = 'Qualified',
            Product_line__c = 'Community Solar',
            Product__c = csProduct.Id,
            Custom_ID__c = 'partner',
            System_Assignment__c = 'Automatic - Assignment Order',
            Parent_Account__c = parentAccount.Id
        );
        insert lead;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = lead.Id,
            LASERCA__Credit_Score_TransUnion__c = '720'
        );
        insert pcr;
        lead.Personal_Credit_Report__c = pcr.Id;
        update lead;

        lead = [
            SELECT Id, LASER_Credit_Score__c, ConvertedAccountId, FirstName, LastName, Application__c, Acquired_By_Client_Closed_By_BlueWave__c,
                Application_Type__c, Avidia_Checking_Account__c, Business_Title__c, Customer_Referral__c, Customer_Type__c,
                Customer_Type_Formula__c, LeadSource, Date_Of_Application__c, DOER_Solar_Loan__c, Email_Re_Enter__c, LASERCA__Home_State__c,
                Is_Loan_Secured__c, Lead_ID__c, Loan_Program_Class__c, Maximum_Monthly_Disbursement2__c, Company,
                Number_of_Years_at_Location__c, Number_of_Years_in_Business__c, Parcel_Zip__c, Partner_lookup__c, Partner_Account__c, Partner_Contact__c, 
                Partner_Email__c, Personal_Credit_Report__c, Phone2__c, Product_Line__c, Referral_Email__c, bs_Sales_ID__c,
                Security_Type__c, LoadZone__c, System_Assignment__c, Utility__c, OwnerId, Loan_System_Information__c, Underwriting_Criteria__c
            FROM Lead
            WHERE Id =: lead.Id
        ];

        List<Opportunity> generatedOpps = CSOpportunityFactory.generateCSOpportunities(lead, availableSSS, annualTotals, propertyAccount.Id);

        Opportunity opp1 = generatedOpps[0];
        Opportunity opp2 = generatedOpps[1];
        System.assertEquals(2, generatedOpps.size());

        System.assertEquals(sss1.Id, opp1.Shared_Solar_System__c);
        System.assertEquals(0, opp1.Annual_Electricity_Cost__c);
        Decimal maximumKWHSubscription =  sss1.Maximum_Subscription_Capacity_kWDC__c *sss1.Expected_Yield_kWh_kW__c;
        System.assertEquals(maximumKWHSubscription, opp1.Annual_Consumption_kWh__c);
        System.assertEquals('QC in Process', opp1.StageName);

        System.assertEquals(sss2.Id, opp2.Shared_Solar_System__c);
        System.assertEquals(0, opp2.Annual_Electricity_Cost__c);
        System.assertEquals(annualTotals.kWh - opp1.Annual_Consumption_kWh__c, opp2.Annual_Consumption_kWh__c);
        System.assertEquals('QC in Process', opp2.StageName);
    }

    @IsTest
    public static void testCanGenerateCSOpportunitiesWithZuora() {
        Utility_NMC_Tariff__c nmcRate =  new Utility_NMC_Tariff__c(
            Value_of_Net_Metering_Credit__c = .1848,
            Name = 'Nation Grid WCMA Class 2 - S/F 2016',
            Sizing_Rate__c = true,
            Date__c = Date.today()
        );
        insert nmcRate;

        Product2 csProduct = new Product2( Name = 'Community Solar - SREC 16-01',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            Monthly_Late_Fee__c = 1);
        insert csProduct;

        Utility__c eversource = new Utility__c(Name = 'Eversource', Number_of_Decimal_Places__c = 2);
        insert eversource;

        Shared_Solar_System__c sss1 = getSharedSolarSystem(nmcRate, csProduct, eversource, 'Eversource P1');
        Shared_Solar_System__c sss2 = getSharedSolarSystem(nmcRate, csProduct, eversource, 'Eversource P2');

        List<Shared_Solar_System__c> availableSSS = new List<Shared_Solar_System__c>{sss1, sss2};

        insert availableSSS;

        availableSSS = [
            SELECT Id, Maximum_Subscription_Cost__c, Expected_Yield_kWh_kW__c, Maximum_Subscription_Capacity_kWDC__c,
                Reserved_Capacity_kW_DC__c, Project_Capacity_Available_kW_DC__c, Product__c, Product__r.Sizing_Method__c,
                Utility_NMC_Tariff__c, Credit_Score_Requirement__c, Product__r.Customer_Subscription_Type__c
            FROM Shared_Solar_System__c
            WHERE Id IN : availableSSS
            ORDER BY Name
        ];
        sss1 = availableSSS[0];
        sss2 = availableSSS[1];

        Decimal costToAssign = 0;
        Decimal kWhToAssign = 50000;
        CSSubscriptionEnroller.AnnualEnergyTotal annualTotals = new CSSubscriptionEnroller.AnnualEnergyTotal(costToAssign, kWhToAssign);

        Account parentAccount = new Account(Name = 'Parent');
        insert parentAccount;

        Account propertyAccount = new Account(Name = 'Property');
        insert propertyAccount;

        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Testcase',
            Email = 'test@test.com',
            Electricity_Provider__c = 'Eversource',
            Utility_1__c = 'Eversource',
            LoadZone__c = 'WCMA',
            Company = 'Test',
            Status = 'Qualified',
            Product_line__c = 'Community Solar',
            Product__c = csProduct.Id,
            Custom_ID__c = 'partner',
            System_Assignment__c = 'Automatic - Assignment Order',
            Parent_Account__c = parentAccount.Id);
        insert lead;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = lead.Id,
            LASERCA__Credit_Score_TransUnion__c = '720'
        );
        insert pcr;
        lead.Personal_Credit_Report__c = pcr.Id;
        update lead;

        lead = [
            SELECT Id, LASER_Credit_Score__c, ConvertedAccountId, FirstName, LastName, Application__c, Acquired_By_Client_Closed_By_BlueWave__c,
                Application_Type__c, Avidia_Checking_Account__c, Business_Title__c, Customer_Referral__c, Customer_Type__c,
                Customer_Type_Formula__c, LeadSource, Date_Of_Application__c, DOER_Solar_Loan__c, Email_Re_Enter__c, LASERCA__Home_State__c,
                Is_Loan_Secured__c, Lead_ID__c, Loan_Program_Class__c, Maximum_Monthly_Disbursement2__c, Company,
                Number_of_Years_at_Location__c, Number_of_Years_in_Business__c, Parcel_Zip__c, Partner_lookup__c, Partner_Account__c, Partner_Contact__c, 
                Partner_Email__c, Personal_Credit_Report__c, Phone2__c, Product_Line__c, Referral_Email__c, bs_Sales_ID__c,
                Security_Type__c, LoadZone__c, System_Assignment__c, Utility__c, OwnerId,  Underwriting_Criteria__c
            FROM Lead
            WHERE Id =: lead.Id
        ];

        List<Opportunity> generatedOpps = CSOpportunityFactory.generateCSOpportunities(lead, availableSSS, annualTotals, propertyAccount.Id);

        Opportunity opp1 = generatedOpps[0];
        Opportunity opp2 = generatedOpps[1];
        System.assertEquals(2, generatedOpps.size());

        System.assertEquals(sss1.Id, opp1.Shared_Solar_System__c);
        System.assertEquals(0, opp1.Annual_Electricity_Cost__c);
        Decimal maximumKWHSubscription = sss1.Maximum_Subscription_Capacity_kWDC__c * sss1.Expected_Yield_kWh_kW__c;
        System.assertEquals(maximumKWHSubscription, opp1.Annual_Consumption_kWh__c);
  
        System.assertEquals(sss2.Id, opp2.Shared_Solar_System__c);
        System.assertEquals(0, opp2.Annual_Electricity_Cost__c);
        System.assertEquals(annualTotals.kWh - opp1.Annual_Consumption_kWh__c, opp2.Annual_Consumption_kWh__c);
    }
}