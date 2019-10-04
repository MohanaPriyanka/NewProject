/**
 * Created by SarahRenfro on 6/4/2019.
 */

@IsTest
public class LeadServiceTestclass {
    @TestSetup
    public static void setupTestData() {

        Utility__c nyseg = new Utility__c(
            Name = 'NYS Electric and Gas'
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{
            nyseg, nationalGrid
        };

        Load_U__c nysegLZU = new Load_U__c(
            Name = '12345',
            LZ__c = 'Hudson Valley'
        );
        Load_U__c natgridLZU = new Load_U__c(
            Name = '98765',
            LZ__c = 'WCMA'
        );
        insert new List<Load_U__c>{
            nysegLZU, natgridLZU
        };


        ZipCode_Utility_Junction__c junction1 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = nysegLZU.Id,
            Utility__c = nyseg.Id
        );

        ZipCode_Utility_Junction__c junction2 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = natgridLZU.Id,
            Utility__c = nationalGrid.Id
        );

        insert new List<ZipCode_Utility_Junction__c>{
            junction1, junction2
        };

        Utility_NMC_Tariff__c nmcRate = (Utility_NMC_Tariff__c) TestFactory.createSObject(new Utility_NMC_Tariff__c(Value_of_Net_Metering_Credit__c = 1,
            Name = 'Nation Grid WCMA Class 2 - S/F 2016',
            Sizing_Rate__c = true,
            Date__c = Date.today()));
        insert nmcRate;

        Product2 csProduct = new Product2(
            Name = 'VDER',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'VDER - Community Solar',
            State__c = 'NY',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Customer_Subscription_Type__c = 'kWh');
        insert csProduct;

