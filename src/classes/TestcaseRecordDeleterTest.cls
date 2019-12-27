/**
 * Created by abarnes on 7/30/2018.
 */

@IsTest
public class TestcaseRecordDeleterTest {
    @TestSetup public static void setupData() {
        Loan_Data__c capitalPool = new Loan_Data__c(Name = 'Revolving Credit Line',
            Total_Capital__c = 10000000,
            Investor__c = 'The Bank',
            Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

        Loan_Traunch__c loanTranchePending = new Loan_Traunch__c(
            Name = 'Tranche Assignment Pending',
            Tranche_Type__c = 'Holding',
            Stage__c = 'Closed',
            Loan_Data__c = capitalPool.id);
        insert loanTranchePending;

        Product2 srecProduct = new Product2( Name = 'Market Price - $10 Fee',
            Family = 'Solar Loan',
            Product_Type__c = 'SREC',
            State__c = 'MA',
            ProductCode = 'SREC-2',
            SREC_Fee_Fixed_Rate__c = 10,
            IsActive = True);
        insert srecProduct;

        Partner__c partner = new Partner__c(Name = 'Installer Co');
        insert partner;

        BSST__c salesRep = new BSST__c(Name = 'Joe Bob', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@Sales.com');
        insert salesRep;

        ChargentBase__Gateway__c chGateway  =
            new ChargentBase__Gateway__c(   Name = 'SREC',
                ChargentBase__Merchant_ID__c = '235986',
                ChargentBase__Available_Payment_Methods__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
                ChargentBase__Active__c = True);
        insert chGateway;

        /* Only one Chargent Order to avoid error: No more than one executeBatch can be called from within a test method.
        Please make sure the iterable returned from your start method matches the batch size, resulting in one executeBatch invocation */
        ChargentOrders__ChargentOrder__c alreadyReady = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Bank_Account_Number__c = '00000000000',
            ChargentOrders__Bank_Routing_Number__c = '123456789',
            ChargentOrders__Bank_Account_Name__c = 'Jordan Test',
            ChargentOrders__Bank_Name__c = 'Originally Set to Ready',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Payment_Method__c = 'Check',
            ChargentOrders__Gateway__c = chGateway.Id,
            ChargentOrders__Credit_Amount__c = 0.03,
            SREC_Status__c = 'Ready');
        ChargentOrders__ChargentOrder__c orderOne = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Bank_Account_Number__c = '00000000000',
            ChargentOrders__Bank_Routing_Number__c = '123456789',
            ChargentOrders__Bank_Account_Name__c = 'Jordan Test',
            ChargentOrders__Bank_Name__c = 'Bank of Bank',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Payment_Method__c = 'Check',
            ChargentOrders__Gateway__c = chGateway.Id,
            ChargentOrders__Credit_Amount__c = 0,
            SREC_Status__c = '');
        ChargentOrders__ChargentOrder__c orderTwo = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Bank_Account_Number__c = '00000000000',
            ChargentOrders__Bank_Routing_Number__c = '123456789',
            ChargentOrders__Bank_Account_Name__c = 'Jordan Test',
            ChargentOrders__Bank_Name__c = 'Bank of Bank',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Payment_Method__c = 'Check',
            ChargentOrders__Gateway__c = chGateway.Id,
            ChargentOrders__Credit_Amount__c = 0,
            SREC_Status__c = '');
        ChargentOrders__ChargentOrder__c orderThree = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Bank_Account_Number__c = '00000000000',
            ChargentOrders__Bank_Routing_Number__c = '123456789',
            ChargentOrders__Bank_Account_Name__c = 'Jordan Test',
            ChargentOrders__Bank_Name__c = 'Bank of Bank',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Payment_Method__c = 'Check',
            ChargentOrders__Gateway__c = chGateway.Id,
            ChargentOrders__Credit_Amount__c = 0,
            SREC_Status__c = '');
        insert new List<ChargentOrders__ChargentOrder__c>{alreadyReady, orderOne, orderTwo, orderThree};

        Lead leadOne = new Lead (   FirstName = 'One',
            LastName = 'Testcase',
            Company = 'Company one');
        Lead leadTwo = new Lead (   FirstName = 'Two',
            LastName = 'Testcase',
            Company = 'Company two');
        Lead leadThree = new Lead ( FirstName = 'Three',
            LastName = 'Testcase',
            Company = 'Company three');
        insert new List<Lead>{leadOne, leadTwo, leadThree};

        Account accountOne = new Account(Name = 'AccountOne');
        Account accountTwo = new Account(Name = 'AccountTwo');
        Account accountThree = new Account(Name = 'AccountThree');
        insert new List<Account>{accountOne, accountTwo, accountThree};

        Opportunity oppOne = new Opportunity (  Name = 'OppOne',
            AccountId = accountOne.Id,
            Email__c = 'jpentaleri@bluewavesolar.com',
            SREC_Product__c = srecProduct.Id,
            StageName = 'Complete',
            CloseDate = Date.today().addYears(-1));
        Opportunity oppTwo = new Opportunity (  Name = 'OppTwo',
            AccountId = accountTwo.Id,
            Email__c = 'jpentaleri@bluewavesolar.com',
            SREC_Product__c = srecProduct.Id,
            StageName = 'Complete',
            CloseDate = Date.today().addYears(-1));
        Opportunity oppThree = new Opportunity (  Name = 'OppThree',
            AccountId = accountThree.Id,
            Email__c = 'jpentaleri@bluewavesolar.com',
            SREC_Product__c = srecProduct.Id,
            StageName = 'Complete',
            CloseDate = Date.today().addYears(-1));
        insert new List<Opportunity>{oppOne, oppTwo, oppThree};

        Loan__c loanOne = new Loan__c ( Name = 'Jordan Persist',
            Requested_Loan_Amount__c = 23000.00,
            Lead__c = leadOne.Id,
            Partner__c = partner.Id,
            Sales_Agent__c = salesRep.Id,
            Number_of_Days_Past_Due__c = 0,
            Opportunity__c = oppOne.Id,
            CreatedDate = Date.today().addYears(-1),
            SREC_Direct_Deposit_Order__c = orderOne.Id,
            Loan_Tranche__c = loanTranchePending.Id);
        Loan__c loanTwo = new Loan__c ( Name = 'Jordan Testcase',
            Requested_Loan_Amount__c = 23000.00,
            Lead__c = leadTwo.Id,
            Partner__c = partner.Id,
            Sales_Agent__c = salesRep.Id,
            Number_of_Days_Past_Due__c = 0,
            Opportunity__c = oppTwo.Id,
            CreatedDate = Date.today().addYears(-1),
            SREC_Direct_Deposit_Order__c = orderTwo.Id,
            Loan_Tranche__c = loanTranchePending.Id);
        Loan__c loanThree = new Loan__c (Name = 'Jordan Testcase',
            Requested_Loan_Amount__c = 23000.00,
            Lead__c = leadThree.Id,
            Partner__c = partner.Id,
            Sales_Agent__c = salesRep.Id,
            Number_of_Days_Past_Due__c = 0,
            Opportunity__c = oppThree.Id,
            SREC_Direct_Deposit_Order__c = orderThree.Id,
            Loan_Tranche__c = loanTranchePending.Id);
        insert new List<Loan__c>{loanOne, loanTwo, loanThree};

        LASERCA__Personal_Credit_Report__c pcrOne = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = leadOne.Id,
            LASERCA__Credit_Score_TransUnion__c = '700'
        );
        LASERCA__Personal_Credit_Report__c pcrTwo = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = leadTwo.Id,
            LASERCA__Credit_Score_TransUnion__c = '700',
            CreatedDate = System.today().addDays(-30)
        );
        LASERCA__Personal_Credit_Report__c pcrThree = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = leadThree.Id,
            LASERCA__Credit_Score_TransUnion__c = '700'
        );
        insert new List<LASERCA__Personal_Credit_Report__c>{
            pcrOne, pcrTwo, pcrThree
        };

        Date twoWeeksAgo = System.today().addDays(-30);

        Residential_Equipment__c resiEquipOne = new Residential_Equipment__c(
            Name = 'Testcase Residential Equipment 1',
            Loan__c = loanOne.Id,
            CreatedDate = twoWeeksAgo);
        Residential_Equipment__c resiEquipTwo = new Residential_Equipment__c(
            Name = 'Testcase Residential Equipment 2',
            Loan__c = loanTwo.Id);
        Residential_Equipment__c resiEquipThree = new Residential_Equipment__c(
            Name = 'Persist Residential Equipment 3',
            Loan__c = loanThree.Id);
        insert new List<Residential_Equipment__c>{resiEquipOne, resiEquipTwo, resiEquipThree};

        Date mintDate = Date.newInstance(2018, 6, 6);

        SREC__c srecOne = new SREC__c(  Name = 'SREC one',
            Residential_Equipment__c = resiEquipOne.Id,
            Minted_Date__c = mintDate);
        SREC__c srecTwo = new SREC__c(  Name = 'SREC two',
            Residential_Equipment__c = resiEquipTwo.Id,
            Minted_Date__c = mintDate);
        SREC__c srecThree = new SREC__c(  Name = 'SREC three',
            Residential_Equipment__c = resiEquipThree.Id,
            Minted_Date__c = mintDate);
        insert new List<SREC__c>{srecOne, srecTwo, srecThree};

        SREC_Invoice__c invoice = new SREC_Invoice__c(  Name = 'SREC Invoice #1',
            SREC__c = srecThree.Id,
            Residential_Equipment__c = resiEquipThree.Id);
        insert invoice;

        alreadyReady.SREC_Invoice__c = invoice.Id;
        update alreadyReady;
    }

    @IsTest static void testLeadTestcaseDeletion() {
        List<Lead> testLeads = new List<Lead>();
        for(Integer i = 0; i<5; i++){
            Lead testLead = new Lead (FirstName = 'NewLead' + i,
                LastName = 'Testcase',
                Company = 'CompanyOther',
                Email = 'NewTestEmail' + i + '@bluewavesolar.com',
                Status = 'Qualified');
            testLeads.add(testLead);
        }
        for(Integer i = 0; i<5; i++){
            Lead testLead = new Lead (FirstName = 'NewLead' + i,
                LastName = 'Persist',
                Company = 'CompanyOther',
                Email = 'NewPersistEmail' + i + '@bluewavesolar.com',
                Status = 'Qualified');
            testLeads.add(testLead);
        }

//      The following set of 5 Leads are the only ones that should be deleted
        for(Integer i = 0; i<5; i++){
            Date dateTwoWeeksAgo = System.today().addDays(-30);
            Lead testLead = new Lead (FirstName = 'OldLead' + i,
                LastName = 'Testcase',
                Company = 'CompanyOther',
                Email = 'OldTestEmail' + i + '@bluewavesolar.com',
                CreatedDate = dateTwoWeeksAgo,
                Status = 'Qualified');
            testLeads.add(testLead);
        }
        for(Integer i = 0; i<5; i++){
            Date dateTwoWeeksAgo = System.today().addDays(-30);
            Lead testLead = new Lead (FirstName = 'OldLead' + i,
                LastName = 'Persist',
                Company = 'CompanyOther',
                Email = 'OldPersistEmail' + i + '@bluewavesolar.com',
                CreatedDate = dateTwoWeeksAgo,
                Status = 'Qualified');
            testLeads.add(testLead);
        }
        insert testLeads;

        List<Lead> preTaskLeadList = [SELECT Id FROM Lead];
        System.assertEquals(23, preTaskLeadList.size());

        Test.startTest();
        TestcaseRecordDeleter deleteRecords = new TestcaseRecordDeleter();
        deleteRecords.deleteTestcaseRecords();

//      The task should only delete the 5 of the 20 leads.
        List<Lead> postTaskLeadList = [SELECT Id FROM Lead];
        System.assertEquals(18, postTaskLeadList.size());

        deleteRecords.deleteAll = true;
        deleteRecords.deleteTestcaseRecords();

//      The task should delete 5 more of the leads.
        postTaskLeadList = [SELECT Id FROM Lead];
        System.assertEquals(10, postTaskLeadList.size());

        Test.stopTest();
    }

    @IsTest static void testContactTestcaseDeletion() {
        Partner__c partner1 = new Partner__c(Name = 'Bluewave Inside Sales');
        insert partner1;

        Partner__c partner2 = new Partner__c(Name = 'Solar Market Sales');
        insert partner2;

        List<Contact> testContacts = new List<Contact>();
        for(Integer i = 0; i<5; i++){
            Contact testContact = new Contact (FirstName = 'NewContact' + i,
                LastName = 'Testcase',
                Partner_Lookup__c = partner1.Id,
                Email = 'NewTestEmail' + i + '@bluewavesolar.com');
            testContacts.add(testContact);
        }

        for(Integer i = 0; i<5; i++){
            Contact testContact = new Contact (FirstName = 'NewContact' + i,
                LastName = 'Testcase',
                Partner_Lookup__c = partner2.Id,
                Email = 'NewTestEmail' + i + '@bluewavesolar.com');
            testContacts.add(testContact);
        }

        for(Integer i = 0; i<5; i++){
            Contact testContact = new Contact (FirstName = 'NewContact' + i,
                LastName = 'Persist',
                Email = 'NewPersistEmail' + i + '@bluewavesolar.com');
            testContacts.add(testContact);
        }

//      The following set of 5 Leads are the only ones that should be deleted
        for(Integer i = 0; i<5; i++){
            Date dateTwoWeeksAgo = System.today().addDays(-30);
            Contact testContact = new Contact (FirstName = 'OldContact' + i,
                LastName = 'Testcase',
                Partner_Lookup__c = partner2.Id,
                Email = 'OldTestEmail' + i + '@bluewavesolar.com',
                CreatedDate = dateTwoWeeksAgo);
            testContacts.add(testContact);
        }

        for(Integer i = 0; i<5; i++){
            Date dateTwoWeeksAgo = System.today().addDays(-30);
            Contact testContact = new Contact (FirstName = 'OldContact' + i,
                LastName = 'Testcase',
                Partner_Lookup__c = partner1.Id,
                Email = 'OldTestEmail' + i + '@bluewavesolar.com',
                CreatedDate = dateTwoWeeksAgo);
            testContacts.add(testContact);
        }

        for(Integer i = 0; i<5; i++){
            Date dateTwoWeeksAgo = System.today().addDays(-30);
            Contact testContact = new Contact (FirstName = 'OldContact' + i,
                LastName = 'Persist',
                Email = 'OldPersistEmail' + i + '@bluewavesolar.com',
                CreatedDate = dateTwoWeeksAgo);
            testContacts.add(testContact);
        }
        insert testContacts;

        List<Contact> preTaskContactList = [SELECT Id FROM Contact];
        System.assertEquals(30, preTaskContactList.size());

        Test.startTest();
        TestcaseRecordDeleter deleteRecords = new TestcaseRecordDeleter();
        deleteRecords.deleteTestcaseRecords();

//      The task should only delete the 5 of the 20 leads.
        List<Contact> postTaskContactList = [SELECT Id FROM Contact];
        System.assertEquals(25, postTaskContactList.size());

        deleteRecords.deleteAll = true;
        deleteRecords.deleteTestcaseRecords();
        postTaskContactList = [SELECT Id FROM Contact];
        System.assertEquals(20, postTaskContactList.size());
        Test.stopTest();
    }

    @isTest static void testOpportunityTestcaseDeletion() {
        List<Opportunity> testOpportunities = new List<Opportunity>();
        Date today = System.today();
        for(Integer i = 0; i<5; i++){
            Opportunity testOpportunity = new Opportunity (Name = 'NewContact' + i + ' Testcase',
                CloseDate = today,
                StageName = 'New');
            testOpportunities.add(testOpportunity);
        }

        for(Integer i = 0; i<5; i++){
            Opportunity testOpportunity = new Opportunity (Name = 'NewContact' + i + ' Persist',
                CloseDate = today,
                StageName = 'New');
            testOpportunities.add(testOpportunity);
        }

//      The following set of 5 Leads are the only ones that should be deleted
        Date dateTwoWeeksAgo = System.today().addDays(-30);
        for(Integer i = 0; i<5; i++){
            Opportunity testOpportunity = new Opportunity (Name = 'NewContact' + i + ' Testcase',
                CloseDate = dateTwoWeeksAgo,
                StageName = 'New');
            testOpportunities.add(testOpportunity);
        }

        for(Integer i = 0; i<5; i++){
            Opportunity testOpportunity = new Opportunity (Name = 'NewContact' + i + ' Persist',
                CloseDate = dateTwoWeeksAgo,
                StageName = 'New');
            testOpportunities.add(testOpportunity);
        }

        insert testOpportunities;

        List<Opportunity> preTaskOppList = [SELECT Id FROM Opportunity];
        System.assertEquals(23, preTaskOppList.size());

        Test.startTest();
        TestcaseRecordDeleter deleteRecords = new TestcaseRecordDeleter();
        deleteRecords.deleteTestcaseRecords();

//      The task should only delete the 5 of the 20 leads.
        List<Opportunity> postTaskOppList = [SELECT Id FROM Opportunity];
        System.assertEquals(18, postTaskOppList.size());

        deleteRecords.deleteAll = true;
        deleteRecords.deleteTestcaseRecords();

        postTaskOppList = [SELECT Id FROM Opportunity];
        System.assertEquals(13, postTaskOppList.size());
        Test.stopTest();
    }

    @isTest static void testAccountTestcaseDeletion() {
        List<Account> testAccounts = new List<Account>();
        Date today = System.today();
        for(Integer i = 0; i<5; i++){
            Account testAccount = new Account (Name = 'NewContact' + i + ' Testcase',
                CreatedDate = today);
            testAccounts.add(testAccount);
        }

        for(Integer i = 0; i<5; i++){
            Account testAccount = new Account (Name = 'NewContact' + i + ' Persist',
                CreatedDate = today);
            testAccounts.add(testAccount);
        }

//      The following set of 5 Leads are the only ones that should be deleted
        Date dateTwoWeeksAgo = System.today().addDays(-30);
        for(Integer i = 0; i<5; i++){
            Account testAccount = new Account (Name = 'NewContact' + i + ' Testcase',
                CreatedDate = dateTwoWeeksAgo);
            testAccounts.add(testAccount);
        }

        for(Integer i = 0; i<5; i++){
            Account testAccount = new Account (Name = 'NewContact' + i + ' Persist',
                CreatedDate = dateTwoWeeksAgo);
            testAccounts.add(testAccount);
        }

        insert testAccounts;

        List<Account> preTaskAccList = [SELECT Id FROM Account];
        System.assertEquals(23, preTaskAccList.size());

        Test.startTest();
        TestcaseRecordDeleter deleteRecords = new TestcaseRecordDeleter();
        deleteRecords.deleteTestcaseRecords();

//      The task should only delete the 5 of the 20 leads.
        List<Account> postTaskAccList = [SELECT Id FROM Account];
        System.assertEquals(18, postTaskAccList.size());

        deleteRecords.deleteAll = true;
        deleteRecords.deleteTestcaseRecords();

        postTaskAccList = [SELECT Id FROM Account];
        System.assertEquals(13, postTaskAccList.size());
        Test.stopTest();
    }

    @isTest static void testLoanTestcaseDeletion() {

        List<Loan__c> preTaskLoanList = [SELECT Id FROM Loan__c];
        System.assertEquals(3, preTaskLoanList.size());

        Test.startTest();
        TestcaseRecordDeleter deleteRecords = new TestcaseRecordDeleter();
        deleteRecords.deleteTestcaseRecords();

//      The method should only delete the one load that is over two weeks old with the last name 'Testcase'
        List<Loan__c> postTaskLoanList = [SELECT Id FROM Loan__c];
        System.assertEquals(2, postTaskLoanList.size());

        deleteRecords.deleteAll = true;
        deleteRecords.deleteTestcaseRecords();

        postTaskLoanList = [SELECT Id FROM Loan__c];
        System.assertEquals(1, postTaskLoanList.size());
        Test.stopTest();
    }

    @isTest static void testResiEquipTestcaseDeletion() {

        List<Residential_Equipment__c> preResiEquipList = [SELECT Id FROM Residential_Equipment__c];
        System.assertEquals(3, preResiEquipList.size());

        Test.startTest();
        TestcaseRecordDeleter deleteRecords = new TestcaseRecordDeleter();
        deleteRecords.deleteTestcaseRecords();

//      Only one of the Test Equipments created was over two weeks old.
        List<Residential_Equipment__c> postResiEquipList = [SELECT Id FROM Residential_Equipment__c];
        System.assertEquals(2, postResiEquipList.size());

        deleteRecords.deleteAll = true;
        deleteRecords.deleteTestcaseRecords();

        postResiEquipList = [SELECT Id FROM Residential_Equipment__c];
        System.assertEquals(1, postResiEquipList.size());
        Test.stopTest();
    }

    @isTest static void testUALTestcaseDeletion() {
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        insert eversource;

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c (Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = TRUE);

        insert eversizeNMC;

        Load_U__c everLZU = new Load_U__c (Name = '02633',
            LZ__c = 'SEMA',
            Town__c= 'Medfield');
        insert everLZU;

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU.Id,
            Utility__c = eversource.Id
        );
        insert junction;

        insert new BW_Address__c(Name = 'BlueWave', Address_Line_One__c = '137 Newbury Street', Address_Line_Two__c = 'Boston, MA 02114');

        Account clientAccount = new Account(name = 'Client Account',
            Client_Brand_Key__c = 'AmpBlack');
        insert clientAccount;

        Account clientAccount2 = new Account(name = 'Client Account 2',
            Client_Brand_Key__c = 'AmpBlack');
        insert clientAccount2;

        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent = new Account(name = 'Account Parent',
            RecordTypeId = parentAccountRT);
        insert accountParent;
        Account accountParent2 = new Account(name = 'Account Parent',
            RecordTypeId = parentAccountRT);
        insert accountParent2;

        Contact contactA = new Contact( FirstName = 'Contact',
            LastName = 'A',
            AccountId = accountParent.Id);
        insert contactA;
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Community Solar Community User'];

        User userRecord = new User(
            FirstName = 'Jordan',
            Lastname ='Testcase',
            Alias = 'xxx234',
            Email = 'jpentaleri@bluewavesolar.com',
            Emailencodingkey ='UTF-8',
            Languagelocalekey ='en_US',
            Localesidkey ='en_US',
            Profileid = profileRecord.Id,
            Country ='United States',
            IsActive = true,
            ContactId = contactA.Id,
            Timezonesidkey='America/Los_Angeles',
            Username='testBillCreationandPay@bluewavesolar.com');
        Util.insertSobj(userRecord);

        ChargentBase__Gateway__c chGateway  =
            new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                ChargentBase__Merchant_ID__c = '235986',
                ChargentBase__Available_Payment_Methods__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
                ChargentBase__Debug__c = True,
                ChargentBase__Active__c = TRUE);
        insert chGateway;

        Entity__c entity2 = new Entity__c (
            Name = 'Oxford Barrett St. P2',
            Send_Checks_Address__c = '200 Other Street, City MA 02114',
            Client_Account__c = clientAccount2.Id,
            Gateway__c = chGateway.Id
        );
        insert entity2;

        Shared_Solar_System__c sss2 =
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                Service_Territory__c = 'SEMA',
                Service_Territories__c = 'SEMA',
                Open__c = true,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c  = 996,
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '2',
                Client_Account__c = clientAccount2.Id,
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Sales_Partners__c = 'All',
//                Billing_Method__c = 'NMC',
                BWC_Project_Entity_Manual__c = entity2.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id
            );
        insert sss2;


        Account accountA = new Account(name = 'Account A',
            Parent_Account__c = accountParent.Id);
        Account accountB = new Account(name = 'Account B',
            Parent_Account__c = accountParent2.Id);
        Account accountC = new Account(name = 'Account c',
            Parent_Account__c = accountParent2.Id);
        insert new List<Account>{accountA, accountB};

        Date twoWeeksAgo = System.today().addDays(-30);

        Utility_Account_Log__c ualog =
            new Utility_Account_Log__c(Name = '0000234',
                Account__c = accountA.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'UAL Testcase',
                CreatedDate = twoWeeksAgo);
        Utility_Account_Log__c ualog2 =
            new Utility_Account_Log__c(Name = '0000345',
                Account__c = accountB.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'UAL Testcase');
        Utility_Account_Log__c ualog3 =
            new Utility_Account_Log__c(Name = '0000345',
                Account__c = accountC.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'UAL Persist');

        insert new List<Utility_Account_Log__c>{ualog, ualog2, ualog3};

        List<Utility_Account_Log__c> preUALList = [SELECT Id FROM Utility_Account_Log__c];
        System.assertEquals(3, preUALList.size());

        Test.startTest();
        TestcaseRecordDeleter deleteRecords = new TestcaseRecordDeleter();
        deleteRecords.deleteTestcaseRecords();

        List<Utility_Account_Log__c> postUALList = [SELECT Id FROM Utility_Account_Log__c];
        System.assertEquals(2, postUALList.size());

        deleteRecords.deleteAll = true;
        deleteRecords.deleteTestcaseRecords();

        postUALList = [SELECT Id FROM Utility_Account_Log__c];
        System.assertEquals(1, postUALList.size());
        Test.stopTest();
    }

    @IsTest static void testPCRTestcaseDeletion() {
        List<LASERCA__Personal_Credit_Report__c> preTaskPCRList = [SELECT Id FROM LASERCA__Personal_Credit_Report__c];
        System.assertEquals(3, preTaskPCRList.size());

        Test.startTest();
        TestcaseRecordDeleter deleteRecords = new TestcaseRecordDeleter();
        deleteRecords.deleteTestcaseRecords();

//      Only one PCR is over two weeks old.
        List<LASERCA__Personal_Credit_Report__c> postTaskPCRList = [SELECT Id FROM LASERCA__Personal_Credit_Report__c];
        System.assertEquals(2, postTaskPCRList.size());

        deleteRecords.deleteAll = true;
        deleteRecords.deleteTestcaseRecords();

        postTaskPCRList = [SELECT Id FROM LASERCA__Personal_Credit_Report__c];
        System.assertEquals(0, postTaskPCRList.size());
        Test.stopTest();
    }

    @IsTest static void testDeleteAccountsFromSFDCAndZuora() {
        List<Account> testAccounts = new List<Account>();
        Date dateTwoWeeksAgo = System.today().addDays(-30);
        for (Integer i = 0; i<5; i++) {
            Account testAccount = new Account(
                Name = 'NewContact' + i + ' Testcase',
                CreatedDate = dateTwoWeeksAgo,
                Zuora_Id__c = '12345' + i
            );
            testAccounts.add(testAccount);
        }
        insert testAccounts;

        List<Account> preTaskAccList = [SELECT Id FROM Account];

        Test.startTest();
        TestcaseRecordDeleterMock deleteRecords = new TestcaseRecordDeleterMock();
        System.enqueueJob(deleteRecords);
        Test.stopTest();

        List<Account> postTaskAccList = [SELECT Id FROM Account];
        System.assertEquals(preTaskAccList.size() - 5, postTaskAccList.size(),
            'Expected to delete just the 5 accounts that do not have a Zuora id');
    }

    private class TestcaseRecordDeleterMock extends TestcaseRecordAsyncDeleter {
        protected override List<ZuoraAPI.ZuoraAccount> getZuoraTestcaseAccounts() {
            List<Account> accounts = [
                SELECT Id, Zuora_Id__c
                FROM Account
                WHERE CreatedDate < LAST_N_DAYS:28
                AND Name LIKE '%Testcase%'
            ];
            List<ZuoraAPI.ZuoraAccount> zuoraAccounts = new List<ZuoraAPI.ZuoraAccount>();
            for (Account account : accounts) {
                ZuoraAPI.ZuoraAccount zuoraAccount = new ZuoraAPI.ZuoraAccount();
                zuoraAccount.Id = account.Zuora_Id__c;
                zuoraAccount.CrmId = account.Id;
                zuoraAccounts.add(zuoraAccount);
            }
            return zuoraAccounts;
        }
    }
}