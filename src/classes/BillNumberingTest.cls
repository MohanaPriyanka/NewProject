/**
 * Created by mstackhouse on 7/26/2018.
 * Description: Removed this test from TestBillCreationandPayment because the testSetup in that class wasn't completely
 * necessary for this test. This test isn't actually required for code coverage, but is important.
 *
 */

@isTest
public with sharing class BillNumberingTest {
    @isTest public static void testBillNumbering() {
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

        TestFactory.insertBWAddress();
        TestFactory.setCSBillSettings();

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
                ChargentBase__Debug__c = True,
                ChargentBase__Available_Payment_Methods__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
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
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Sales_Partners__c = 'All',
                Billing_Method__c = 'NMC',
                Client_Account__c = clientAccount2.Id,
                BWC_Project_Entity_Manual__c = entity2.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id
            );

        insert sss2;


        Account accountA = new Account(name = 'Account A',
            Parent_Account__c = accountParent.Id);
        Account accountB = new Account(name = 'Account B',
            Parent_Account__c = accountParent2.Id);
        insert new List<Account>{accountA, accountB};



        Utility_Account_Log__c ualog =
            new Utility_Account_Log__c(Name = '0000234',
                Account__c = accountA.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'jordan jordan');

        Utility_Account_Log__c ualog2 =
            new Utility_Account_Log__c(Name = '0000345',
                Account__c = accountB.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'jordan jordan');
        insert new List<Utility_Account_Log__c>{ualog, ualog2};

        Product2 normalCSProduct = new Product2( Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_In_Bill_Period__c = 20,
            Monthly_Late_Fee__c = 1);
        insert normalCSProduct;

        Opportunity opportunitytwo =
            new Opportunity(Name = 'BOpp One',
                AccountId = accountA.Id,
                Shared_Solar_System__c = sss2.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                CloseDate = System.today());

        Opportunity opportunitythree =
            new Opportunity(Name = 'BOpp Two',
                AccountId = accountB.Id,
                Shared_Solar_System__c = sss2.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                CloseDate = System.today());
        insert new List<Opportunity>{opportunitytwo, opportunitythree};

        Utility_Account_Subscription__c uastwo =
            new Utility_Account_Subscription__c(Name = '000-0234',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunitytwo.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 6000,
                Calculated_Annual_Cost_of_Electricity__c = 6000,
                Subscribed_Annual_Cost_of_Electricity__c = 6000);

        Utility_Account_Subscription__c uasfour =
            new Utility_Account_Subscription__c(Name = '0000345',
                Utility_Account_Log__c = ualog2.Id,
                Opportunity__c = opportunitythree.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 6000,
                Calculated_Annual_Cost_of_Electricity__c = 6000,
                Subscribed_Annual_Cost_of_Electricity__c = 6000);

        insert new List<Utility_Account_Subscription__c>{uastwo, uasfour};

        uastwo.Customer_Subscription_KW_DC_STATIC__c = 20;
        update uastwo;

        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);


        Schedule_Z__c scheduleZ2 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P2',
            Shared_Solar_System__c = sss2.Id,
            Status__c = 'Billing'
        );

        insert scheduleZ2;

        Energy_Usage_Update__c productionupdateB1 = new Energy_Usage_Update__c (
            Name = 'sssB - January 2016',
            Shared_Solar_System__c = sss2.id,
            Schedule_Z__c = scheduleZ2.id,
            Production__c = 90000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateFeb,
            Total_System_NMCs__c = 16632,
            Date__c = myDateJan
        );

        insert productionupdateB1;

        Energy_Usage_Update__c productionupdateB2 = new Energy_Usage_Update__c (
            Name = 'sssB - February 2016',
            Shared_Solar_System__c = sss2.id,
            Schedule_Z__c = scheduleZ2.id,
            Production__c = 120000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateMar,
            Total_System_NMCs__c = 22176,
            Date__c = myDateFeb
        );

        insert productionupdateB2;

        TestBillCreationandPayment.runProductionUpdate(new List<Id>{productionupdateB1.Id});


        APXT_BPM__Conductor__c newConga = new APXT_BPM__Conductor__c (APXT_BPM__Title__c = 'Conga Record');
        insert newConga;
        newConga.Apply_Overpay_Adjust__c = true;
        update newConga;
        Test.startTest();

        TestBillCreationandPayment.setBillsToPublished();

        TestBillCreationandPayment.simulateBatchBillCreation(new List<Energy_Usage_Update__c>{productionupdateB2});

        Test.stopTest();

        Opportunity oppOne = [
            SELECT Id, AccountId, Name
            FROM Opportunity
            WHERE Name = 'BOpp One'
            LIMIT 1
        ];

        Opportunity oppTwo = [
            SELECT Id, AccountId, Name
            FROM Opportunity
            WHERE Name = 'BOpp Two'
            LIMIT 1
        ];

        List<Account_Bill__c> oppOneAccountBills = [
            SELECT Id, Bill_Number__c, Past_Bill__c, Total_Due__c, Month__c
            FROM Account_Bill__c
            WHERE Parent_Account__c = : oppOne.AccountId
            ORDER BY Bill_Number__c
        ];

        List<Account_Bill__c> oppTwoAccountBills = [
            SELECT Id, Bill_Number__c, Past_Bill__c, Total_Due__c, Month__c
            FROM Account_Bill__c
            WHERE Parent_Account__c = : oppTwo.AccountId
            ORDER BY Bill_Number__c
        ];

        List<System_Bill__c> oppOneSystemBills = [
            SELECT Id, Bill_Number__c, Month__c
            FROM System_Bill__c
            WHERE Property_Account__c = : oppOne.AccountId
            AND Shared_Solar_System__c = : productionupdateB2.Shared_Solar_System__c
            ORDER BY Bill_Number__c
        ];

        List<System_Bill__c> oppTwoSystemBills = [
            SELECT Id, Bill_Number__c, Month__c
            FROM System_Bill__c
            WHERE Opportunity__c = : oppTwo.Id
            ORDER BY Bill_Number__c
        ];

        Account_Bill__c oppOneJanuaryAccountBill = oppOneAccountBills[0];
        Account_Bill__c oppOneFebruaryAccountBill = oppOneAccountBills[1];
        System_Bill__c oppOneJanuarySystemBill = oppOneSystemBills[0];
        System_Bill__c oppOneFebruarySystemBill = oppOneSystemBills[1];

        System.AssertEquals(2, oppOneAccountBills.size());
        System.AssertEquals(1, oppOneJanuaryAccountBill.Bill_Number__c);
        System.AssertEquals(1, oppOneJanuaryAccountBill.Month__c);
        System.AssertEquals(2, oppOneFebruaryAccountBill.Bill_Number__c);
        System.AssertEquals(2, oppOneFebruaryAccountBill.Month__c);
        System.AssertEquals(oppOneJanuaryAccountBill.Total_Due__c, oppOneFebruaryAccountBill.Past_Bill__c);

        System.AssertEquals(2, oppOneSystemBills.size());
        System.AssertEquals(1, oppOneJanuarySystemBill.Bill_Number__c);
        System.AssertEquals(1, oppOneJanuarySystemBill.Month__c);
        System.AssertEquals(2, oppOneFebruarySystemBill.Bill_Number__c);
        System.AssertEquals(2, oppOneFebruarySystemBill.Month__c);

        Account_Bill__c oppTwoJanuaryAccountBill = oppTwoAccountBills[0];
        Account_Bill__c oppTwoFebruaryAccountBill = oppTwoAccountBills[1];
        System_Bill__c oppTwoJanuarySystemBill = oppTwoSystemBills[0];
        System_Bill__c oppTwoFebruarySystemBill = oppTwoSystemBills[1];

        System.AssertEquals(2, oppTwoAccountBills.size());
        System.AssertEquals(1, oppTwoJanuaryAccountBill.Bill_Number__c);
        System.AssertEquals(1, oppTwoJanuaryAccountBill.Month__c);
        System.AssertEquals(2, oppTwoFebruaryAccountBill.Bill_Number__c);
        System.AssertEquals(2, oppTwoFebruaryAccountBill.Month__c);
        System.AssertEquals(oppTwoJanuaryAccountBill.Total_Due__c, oppTwoFebruaryAccountBill.Past_Bill__c);

        System.AssertEquals(2, oppTwoSystemBills.size());
        System.AssertEquals(1, oppTwoJanuarySystemBill.Bill_Number__c);
        System.AssertEquals(1, oppTwoJanuarySystemBill.Month__c);
        System.AssertEquals(2, oppTwoFebruarySystemBill.Bill_Number__c);
        System.AssertEquals(2, oppTwoFebruarySystemBill.Month__c);
    }

}