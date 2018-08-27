@IsTest
public with sharing class CSAPControllerTest {
    @TestSetup static void setupTestData(){
        List<String> partnerSetUpIds = LoanTestRecordWarehouse.partnerSetup();
        LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms();
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='API Only'];

        User apiUser = new User(
            FirstName = 'API',
            LastName = 'API',
            ProfileId = profileRecord.Id,
            Alias = '123api',
            Email = 'api@bluewavesolar.com',
            EmailEncodingKey ='UTF-8',
            PortalRole = 'Manager',
            LanguageLocaleKey ='en_US',
            LocaleSidKey ='en_US',
            Country ='United States',
            IsActive = true,
            TimeZoneSidKey='America/Los_Angeles',
            Username='api123@bluewavesolar.com');
        Util.insertSObj(apiUser);

        RecordType partnerRecordType = [SELECT Id FROM RecordType WHERE Name = 'Partner Contact'];

        Account accountRecord = new Account(
            Name = 'BlueWave Customer Care',
            State_Market__c = 'MA',
            Enable_CS_Application_in_Portal__c = true,
            Community_Solar_Application_Type__c = 'CSAP');
        insert accountRecord;

        Account accountRecord2 = new Account(
            Name = 'Mass Renewables',
            State_Market__c = 'MA',
            Enable_CS_Application_in_Portal__c = true,
            Community_Solar_Application_Type__c = 'CSAP');
        insert accountRecord2;

        Partner__c partner2 = new Partner__c(
            Name = 'Mass Renewables',
            CS_Referral_Status__c = 'Default CS Partner',
            Email__c = 'massRenewables@test.com');
        insert partner2;

        BSST__c salesRep2 = new BSST__c(
            Name = 'Dianne Martz',
            Partner__c = partner2.Id,
            Email__c = 'martz@testemail.com');
        insert salesRep2;

        partner2.Default_Sales_Rep__c = salesRep2.Id;
        update partner2;

        Account customerAccount = new Account(Name = 'Customer Account', Client_Brand_Key__c = 'BluewaveLogo');
        insert customerAccount;

        Contact contactRecord = new Contact(
            FirstName = 'User',
            LastName = 'Swain',
            AccountId = accountRecord.Id,
            RecordType = partnerRecordType,
            Partner_Lookup__c = partnerSetUpIds.get(0),
            Sales_Representative__c = partnerSetUpIds.get(1));
        insert contactRecord;

        Contact customerContact = new Contact( FirstName = 'Contact A',
            LastName = 'Customer',
            Account = customerAccount,
            Email = 'srenfro@bluewavesolar.com');
        insert customerContact;

        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];

        Load_U__c everLZU = new Load_U__c (Name = '02052',
                                           Load_Zone__c = 'SEMA Eversource',
                                           LZ__c = 'SEMA',
                                           Town__c= 'Medfield',
                                           Utility__c = 'Eversource');
        insert everLZU;

        Product2 srecProduct = new Product2( Name = 'SREC Community Solar',
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
                                                  Days_in_Bill_Period__c = 30,
                                                  Monthly_Late_Fee__c = 1);

        Product2 smartProduct = new Product2(  Name = 'SMART Community Solar',
                                                  Family = 'Community Solar',
                                                  Product_Type__c = 'Community Solar',
                                                  Program__c = 'SMART - Community Solar',
                                                  State__c = 'MA',
                                                  ProductCode = 'CS - Bluewave - Public CS - 20%',
                                                  IsActive = true,
                                                  Lender_of_Record__c = 'BlueWave',
                                                  NMC_Discount__c = 20,
                                                  Annual_kWh_Maximum__c = 63000,
                                                  NM_Rate_Floor__c = 0.09,
                                                  Days_in_Bill_Period__c = 30,
                                                  Monthly_Late_Fee__c = 0.8333);
        insert new List<Product2>{srecProduct, smartProduct};

        Lead lead = new Lead(
            FirstName = 'Tester',
            LastName = 'Testcase',
            Company = 'Test',
            Email = 'testymctesterson@tester.com',
            Application_Type__c = 'Residential',
            Product_line__c = 'Community Solar',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Boston',
            LASERCA__Home_State__c = 'MA',
            LASERCA__Home_Zip__c = '02052',
            Parcel_Zip__c = '02052',
            LASERCA__Social_Security_Number__c = '000000001',
            Requested_Loan_Amount__c = 35000,
            Annual_Income_Currency__c = 15000,
            Partner_Lookup__c = partner.Id,
            System_Assignment__c = 'Automatic - COD Date/Available Capacity',
            Status = 'Ready for Credit Check',
            Utility_1__c = 'Eversource',
            Electricity_Provider__c = 'Eversource'
        );
        insert lead;

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = lead.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Tester Testcase');
        insert ual;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = lead.Id,
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
            LASERCA__Lead__c = lead.Id,
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Status__c = 'Completed'
        );
        insert crLog;


        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
                                                                    Service_Territory__c = 'SEMA',
                                                                    Service_Territories__c = 'SEMA',
                                                                    Open__c = true,
                                                                    Reserved_Capacity_kW_DC__c = '10',
                                                                    Capacity_Committed_kW_DC__c = 0,
                                                                    Total_System_Size_kWh_DC__c = 1445.86,
                                                                    Total_System_Size_kW_AC__c  = 996,
                                                                    System_Utility__c = 'Eversource',
                                                                    Credit_Score_Requirement__c = 300,
                                                                    Assignment_Order__c = '1',
                                                                    Expected_Yield_kWh_kW__c = 1300,
                                                                    Assemblage_Count__c = 1,
                                                                    Sales_Partners__c = 'All',
                                                                    Product__c = smartProduct.Id,
                                                                    Maximum_Subscription_Assemblage__c = 25);
        insert sss1;
    }

    @IsTest static void testEmailCSAPApplication() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c LIMIT 1];
        Contact contactPartner = [SELECT Id FROM Contact WHERE Lastname = 'SWAIN' LIMIT 1];
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community Login User (Custom)'];
        Contact customerContact = [SELECT Id FROM Contact WHERE Lastname='Customer' LIMIT 1];

        User userRecord = new User(
            FirstName = 'User',
            LastName ='Testing',
            Alias = 'cswain',
            Email = 'tropicole34@aol.com',
            EmailEncodingKey ='UTF-8',
            PortalRole = 'Manager',
            LanguageLocaleKey ='en_US',
            LocaleSidKey ='en_US',
            ProfileId = profileRecord.Id,
            Country ='United States',
            IsActive = true,
            ContactId = contactPartner.Id,
            TimeZoneSidKey='America/Los_Angeles',
            Username='tropicole34@aol.com');
        Util.insertSObj(userRecord);

        Lead leadToInsert = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c, 
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c, Customer_Referral__c
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'];
        LASERCA__Personal_Credit_Report__c pcr = [SELECT LASERCA__Credit_Score__c FROM LASERCA__Personal_Credit_Report__c WHERE LASERCA__Lead__c = :leadToInsert.Id];
        Product2 smartProduct = [SELECT Id FROM Product2 WHERE Name = 'SMART Community Solar'];

        Test.startTest();
        System.runAs(userRecord) {
            CSAPController.upsertCSAPRecords(leadToInsert, partner.Id, salesRep.Id, customerContact.Id);
            leadToInsert.Application_Type__c = 'Non-Residential';
            CSAPController.addAdditionalLead(leadToInsert);
        }

        List<Lead> leads = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id, OwnerId,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'];

        // Should be a primary lead, and another lead representing the additional property
        System.assertEquals(2, leads.size());

        //Check upserted Lead, Contact and Account records
        Lead residentialLead;
        for (Lead lead : leads) {
            System.assertEquals(lead.Id, CSAPController.getLead(lead.Id, lead.Email).Id);
            System.assertEquals(partner.Id, CSAPController.getLead(lead.Id, lead.Email).Partner_Lookup__c);
            System.assertEquals(salesRep.Id, CSAPController.getLead(lead.Id, lead.Email).bs_Sales_ID__c);
            System.assertEquals(customerContact.Id, CSAPController.getLead(lead.Id, lead.Email).Customer_Referral__c);
            if (lead.Application_Type__c == 'Residential') {
                System.assert(CSAPController.getContact(lead.Id, lead.Email).Id != null);
                System.assert(CSAPController.getAccount(lead.Id, lead.Email).Id != null);
                residentialLead = lead;
            }
            System.assert(true, CSAPController.hasAvailableCapacity(lead.Id));
        }

        //Try pulling credit report
        CSAPController.pullCreditStatus(residentialLead);
        //Check for qualified since Credit Score is 700
        System.assertEquals('Qualified', CSAPController.checkLeadCreditIfQualified(residentialLead.Id).sssCreditQualification);
        System.assertEquals(null, CSAPController.checkLeadCreditIfQualified(residentialLead.Id).srecProduct);
        System.assertEquals(smartProduct.Id, CSAPController.checkLeadCreditIfQualified(residentialLead.Id).smartProduct.Id);

        User apiUser = [SELECT Id, Name, Username
        FROM User
        WHERE Name = 'API'
        AND IsActive = True
        LIMIT 1];

        System.assertEquals('API', residentialLead.Parent_Account__r.Owner.Name);
        System.assertNotEquals('User Testing', residentialLead.Parent_Account__r.Owner.Name);
        System.assertEquals(apiUser.Id, residentialLead.OwnerId);

        //Check for un-qualified
        pcr.LASERCA__Credit_Score__c = '200';
        update pcr;
        System.assertEquals('Unqualified', CSAPController.checkLeadCreditIfQualified(residentialLead.Id).sssCreditQualification);

        Test.stopTest();
    }

    @isTest static void testDefaultReferral(){
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community Login User (Custom)'];
        Contact customerContact = [SELECT Id FROM Contact WHERE Lastname='Customer' LIMIT 1];
        Contact contactPartner = [SELECT Id FROM Contact WHERE Lastname = 'SWAIN' LIMIT 1];

        User userRecord = new User(
            FirstName = 'User',
            Lastname ='Testing',
            Alias = 'cswain',
            Email = 'tropicole34@aol.com',
            Emailencodingkey ='UTF-8',
            PortalRole = 'Manager',
            Languagelocalekey ='en_US',
            Localesidkey ='en_US',
            Profileid = profileRecord.Id,
            Country ='United States',
            IsActive = true,
            ContactId = contactPartner.Id,
            Timezonesidkey='America/Los_Angeles',
            Username='tropicole34@aol.com');
        Util.insertSObj(userRecord);

        Lead defaultLead = new Lead(FirstName = 'NoPartner',
            LastName = 'Testcase',
            Company = 'Test',
            Email = 'nopartner@tester.com',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Boston',
            LASERCA__Home_State__c = 'MA',
            LASERCA__Home_Zip__c = '02052',
            Parcel_Zip__c = '02052',
            LASERCA__Social_Security_Number__c = '000000001',
            Requested_Loan_Amount__c = 35000,
            Annual_Income_Currency__c = 15000,
            System_Assignment__c = 'Automatic - COD Date/Available Capacity',
            Status = 'Ready for Credit Check',
            Utility_1__c = 'Eversource',
            Electricity_Provider__c = 'Eversource');
        insert defaultLead;


        Test.startTest();

        CSAPController.upsertCSAPRecords(defaultLead, null, null, customerContact.Id );

        Test.stopTest();

        Partner__c defaultPartner = [ SELECT Id, Email__c, Default_Sales_Rep__c FROM Partner__c WHERE CS_Referral_Status__c = 'Default CS Partner' LIMIT 1];
        BSST__c defaultSalesRep = [ SELECT Id FROM BSST__c WHERE Id = :defaultPartner.Default_Sales_Rep__c];

        System.assertEquals(defaultPartner.Id, defaultLead.Partner_Lookup__c);
        System.assertEquals(defaultSalesRep.Id, defaultLead.Bs_Sales_ID__c);
        System.assertEquals(customerContact.Id, defaultLead.Customer_Referral__c);


    }

    @IsTest static void testSLPortalCSAPApplication() {
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community Login User (Custom)'];

        Partner__c partner = new Partner__c(
            Name = 'Solar Installer',
            Email__c = 'test@test.com');
        insert partner;

        BSST__c salesRep = new BSST__c(
            Name = 'Test Tester',
            Partner__c = partner.Id,
            Email__c = 'test@test.com');
        insert salesRep;

        Account account = new Account(
            Name = 'Solar Installer',
            State_Market__c = 'MA',
            Enable_CS_Application_in_Portal__c = true,
            Community_Solar_Application_Type__c = 'CSAP'
        );
        insert account;

        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Testcase',
            AccountId = account.Id,
            Partner_Lookup__c = partner.Id,
            Sales_Representative__c = salesRep.Id
        );
        insert contact;

        User otherUser = new User(
            FirstName = 'User',
            LastName ='Jordan',
            Alias = 'jUser132',
            Email = 'jpentaleri@aol.com',
            EmailEncodingKey ='UTF-8',
            PortalRole = 'Manager',
            LanguageLocaleKey ='en_US',
            LocaleSidKey ='en_US',
            ProfileId = profileRecord.Id,
            Country ='United States',
            IsActive = true,
            ContactId = contact.Id,
            TimeZoneSidKey='America/Los_Angeles',
            Username='jUser132@aol.com');
        Util.insertSObj(otherUser);

        Lead leadToInsert = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'];
        LASERCA__Personal_Credit_Report__c pcr = [SELECT LASERCA__Credit_Score__c FROM LASERCA__Personal_Credit_Report__c WHERE LASERCA__Lead__c = :leadToInsert.Id];
        Product2 smartProduct = [SELECT Id FROM Product2 WHERE Name = 'SMART Community Solar'];

        Test.startTest();
        System.runAs(otherUser) {
            CSAPController.upsertCSAPRecords(leadToInsert, null, null, '');
        }

        Lead lead = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'];
        //Check upserted Lead, Contact and Account records
        System.assertEquals(lead.Id, CSAPController.getLead(lead.Id, lead.Email).Id);
        // The lead's partner should be the same partner that is running the CSAP (not the default partner)
        System.assertEquals(partner.Id, CSAPController.getLead(lead.Id, lead.Email).Partner_Lookup__c);
        System.assert(CSAPController.getContact(lead.Id, lead.Email).Id != null);
        System.assert(CSAPController.getAccount(lead.Id, lead.Email).Id != null);

        System.assert(true, CSAPController.hasAvailableCapacity(lead.Id));

        //Try pulling credit report
        CSAPController.pullCreditStatus(lead);
        //Check for qualified since credit score is 700
        System.assertEquals('Qualified', CSAPController.checkLeadCreditIfQualified(lead.Id).sssCreditQualification);
        System.assertEquals(null, CSAPController.checkLeadCreditIfQualified(lead.Id).srecProduct);
        System.assertEquals(smartProduct.Id, CSAPController.checkLeadCreditIfQualified(lead.Id).smartProduct.Id);

        //Check not qualified
        pcr.LASERCA__Credit_Score__c = '200';
        update pcr;
        System.assertEquals('Unqualified', CSAPController.checkLeadCreditIfQualified(lead.Id).sssCreditQualification);

        Test.stopTest();
    }

    @IsTest static void creditCheckTimeout() {
        System.assertEquals(60000, CSAPController.getCreditCheckTimeout());
        System_Properties__c systemProperties = System_Properties__c.getAll().values()[0];
        systemProperties.Credit_Check_Timeout__c = 30000;
        update systemProperties;
        System.assertEquals(30000, CSAPController.getCreditCheckTimeout());
    }

    @IsTest
    static void testConversion() {
        User apiUser = [SELECT Id, Name, Username
                        FROM User
                        WHERE Name = 'API'
                        AND IsActive = True
                        LIMIT 1];

        Lead residentialLead = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c, Product_line__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id, Utility__c, Utility_1__c, Personal_Credit_Report__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'];
        residentialLead.Status = 'Qualified';
        residentialLead.OwnerId = apiUser.Id;
        update residentialLead;
        // Insert 10 other property accounts
        List<Utility_Account_Log__c> ualList = new List<Utility_Account_Log__c>();
        List<Lead> leadList = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            Lead nonResidentialLead = residentialLead.clone();
            nonResidentialLead.Id = null;
            nonResidentialLead.Application_Type__c = 'Non-Residential';
            CSAPController.processLead(nonResidentialLead);
            nonResidentialLead.OwnerId = apiUser.Id;
            leadList.add(nonResidentialLead);
        }
        insert leadList;
        for (Lead lead : leadList) {
            Utility_Account_Log__c ual = new Utility_Account_Log__c(
                Lead__c = lead.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'TBD');
            ualList.add(ual);
        }
        insert ualList;

        Test.startTest();
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        // There shouldn't be any opportunities yet, because nothing has been converted
        System.assertEquals(0, opps.size());

        CSAPController.convertCSLead(residentialLead.Id, residentialLead.Email);
        residentialLead = [
            SELECT Id, Email, IsConverted
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            AND Application_Type__c = 'Residential'
        ];
        // The lead in the testSetup is residential, and should be converted
        System.assertEquals(true, residentialLead.IsConverted);
        opps = [SELECT Id, OwnerId, Name FROM Opportunity];
        // And there should be 10 Non-Residential opps, plus the Residential opp after conversion
        System.assertEquals(11, opps.size());

        System.assertEquals(apiUser.Id, opps[0].OwnerId);

        Test.stopTest();
    }
}