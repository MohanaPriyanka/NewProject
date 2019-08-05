/**
 * Created by SarahRenfro on 5/22/2019.
 */

@IsTest
private class CSQualificationTestclass {
    @TestSetup
    public static void setupTestData() {
        Test.startTest();

        Account accountRecord = new Account(
            Name = 'Mass Renewables',
            State_Market__c = 'MA',
            Enable_CS_Application_in_Portal__c = true,
            Community_Solar_Application_Type__c = 'CSAP');
        insert accountRecord;

        Partner__c partner = new Partner__c(
            Name = 'Mass Renewables',
            Email__c = 'massRenewables@test.com');
        insert partner;

        TestFactory.setDefaultCSPartner(partner.Id);

        BSST__c salesRep = new BSST__c(
            Name = 'Mr. Sales',
            Partner__c = partner.Id,
            Email__c = 'martz@testemail.com');
        insert salesRep;

        partner.Default_Sales_Rep__c = salesRep.Id;
        update partner;

        Product2 vderProduct = new Product2( Name = 'VDER',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'VDER - Community Solar',
            State__c = 'NY',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_in_Bill_Period__c = 20,
            Monthly_Late_Fee__c = 1);

        Utility__c nyseg = new Utility__c(
            Name = 'NYS Electric and Gas',
            Number_of_Decimal_Places__c = 2,
            EIA_ID__c = '1234'
        );

        Utility__c central = new Utility__c(
            Name = 'Central Hudson Gas and Electric',
            Number_of_Decimal_Places__c = 2,
            EIA_ID__c = '5678'
        );
        insert new List<Utility__c>{nyseg, central};

        Load_U__c loadZone = new Load_U__c (
            Name = '12345',
            LZ__c = 'Hudson Valley',
            Town__c= 'Albany'
        );
        insert loadZone;

        ZipCode_Utility_Junction__c junction1 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = loadZone.Id,
            Utility__c = nyseg.Id
        );

        ZipCode_Utility_Junction__c junction2 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = loadZone.Id,
            Utility__c = central.Id
        );

        insert new List<ZipCode_Utility_Junction__c>{junction1, junction2};

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(   Name = 'Albany Post Rd',
            Service_Territory__c = 'Hudson Valley',
            Service_Territories__c = 'Hudson Valley',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = nyseg.Id,
            Public__c = true,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Product__c = vderProduct.Id,
            Maximum_Subscription_Assemblage__c = 25);
        insert sss1;

        Lead resiLead =  new Lead(
            FirstName = 'Switch',
            LastName = 'Testcase',
            Email = 'test@email.com',
            MobilePhone = '1231231234',
            Company = 'Post Testcase',
            Application_Type__c = 'Residential',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Albany',
            LASERCA__Home_State__c = 'NY',
            LASERCA__Home_Zip__c = '12345',
            Street = '55 Boston St',
            City = 'Albany',
            State = BlueWaveParent.convertAbbreviationToState('NY'),
            PostalCode = '12345',
            Parcel_Zip__c = '12345',
            Application_Source_Phase_1__c ='Switch without Partner',
            LeadSource = 'Switch',
            Product_line__c = 'Community Solar',
            Product__c = vderProduct.Id,
            LoadZone__c = loadZone.LZ__c,
            Utility_relationship__c = nyseg.Id,
            Phone = '1231231234',
            Customer_type__c = 'Residential',
            Status = 'Sales Qualified'
        );

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        resiLead.setOptions(dmo);

        insert resiLead;

        Test.stopTest();
    }

    @IsTest
    public static void testCheckCSQualification() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        pullCreditForLead(lead.Id, true);

        Lead checkLead = [
            SELECT Id, Status, Personal_Credit_Report__c, Personal_Credit_Report__r.LASERCA__Credit_Score__c,
                Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c
            FROM Lead
            WHERE Id = :lead.Id
        ];


        System.assertEquals('Qualified', checkLead.Status);
        System.assertNotEquals(null, checkLead.Personal_Credit_Report__c);
        System.assertEquals('700', checkLead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c );
    }

    @IsTest
    public static void testUnqualifiedLead() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Utility__c central = [SELECT Id FROM Utility__c WHERE Name = 'Central Hudson Gas and Electric' LIMIT 1];

        lead.Utility_relationship__c = central.Id;
        update lead;

        //Should I query for the lead again before I pull credit?
        pullCreditForLead(lead.Id, true);

        Lead checkLead = [
            SELECT Id, Status, Personal_Credit_Report__c, Personal_Credit_Report__r.LASERCA__Credit_Score__c,
                Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c
            FROM Lead
            WHERE Id = :lead.Id
        ];



        System.assertEquals('Unqualified', checkLead.Status);
        System.assertNotEquals(null, checkLead.Personal_Credit_Report__c);
        System.assertEquals('700', checkLead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c );

    }

    @IsTest
    public static void testNoPCRMatch() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        pullCreditForLead(lead.Id, false);

        Lead checkLead = [
            SELECT Id, Status, Personal_Credit_Report__c, Personal_Credit_Report__r.LASERCA__Credit_Score__c,
                Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c
            FROM Lead
            WHERE Id = :lead.Id
        ];


        System.assertEquals('Qualified', checkLead.Status);
        System.assertNotEquals(null, checkLead.Personal_Credit_Report__c);
        System.assertEquals('9999', checkLead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c );

    }

    public static void pullCreditForLead(Id leadId, Boolean match) {

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = leadId
        );
        if (match) {
            pcr.LASERCA__Credit_Score__c = '700';
            pcr.LASERCA__Credit_Score_TransUnion__c = '700';
        }
        insert pcr;

        LASERCA__Trade_Accounts__c tradeAccounts = new LASERCA__Trade_Accounts__c(
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Monthly_Payment__c = 339
        );
        insert tradeAccounts;

        LASERCA__Credit_Report_Log__c crLog = new LASERCA__Credit_Report_Log__c(
            LASERCA__Lead__c = leadId,
            LASERCA__Personal_Credit_Report__c = pcr.Id
        );

        if (match) {
            crLog.LASERCA__Status__c = 'Error';
        } else {
            crLog.LASERCA__Status__c = 'Completed';
        }
        insert crLog;
    }

}