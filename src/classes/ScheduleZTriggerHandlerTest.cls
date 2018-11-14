@isTest
public class ScheduleZTriggerHandlerTest {
    @IsTest static void testSubscriptionsCreatedWithoutFutureSubscription() {
        Shared_Solar_System__c sss1 = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
            LIMIT 1
        ];

        test.startTest();
        /*
        Test subscription set by Customer_Subscription_KW_DC_STATIC__c (Current Subscription)
        This is an edge case, most cases should be set by Customer_Subscription_KW_DC__c (Future Subscription)
        unless the formula inputs are missing
         */
        Schedule_Z__c sss1ScheduleZ = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id
        );

        insert sss1ScheduleZ;

        List<Schedule_Z_Subscription__c> sss1ScheduleZs = [
            SELECT Id, Customer_Subscription_kW_DC__c
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c = : sss1ScheduleZ.Id
        ];

        System.assertEquals(1, sss1ScheduleZs.size());
        System.assertEquals(20.2312 , sss1ScheduleZs[0].Customer_Subscription_kW_DC__c);

        test.stopTest();
    }

    @IsTest static void testSubscriptionsCreatedWithFutureSubscription() {
        Shared_Solar_System__c sss2 = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P2'
            LIMIT 1
        ];

        test.startTest();
        // Test subscription set by Customer_Subscription_KW_DC__c (Future Subscription)
        Schedule_Z__c sss2ScheduleZ = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss2.Id
        );

        insert sss2ScheduleZ;

        List<Schedule_Z_Subscription__c> sss2ScheduleZs = [
            SELECT Id, Customer_Subscription_kW_DC__c, Number_of_Decimal_Places__c,
                System_Size_kW_DC__c, Percent_Share__c
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c = : sss2ScheduleZ.Id
        ];

        System.assertEquals(1, sss2ScheduleZs.size());
        System.assertEquals(4.6154 , sss2ScheduleZs[0].Customer_Subscription_kW_DC__c);
        System.assertEquals(4, sss2ScheduleZs[0].Number_of_Decimal_Places__c);
        System.assertEquals(1445.86, sss2ScheduleZs[0].System_Size_kW_DC__c);

        Decimal customerSubscription = sss2ScheduleZs[0].Customer_Subscription_kW_DC__c;
        Decimal systemSize = sss2ScheduleZs[0].System_Size_kW_DC__c;
        Integer decimalPlaces = (Integer) sss2ScheduleZs[0].Number_of_Decimal_Places__c;

        Decimal calculatedPercentShare = (100.00 * customerSubscription / systemSize).setScale(decimalPlaces);

        System.assertEquals(calculatedPercentShare, sss2ScheduleZs[0].Percent_Share__c);

        test.stopTest();
    }

    @testSetup public static void setupTestData(){
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 4
        );

        Utility__c national_grid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 4
        );

        insert new List<Utility__c>{eversource, national_grid};

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c (Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = TRUE);

        Utility_NMC_Tariff__c ngridsizeNMC = new Utility_NMC_Tariff__c (Name = 'National Grid WCMA Class 2',
            Utility__c = 'National Grid',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = TRUE);

        insert new List<Utility_NMC_Tariff__c>{eversizeNMC, ngridsizeNMC};

        Load_U__c everLZU = new Load_U__c (Name = '02633',
            Load_zone__c = 'SEMA Eversource',
            LZ__c = 'SEMA',
            Utility__C = 'Eversource',
            Town__c= 'Medfield');

        Load_U__c ngridLZU = new Load_U__c (Name = '01570',
            Load_zone__c= 'WCMA National Grid',
            LZ__c = 'WCMA',
            Utility__C = 'National Grid',
            Town__c= 'Westtown');

        insert new List<Load_U__c>{everLZU, ngridLZU};
        TestFactory.insertBWAddress();

        Account clientAccount = new Account(name = 'Client Account',
            Client_Brand_Key__c = 'AmpBlack');
        insert clientAccount;

        Account clientAccount2 = new Account(name = 'Client Account 2',
            Client_Brand_Key__c = 'AmpBlack');
        insert clientAccount2;

        ChargentBase__Gateway__c chGateway  =
            new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                ChargentBase__Merchant_ID__c = '235986',
                ChargentBase__Available_Payment_Methods__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
                ChargentBase__Debug__c = True,
                ChargentBase__Active__c = TRUE);
        insert chGateway;

        Entity__c entity1 = new Entity__c (Name = 'Oxford Barrett St. P1',
            Send_Checks_Address__c = 'Fake Lockbox Address, P.O Box 12345, Phoenix Arizona 02114',
            Client_Account__c = clientAccount.Id,
            Gateway__c = chGateway.Id
        );
        insert entity1;

        Entity__c entity2 = new Entity__c (Name = 'Oxford Barrett St. P2',
            Send_Checks_Address__c = '200 Other Street, City MA 02114',
            Client_Account__c = clientAccount2.Id);
        insert entity2;

        Shared_Solar_System__c sss1 =
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                Service_Territory__c = 'SEMA',
                Service_Territories__c = 'SEMA',
                Open__c = true,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c  = 996,
                System_Utility__c = 'Eversource',
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '1',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Sales_Partners__c = 'All',
                BWC_Project_Entity_Manual__c = entity1.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id);

        Shared_Solar_System__c sss2 =
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                Service_Territory__c = 'SEMA',
                Service_Territories__c = 'SEMA',
                Open__c = true,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c  = 996,
                System_Utility__c = 'Eversource',
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '2',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Sales_Partners__c = 'All',
                BWC_Project_Entity_Manual__c = entity2.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id
            );
        insert new List<Shared_Solar_System__c>{sss1, sss2};

        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent = new Account(name = 'Account Parent',
            RecordTypeId = parentAccountRT);
        insert accountParent;

        Contact contactA = new Contact( FirstName = 'Contact',
            LastName = 'A',
            AccountId = accountParent.Id);
        insert contactA;

        Account accountA = new Account(name = 'Account A',
            Parent_Account__c = accountParent.Id);
        insert accountA;

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
        Util.insertSobjs(new list<User>{userRecord});

        Utility_Account_Log__c ualog =
            new Utility_Account_Log__c(Name = '0000234',
                Account__c = accountA.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'jordan jordan');
        insert ualog;

        Product2 normalCSProduct = new Product2( Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Customer_Subscription_Type__c = 'kWh',
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

        Opportunity opportunityone =
            new Opportunity(Name = 'AOpp One',
                AccountId = accountA.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                CloseDate = System.today());

        Opportunity opportunitytwo =
            new Opportunity(Name = 'BOpp Two',
                AccountId = accountA.Id,
                Shared_Solar_System__c = sss2.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                CloseDate = System.today());

        Opportunity opportunitythree =
            new Opportunity(Name = 'BOpp Two',
                AccountId = accountA.Id,
                Shared_Solar_System__c = sss2.Id,
                StageName = 'New',
                Product__c = normalCSProduct.Id,
                CloseDate = System.today());

        insert new List<Opportunity>{opportunityone, opportunitytwo, opportunitythree};

        Utility_Account_Subscription__c uasone =
            new Utility_Account_Subscription__c(Name = '0000234',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunityone.Id,
                Customer_Subscription_KW_DC_STATIC__c = 20.2312,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Calculated_Annual_Cost_of_Electricity__c = 4000,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);

        Utility_Account_Subscription__c uastwo =
            new Utility_Account_Subscription__c(Name = '000-0234',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunitytwo.Id,
                Customer_Subscription_KW_DC_STATIC__c = 20.2312,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 6000,
                Calculated_Annual_Cost_of_Electricity__c = 6000,
                Subscribed_Annual_Cost_of_Electricity__c = 6000);

// Test for only active subscriptions have Sched Z Subs created
        Utility_Account_Subscription__c uasthree =
            new Utility_Account_Subscription__c(Name = '0000237',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunityone.Id,
                Customer_Subscription_KW_DC_STATIC__c = 1000,
                Next_Schedule_Z_Status__c = 'Inactive Subscription',
                Calculated_Annual_Cost_of_Electricity__c = 8000,
                Subscribed_Annual_Cost_of_Electricity__c = 8000);

        // Test only completed opportunities have Sched Z Subs created
        Utility_Account_Subscription__c uasfour =
            new Utility_Account_Subscription__c(Name = '0000237',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunitythree.Id,
                Customer_Subscription_KW_DC_STATIC__c = 1000,
                Next_Schedule_Z_Status__c = 'Inactive Subscription',
                Calculated_Annual_Cost_of_Electricity__c = 8000,
                Subscribed_Annual_Cost_of_Electricity__c = 8000);

        insert new List<Utility_Account_Subscription__c>{uasone, uastwo, uasthree, uasfour};
    }
}