        Product2 csProduct2 = new Product2(
            Name = 'Community Solar - SREC 16-01',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            NM_Rate_Floor__c = 0,
            Monthly_Late_Fee__c = 1);
        insert csProduct2;


        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Albany Post Rd Solar Farm',
            Service_Territories__c = 'Hudson Valley; Central',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = nyseg.Id,
            Credit_Score_Requirement__c = 500,
            Assignment_Order__c = '1',
            Product__c = csProduct.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'BlueWave Test Partner'
        );

        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(
            Name = 'Oxford Barrett St. P1',
            Service_Territories__c = 'WCMA; SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = nationalGrid.Id,
            Credit_Score_Requirement__c = 200,
            Assignment_Order__c = '1',
            Utility_NMC_Tariff__c = nmcRate.Id,
            Product__c = csProduct2.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Assemblage__c = 25,
            Sales_Partners__c = 'All'
        );
        insert new List<Shared_Solar_System__c>{
            sss1, sss2
        };

        Partner__c partner1 = new Partner__c (
            Name = 'BlueWave Test Partner',
            Email__c = 'bwtest@email.com'
        );

        TestFactory.setDefaultCSPartner(partner1.Id);

        Partner__c partner2 = new Partner__c(
            Name = 'Other Test Partner',
            Email__c = 'otherTest@email.com'
        );

        insert new List<Partner__c>{
            partner1, partner2
        };

        BSST__c salesRep1 = new BSST__c(
            Name = 'BW Sales Rep',
            Partner__c = partner1.Id
        );

        BSST__c salesRep2 = new BSST__c(
            Name = 'Other Sales Rep',
            Partner__c = partner2.Id
        );
        insert new List<BSST__c>{
            salesRep1, salesRep2
        };

        partner1.Default_Sales_Rep__c = salesRep1.Id;
        partner2.Default_Sales_Rep__c = salesRep2.Id;
        update new List<Partner__c>{
            partner1, partner2
        };


        Lead switchLead = (Lead)TestFactory.createSObject(new Lead(
            LastName = 'Testcase',
            FirstName = 'Switch',
            Email = 'switch@email.com',
            Utility_relationship__c = nyseg.Id,
            LASERCA__Home_Address__c = '123 Street',
            LASERCA__Home_City__c = 'Albany',
            LASERCA__Home_Zip__c = '12345',
            LASERCA__Home_State__c = 'NY',
            LoadZone__c = 'Hudson Valley',
            LeadSource = 'Switch',
            Company = 'Switch Comp',
            Status = 'Sales Qualified',
            Partner_Lookup__c = partner1.Id,
            Product_line__c = 'Community Solar',
            Product__c = csProduct.Id,
            Parcel_Zip__c = '12345',
            Customer_type__c = 'Residential',
            Application_Type__c = 'Residential',
            System_Assignment__c = 'Automatic - Assignment Order'));
        insert switchLead;


    }
    @IsTest
    static void testDispatchCSAPLead() {
        Lead csapLead = (Lead)TestFactory.createSObject(new Lead(
            LastName = 'Testcase',
            FirstName = 'CSAP',
            Email = 'test@email.com',
            LeadSource = 'CSAP',
            Company = 'Cloud Jedi',
            Status = 'Qualified',
            Product_line__c = 'Community Solar',
            Parcel_Zip__c = '12345',
            System_Assignment__c = 'Automatic - Assignment Order'));

        insert csapLead;



        Partner__c partner = [SELECT Id FROM Partner__c WHERE Email__c = 'otherTest@email.com' LIMIT 1];


        csapLead.Partner_Lookup__c = partner.Id;
        update csapLead;

        Lead lead = [
            SELECT Id, Partner_Lookup__c, Utility_relationship__r.Name, LoadZone__c
            FROM Lead
            WHERE FirstName = 'CSAP'
            LIMIT 1
        ];

        //LeadDispatcher should send lead to LeadTriggerHandler where LoadZone and Utliity are set using UtilityLoadZoneService
        System.assertEquals('Hudson Valley' , lead.LoadZone__c);
        System.assertEquals('NYS Electric and Gas', lead.Utility_relationship__r.Name);

    }

    @IsTest
    static void testBuildPropertyAccount() {
        Lead switchLead = [
            SELECT Id, Status, Company, Product_line__c, Utility_relationship__r.Id, LASERCA__Home_Address__c,
                LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c
            FROM Lead
            WHERE FirstName = 'Switch'
            LIMIT 1
        ];
        LeadService leadService = new LeadService();

        Account propertyAccount = leadService.buildPropertyAccountFromLegacyLead(switchLead);
        insert propertyAccount;

        List<Account> propAccounts = [SELECT Id, Name, Lead__c, RecordType.Name FROM Account WHERE Lead__c = :switchLead.Id];

        System.assertNotEquals(null, propAccounts);
        System.assertEquals('Switch Comp', propAccounts[0].Name);
        System.assertEquals('Property', propAccounts[0].RecordType.Name);

    }

    @IsTest
    static void testBuildUtilityAccountLog() {
        Lead switchLead = [
            SELECT Id, Status, Company, Product_line__c, Utility_relationship__r.Id, LASERCA__Home_Address__c,
                LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c
            FROM Lead
            WHERE FirstName = 'Switch'
            LIMIT 1
        ];
        LeadService leadService = new LeadService();

        Account propertyAccount = leadService.buildPropertyAccountFromLegacyLead(switchLead);
        insert propertyAccount;

        Utility_Account_Log__c ual = leadService.buildUtilityAccountLogFromLegacyLead(switchLead, propertyAccount);
        insert ual;

        List<Utility_Account_Log__c> ualList = [
            SELECT Id, Name, Name_on_Account__c, Utility_lookup__r.Name
            FROM Utility_Account_Log__c
            WHERE Lead__c = :switchLead.Id
        ];

        System.assertNotEquals(null, ualList);
        System.assertEquals(propertyAccount.Name, ualList[0].Name_on_Account__c);
        System.assertEquals(switchLead.Utility_relationship__c, ualList[0].Utility_lookup__c);
    }

    @IsTest
    static void testCompleteLeadConversion() {
        Lead switchLead = [
            SELECT Id, Status, Company, Product_line__c, Utility_relationship__r.Id, LASERCA__Home_Address__c,
                LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c
            FROM Lead
            WHERE FirstName = 'Switch'
            LIMIT 1
        ];
        LeadService leadService = new LeadService();

        Account propertyAccount = leadService.buildPropertyAccountFromLegacyLead(switchLead);
        insert propertyAccount;

        Utility_Account_Log__c ual = leadService.buildUtilityAccountLogFromLegacyLead(switchLead, propertyAccount);
        ual.Annual_kWh__c = 9000;
        insert ual;

        switchLead.Status = 'Qualified';
        update switchLead;


        pullCreditForLead(switchLead.Id);


        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(switchLead.Id);
        lc.setConvertedStatus('Qualified');
        lc.setDoNotCreateOpportunity(true);

        Database.LeadConvertResult lcr = Database.convertLead(lc, false);
        System.assert(lcr.isSuccess());

        Lead convertedLead = [
            SELECT Id, ConvertedAccountId, ConvertedContactId, IsConverted, Personal_Credit_Report__c
            FROM Lead
            WHERE IsConverted = TRUE
            LIMIT 1
        ];

        System.assertNotEquals(null, convertedLead);
        System.assertNotEquals(null, convertedLead.ConvertedAccountId);

        Account convertedAccount = [
            SELECT Id, Owner.Name, RecordType.Name
            FROM Account
            WHERE Id = :convertedLead.ConvertedAccountId
            LIMIT 1
        ];

        Account propAcct = [
            SELECT Id, Send_Bills_Contact__c, RecordType.Name, Parent_Account__c
            FROM Account
            WHERE Lead__c = :convertedLead.Id AND RecordType.Name = 'Property'
            LIMIT 1
        ];

        Contact contact = [
            SELECT Id, Product_Line__c
            FROM Contact
            WHERE Id = :convertedLead.ConvertedContactId
            LIMIT 1
        ];

        List<Opportunity> oppList = [
            SELECT Id, Shared_Solar_System__r.Name, StageName, Personal_Credit_Report2__c
            FROM Opportunity
            WHERE Lead__c = :convertedLead.Id
        ];

        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Utility_Account_Log__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c IN :oppList
            LIMIT 1
        ];



        //test converted account = parent account
        System.assertEquals('Parent Account', convertedAccount.RecordType.Name);
        System.assertEquals('API', convertedAccount.Owner.Name);

        //Test property's parent account
        System.assertEquals(convertedAccount.Id, propAcct.Parent_Account__c);
        System.assertEquals(contact.Id, propAcct.Send_Bills_Contact__c);
        System.assertEquals('Community Solar', contact.Product_Line__c);

        System.assertEquals(1, oppList.size());
        System.assertEquals('Albany Post Rd Solar Farm', oppList[0].Shared_Solar_System__r.Name);
        System.assertEquals(convertedLead.Personal_Credit_Report__c, oppList[0].Personal_Credit_Report2__c);
        System.assertEquals('QC In Progress'.toLowerCase(), oppList[0].StageName.toLowerCase());

        //test uas creation
        System.assertNotEquals(null, uasList);
        System.assertEquals(1, uasList.size());
        System.assertEquals(ual.Id, uasList[0].Utility_Account_Log__c);

    }

    @IsTest
    static void testFailedEnrollment(){
        Lead switchLead = [
            SELECT Id, Status, Company, Product_line__c, Utility_relationship__r.Id, LASERCA__Home_Address__c,
                LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c
            FROM Lead
            WHERE FirstName = 'Switch'
            LIMIT 1
        ];
        LeadService leadService = new LeadService();

        Account propertyAccount = leadService.buildPropertyAccountFromLegacyLead(switchLead);
        insert propertyAccount;

        Utility_Account_Log__c ual = leadService.buildUtilityAccountLogFromLegacyLead(switchLead, propertyAccount);
        insert ual;

        switchLead.Status = 'Qualified';
        update switchLead;


        pullCreditForLead(switchLead.Id);


        try {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(switchLead.Id);
            lc.setConvertedStatus('Qualified');
            lc.setDoNotCreateOpportunity(true);

            Database.LeadConvertResult lcr = Database.convertLead(lc, false);
        } catch(Exception e) {
            Boolean expectedException = e.getMessage().contains('No Annual Usage populated on UALs. Please enter usage before converting')? true : false;
            System.assertEquals(expectedException, true);
        }

        Lead failedLead = [
            SELECT Id, ConvertedAccountId, ConvertedContactId, IsConverted, Personal_Credit_Report__c
            FROM Lead
            WHERE Id = :switchLead.Id
            LIMIT 1
        ];

        System.assertEquals(false, failedLead.IsConverted);
        System.assertEquals(null, failedLead.ConvertedAccountId);

        List<Opportunity> oppList = [
            SELECT Id, Shared_Solar_System__r.Name, StageName, Personal_Credit_Report2__c
            FROM Opportunity
            WHERE Lead__c = :failedLead.Id
        ];

        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Utility_Account_Log__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c IN :oppList
            LIMIT 1
        ];

        System.assertEquals(0, oppList.size());
        System.assertEquals(0, uasList.size());
    }



    public static void pullCreditForLead(Id leadId) {
        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = leadId,
            LASERCA__Credit_Score__c = '700',
            LASERCA__Credit_Score_TransUnion__c = '700'
        );
        insert pcr;
        LASERCA__Trade_Accounts__c tradeAccounts = new LASERCA__Trade_Accounts__c(
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Monthly_Payment__c = 339
        );
        insert tradeAccounts;

        LASERCA__Credit_Report_Log__c crLog = new LASERCA__Credit_Report_Log__c(
            LASERCA__Lead__c = leadId,
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Status__c = 'Completed'
        );
        insert crLog;
    }
}