/**
 * Created by PeterYao on 4/30/2019.
 */
@SuppressWarnings('PMD.AvoidHardcodingId')
@IsTest
public with sharing class ZuoraAccountServiceTest {
    public static void useMocks() {
        ZuoraAccountService.accountSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new MockAccountsSelector());
    }
    @TestSetup
    public static void setupTestData() {
        Test.startTest();
        List<String> partnerSetUpIds = partnerSetup();
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='API Only'];

        List<User> apiUsers = [
            SELECT Id, Name, Username
            FROM User
            WHERE Name = 'API'
            AND IsActive = TRUE
        ];
        if (apiUsers.isEmpty()) {
            User apiUser = new User(
                FirstName = 'API',
                LastName = 'API',
                ProfileId = profileRecord.Id,
                Alias = '123api',
                Email = 'api@bluewavesolar.com',
                EmailEncodingKey = 'UTF-8',
                PortalRole = 'Manager',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Country = 'United States',
                IsActive = true,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'api123@bluewavesolar.com');
            Util.insertSObj(apiUser);
        }

        RecordType partnerRecordType = [SELECT Id FROM RecordType WHERE Name = 'Partner Contact'];

        Account accountRecord = new Account(
            Name = 'BlueWave Customer Care',
            State_Market__c = 'MA',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        insert accountRecord;

        Account accountRecord2 = new Account(
            Name = 'Mass Renewables',
            State_Market__c = 'MA',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        insert accountRecord2;

        Partner__c partner2 = new Partner__c(
            Name = 'Mass Renewables',
            Email__c = 'massRenewables@test.com',
            Account__c = accountRecord2.Id);
        insert partner2;
        accountRecord2.Partner__c = partner2.Id;
        update accountRecord2;

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
                                                                    Pending_Small_CS_Capacity__c = 10,
                                                                    Capacity_Committed_kW_DC__c = 0,
                                                                    Total_System_Size_kWh_DC__c = 1445.86,
                                                                    Total_System_Size_kW_AC__c  = 996,
                                                                    Utility__c = eversource.Id,
                                                                    Credit_Score_Requirement__c = 300,
                                                                    Assignment_Order__c = '1',
                                                                    Expected_Yield_kWh_kW__c = 1300,
                                                                    Assemblage_Count__c = 1,
                                                                    Product__c = smartProduct.Id,
                                                                    Maximum_Subscription_Capacity_kWDC__c = 25,
                                                                    Available_SMB_Underwriting_Method_FICO__c = true);
        insert sss1;

        insert SharedSolarSystemsTest.getPartnerEligibilities(
            new List<Shared_Solar_System__c>{sss1}, [SELECT Id, Name FROM Account WHERE RecordType.Name = 'Partner Account']
        );

        Test.stopTest();
    }

    private static List<String> partnerSetup() {
        List<String> partnerSetupList = new List<String>();
        Account partnerAccount = new Account(
            Name = 'Bluewave Inside Sales',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        insert partnerAccount;
        Partner__c partner = new Partner__c(
            Name = 'Bluewave Inside Sales',
            Account__c = partnerAccount.Id
        );
        insert partner;
        partnerAccount.Partner__c = partner.Id;
        update partnerAccount;
        partnerSetupList.add(partner.Id);

        BSST__c salesRep = new BSST__c(Name = 'BlueWave User', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@Sales.com');
        insert salesRep;
        partnerSetupList.add(salesRep.Id);

        BSST__c salesRepExec = new BSST__c(Name = 'BlueWave Executive', Partner__c = partner.Id, Custom_ID__c = 'exec', Email__c = 'executive@Sales.com');
        insert salesRepExec;
        partnerSetupList.add(salesRepExec.Id);

        return partnerSetupList;
    }


    public static Lead getLeadForTest() {
        Partner__c partner = [SELECT Id, Account__c FROM Partner__c WHERE Name = 'Mass Renewables' LIMIT 1];

        Utility__c eversource = [SELECT Id FROM Utility__C where Name = 'Eversource' LIMIT 1 ];

        Lead lead = new Lead(
            FirstName = 'Tester',
            LastName = 'Testcase',
            Company = 'Test',
            Email = 'testymctesterson@tester.com',
            Utility_relationship__c = eversource.Id,
            Application_Type__c = 'Residential',
            Product_line__c = 'Community Solar',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Boston',
            LASERCA__Home_State__c = 'MA',
            LASERCA__Home_Zip__c = '02052',
            Parcel_Zip__c = '02052',
            LoadZone__c = 'SEMA',
            LeadSource = 'Switch',
            Partner_Lookup__c = partner.Id,
            Partner_Account__c = partner.Account__c,
            System_Assignment__c = 'Automatic - Assignment Order',
            Status = 'Sales Qualified'
        );
        return lead;
    }

    private static Account getPropAcctForTest(Id leadId) {
        
        Account account = new Account(
            Lead__c = leadId,
            Name = 'Prop Account',
            Product_Line__c = 'Community Solar',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId(),
            BillingStreet = '123 Main St',
            BillingCity = 'Boston',
            BillingState = 'New York',
            BillingPostalCode = '12122',
            Zuora_Payment_Ref_Id__c = '12345678901234567890123456789012',
            Zuora_Payment_Ref_Id_Expiration_Date__c = Datetime.now()+1
        );
        
        return account;
    }

    public static void pullCreditForLead(Id leadId) {
        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = leadId,
            LASERCA__Credit_Score__c = '700'
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
    @IsTest
    static void testZuoraAccountCreationOnConvert() {
        User apiUser = [
            SELECT Id, Name, Username
            FROM User
            WHERE Name = 'API'
            AND IsActive = TRUE
            LIMIT 1
        ];

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
        residentialLead.Zuora_Payment_Ref_Id__c = '12345678901234567890123456789012';
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

        Account propAccount = getPropAcctForTest(residentialLead.Id);
        insert propAccount;

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = residentialLead.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Tester Testcase'
        );
        insert ual;

        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        // There shouldn't be any opportunities yet, because nothing has been converted
        System.assertEquals(0, opps.size());

        Test.startTest();
        ZuoraAccountService.createAccounts(new Set<Id>{residentialLead.Id});
        List<Id> leadIdList = new List<Id>();
        leadIdList.add(residentialLead.Id);
        convertLead(leadIdList);
        Test.stopTest();

        residentialLead = [
            SELECT Id, Email, IsConverted, ConvertedAccountId
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            AND Application_Type__c = 'Residential'
        ];

        
        
        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{propAccount.Id});
        
        System.assertEquals(true, residentialLead.IsConverted,'The lead in the testSetup is residential, and should be converted');
        opps = [SELECT Id, OwnerId, Name FROM Opportunity];
        System.assertEquals(1, opps.size());
        // The account and contact should now have a zuora Id
        System.assertEquals(1, propertyAccounts.size());
        System.assertEquals(ZuoraAPIMock.genericId, propertyAccounts[0].Zuora_Id__c);
        // There should be a Zuora Contact record under the Salesforce Contact
        List<Zuora_Contact__c> zuoraContacts = [
            SELECT Id, Zuora_Id__c
            FROM Zuora_Contact__c
            WHERE Contact__c = :propertyAccounts[0].Send_Bills_Contact__c
        ];
        System.assertEquals(1, zuoraContacts.size());
        System.assertEquals(ZuoraAPIMock.genericId, zuoraContacts[0].Zuora_Id__c);
    }

    @IsTest
    static void testZuoraAccountCreationSwitchLead() {
        User apiUser = [
            SELECT Id, Name, Username
            FROM User
            WHERE Name = 'API'
            AND IsActive = TRUE
            LIMIT 1
        ];

        Product2 smartProduct = [
            SELECT Id
            FROM Product2
            WHERE IsActive = TRUE
            AND Program__c = 'SMART - Community Solar'
            LIMIT 1
        ];
        Lead residentialLead = getLeadForTest();

        residentialLead.Status = 'Qualified';
        residentialLead.LeadSource = 'Switch';
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
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id, Utility_relationship__c, Utility_relationship__r.Id, Personal_Credit_Report__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            LIMIT 1
        ];

        LeadService leadService = new LeadService();
        Account propertyAccount = leadService.buildPropertyAccountFromLegacyLead(residentialLead);
        propertyAccount.Zuora_Payment_Ref_Id__c = '12345678901234567890123456789012';
        insert propertyAccount;

        Utility_Account_Log__c ual = leadService.buildUtilityAccountLogFromLegacyLead(residentialLead, propertyAccount);
        insert ual;

        Test.startTest();
            ZuoraAccountService.createAccounts(new Set<Id>{residentialLead.Id});
        Test.stopTest();

        residentialLead = [
            SELECT Id, Email, IsConverted, ConvertedAccountId
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            AND Application_Type__c = 'Residential'
        ];

        propertyAccount = [
            SELECT Id, Zuora_Payment_Ref_Id__c, Zuora_Id__c
            FROM Account
            WHERE Lead__c = :residentialLead.Id
        ];

        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{propertyAccount.Id});

        // The account and contact should now have a zuora Id
        System.assertEquals(1, propertyAccounts.size());
        System.assertEquals(ZuoraAPIMock.genericId, propertyAccounts[0].Zuora_Id__c);
        // There should be a Zuora Contact record under the Salesforce Contact
        List<Zuora_Contact__c> zuoraContacts = [
            SELECT Id, Zuora_Id__c, Contact__c
            FROM Zuora_Contact__c
        ];
        System.assertEquals(1, zuoraContacts.size());
        System.assertEquals(ZuoraAPIMock.genericId, zuoraContacts[0].Zuora_Id__c);

    }

    @IsTest
    static void testZuoraAccountCreationIssue() {
        User apiUser = [
            SELECT Id, Name, Username
            FROM User
            WHERE Name = 'API'
            AND IsActive = TRUE
            LIMIT 1
        ];

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
        residentialLead.Zuora_Payment_Ref_Id__c = '12345678901234567890123456789012';
        insert residentialLead;

        pullCreditForLead(residentialLead.Id);

        Account propAccount = getPropAcctForTest(residentialLead.Id);
        insert propAccount;

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
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = residentialLead.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Tester Testcase'
        );
        insert ual;

        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        // There shouldn't be any opportunities yet, because nothing has been converted
        System.assertEquals(0, opps.size());

        Test.startTest();
        List<Id> leadIdList = new List<Id>();
        leadIdList.add(residentialLead.Id);
        convertLead(leadIdList);
        residentialLead = [
            SELECT Id, Email, IsConverted, ConvertedAccountId
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            AND Application_Type__c = 'Residential'
        ];
        // This should cause the queueable job to fail with a SOQL issue when it's run
        delete residentialLead;
        Test.stopTest();

        opps = [SELECT Id, OwnerId, Name, Account.Zuora_Id__c FROM Opportunity];
        System.assertEquals(1, opps.size());
        // The account and contact should now have a zuora Id
        System.assertEquals(null, opps[0].Account.Zuora_Id__c);
        List<Error_Log__c> errorLogs = [
            SELECT Id, Class__c, Message__c
            FROM Error_Log__c
        ];

        Boolean errorLogFound = false;
        for (Error_Log__c err : errorLogs) {
            if (err.Message__c.contains('Found no property accounts to create for these lead Ids:')) {
                // Because we deleted the lead
                errorLogFound = true;
            }
        }
        System.assertEquals(true, errorLogFound, 'Error log not constructed for deleted Lead scenario');
    }

    @IsTest
    static void testZuoraAccountCreationWithoutRefId() {
        User apiUser = [
            SELECT Id, Name, Username
            FROM User
            WHERE Name = 'API'
            AND IsActive = TRUE
            LIMIT 1
        ];

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
        residentialLead.Zuora_Payment_Ref_Id__c = '12345678901234567890123456789012';
        residentialLead.Zuora_Payment_Ref_Id_Expiration_Date__c = Datetime.now()-1; // Ref Id expired yesterday
        insert residentialLead;

        pullCreditForLead(residentialLead.Id);

        Account propAccount = getPropAcctForTest(residentialLead.Id);
        insert propAccount;

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
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = residentialLead.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Tester Testcase'
        );
        insert ual;

        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        // There shouldn't be any opportunities yet, because nothing has been converted
        System.assertEquals(0, opps.size());

        Test.startTest();
        List<Id> leadIdList = new List<Id>();
        leadIdList.add(residentialLead.Id);
        convertLead(leadIdList);
        Test.stopTest();

        residentialLead = [
            SELECT Id, Email, IsConverted, ConvertedAccountId
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            AND Application_Type__c = 'Residential'
        ];
        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{residentialLead.ConvertedAccountId});
        // The lead in the testSetup is residential, and should be converted
        System.assertEquals(true, residentialLead.IsConverted);
        opps = [SELECT Id, OwnerId, Name FROM Opportunity];
        System.assertEquals(1, opps.size());
        // The account and contact should now have a zuora Id
        System.assertEquals(1, propertyAccounts.size());
        System.assertEquals(ZuoraAPIMock.genericId, propertyAccounts[0].Zuora_Id__c);
        // There should be a Zuora Contact record under the Salesforce Contact
        List<Zuora_Contact__c> zuoraContacts = [
            SELECT Id, Zuora_Id__c
            FROM Zuora_Contact__c
            WHERE Contact__c = :propertyAccounts[0].Send_Bills_Contact__c
        ];
        System.assertEquals(1, zuoraContacts.size());
        System.assertEquals(ZuoraAPIMock.genericId, zuoraContacts[0].Zuora_Id__c);
        List<Error_Log__c> errorLogs = [
            SELECT Id, Class__c, Message__c
            FROM Error_Log__c
        ];
        System.assert(errorLogs.size() > 1, 'Should be at least one error log');
        String message = '';
        for (Error_Log__c errorLog : errorLogs) {
            message += errorLog.Message__c;
        }
        // Because we didn't include the refId, one of the error logs should report the error
        System.assert(message.contains('Found an expired payment method '));
    }

    @IsTest
    static void testZuoraAccountCreationWithException() {
        User apiUser = [
            SELECT Id, Name, Username
            FROM User
            WHERE Name = 'API'
            AND IsActive = TRUE
            LIMIT 1
        ];

        Product2 smartProduct = [
            SELECT Id
            FROM Product2
            WHERE IsActive = TRUE
            AND Program__c = 'SMART - Community Solar'
            LIMIT 1
        ];

        Lead residentialLead = getLeadForTest();
        residentialLead.Company = 'ThrowException';
        residentialLead.Status = 'Qualified';
        residentialLead.OwnerId = apiUser.Id;
        residentialLead.Product__c = smartProduct.Id;
        residentialLead.Zuora_Payment_Ref_Id__c = '12345678901234567890123456789012';
        residentialLead.Zuora_Payment_Ref_Id_Expiration_Date__c = Datetime.now()+1; // Ref Id good until tomorrow
        insert residentialLead;

        Account propAccount = getPropAcctForTest(residentialLead.Id);
        insert propAccount;

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
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = residentialLead.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Tester Testcase'
        );
        insert ual;

        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        System.assertEquals(0, opps.size(),'There shouldn\'t be any opportunities yet, because nothing has been converted');

        Test.startTest();
        List<Id> convertedLeadIds = new List<Id>();
        convertedLeadIds.add(residentialLead.Id);
        // Lead conversion queues the ZuoraAccountAsyncService via CSSubscriptionEnroller.enroll()
        convertLead(new List<Id>{residentialLead.Id});
        // And in this test we want force a callout to fail, which the ZuoraAPIMock does when it sees "ThrowException" in
        // the body of the request
        List<Lead> convertedLeads = LeadSelector.selectConvertedByIds(convertedLeadIds);
        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{convertedLeads[0].ConvertedAccountId});
        // So we force the account name to have that string, before stopTest(), which executes the ZuoraAccountAsyncService queueable
        propertyAccounts[0].Name = 'ThrowException';
        update propertyAccounts[0];
        Test.stopTest();

        residentialLead = [
            SELECT Id, Email, IsConverted, ConvertedAccountId
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            AND Application_Type__c = 'Residential'
        ];
        System.assertEquals(true, residentialLead.IsConverted,'The lead in the testSetup is residential, and should be converted');
        opps = [SELECT Id, OwnerId, Name FROM Opportunity];
        System.assertEquals(1, opps.size());
        // But since the callout failed, the property account shouldn't have a zuora id:
        System.assertEquals(1, propertyAccounts.size());
        System.assertEquals(null, propertyAccounts[0].Zuora_Id__c);
        // And we should have logged an error
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size(),
            'There should be an one error log when async account creation fails, but got ' + errorLogs);
        String expectedErrorMessage = 'Zuora account async CREATE operation failed for lead';
        System.assert(errorLogs[0].Message__c.contains(expectedErrorMessage),
            'Expected ' + expectedErrorMessage + ' but got: ' + errorLogs[0].Message__c);
    }

    @IsTest
    public static void testContactEmailNotObfuscated() {
        String actualEmail = 'pyao@bluewavesolar.com';
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Test',
            Email = actualEmail
        );
        insert contact;

        Account propertyAccount = new Account(
            Name = 'Property',
            Send_Bills_Contact__c = contact.Id,
            Zuora_Id__c = '12345'
        );
        insert propertyAccount;

        Map<Id, String> accountIdToZuoraIdMap = new Map<Id, String>();
        accountIdToZuoraIdMap.put(propertyAccount.Id, propertyAccount.Zuora_Id__c);

        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{
            propertyAccount.Id
        });
        ZuoraAccountService.createContact(propertyAccounts, accountIdToZuoraIdMap);
        // There should be one list of logs for ZuoraAPIHelper, Fine
        System.assertEquals(1, Logger.logs.values().size());
        // There should be one log in that list of logs
        System.assertEquals(1, Logger.logs.values()[0].size());
        // It should have pyao@bluewavesolar.com in it
        System.assert(Logger.logs.values()[0][0].message.contains(actualEmail));
    }

    @IsTest
    public static void testNoSendBillsContact() {
        Account propertyAccount = new Account(
            Name = 'Property',
            Zuora_Id__c = '12345',
            BillingCity = 'Boston',
            BillingState = 'Massachusetts',
            BillingCountry = 'United States'
        );
        insert propertyAccount;

        Map<Id, String> accountIdToZuoraIdMap = new Map<Id, String>();
        accountIdToZuoraIdMap.put(propertyAccount.Id, propertyAccount.Zuora_Id__c);

        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{
            propertyAccount.Id
        });
        ZuoraAccountService.createContact(propertyAccounts, accountIdToZuoraIdMap);
        System.assertEquals(1, Logger.logs.values().size(),
            'There should be one list of logs for ZuoraAPIHelper, Fine');
        System.assertEquals(1, Logger.logs.values()[0].size(),
            'There should be one log in the list of logs for ZuoraAPIHelper, Fine');
        System.assert(Logger.logs.values()[0][0].message.contains('"Success":true'),
            'Expected contact creation to be successful, even if there is no send bills contact');
        System.assert(Logger.logs.values()[0][0].message.contains('"LastName":"Billing Contact","FirstName":"Default"'),
            'Expected to create a Default Billing Contact if no send bills contact');
        System.assert(Logger.logs.values()[0][0].message.contains('"City":"Boston"') &&
            Logger.logs.values()[0][0].message.contains('"State":"Massachusetts"') &&
            Logger.logs.values()[0][0].message.contains('"Country":"United States"'),
            'Expected to set the address for the default contact');
    }

    @IsTest
    private static void testHandleAccountUpdates() {
        Account account = [SELECT Id, Name, Address_Attn__c FROM Account LIMIT 1];
        account.Zuora_Id__c = '123455';
        account.Name = account.Name + ' Changed';
        account.Address_Attn__c = account.Address_Attn__c + ' Changed';
        Test.startTest();
        update account;
        Test.stopTest();

        Boolean foundContactCreate = false;
        Boolean foundBillToUpdate = false;
        Boolean foundNameUpdate = false;
        for (ZuoraAPIHelper.EndpointCall endpointCall : ZuoraAPIHelper.endpointsCalled) {
            if (endpointCall.endpoint == '/v1/action/create' && endpointCall.jsonBody.contains('\"type\":\"Contact\"')) {
                foundContactCreate = true;
            } else if (endpointCall.endpoint == '/v1/action/update' && endpointCall.jsonBody.contains('\"type\":\"Account\"')) {
                if (endpointCall.jsonBody.contains('BillTo')) {
                    foundBillToUpdate = true;
                } else if (endpointCall.jsonBody.contains('Name')) {
                    foundNameUpdate = true;
                }
            }
        }
        System.assert(foundBillToUpdate, 'Did not find the account updated with the Bill To');
        System.assert(foundNameUpdate, 'Did not find the account update for the Name');
        System.assert(foundContactCreate, 'Did not find a contact create');
    }

    @IsTest
    private static void testHandleAccountNameUpdatesFuture() {
        useMocks();
        Test.startTest();
        ZuoraAccountService.handleAccountNameUpdates(new Set<Id>{'001S000000yKIYqIAO'});
        Test.stopTest();
        System.assertEquals(1, ZuoraAPIHelper.endpointsCalled.size());
        System.assert(ZuoraAPIHelper.endpointsCalled[0].jsonBody.contains('\"type\":\"Account\"'));
        System.assertEquals('/v1/action/update', ZuoraAPIHelper.endpointsCalled[0].endpoint);
    }

    @IsTest
    private static void testHandleAccountAddressUpdatesFuture() {
        useMocks();
        Test.startTest();
        ZuoraAccountService.handleAccountAddressUpdatesFuture(new Set<Id>{'001S000000yKIYqIAO'});
        Test.stopTest();
        System.assertEquals(2, ZuoraAPIHelper.endpointsCalled.size());
        System.assertEquals('/v1/action/create', ZuoraAPIHelper.endpointsCalled[0].endpoint);
        System.assert(ZuoraAPIHelper.endpointsCalled[0].jsonBody.contains('\"type\":\"Contact\"'),
            'First endpoint should create a contact');
        System.assertEquals('/v1/action/update', ZuoraAPIHelper.endpointsCalled[1].endpoint);
        System.assert(ZuoraAPIHelper.endpointsCalled[1].jsonBody.contains('\"type\":\"Account\"'),
            'Second endpoint should update the account with the contact as Bill To');
    }

    @IsTest
    private static void testAccountsWithZuoraUpdates() {
        String json = '{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001S000000yKIYqIAO"},' +
            '"Id":"001S000000yKIYqIAO",' +
            '"Name":"Keith Morgan",' +
            '"BillingStreet":"8888 Main Street",' +
            '"BillingCity":"Boston",' +
            '"BillingState":"Massachusetts",' +
            '"BillingStateCode":"MA",' +
            '"BillingPostalCode":"12312",' +
            '"BillingCountry":"United States",' +
            '"Send_Bills_Contact__c":"003S0000016Y23tIAC"}';
        Account oldAccount = (Account) System.JSON.deserialize(json, Account.class);
        Account newAccount = oldAccount.clone(true);
        newAccount.Name = oldAccount.Name + ' Changed';
        Map<Id, Account> oldAccounts = new Map<Id, Account>();
        Map<Id, Account> newAccounts = new Map<Id, Account>();
        oldAccounts.put(oldAccount.Id, oldAccount);
        newAccounts.put(newAccount.Id, newAccount);
        System.assertEquals(false, new ZuoraAccountService().accountsWithZuoraUpdates(oldAccounts, newAccounts).hasChanges(),
            'No changes expected because accounts have no zuora id'
        );
        oldAccount.Zuora_Id__c = '123455';
        newAccount.Zuora_Id__c = '123455';
        System.assertEquals(true, new ZuoraAccountService().accountsWithZuoraUpdates(oldAccounts, newAccounts).hasChanges());


    }

    @IsTest
    private static void testAccountNeedsAddressUpdate() {
        String json = '{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001S000000yKIYqIAO"},' +
            '"Id":"001S000000yKIYqIAO",' +
            '"Name":"Keith Morgan",' +
            '"BillingStreet":"8888 Main Street",' +
            '"BillingCity":"Boston",' +
            '"BillingState":"Massachusetts",' +
            '"BillingStateCode":"MA",' +
            '"BillingPostalCode":"12312",' +
            '"BillingCountry":"United States",' +
            '"Send_Bills_Contact__c":"003S0000016Y23tIAC"}';
        Account oldAccount = (Account) System.JSON.deserialize(json, Account.class);
        Account newAccount = oldAccount.clone(true);
        newAccount.BillingCity = 'Somerville';
        System.assertEquals(false, new ZuoraAccountService().accountNeedsAddressUpdate(oldAccount, newAccount),
            'Expected no change necessary because there is no Zuora Id'
        );
        newAccount.Zuora_Id__c = '123456';
        System.assertEquals(true, new ZuoraAccountService().accountNeedsAddressUpdate(oldAccount, newAccount),
            'Expected to need to update Zuora'
        );
        newAccount.BillingCity = oldAccount.BillingCity;
        System.assertNotEquals(null, newAccount.Zuora_Id__c, 'Zuora Id is still set');
        System.assertEquals(false, new ZuoraAccountService().accountNeedsAddressUpdate(oldAccount, newAccount),
            'Expected no change necessary because addresses are the same'
        );
        newAccount.Name = oldAccount.Name + ' Changed';
        System.assertEquals(false, new ZuoraAccountService().accountNeedsAddressUpdate(oldAccount, newAccount),
            'Expected no change necessary because there is no address change'
        );
    }

    public static void convertLead(List<Id> leadIdsToConvert) {
        Lead leadToConvert = new LeadSelector().selectOne(leadIdsToConvert[0]);
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setLeadId(leadToConvert.Id);
        leadConvert.setConvertedStatus('Qualified');
        leadConvert.setDoNotCreateOpportunity(true);
        leadConverts.add(leadConvert);
        Database.convertLead(leadConverts, false);
    }

    /*************
      *** MOCKS ***
      *************/
    public class MockAccountsSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectAll' {
                    String json = '[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001S000000yKIYqIAO"},' +
                        '"Id":"001S000000yKIYqIAO",' +
                        '"Name":"Keith Morgan",' +
                        '"BillingStreet":"8888 Main Street",' +
                        '"BillingCity":"Boston",' +
                        '"BillingState":"Massachusetts",' +
                        '"BillingStateCode":"MA",' +
                        '"BillingPostalCode":"12312",' +
                        '"BillingCountry":"United States",' +
                        '"Send_Bills_Contact__c":"003S0000016Y23tIAC",' +
                        '"Zuora_Id__c":"2c92c0f86e5e38b0016e5fc9f13d15fb",' +
                        '"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/003S0000016Y23tIAC"},' +
                        '"Id":"003S0000016Y23tIAC",' +
                        '"Email":"bulk@bluewavesolar.com.disabledagain",' +
                        '"FirstName":"Keith",' +
                        '"LastName":"Morgan"}}]';
                    List<Account> accounts = (List<Account>) System.JSON.deserialize(json, List<Account>.class);
                    return accounts;
                }
            }
            return null;
        }
    }
}