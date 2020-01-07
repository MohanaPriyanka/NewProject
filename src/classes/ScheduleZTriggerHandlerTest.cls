@IsTest
public class ScheduleZTriggerHandlerTest {
    @TestSetup public static void setupTestData(){
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
            Sizing_Rate__c = true);

        Utility_NMC_Tariff__c ngridsizeNMC = new Utility_NMC_Tariff__c (Name = 'National Grid WCMA Class 2',
            Utility__c = 'National Grid',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = true);

        insert new List<Utility_NMC_Tariff__c>{eversizeNMC, ngridsizeNMC};

        Load_U__c everLZU = new Load_U__c (Name = '02633',
            LZ__c = 'SEMA',
            Town__c= 'Medfield');

        Load_U__c ngridLZU = new Load_U__c (Name = '01570',
            LZ__c = 'WCMA',
            Town__c= 'Westtown');

        insert new List<Load_U__c>{everLZU, ngridLZU};

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU.Id,
            Utility__c = eversource.Id
        );
        ZipCode_Utility_Junction__c junctionTwo = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = ngridLZU.Id,
            Utility__c = national_grid.Id
        );
        insert new List<ZipCode_Utility_Junction__c>{junction, junctionTwo};

        TestFactory.insertBWAddress();

        Account clientAccount = new Account(Name = 'Client Account',
            Client_Brand_Key__c = 'AmpBlack');
        insert clientAccount;

        Account clientAccount2 = new Account(Name = 'Client Account 2',
            Client_Brand_Key__c = 'AmpBlack');
        insert clientAccount2;

        ChargentBase__Gateway__c chGateway  =
            new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                ChargentBase__Merchant_ID__c = '235986',
                ChargentBase__Available_Payment_Methods__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
                ChargentBase__Debug__c = true,
                ChargentBase__Active__c = true);
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
                Credit_Score_Requirement__c = 200,
                Assignment_Order__c = '1',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Sales_Partners__c = 'All',
                Client_Account__c = clientAccount.Id,
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
                Credit_Score_Requirement__c = 200,
                Assignment_Order__c = '2',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Sales_Partners__c = 'All',
                Client_Account__c = clientAccount2.Id,
                BWC_Project_Entity_Manual__c = entity2.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id
            );
        insert new List<Shared_Solar_System__c>{sss1, sss2};

        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent = new Account(Name = 'Account Parent',
            RecordTypeId = parentAccountRT);
        insert accountParent;

        Contact contactA = new Contact( FirstName = 'Contact',
            LastName = 'A',
            AccountId = accountParent.Id);
        insert contactA;

        Account accountA = new Account(Name = 'Account A',
            Parent_Account__c = accountParent.Id);
        Account accountB = new Account(Name = 'Account B',
            Parent_Account__c = accountParent.Id);
        insert new List<Account>{accountA, accountB};

        Utility_Account_Log__c ualog =
            new Utility_Account_Log__c(Name = '0000234',
                Account__c = accountA.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'jordan jordan');
        Utility_Account_Log__c ualogB =
            new Utility_Account_Log__c(Name = '0000567',
                Account__c = accountB.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'jordan jordan');
        insert new List<Utility_Account_Log__c>{ualog, ualogB};

        Product2 normalCSProduct = new Product2( Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Customer_Subscription_Type__c = 'kWh',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_in_Bill_Period__c = 20,
            Monthly_Late_Fee__c = 1);
        insert normalCSProduct;

        Opportunity opportunityone =
            new Opportunity(Name = 'AOpp One',
                AccountId = accountA.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                CloseDate = System.today());
        Opportunity opportunityoneB =
            new Opportunity(Name = 'BOpp One',
                AccountId = accountB.Id,
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

        insert new List<Opportunity>{opportunityone, opportunityoneB, opportunitytwo, opportunitythree};

        Utility_Account_Subscription__c uasone =
            new Utility_Account_Subscription__c(Name = '0000234',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunityone.Id,
                Customer_Subscription_KW_DC_STATIC__c = 20.2312,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                calculated_annual_cost_of_electricity__c = 4000,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);

        Utility_Account_Subscription__c uasoneB =
            new Utility_Account_Subscription__c(Name = '0000235',
                Utility_Account_Log__c = ualogB.Id,
                Opportunity__c = opportunityoneB.Id,
                Customer_Subscription_KW_DC_STATIC__c = 20.2312,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                calculated_annual_cost_of_electricity__c = 4000,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);

        Utility_Account_Subscription__c uastwo =
            new Utility_Account_Subscription__c(Name = '000-0234',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunitytwo.Id,
                Customer_Subscription_KW_DC_STATIC__c = 20.2312,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 6000,
                calculated_annual_cost_of_electricity__c = 6000,
                Subscribed_Annual_Cost_of_Electricity__c = 6000);

        // Test for only active subscriptions have Sched Z Subs created
        Utility_Account_Subscription__c uasthree =
            new Utility_Account_Subscription__c(Name = '0000237',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunityone.Id,
                Customer_Subscription_KW_DC_STATIC__c = 1000,
                Next_Schedule_Z_Status__c = 'Inactive Subscription',
                calculated_annual_cost_of_electricity__c = 8000,
                Subscribed_Annual_Cost_of_Electricity__c = 8000);

        // Test only completed opportunities have Sched Z Subs created
        Utility_Account_Subscription__c uasfour =
            new Utility_Account_Subscription__c(Name = '0000237',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunitythree.Id,
                Customer_Subscription_KW_DC_STATIC__c = 1000,
                Next_Schedule_Z_Status__c = 'Inactive Subscription',
                calculated_annual_cost_of_electricity__c = 8000,
                Subscribed_Annual_Cost_of_Electricity__c = 8000);

        insert new List<Utility_Account_Subscription__c>{uasone, uasoneB, uastwo, uasthree, uasfour};

        zqu__ZProduct__c zProduct = new zqu__ZProduct__c(
            Name = 'Community Solar'
        );
        insert zProduct;

        zqu__ProductRatePlan__c productRatePlan = new zqu__ProductRatePlan__c(
            Name = 'Community Solar Subscriptions',
            zqu__ZuoraId__c = '2c92c0f86ab120de016ab427c7d8234d',
            zqu__ZProduct__c = zProduct.Id
        );
        insert productRatePlan;
        zqu__ProductRatePlanCharge__c productRatePlanCharge = new zqu__ProductRatePlanCharge__c(
            Name = 'Utility Credit',
            zqu__ZuoraId__c = '2c92c0f86ab120de016ab427c97b2368',
            zqu__ProductRatePlan__c = productRatePlan.Id
        );
        insert productRatePlanCharge;

        System_Properties__c properties = new System_Properties__c(
            Name = 'System',
            Use_Zuora_For_Subscription_Billing__c = true
        );
        insert properties;
    }

    @IsTest static void testHandleDates() {
        Shared_Solar_System__c sss1 = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
            LIMIT 1
        ];

        Test.startTest();

        Schedule_Z__c sss1ScheduleZ = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Status__c = 'Enacted by Utility',
            Date_Enacted_by_Utility__c = System.today()
        );

        Schedule_Z__c sss1ScheduleZ2 = new Schedule_Z__c(
            Name = '18-0615 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Status__c = 'QC Complete'
        );

        insert sss1ScheduleZ;
        // Because a process builder sets teh Date_Enacted_by_Utility to today(), and we use that date to figure
        // out the order of the SZs, set the date back
        sss1ScheduleZ.Date_Enacted_by_Utility__c = System.today().addMonths(-5);
        update sss1ScheduleZ;
        insert sss1ScheduleZ2;

        System.assertEquals(null, sss1ScheduleZ.Date_Schedule_Z_Retired_by_Utility__c);

        Date dateEnacted = System.today();
        sss1ScheduleZ2.Status__c = 'Enacted by Utility';
        update sss1ScheduleZ2;

        Schedule_Z__c firstSchedZ = [
            SELECT Id, Name, Date_Schedule_Z_Retired_by_Utility__c
            FROM Schedule_Z__c
            WHERE Name = '18-0515 Oxford Barrett St. P1'
        ];

        System.assertEquals(dateEnacted, firstSchedZ.Date_Schedule_Z_Retired_by_Utility__c);
    }

    @IsTest static void testSubscriptionsCreatedWithoutFutureSubscription() {
        Shared_Solar_System__c sss1 = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
            LIMIT 1
        ];

        Test.startTest();
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

        System.assertEquals(2, sss1ScheduleZs.size());
        System.assertEquals(20.2312 , sss1ScheduleZs[0].Customer_Subscription_kW_DC__c);

        Test.stopTest();
    }

    @IsTest static void testSubscriptionsCreatedWithFutureSubscription() {
        Shared_Solar_System__c sss2 = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P2'
            LIMIT 1
        ];

        Test.startTest();
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

        Test.stopTest();
    }

    @IsTest static void testAccountsMissingZuoraIds() {
        Shared_Solar_System__c sss1 = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
            LIMIT 1
        ];

        Test.startTest();
        Schedule_Z__c sss1ScheduleZ = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Status__c = 'Enacted by Utility'
        );
        insert sss1ScheduleZ;
        // This should insert schedule z subscriptions, but zuora accounts haven't been set up so we should get an error log
        List<Schedule_Z_Subscription__c> scheduleZSubscriptions = [
            SELECT Id
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c = :sss1ScheduleZ.Id
        ];

        Test.stopTest();

        List<Error_Log__c> logs = [SELECT Message__c FROM Error_Log__c];
        System.assertEquals(1, logs.size());
        System.assert(logs[0].Message__c.contains('Found an account that should have a Zuora Id but didn\'t'));
    }

    @IsTest static void testZuoraSubscription() {
        Shared_Solar_System__c sss1 = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
            LIMIT 1
        ];
        List<Account> accounts = [
            SELECT Id
            FROM Account
        ];
        for (Account account : accounts) {
            account.Zuora_Id__c = '12345';
        }
        update accounts;

        Test.startTest();
        Schedule_Z__c sss1ScheduleZ = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Status__c = 'Enacted by Utility'
        );
        insert sss1ScheduleZ;
        // This should insert schedule z subscriptions, which should get Zuora accounts
        List<Schedule_Z_Subscription__c> scheduleZSubscriptions = [
            SELECT Id
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c = :sss1ScheduleZ.Id
        ];

        Test.stopTest();

        List<Error_Log__c> logs = [SELECT Message__c FROM Error_Log__c];
        System.assertEquals(1, logs.size());
        System.assert(logs[0].Message__c.contains('zuora.com/v1/orders'));
        System.assert(logs[0].Message__c.contains('CreateSubscription'));
    }

    @IsTest static void testZuoraSubscriptionsWarnWhenAccountMissingIdFound() {
        Shared_Solar_System__c sss1 = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
            LIMIT 1
        ];
        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Name = 'Account A'
        ];
        accounts[0].Zuora_Id__c = '12345';
        update accounts[0];

        Test.startTest();
        Schedule_Z__c sss1ScheduleZ = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Status__c = 'Enacted by Utility'
        );
        insert sss1ScheduleZ;
        // This should insert schedule z subscriptions, which should get Zuora accounts
        List<Schedule_Z_Subscription__c> scheduleZSubscriptions = [
            SELECT Id
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c = :sss1ScheduleZ.Id
        ];

        Test.stopTest();

        List<Error_Log__c> logs = [SELECT Message__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR];
        System.assertEquals(1, logs.size());
        System.assert(logs[0].Message__c.contains('Found an account that should have a Zuora Id but didn\'t'), 'Expected to find an account without a Zuora Id');
        logs = [SELECT Message__c FROM Error_Log__c WHERE Severity__c != :Logger.ERROR];
        System.assert(logs[0].Message__c.contains('zuora.com/v1/orders'), 'Expected a v1/orders callout');
        System.assert(logs[0].Message__c.contains('CreateSubscription'), 'Expected CreateSubscription in the orders callout');
    }

    @IsTest static void testMostRecentALSSUpdate() {
        List<Utility_Account_Subscription__c> initialUASList = [
            SELECT Id, Name, Most_Recent_Enacted_ALSS__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.StageName = 'Complete'
            ORDER BY Opportunity__r.Shared_Solar_System_Name__c
        ];

        System.assertEquals(4,initialUASList.size());
        System.assertEquals(null,initialUASList[0].Most_Recent_Enacted_ALSS__c);
        System.assertEquals(null,initialUASList[1].Most_Recent_Enacted_ALSS__c);
        System.assertEquals(null,initialUASList[2].Most_Recent_Enacted_ALSS__c);
        System.assertEquals(null,initialUASList[3].Most_Recent_Enacted_ALSS__c);

        for (Utility_Account_Subscription__c uas : initialUASList){
            uas.Next_Schedule_Z_Status__c = 'Active Subscription';
        }
        update initialUASList;

        List<Shared_Solar_System__c> sharedSolarSystems = [
            SELECT Id
            FROM Shared_Solar_System__c
            ORDER BY Name
        ];

        Test.startTest();

        Schedule_Z__c sss1FirstAllocationSchedule = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sharedSolarSystems[0].Id,
            Status__c = 'QC Complete'
        );

        Schedule_Z__c sss2FirstAllocationSchedule = new Schedule_Z__c(
            Name = '18-0615 Oxford Barrett St. P2',
            Shared_Solar_System__c =  sharedSolarSystems[1].Id,
            Status__c = 'QC Complete'
        );

        List<Schedule_Z__c> szsList = new List<Schedule_Z__c>{sss1FirstAllocationSchedule,sss2FirstAllocationSchedule};
        insert szsList;

        sss1FirstAllocationSchedule.Status__c = 'Enacted by Utility';
        sss2FirstAllocationSchedule.Status__c = 'Enacted by Utility';
        // Because a process builder sets Date_Enacted_by_Utility to today(), override:
        sss1FirstAllocationSchedule.Date_Enacted_by_Utility__c = System.today().addDays(-2);
        sss2FirstAllocationSchedule.Date_Enacted_by_Utility__c = System.today().addDays(-2);
        update szsList;

        List<Utility_Account_Subscription__c> updatedUASListOne = [
            SELECT Id, Name, Most_Recent_Enacted_ALSS__c, Most_Recent_Enacted_ALSS__r.Schedule_Z__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.StageName = 'Complete'
            ORDER BY Opportunity__r.Shared_Solar_System_Name__c
        ];

        System.assertEquals(4,updatedUASListOne.size());
        System.assertEquals(sss1FirstAllocationSchedule.Id,updatedUASListOne[0].Most_Recent_Enacted_ALSS__r.Schedule_Z__c, 'Expected uasone to be on sss1');
        System.assertEquals(sss1FirstAllocationSchedule.Id,updatedUASListOne[1].Most_Recent_Enacted_ALSS__r.Schedule_Z__c, 'Expected uasoneB to be on sss1');
        System.assertEquals(sss1FirstAllocationSchedule.Id,updatedUASListOne[2].Most_Recent_Enacted_ALSS__r.Schedule_Z__c, 'Expected uastwo to be on sss1');
        System.assertEquals(sss2FirstAllocationSchedule.Id,updatedUASListOne[3].Most_Recent_Enacted_ALSS__r.Schedule_Z__c, 'Expected uasthree to be on sss2');

        Schedule_Z__c sss1SecondAllocationSchedule = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sharedSolarSystems[0].Id,
            Status__c = 'QC Complete'
        );

        Schedule_Z__c sss2SecondAllocationSchedule = new Schedule_Z__c(
            Name = '18-0615 Oxford Barrett St. P2',
            Shared_Solar_System__c =  sharedSolarSystems[1].Id,
            Status__c = 'QC Complete'
        );

        List<Schedule_Z__c> secondSZList = new List<Schedule_Z__c>{sss1SecondAllocationSchedule,sss2SecondAllocationSchedule};
        insert secondSZList;

        sss1SecondAllocationSchedule.Status__c = 'Enacted by Utility';
        sss2SecondAllocationSchedule.Status__c = 'Enacted by Utility';
        // First group of Schedule Zs were dated 2 days ago:
        sss1SecondAllocationSchedule.Date_Enacted_by_Utility__c = System.today().addDays(-5);
        sss2SecondAllocationSchedule.Date_Enacted_by_Utility__c = System.today().addDays(-1);
        update secondSZList;

        List<Utility_Account_Subscription__c> updatedUASListTwo = [
            SELECT Id, Name, Most_Recent_Enacted_ALSS__c, Most_Recent_Enacted_ALSS__r.Schedule_Z__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.StageName = 'Complete'
            ORDER BY Opportunity__r.Shared_Solar_System_Name__c
        ];

        System.assertEquals(4,updatedUASListTwo.size());
        // sss1 should still be linked to the first schedule z, since sss1SecondAllocationSchedule is dated before sss1FirstAllocationSchedule
        System.assertEquals(sss1FirstAllocationSchedule.Id,updatedUASListTwo[0].Most_Recent_Enacted_ALSS__r.Schedule_Z__c);
        System.assertEquals(sss1FirstAllocationSchedule.Id,updatedUASListTwo[1].Most_Recent_Enacted_ALSS__r.Schedule_Z__c);
        System.assertEquals(sss1FirstAllocationSchedule.Id,updatedUASListTwo[2].Most_Recent_Enacted_ALSS__r.Schedule_Z__c);

        // but sss2 should be linked to the second schedule z, since sss2SecondAllocationSchedule is dated after sss2FirstAllocationSchedule
        System.assertEquals(sss2SecondAllocationSchedule.Id,updatedUASListTwo[3].Most_Recent_Enacted_ALSS__r.Schedule_Z__c);
    }
}