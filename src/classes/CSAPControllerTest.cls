@IsTest
public with sharing class CSAPControllerTest {
    @TestSetup
    public static void setupTestData() {
        Test.startTest();
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
            Email__c = 'massRenewables@test.com');
        insert partner2;

        TestFactory.setDefaultCSPartner(partner2.Id);

        BSST__c salesRep2 = new BSST__c(
            Name = 'Dianne Martz',
            Partner__c = partner2.Id,
            Email__c = 'martz@testemail.com');
        insert salesRep2;

        partner2.Default_Sales_Rep__c = salesRep2.Id;
        update partner2;


        Contact contactRecord = new Contact(
            FirstName = 'User',
            LastName = 'Swain',
            AccountId = accountRecord.Id,
            RecordType = partnerRecordType,
            Partner_Lookup__c = partnerSetUpIds.get(0),
            Sales_Representative__c = partnerSetUpIds.get(1));
        insert contactRecord;

        Account customerAccount = new Account(Name = 'Customer Account', Client_Brand_Key__c = 'BluewaveLogo');
        insert customerAccount;

        Contact referralContact = new Contact( FirstName = 'Contact A',
            LastName = 'Customer',
            Account = customerAccount,
            Email = 'srenfro@bluewavesolar.com');
        insert referralContact;

        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{eversource, nationalGrid};

        Load_U__c everLZU = new Load_U__c (
            Name = '02052',
            LZ__c = 'SEMA',
            Town__c= 'Medfield'
        );
        Load_U__c canton = new Load_U__c (
            Name = '02021',
            LZ__c = 'NEMA/SEMA',
            Town__c= 'Canton'
        );
        insert new List<Load_U__c>{everLZU, canton};

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU.Id,
            Utility__c = eversource.Id
        );
        ZipCode_Utility_Junction__c junctionTwo = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = canton.Id,
            Utility__c = nationalGrid.Id
        );
        ZipCode_Utility_Junction__c junctionThree = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = canton.Id,
            Utility__c = eversource.Id
        );
        insert new List<ZipCode_Utility_Junction__c>{junction, junctionTwo, junctionThree};


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


        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
                                                                    Service_Territory__c = 'SEMA',
                                                                    Service_Territories__c = 'SEMA',
                                                                    Open__c = true,
                                                                    Reserved_Capacity_kW_DC__c = '10',
                                                                    Capacity_Committed_kW_DC__c = 0,
                                                                    Total_System_Size_kWh_DC__c = 1445.86,
                                                                    Total_System_Size_kW_AC__c  = 996,
                                                                    Utility__c = eversource.Id,
                                                                    Credit_Score_Requirement__c = 300,
                                                                    Assignment_Order__c = '1',
                                                                    Expected_Yield_kWh_kW__c = 1300,
                                                                    Assemblage_Count__c = 1,
                                                                    Sales_Partners__c = 'All',
                                                                    Product__c = smartProduct.Id,
                                                                    Maximum_Subscription_Assemblage__c = 25);
        insert sss1;
        Test.stopTest();
    }

    public static Lead getLeadForTest() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Mass Renewables' LIMIT 1];

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
            Partner_Lookup__c = partner.Id,
            System_Assignment__c = 'Automatic - COD Date/Available Capacity',
            Status = 'Ready for Credit Check',
            Electricity_Provider__c = 'Eversource',
            Application_Source_Phase_1__c = 'CSAP 2.1 with Partner'
        );
        return lead;
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

    @IsTest static void testEmailCSAPApplication() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c LIMIT 1];
        Contact contactPartner = [SELECT Id FROM Contact WHERE Lastname = 'SWAIN' LIMIT 1];
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community Login User (Custom)'];
        Contact referralContact = [SELECT Id FROM Contact WHERE Lastname='Customer' LIMIT 1];
        Utility__c eversource = [SELECT Id FROM Utility__c WHERE Name = 'Eversource' LIMIT 1];

        User currentUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        User userRecord;
        System.runAs(currentUser) {
            userRecord = new User(
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
        }

        Lead leadToInsert = getLeadForTest();

        Test.startTest();
        System.runAs(userRecord) {
            Lead insertedLead = CSAPController.upsertCSAPRecords(leadToInsert, partner.Id, salesRep.Id, referralContact.Id);

            // CSAPEnergyInfoController.addNewLead creates a new lead
            Lead additionalLead = new Lead(
                Application_Type__c = 'Non-Residential',
                Parcel_Zip__c = '02052',
                LASERCA__Home_Zip__c = '02052',
                Personal_Credit_Report__c = leadToInsert.Personal_Credit_Report__c,
                Parent_Account__c = leadToInsert.Parent_Account__c,
                Partner_Lookup__c = leadToInsert.Partner_Lookup__c,
                Customer_Referral__c = leadToInsert.Customer_Referral__c,
                bs_Sales_ID__c = leadToInsert.bs_Sales_ID__c,
                Email = leadToInsert.Email,
                FirstName = leadToInsert.FirstName,
                LastName = leadToInsert.LastName,
                MobilePhone = leadToInsert.MobilePhone,
                Phone = leadToInsert.Phone,
                LASERCA__Birthdate__c = leadToInsert.LASERCA__Birthdate__c,
                LASERCA__SSN__c = leadToInsert.LASERCA__SSN__c,
                Application_Source_Phase_1__c = 'CSAP 2.1 with Partner',
                Application_Source_Phase_2__c = 'CSAP Additional Property',
                Product_line__c = 'Community Solar',
                OwnerId = leadToInsert.OwnerId,
                Company = leadToInsert.FirstName + ' ' + leadToInsert.LastName
            );
            insertedLead = CSAPController.addAdditionalLead(additionalLead);
            // The CSAP looks at Load Zone and Utility to see if they're split, and they should get updated
            System.assertEquals('SEMA', insertedLead.LoadZone__c);
            System.assertEquals(eversource.Id, insertedLead.Utility_relationship__c);
        }

        List<Lead> leads = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id, OwnerId, Product_line__c, Application_Source_Phase_1__c,
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
            System.assertEquals(referralContact.Id, CSAPController.getLead(lead.Id, lead.Email).Customer_Referral__c);
            if (lead.Application_Type__c == 'Residential') {
                List<Contact> contactList = [
                    SELECT Id, FirstName, LastName, Email, Phone, AccountId, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, MobilePhone, Product_Line__c
                    FROM Contact
                    WHERE AccountId = :lead.Parent_Account__c
                    LIMIT 1
                ];
                List<Account> accountList = [
                    SELECT Id, Name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, BillingStreet, BillingCity, BillingState, BillingPostalCode, Social_Security_Number__c
                    FROM Account
                    WHERE Id = :lead.Parent_Account__c
                    LIMIT 1
                ];
                System.assertNotEquals(null, contactList[0].Id);
                System.assertNotEquals(null, accountList[0].Id);
                residentialLead = lead;
            }
            System.assert(CSAPController.hasAvailableCapacity(lead.Id),
                lead.Application_Type__c + 'Lead should have available capacity');
        }

        pullCreditForLead(residentialLead.Id);
        //Try pulling credit report
        CSAPController.pullCreditStatus(residentialLead);

        Product2 smartProduct = [SELECT Id FROM Product2 WHERE Name = 'SMART Community Solar'];

        //Check for qualified since Credit Score is 700
        System.assertEquals('Qualified', CSAPController.checkLeadCreditIfQualified(residentialLead.Id).sssCreditQualification);

        Boolean containsSmartProduct = false;
        Boolean containsNonSmartProduct = false;
        for (Product2 product : CSAPController.checkLeadCreditIfQualified(residentialLead.Id).productList){
            if (product.Id == smartProduct.Id) {
                containsSmartProduct = true;
            } else {
                containsNonSmartProduct = true;
            }
        }
        System.assertEquals(true, containsSmartProduct);
        System.assertEquals(false, containsNonSmartProduct);

        Group csInsideSales = [
            SELECT Id, Name
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'CS_Inside_Sales'
            LIMIT 1
        ];

        User apiUser = [SELECT Id, Name, Username
        FROM User
        WHERE Name = 'API'
        AND IsActive = True
        LIMIT 1];

        System.assertEquals('API', residentialLead.Parent_Account__r.Owner.Name);
        System.assertNotEquals('User Testing', residentialLead.Parent_Account__r.Owner.Name);
        System.assertEquals(csInsideSales.Id, residentialLead.OwnerId);

        //Check for un-qualified
        LASERCA__Personal_Credit_Report__c pcr = [SELECT LASERCA__Credit_Score__c FROM LASERCA__Personal_Credit_Report__c WHERE LASERCA__Lead__c = :leadToInsert.Id];
        pcr.LASERCA__Credit_Score__c = '200';
        update pcr;
        System.assertEquals('Unqualified', CSAPController.checkLeadCreditIfQualified(residentialLead.Id).sssCreditQualification);

        Test.stopTest();
    }

    @IsTest
    static void testSSNDefaultsInSandbox() {
        Lead residentialLead = getLeadForTest();
        insert residentialLead;

        CSAPController.pullCreditStatus(residentialLead);

        Lead leadAfterPull = [
            SELECT Id, LASERCA__SSN__c
            FROM Lead
            WHERE Id =: residentialLead.Id
            LIMIT 1
        ];

        Organization o = [SELECT IsSandbox FROM Organization LIMIT 1];

            System.assertEquals('000000001', leadAfterPull.LASERCA__SSN__c);
    }

    @IsTest
    static void testSSNDefaultsToPAssesForTestcases() {
        Lead residentialLead = getLeadForTest();
        residentialLead.LastName = 'testcase';
        insert residentialLead;

        CSAPController.pullCreditStatus(residentialLead);

        Lead leadAfterPull = [
            SELECT Id, LASERCA__SSN__c
            FROM Lead
            WHERE Id =: residentialLead.Id
            LIMIT 1
        ];

        System.assertEquals('000000001', leadAfterPull.LASERCA__SSN__c);
    }

    @IsTest
    static void testSSNDefaultsToFailForFailTestcases() {
        Lead residentialLead = getLeadForTest();
        residentialLead.LastName = 'testcase';
        residentialLead.FirstName = 'maxfrozen';
        insert residentialLead;

        CSAPController.pullCreditStatus(residentialLead);

        Lead leadAfterPull = [
            SELECT Id, LASERCA__SSN__c
            FROM Lead
            WHERE Id =: residentialLead.Id
            LIMIT 1
        ];

        System.assertEquals('000000010', leadAfterPull.LASERCA__SSN__c);
    }

    @IsTest
    static void testSSNDefaultsToFrozenForFrozenTestcases() {
        Lead residentialLead = getLeadForTest();
        residentialLead.LastName = 'testcase';
        residentialLead.FirstName = 'maxfail';
        insert residentialLead;

        CSAPController.pullCreditStatus(residentialLead);

        Lead leadAfterPull = [
            SELECT Id, LASERCA__SSN__c
            FROM Lead
            WHERE Id =: residentialLead.Id
            LIMIT 1
        ];

        System.assertEquals('000000008', leadAfterPull.LASERCA__SSN__c);
    }

    @isTest static void testDefaultReferral(){
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community Login User (Custom)'];
        Contact customerContact = [SELECT Id FROM Contact WHERE Lastname='Customer' LIMIT 1];
        Contact contactPartner = [SELECT Id FROM Contact WHERE Lastname = 'SWAIN' LIMIT 1];
        Utility__c eversource = [SELECT Id FROM Utility__c WHERE Name = 'Eversource' LIMIT 1];

        User currentUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        User userRecord;
        System.runAs(currentUser) {
            userRecord = new User(
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
        }

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
            Utility_relationship__c = eversource.Id,
            Electricity_Provider__c = 'Eversource');
//      Shouldn't be inserting the lead at this point, the lead gets inserted for the first time in upsertCSAPRecords
//      insert defaultLead;

        Test.startTest();

        CSAPController.upsertCSAPRecords(defaultLead, null, null, customerContact.Id );

        Test.stopTest();

        //system properties should have the partner that we set up in test data
        System_Properties__c sysProp = System_Properties__c.getAll().values()[0];
        Partner__c defaultPartner = [ SELECT Id, Email__c, Default_Sales_Rep__c FROM Partner__c WHERE Id = :sysProp.Default_CS_Partner__c];
        BSST__c defaultSalesRep = [ SELECT Id FROM BSST__c WHERE Id = :defaultPartner.Default_Sales_Rep__c];

        //Check to see if the lead was assigned to the default partner in System Properties
        System.assertEquals(defaultPartner.Id, defaultLead.Partner_Lookup__c);
        System.assertEquals(defaultSalesRep.Id, defaultLead.Bs_Sales_ID__c);
        System.assertEquals(customerContact.Id, defaultLead.Customer_Referral__c);


    }

    @isTest static void testcheckApplicationPartner() {
        Lead lead = getLeadForTest();
        insert lead;

        Lead checkLead = [
            SELECT Id, Partner_Lookup__r.Id
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
        LIMIT 1 ];

        Test.startTest();
        Boolean partnerApp = CSAPController.checkApplicationPartner(checkLead.Partner_Lookup__r.Id);
        System.assertEquals(true, partnerApp);
        Test.stopTest();

    }

    @IsTest static void testgetCSApplicationURL() {
        Test.startTest();
        String url = CSAPController.getCSApplicationURL();

        String[] checkURL = url.split('=');
        String partnerId = checkURL[1];

        Partner__c checkPartner = [SELECT Id, Name FROM Partner__c WHERE Id = :partnerId LIMIT 1];

        System.assertEquals('Mass Renewables', checkPartner.Name);

        Test.stopTest();
    }

    @IsTest
    public static void testSaveTerms() {
        Lead residentialLead = getLeadForTest();

        List<Task> allTasks = [SELECT Id FROM Task WHERE WhoId = :residentialLead.Id];
        Integer numTasks = allTasks.size();

        String terms = 'Testing Exact Language for Customer Payment Terms Consent';
        String termsType = 'Payment Terms';

        Test.startTest();

        CSAPController.saveTerms(terms, residentialLead, termsType);

        List<Task> checkTasks = [SELECT Id, Subject FROM Task WHERE WhoId = :residentialLead.Id];
        System.assertEquals(numTasks + 1, checkTasks.size());

        Test.stopTest();
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

        partner.Default_Sales_Rep__c = salesRep.Id;
        update partner;

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

        Lead leadToInsert = getLeadForTest();

        Product2 smartProduct = [SELECT Id FROM Product2 WHERE Name = 'SMART Community Solar'];

        Test.startTest();
        System.runAs(otherUser) {
            CSAPController.upsertCSAPRecords(leadToInsert, partner.Id, null, '');
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

        List<Contact> contactList = [
            SELECT Id, FirstName, LastName, Email, Phone, AccountId, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, MobilePhone, Product_Line__c
            FROM Contact
            WHERE AccountId = :lead.Parent_Account__c
            LIMIT 1
        ];
        List<Account> accountList = [
            SELECT Id, Name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, BillingStreet, BillingCity, BillingState, BillingPostalCode, Social_Security_Number__c
            FROM Account
            WHERE Id = :lead.Parent_Account__c
            LIMIT 1
        ];
        System.assertNotEquals(null, contactList[0].Id);
        System.assertNotEquals(null, accountList[0].Id);

        System.assert(CSAPController.hasAvailableCapacity(lead.Id),
            lead.Application_Type__c + 'Lead should have available capacity');

        pullCreditForLead(lead.Id);
        //Try pulling credit report
        CSAPController.pullCreditStatus(lead);
        //Check for qualified since credit score is 700
        System.assertEquals('Qualified', CSAPController.checkLeadCreditIfQualified(lead.Id).sssCreditQualification);

        Boolean containsSmartProduct = false;
        Boolean containsNonSmartProduct = false;
        for (Product2 product : CSAPController.checkLeadCreditIfQualified(lead.Id).productList){
            if (product.Id == smartProduct.Id) {
                containsSmartProduct = true;
            } else {
                containsNonSmartProduct = true;
            }
        }
        System.assertEquals(true, containsSmartProduct);
        System.assertEquals(false, containsNonSmartProduct);

        LASERCA__Personal_Credit_Report__c pcr = [SELECT LASERCA__Credit_Score__c FROM LASERCA__Personal_Credit_Report__c WHERE LASERCA__Lead__c = :leadToInsert.Id];
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

        Product2 smartProduct = [
            SELECT Id
            FROM Product2
            WHERE IsActive = TRUE
            AND Program__c = 'SMART - Community Solar'
            LIMIT 1
        ];

        Lead residentialLead = getLeadForTest();

        residentialLead.Status = 'Qualified';
        residentialLead.OwnerId = apiUser.Id;
        residentialLead.Product__c = smartProduct.Id;
        insert residentialLead;

        pullCreditForLead(residentialLead.Id);

        residentialLead = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c, Product_line__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id, Utility_relationship__c, Personal_Credit_Report__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            LIMIT 1
        ];
        // Insert 2 other property accounts
        List<Utility_Account_Log__c> ualList = new List<Utility_Account_Log__c>();

        ualList.add(new Utility_Account_Log__c(
            Lead__c = residentialLead.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Tester Testcase'
        ));

        List<ChargentOrders__ChargentOrder__c> orderList = new List<ChargentOrders__ChargentOrder__c>();
        List<Lead> leadList = new List<Lead>();
        for (Integer i = 0; i < 2; i++) {
            Lead nonResidentialLead = residentialLead.clone();
            nonResidentialLead.Id = null;
            nonResidentialLead.Application_Type__c = 'Non-Residential';
            nonResidentialLead.Application_Source_Phase_1__c = 'CSAP 2.1 with Partner';
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

            ChargentOrders__ChargentOrder__c chOrder = new ChargentOrders__ChargentOrder__c(

            );
            orderList.add(chOrder);
        }
        insert ualList;

        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        // There shouldn't be any opportunities yet, because nothing has been converted
        System.assertEquals(0, opps.size());

        Test.startTest();
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
        // And there should be 2 Non-Residential opps, plus the Residential opp after conversion
        System.assertEquals(3, opps.size());

        System.assertEquals(apiUser.Id, opps[0].OwnerId);

        Test.stopTest();
    }

    @IsTest static void testCreditCheckReturnsResultIfNoCreditScore() {
        Lead leadToInsert = getLeadForTest();
        insert leadToInsert;

        Test.startTest();

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = leadToInsert.Id,
            LASERCA__Credit_Score__c = null,
            LASERCA__Credit_Score_TransUnion__c = null
        );
        insert pcr;

        LASERCA__Credit_Report_Log__c crLog = new LASERCA__Credit_Report_Log__c(
            LASERCA__Lead__c = leadToInsert.Id,
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Status__c = 'Completed'
        );
        insert crLog;


        CSAPController.SSSResult result = CSAPController.checkLeadCreditIfQualified(leadToInsert.Id);

        LASERCA__Personal_Credit_Report__c checkPCR = [
            SELECT Id, LASERCA__Credit_Score__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE Id = :pcr.Id
            LIMIT 1
        ];

        Lead checkLead = [
            SELECT Id
            FROM Lead
            WHERE Id = :leadToInsert.Id
            LIMIT 1
        ];

        //No PCR will still be marked as qualified but with a credit score of 9999
        System.assertEquals('Qualified', result.sssCreditQualification);
        System.assertEquals('9999', checkPCR.LASERCA__Credit_Score__c);

        //Lead should be qualified for a Project with a Product
        System.assertNotEquals(null, result.ProductList);

        Test.stopTest();

    }

    @IsTest static void testSplitZone() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c LIMIT 1];
        Contact contactPartner = [SELECT Id FROM Contact WHERE Lastname = 'SWAIN' LIMIT 1];
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community Login User (Custom)'];
        Contact customerContact = [SELECT Id FROM Contact WHERE Lastname='Customer' LIMIT 1];
        Utility__c eversource = [SELECT Id FROM Utility__c WHERE Name = 'Eversource' LIMIT 1];

        List<Product2> smartProducts = [
            SELECT Id
            FROM Product2
            WHERE IsActive = TRUE
            AND Program__c = 'SMART - Community Solar'
        ];
        User currentUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        User userRecord;
        System.runAs(currentUser) {
            userRecord = new User(
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
        }

        Lead lead = getLeadForTest();
        CSAPController.upsertCSAPRecords(lead, null, null, '');
        // Original lead should be found in SEMA
        System.assertEquals('SEMA', lead.LoadZone__c);

        // Set zip to a split zip code, canton
        lead.Id = null;
        lead.LASERCA__Home_Zip__c = '02021';
        lead.Parcel_Zip__c = '02021';
        lead.LoadZone__c = null;
        lead.Utility_relationship__c = null;
        lead.Product__c = smartProducts[0].Id;
        Test.startTest();
        System.runAs(userRecord) {
            CSAPController.upsertCSAPRecords(lead, partner.Id, salesRep.Id, customerContact.Id);
        }

        lead = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c, LASER_Credit_Score__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id, LoadZone__c, Product_line__c, Utility_relationship__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c, Customer_Referral__c,
                Zipcode__r.LZ__c, Zipcode__r.Utility_Junction_Count__c , Confirm_Utility__c, Continue_Application_Link__c
            FROM Lead
            WHERE Id = :lead.Id];

        // If in 02021, the lead should be found in NEMA/SEMA and National Grid/Eversource
        System.assertEquals('NEMA/SEMA', lead.Zipcode__r.LZ__c);
        System.assertEquals(2, lead.Zipcode__r.Utility_Junction_Count__c);
        System.assertEquals('NEMA/SEMA', lead.LoadZone__c);
        System.assertEquals(null, lead.Utility_relationship__c);
        System.assertNotEquals(null, lead.Confirm_Utility__c);

        // Check Load Zone (01Qj0000000EZU9) wfr sets lead status
        System.assertEquals('Load Zone Check Needed', lead.Status);
        System.assert(lead.Continue_Application_Link__c.contains('apply'),'Application Link should contain Apply');
        System.assert(lead.Continue_Application_Link__c.contains(lead.Id),'Application Link should contain Lead Id');

        System.runAs(userRecord) {
            lead.LoadZone__c = 'SEMA';
            lead.Utility_relationship__c = eversource.Id;
            CSAPController.unsplitLead(lead);
            System.assertEquals('Eversource', CSAPController.getUtility(eversource.Id).Name);
        }

        System.assert(CSAPController.hasAvailableCapacity(lead.Id),
            'Lead that were in a split zone should have available capacity');

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

        //Check for qualified since Credit Score is 700
        System.assertEquals('Qualified', CSAPController.checkLeadCreditIfQualified(lead.Id).sssCreditQualification);
        // CSAPCreditCheckHandler sets lead status to Qualified, if the lead is qualified
        lead.Status = 'Qualified';
        update lead;

        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        // There shouldn't be any opportunities yet, because nothing has been converted
        System.assertEquals(0, opps.size());
        CSAPController.convertCSLead(lead.Id, lead.Email);
        lead = [
            SELECT Id, Email, IsConverted
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assert(lead.IsConverted, 'Split zone lead didn\'t convert');
        opps = [SELECT Id, OwnerId, Name FROM Opportunity];
        System.assertEquals(1, opps.size());
        Test.stopTest();
    }

    @IsTest static void testSplitZoneUnqualified() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c LIMIT 1];
        Contact contactPartner = [SELECT Id FROM Contact WHERE Lastname = 'SWAIN' LIMIT 1];
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community Login User (Custom)'];
        Contact customerContact = [SELECT Id FROM Contact WHERE Lastname='Customer' LIMIT 1];
        Utility__c nationalGrid = [SELECT Id FROM Utility__c WHERE Name = 'National Grid' LIMIT 1];

        List<Product2> smartProducts = [
            SELECT Id
            FROM Product2
            WHERE IsActive = TRUE
            AND Program__c = 'SMART - Community Solar'
        ];

        User currentUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        User userRecord;
        System.runAs(currentUser) {
            userRecord = new User(
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
        }

        Lead lead = getLeadForTest();
        CSAPController.upsertCSAPRecords(lead, null, null, '');
        // Original lead should be found in SEMA
        System.assertEquals('SEMA', lead.LoadZone__c);

        // Set zip to a split zip code, canton
        lead.Id = null;
        lead.LASERCA__Home_Zip__c =' 02021';
        lead.Parcel_Zip__c = '02021';
        lead.LoadZone__c = null;
        lead.Utility_relationship__c = null;
        lead.Status = 'Qualified';
        Test.startTest();
        System.runAs(userRecord) {
            CSAPController.upsertCSAPRecords(lead, partner.Id, salesRep.Id, customerContact.Id);
        }

        lead = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c, LASER_Credit_Score__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id, LoadZone__c, Product_line__c, Utility_relationship__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c, Customer_Referral__c,
                Zipcode__r.LZ__c, Zipcode__r.Utility_Junction_Count__c
            FROM Lead
            WHERE Id = :lead.Id];

        // If in 02021, the lead should be found in NEMA/SEMA and National Grid/Eversource
        System.assertEquals('NEMA/SEMA', lead.Zipcode__r.LZ__c);
        System.assertEquals(2, lead.Zipcode__r.Utility_Junction_Count__c);
        // Check Load Zone (01Qj0000000EZU9) wfr sets lead status
        System.assertEquals('Load Zone Check Needed', lead.Status);

        System.runAs(userRecord) {
            lead.LoadZone__c = 'NEMA';
            lead.Utility_relationship__c = nationalGrid.Id;
            CSAPController.unsplitLead(lead);
        }

        System.assert(!CSAPController.hasAvailableCapacity(lead.Id),
            'Lead that were in a split zone shouldn\'t have available capacity');

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

        //Check for unqualified since there's no SSS in this test servicing NEMA/NGrid
        System.assertEquals('Unqualified', CSAPController.checkLeadCreditIfQualified(lead.Id).sssCreditQualification);
        // CSAPCreditCheckHandler sets lead status to Unqualified
        lead.Status = 'Unqualified';
        update lead;

        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        // There shouldn't be any opportunities yet, because nothing has been converted
        System.assertEquals(0, opps.size());
        CSAPController.convertCSLead(lead.Id, lead.Email);
        lead = [
            SELECT Id, Email, IsConverted
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assert(!lead.IsConverted, 'Should not have converted an unqualified lead');
        opps = [SELECT Id, OwnerId, Name FROM Opportunity];
        System.assertEquals(0, opps.size(), 'Should not have made opportunities for an unqualified lead');
        Test.stopTest();
    }

    @IsTest static void testInsertChargentOrderOnLeadAsPartner() {
        Lead residentialLead = getLeadForTest();
        insert residentialLead;
        ChargentBase__Gateway__c chGateway = new ChargentBase__Gateway__c(
            Name = 'Chargent Gateway',
            ChargentBase__Active__c = true,
            ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
            ChargentBase__Available_Payment_Methods__c = 'eCheck;Credit Card',
            ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck'
        );
        insert chGateway;

        Entity__c defaultEntity = new Entity__c(
            Name = 'BWC Holdings, LLC',
            Gateway__c = chGateway.Id
        );
        insert defaultEntity;

        ChargentOrders__ChargentOrder__c newACHOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Payment_Method__c = 'ACH',
            ChargentOrders__Bank_Name__c = 'Test Bank',
            ChargentOrders__Bank_Routing_Number__c = '123456789',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Bank_Account_Number__c = '1234567890',
            ChargentOrders__Bank_Account_Name__c = 'Testy McTesterson',
            ChargentOrders__Billing_Email__c = residentialLead.Email,
            ChargentOrders__Card_Type__c = '',
            ChargentOrders__Card_Number__c = '',
            ChargentOrders__Card_Expiration_Month__c = '',
            ChargentOrders__Card_Expiration_Year__c = '',
            ChargentOrders__Billing_Address__c = '',
            ChargentOrders__Billing_City__c = '',
            ChargentOrders__Billing_State__c = '',
            ChargentOrders__Billing_Zip_Postal__c = '',
            ChargentOrders__Billing_First_Name__c = '',
            ChargentOrders__Billing_Last_Name__c = '',
            Autopay_Only__c = true
        );

        ChargentOrders__ChargentOrder__c newCreditCardOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Bank_Name__c = '',
            ChargentOrders__Bank_Routing_Number__c = '',
            ChargentOrders__Bank_Account_Type__c = '',
            ChargentOrders__Bank_Account_Number__c = '',
            ChargentOrders__Bank_Account_Name__c = '',
            ChargentOrders__Billing_Email__c = residentialLead.Email,
            ChargentOrders__Card_Type__c = 'VISA',
            ChargentOrders__Card_Number__c = '1234123412341234',
            ChargentOrders__Card_Expiration_Month__c = '01',
            ChargentOrders__Card_Expiration_Year__c = '12',
            ChargentOrders__Billing_Address__c = '',
            ChargentOrders__Billing_City__c = '',
            ChargentOrders__Billing_State__c = '',
            ChargentOrders__Billing_Zip_Postal__c = '12345',
            ChargentOrders__Billing_First_Name__c = 'Testy',
            ChargentOrders__Billing_Last_Name__c = 'McTesterson',
            Autopay_Only__c = true
        );
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


        Test.startTest();
        System.runAs(userRecord) {
            CSAPController.insertChargentOrderOnLead(newACHOrder, residentialLead);
            CSAPController.insertChargentOrderOnLead(newCreditCardOrder, residentialLead);
        }
        Test.stopTest();

        List<ChargentOrders__ChargentOrder__c> newOrders = [
            SELECT Id, Lead__c, Entity__c, ChargentOrders__Gateway__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Lead__c = : residentialLead.Id
        ];

        System.assertEquals(2, newOrders.size());
        System.assertEquals(defaultEntity.Id, newOrders[0].Entity__c);
        System.assertEquals(defaultEntity.Gateway__c, newOrders[0].ChargentOrders__Gateway__c);
        System.assertEquals(defaultEntity.Id, newOrders[1].Entity__c);
        System.assertEquals(defaultEntity.Gateway__c, newOrders[1].ChargentOrders__Gateway__c);
    }

    @IsTest static void testInsertChargentOrderOnLeadAsGuestUser() {
        Lead residentialLead = getLeadForTest();
        insert residentialLead;
        ChargentBase__Gateway__c chGateway = new ChargentBase__Gateway__c(
            Name = 'Chargent Gateway',
            ChargentBase__Active__c = true,
            ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
            ChargentBase__Available_Payment_Methods__c = 'eCheck;Credit Card',
            ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck'
        );
        insert chGateway;

        Entity__c defaultEntity = new Entity__c(
            Name = 'BWC Holdings, LLC',
            Gateway__c = chGateway.Id
        );
        insert defaultEntity;

        ChargentOrders__ChargentOrder__c newACHOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Payment_Method__c = 'ACH',
            ChargentOrders__Bank_Name__c = 'Test Bank',
            ChargentOrders__Bank_Routing_Number__c = '123456789',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Bank_Account_Number__c = '1234567890',
            ChargentOrders__Bank_Account_Name__c = 'Testy McTesterson',
            ChargentOrders__Billing_Email__c = residentialLead.Email,
            ChargentOrders__Card_Type__c = '',
            ChargentOrders__Card_Number__c = '',
            ChargentOrders__Card_Expiration_Month__c = '',
            ChargentOrders__Card_Expiration_Year__c = '',
            ChargentOrders__Billing_Address__c = '',
            ChargentOrders__Billing_City__c = '',
            ChargentOrders__Billing_State__c = '',
            ChargentOrders__Billing_Zip_Postal__c = '',
            ChargentOrders__Billing_First_Name__c = '',
            ChargentOrders__Billing_Last_Name__c = '',
            Autopay_Only__c = true
        );

        ChargentOrders__ChargentOrder__c newCreditCardOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Bank_Name__c = '',
            ChargentOrders__Bank_Routing_Number__c = '',
            ChargentOrders__Bank_Account_Type__c = '',
            ChargentOrders__Bank_Account_Number__c = '',
            ChargentOrders__Bank_Account_Name__c = '',
            ChargentOrders__Billing_Email__c = residentialLead.Email,
            ChargentOrders__Card_Type__c = 'VISA',
            ChargentOrders__Card_Number__c = '1234123412341234',
            ChargentOrders__Card_Expiration_Month__c = '01',
            ChargentOrders__Card_Expiration_Year__c = '12',
            ChargentOrders__Billing_Address__c = '',
            ChargentOrders__Billing_City__c = '',
            ChargentOrders__Billing_State__c = '',
            ChargentOrders__Billing_Zip_Postal__c = '12345',
            ChargentOrders__Billing_First_Name__c = 'Testy',
            ChargentOrders__Billing_Last_Name__c = 'McTesterson',
            Autopay_Only__c = true
        );
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Apply Profile'];

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
            Timezonesidkey='America/Los_Angeles',
            Username='tropicole34@aol.com');
        Util.insertSObj(userRecord);


        Test.startTest();
        System.runAs(userRecord) {
            CSAPController.insertChargentOrderOnLead(newACHOrder, residentialLead);
            CSAPController.insertChargentOrderOnLead(newCreditCardOrder, residentialLead);
        }
        Test.stopTest();

        List<ChargentOrders__ChargentOrder__c> newOrders = [
            SELECT Id, Lead__c, Entity__c, ChargentOrders__Gateway__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Lead__c = : residentialLead.Id
        ];

        System.assertEquals(2, newOrders.size());
        System.assertEquals(defaultEntity.Id, newOrders[0].Entity__c);
        System.assertEquals(defaultEntity.Gateway__c, newOrders[0].ChargentOrders__Gateway__c);
        System.assertEquals(defaultEntity.Id, newOrders[1].Entity__c);
        System.assertEquals(defaultEntity.Gateway__c, newOrders[1].ChargentOrders__Gateway__c);
    }
    @IsTest
    public static void testHasCapacity() {
        System.assertEquals(true, CSAPController.hasCapacity('02052'));
        System.assertEquals(false, CSAPController.hasCapacity('874321'), 'Zipcode is too long');
        System.assertEquals(false, CSAPController.hasCapacity('02115'), 'Zipcode is not in load zone');
        System.assertEquals(false, CSAPController.hasCapacity('015'), 'Zipcode is too short');
    }

    @IsTest
    public static void testSendEmailForPaymentInfo() {
        Lead residentialLead = getLeadForTest();
        insert residentialLead;

        // iSSuccess is dependant on the deliverability setting and those cannot be access from apex
        // So here, we're testing that we can call the method, not the result
        Boolean isSuccess = CSAPController.sendEmailForPaymentInfo(residentialLead);

        System.assertNotEquals(null, isSuccess);

        Organization o = [SELECT IsSandbox FROM Organization LIMIT 1];
        if (!o.IsSandbox) {
            System.assert(isSuccess, 'failed email send in Prod, deliverability may be off');
        }

        residentialLead = [
            SELECT Id, CSAP_Stage__c
            FROM Lead
            WHERE id = :residentialLead.Id
            LIMIT 1
        ];

        System.assertEquals('NAV_Energy_Information', residentialLead.CSAP_Stage__c);
    }

    @IsTest
    public static void testLeadAttachmentsMovedToUAL() {
        Lead residentialLead = getLeadForTest();
        insert residentialLead;

        Attachment bill = new Attachment(
            Name = 'file.pdf',
            Body = Blob.valueOf('body'),
            ParentId = residentialLead.Id,
            Description = 'Electric Bill'
        );
        Attachment notBill = new Attachment(
            Name = 'file.pdf',
            Body = Blob.valueOf('body'),
            ParentId = residentialLead.Id,
            Description = 'Other Document'
        );

        insert new List<Attachment>{bill, notBill};

        Utility_Account_Log__c utilityAccountLog = new Utility_Account_Log__c(
            Name = 'testLeadAttachmentsMovedToUAL',
            Lead__c = residentialLead.Id
        );

        CSAPController.saveUtilityAccountLog(utilityAccountLog);

        Utility_Account_Log__c ual = [
            SELECT Id, Lead__c
            FROM Utility_Account_Log__c
            WHERE Name = 'testLeadAttachmentsMovedToUAL'
        ];

        List<Attachment> leadAttachments = [
            SELECT Name, Description
            FROM Attachment
            WHERE ParentId = : ual.Lead__c
        ];

        List<Attachment> ualAttachments = [
            SELECT Name, Description
            FROM Attachment
            WHERE ParentId = : ual.Id
        ];

        System.assertEquals(1, leadAttachments.size());
        System.assertEquals('Other Document', leadAttachments[0].Description);
        System.assertEquals(1, ualAttachments.size());
        System.assertEquals('Electric Bill', ualAttachments[0].Description);
    }

    @IsTest
    public static void testGetRateClass() {
        Utility__c eversource = [
            SELECT Id
            FROM Utility__c
            WHERE Name = 'Eversource'
        ];

        Utility__c nationalGrid = [
            SELECT Id
            FROM Utility__c
            WHERE Name = 'National Grid'
        ];

        List<Rate_Class__c> rateClasses = new List<Rate_Class__c>();
        for (Integer i = 0; i < 10; i++) {
            rateClasses.add(new Rate_Class__c(
                Name = 'Eversource Rate Class ' + i,
                Utility__c = eversource.Id
            ));
            rateClasses.add(new Rate_Class__c(
                Name = 'National Grid Rate Class ' + i,
                Utility__c = nationalGrid.Id
            ));
        }
        insert rateClasses;

        List<Rate_Class__c> queriedRateClasses = CSAPController.getRateClassesForUtility(eversource.Id);

        System.assertEquals(10, queriedRateClasses.size());
        System.assertEquals(eversource.Id, queriedRateClasses[0].Utility__c);
    }

    @IsTest
    public static void testZipcodeNotFoundLoadZone() {
        Lead residentialLead = getLeadForTest();
        residentialLead.Parcel_Zip__c = '12345';
        residentialLead.LASERCA__Home_Zip__c = '12345';

        insert residentialLead;

        System.assertEquals(false, CSAPController.hasAvailableCapacity(residentialLead.Id));
    }

    @IsTest
    public static void testZuoraPaymentPageEnabled() {
        System.assertEquals(false, CSAPController.zuoraPaymentPageEnabled());

        System_Properties__c systemProperty = System_Properties__c.getAll().values()[0];
        systemProperty.Use_Zuora_for_Payment_Capture__c = true;
        update systemProperty;

        System.assertEquals(true, CSAPController.zuoraPaymentPageEnabled());
    }
}