@IsTest
public class TestBillCreationandPayment {
    @TestSetup
    public static void csTestRecordWarehouse() {
        csTestRecordWarehouse(false);
    }

    public static void csTestRecordWarehouse(Boolean multipleOppsForSingleSystem) {
        Test.startTest();
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );
        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{eversource, nationalGrid};

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
            Utility__c = nationalGrid.Id
        );
        insert new List<ZipCode_Utility_Junction__c>{junction, junctionTwo};

        TestFactory.insertBWAddress();
        TestFactory.setCSBillSettings();

        Account clientAccount = new Account(name = 'Client Account',
            Client_Brand_Key__c = 'AmpBlack');
        Account clientAccount2 = new Account(name = 'Client Account 2',
            Client_Brand_Key__c = 'AmpBlack');

        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent = new Account(name = 'Account Parent',
            RecordTypeId = parentAccountRT);
        Account accountParent2 = new Account(name = 'Account Parent',
            RecordTypeId = parentAccountRT);

        insert new List<Account>{clientAccount, clientAccount2,accountParent,accountParent2};

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
        Util.insertSobjs(new list<User>{userRecord});

        ChargentBase__Gateway__c chGateway  =
            new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                ChargentBase__Merchant_ID__c = '235986',
                ChargentBase__Debug__c = True,
                ChargentBase__Available_Payment_Methods__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
                ChargentBase__Active__c = TRUE);
        insert chGateway;


        Entity__c entity1 = new Entity__c (
            Name = 'Oxford Barrett St. P1',
            Send_Checks_Address__c = 'Fake Lockbox Address, P.O Box 12345, Phoenix Arizona 02114',
            Client_Account__c = clientAccount.Id,
            Gateway__c = chGateway.Id
        );

        Entity__c entity2 = new Entity__c (
            Name = 'Oxford Barrett St. P2',
            Send_Checks_Address__c = '200 Other Street, City MA 02114',
            Client_Account__c = clientAccount2.Id,
            Gateway__c = chGateway.Id
        );
        insert new List<Entity__c>{entity1, entity2};

        Shared_Solar_System__c sss1 =
            new Shared_Solar_System__c(Name = 'Oxford Barrett Street. Part1 With Long Name To Test Unique Id Lengths',
                Service_Territory__c = 'SEMA',
                Service_Territories__c = 'SEMA',
                Open__c = true,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c  = 996,
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '1',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Client_Account__c = clientAccount.Id,
                Sales_Partners__c = 'All',
                Billing_Method__c = 'NMC',
                Billing_Anchors__c = 'Bluewave',
                BWC_Project_Entity_Manual__c = entity1.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Client_Brand_Key__c = null,
                Utility__c = eversource.Id
            );

        Shared_Solar_System__c sss2 =
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                Service_Territory__c = 'SEMA',
                Service_Territories__c = 'SEMA',
                Open__c = true,
                Billing_Method__c = 'kWh',
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c  = 996,
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '2',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Client_Account__c = clientAccount2.Id,
                Sales_Partners__c = 'All',
                Billing_Anchors__c = 'Bluewave',
                BWC_Project_Entity_Manual__c = entity2.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Client_Brand_Key__c = null,
                Utility__c = eversource.Id
            );

        insert new List<Shared_Solar_System__c>{sss1, sss2};


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

        Opportunity opportunityone =
            new Opportunity(Name = 'AOpp One With Long Name To Test Utility Account Subscription Bill and System Bill Lengths',
                AccountId = accountA.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                Customer_Group__c = 'Residential',
                Product__c = normalCSProduct.Id,
                CloseDate = System.today());

        Opportunity opportunitytwo =
            new Opportunity(Name = 'BOpp One',
                AccountId = accountA.Id,
                Shared_Solar_System__c = sss2.Id,
                StageName = 'Complete',
                Customer_Group__c = 'Residential',
                Product__c = normalCSProduct.Id,
                CloseDate = System.today());

        Opportunity opportunitythree =
            new Opportunity(Name = 'BOpp Two',
                AccountId = accountB.Id,
                Shared_Solar_System__c = sss2.Id,
                StageName = 'Complete',
                Customer_Group__c = 'Non-Residential',
                Product__c = normalCSProduct.Id,
                CloseDate = System.today());
        Opportunity opportunityFour;

        if (multipleOppsForSingleSystem) {
            opportunityFour =
                new Opportunity(Name = 'AOpp One With Long Name To Test Utility Account Subscription Bill and System Bill Lengths',
                    AccountId = accountA.Id,
                    Shared_Solar_System__c = sss1.Id,
                    StageName = 'Complete',
                    Customer_Group__c = 'Non-Residential',
                    Product__c = normalCSProduct.Id,
                    CloseDate = System.today());
            insert new List<Opportunity>{opportunityone, opportunitytwo, opportunitythree, opportunityFour};
        } else {
        insert new List<Opportunity>{opportunityone, opportunitytwo, opportunitythree};
        }

        Utility_Account_Subscription__c uasone =
            new Utility_Account_Subscription__c(Name = '0000234',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunityone.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 4000,
                Calculated_Annual_Cost_of_Electricity__c = 4000,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);

        Utility_Account_Subscription__c uastwo =
            new Utility_Account_Subscription__c(Name = '000-0234',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunitytwo.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 6000,
                Calculated_Annual_Cost_of_Electricity__c = 6000,
                Subscribed_Annual_Cost_of_Electricity__c = 6000);

        Utility_Account_Subscription__c uasthree =
            new Utility_Account_Subscription__c(Name = '0000237',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunityone.Id,
                Next_Schedule_Z_Status__c = 'Inactive Subscription',
                Annual_kwh_subscription_future__c = 8000,
                Calculated_Annual_Cost_of_Electricity__c = 8000,
                Subscribed_Annual_Cost_of_Electricity__c = 8000);

        Utility_Account_Subscription__c uasfour =
            new Utility_Account_Subscription__c(Name = '0000345',
                Utility_Account_Log__c = ualog2.Id,
                Opportunity__c = opportunitythree.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 6000,
                Calculated_Annual_Cost_of_Electricity__c = 6000,
                Subscribed_Annual_Cost_of_Electricity__c = 6000);

        Utility_Account_Subscription__c uasFive;
        if (multipleOppsForSingleSystem) {
            uasFive =
                new Utility_Account_Subscription__c(Name = '000-0234',
                    Utility_Account_Log__c = ualog.Id,
                    Opportunity__c = opportunityFour.Id,
                    Next_Schedule_Z_Status__c = 'Active Subscription',
                    Annual_kwh_subscription_future__c = 6000,
                    calculated_annual_cost_of_electricity__c = 6000,
                    Subscribed_Annual_Cost_of_Electricity__c = 6000);
            insert new List<Utility_Account_Subscription__c>{uasone, uastwo, uasthree, uasfour, uasFive};
        } else {
        insert new List<Utility_Account_Subscription__c>{uasone, uastwo, uasthree, uasfour};
        }

        //Changed something (not sure if it was billing number fix) and it now applies this Bill adjustment to every system bill
        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(  Name = 'UASoneAdjustment',
            Utility_Account_Subscription__c = uasOne.Id,
            Adjustment_Type__c = 'Production',
            Adjustment_Amount__c = 24,
            Credits_Allocated__c = 24,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        //Equivalent adjustment as adjustOne, but with an unnaproved status. This should be ignored by all system bills.
        Bill_Adjustment__c adjustTwo = new Bill_Adjustment__c(  Name = 'UASoneAdjustment2',
            Utility_Account_Subscription__c = uasOne.Id,
            Adjustment_Amount__c = 30,
            Approval_Status__c = 'Unapproved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        insert new List<Bill_Adjustment__c>{adjustOne, adjustTwo};

        uasone.Customer_Subscription_KW_DC_STATIC__c = 25;
        uastwo.Customer_Subscription_KW_DC_STATIC__c = 20;
        uasthree.Customer_Subscription_KW_DC_STATIC__c = 15;
        uasfour.Customer_Subscription_KW_DC_STATIC__c = 10;
        if (multipleOppsForSingleSystem) {
            uasFive.Customer_Subscription_KW_DC_STATIC__c = 25;
            update new List<Utility_Account_Subscription__c>{uasone, uastwo, uasthree, uasfour, uasFive};
        } else {
        update new List<Utility_Account_Subscription__c>{uasone, uastwo, uasthree, uasfour};
        }

        // We want to make these dates current, so that generated bills are current
        Date myDateApr = Date.newInstance(Date.today().year(), Date.today().month(), 15);
        Date myDateMar = myDateApr.addMonths(-1);
        Date myDateFeb = myDateApr.addMonths(-2);
        Date myDateJan = myDateApr.addMonths(-3);

        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Status__c = 'Billing'
        );

        Schedule_Z__c scheduleZ2 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P2',
            Shared_Solar_System__c = sss2.Id,
            Status__c = 'Billing'
        );

        insert new List<Schedule_Z__c>{scheduleZ1, scheduleZ2};

        Bill_Period__c bpA1 = new Bill_Period__c(
            Name = 'sssA - January 2016',
            Shared_Solar_System__c = sss1.Id,
            Bill_Date__c = myDateJan
        );

        Bill_Period__c bpA2 = new Bill_Period__c(
            Name = 'sssA - February 2016',
            Shared_Solar_System__c = sss1.Id,
            Bill_Date__c = myDateFeb
        );

        Bill_Period__c bpA3 = new Bill_Period__c(
            Name = 'sssA - March 2016',
            Shared_Solar_System__c = sss1.Id,
            Bill_Date__c = myDateMar
        );

        Bill_Period__c bpB1 = new Bill_Period__c(
            Name = 'sssB - January 2016',
            Shared_Solar_System__c = sss2.Id,
            Bill_Date__c = myDateJan
        );

        Bill_Period__c bpB2 = new Bill_Period__c(
            Name = 'sssB - February 2016',
            Shared_Solar_System__c = sss2.Id,
            Bill_Date__c = myDateFeb
        );

        Bill_Period__c bpB3 = new Bill_Period__c(
            Name = 'sssB - March 2016',
            Shared_Solar_System__c = sss2.Id,
            Bill_Date__c = myDateMar
        );

        insert new List<Bill_Period__c>{bpA1, bpA2, bpA3, bpB1, bpB2, bpB3};


        Production__c prodA1 = new Production__c(
            Name = 'sssA January Production',
            Shared_Solar_System__c = sss1.Id,
            Start_Date__c = myDateJan,
            End_Date__c = myDateFeb - 1,
            Production_kWh__c = 90000,
            Credits_Generated__c = 16632
        );


        Production__c prodA2 = new Production__c(
            Name = 'sssA February Production',
            Shared_Solar_System__c = sss1.Id,
            Start_Date__c = myDateFeb,
            End_Date__c = myDateMar - 1,
            Production_kWh__c = 120000,
            Credits_Generated__c = 22176
        );


        Production__c prodA3 = new Production__c(
            Name = 'sssA March Production',
            Shared_Solar_System__c = sss1.Id,
            Start_Date__c = myDateMar,
            End_Date__c = myDateApr - 1,
            Production_kWh__c = 140000,
            Credits_Generated__c = 25872
        );

        Production__c prodB1 = new Production__c(
            Name = 'sssB January Production',
            Shared_Solar_System__c = sss2.Id,
            Start_Date__c = myDateJan,
            End_Date__c = myDateFeb - 1,
            Production_kWh__c = 90000
        );

        Production__c prodB2 = new Production__c(
            Name = 'sssB February Production',
            Shared_Solar_System__c = sss2.Id,
            Start_Date__c = myDateFeb,
            End_Date__c = myDateMar - 1,
            Production_kWh__c = 120000
        );

        Production__c prodB3 = new Production__c(
            Name = 'sssB March Production',
            Shared_Solar_System__c = sss2.Id,
            Start_Date__c = myDateMar,
            End_Date__c = myDateApr - 1,
            Production_kWh__c = 102000
        );

        insert new List<Production__c>{prodA1, prodA2, prodA3, prodB1, prodB2, prodB3};


        Transfer__c transferA1 = new Transfer__c(
            Name = 'Main Transfer - sssA January',
            Bill_Period__c = bpA1.Id,
            Date_of_Transfer__c = myDateJan,
            Shared_Solar_System__c = sss1.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Attempted_kWh_Transfer__c = 90000,
            Attempted_Transfer__c = 16632,
            Transfer_Amount__c = 16632,
            Default_Credit_Value__c = 0.1848
        );

        Transfer__c transferA2 = new Transfer__c(
            Name = 'Main Transfer - sssA February',
            Bill_Period__c = bpA2.Id,
            Date_of_Transfer__c = myDateFeb,
            Shared_Solar_System__c = sss1.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Attempted_Transfer__c = 22176,
            Attempted_kWh_Transfer__c = 120000,
            Transfer_Amount__c = 22176,
            Default_Credit_Value__c = 0.1848
        );

        Transfer__c transferA3 = new Transfer__c(
            Name = 'Main Transfer - sssA March',
            Bill_Period__c = bpA3.Id,
            Date_of_Transfer__c = myDateMar,
            Shared_Solar_System__c = sss1.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Attempted_Transfer__c = 25872,
            Attempted_kWh_Transfer__c = 140000,
            Transfer_Amount__c = 25872,
            Default_Credit_Value__c = 0.1848
        );

        Transfer__c transferB1 = new Transfer__c(
            Name = 'Main Transfer - sssB January',
            Bill_Period__c = bpB1.Id,
            Date_of_Transfer__c = myDateJan,
            Shared_Solar_System__c = sss2.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ2.Id,
            Attempted_Transfer__c= 16632,
            Attempted_kWh_Transfer__c = 90000,
            Transfer_kWh__c = 90000,
            Default_Credit_Value__c = 0.1848
        );


        Transfer__c transferB2 = new Transfer__c(
            Name = 'Main Transfer - sssB February',
            Bill_Period__c = bpB2.Id,
            Date_of_Transfer__c = myDateFeb,
            Shared_Solar_System__c = sss2.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ2.Id,
            Attempted_Transfer__c = 22176,
            Attempted_kWh_Transfer__c = 120000,
            Transfer_kWh__c = 120000,
            Default_Credit_Value__c = 0.1848
        );

        Transfer__c transferB3 = new Transfer__c(
            Name = 'Main Transfer - sssB March',
            Bill_Period__c = bpB3.Id,
            Date_of_Transfer__c = myDateMar,
            Shared_Solar_System__c = sss2.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ2.Id,
            Attempted_Transfer__c = 21872,
            Attempted_kWh_Transfer__c = 102000,
            Transfer_kWh__c = 102000,
            Default_Credit_Value__c = 0.1848
        );

        insert new List<Transfer__c>{transferA1, transferA2, transferA3, transferB1, transferB2, transferB3};


        TransferPartService transferPartService = new TransferPartService();
        transferPartService.createPartsFromTransfer(new List<Transfer__c>{transferA1, transferA2, transferA3, transferB1, transferB2, transferB3});

        runBillPeriod(new List<Id>{bpA1.Id});

        setBillsToPublished();

        // As of Oct 2019, 75 of 100 queries used.
        Test.stopTest();

        runBillPeriod(new List<Id>{bpA2.Id});
    }

    public static void setBillsToPublished() {
        List <Account_Bill__c> listAccountBills = [
            SELECT Id, Published__c
            FROM Account_Bill__c
            WHERE Published__c = FALSE
        ];
        for (Account_Bill__c acctBill : listAccountBills) {
            acctBill.Published__c = True;
        }
        update listAccountBills;
    }

    public static void runBillPeriod(List<Id> billPeriodIdList) {
        List<Bill_Period__c> billPeriods = [
            SELECT Id, Name, Bill_Date__c, Shared_Solar_System__c
            FROM Bill_Period__c
            WHERE Id IN :billPeriodIdList
        ];
        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(billPeriods);
        ee.runBills();
    }

    public static void simulateBatchBillCreation(List<Transfer__c> transfers) {
        Set<Id> scheduleZs = new Set<Id>();
        Set<Id> bpIds = new Set<Id>();

        for (Transfer__c transfer : transfers) {
            scheduleZs.add(transfer.Allocation_Schedule__c);
            bpIds.add(transfer.Bill_Period__c);
        }

        List<Bill_Period__c> billPeriods = [
            SELECT Id, Name, Bill_Date__c, Shared_Solar_System__c
            FROM Bill_Period__c
            WHERE Id IN :bpIds
        ];

        List<Schedule_Z_Subscription__c> scheduleZSubs = [
            SELECT Id, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Opportunity__c
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c IN : scheduleZs
        ];

        List<Schedule_Z_Subscription__c> batch1 = new List<Schedule_Z_Subscription__c>();
        List<Schedule_Z_Subscription__c> batch2 = new List<Schedule_Z_Subscription__c>();

        Integer counter = 1;
        for (Schedule_Z_Subscription__c scheduleZSubscription : scheduleZSubs) {
            if (Math.mod(counter, 2) == 0) {
                batch1.add(scheduleZSubscription);
            } else {
                batch2.add(scheduleZSubscription);
            }
            counter += 1;
        }

        EnergyUsageUpdateTriggerHandler handler = new EnergyUsageUpdateTriggerHandler(billPeriods);

        //simulate batching in production
        handler.createBills(batch1);
        handler.createBills(batch2);
    }

    @IsTest
    public static void testPreviewBills(){
        Test.startTest();
        List<Transfer__c> transferList = [
            SELECT Id, Name, Allocation_Schedule__c, Allocation_Schedule__r.Name
            FROM Transfer__c
            ORDER BY Date_of_Transfer__c
        ];

        Account accountA = [SELECT Id, Name, Parent_Account__r.Id
        FROM Account
        WHERE Name = 'Account A'];

        String parId = accountA.Parent_Account__r.Id;
        String acctId = accountA.Id;

        System.assertEquals( 1, (PreviewProductionUpdateResults.getUASes(transferList[0].Id, true, transferList[0].Allocation_Schedule__r.Id)).size());
        System.assertEquals( 2, (PreviewProductionUpdateResults.getUASes(transferList[1].Id, true, transferList[1].Allocation_Schedule__r.Id)).size());
        System.assertEquals( 1, (PreviewProductionUpdateResults.getProperties(parId.substring(0,15), true)).size());
        System.assertEquals( 6, (PreviewProductionUpdateResults.getUASes(acctId.substring(0,15), false, null)).size());

        Transfer__c transfer = [
            SELECT Id, Name, Allocation_Schedule__r.Id, Allocation_Schedule__r.Name
            FROM Transfer__c
            WHERE Name = 'Main Transfer - sssA February'
        ];

        List<UASB__c> uasbList = PreviewProductionUpdateResults.getUASes(transfer.Id, true, transfer.Allocation_Schedule__r.Id);
        System.assertEquals(345.28, uasbList[0].PreGen_Discounted_Bill__c);
        System.assertEquals(383.64, uasbList[0].PreGen_NMCs_Allocated__c);
        Test.stopTest();
    }

    @IsTest
    public static void testRadianGenAnchorBills(){
        Test.startTest();

        Shared_Solar_System__c sssRadianGen = [
            SELECT Id, Name
            FROM Shared_Solar_System__c
            WHERE Name =  'Oxford Barrett Street. Part1 With Long Name To Test Unique Id Lengths'
        ];


        Schedule_Z__c schedZ = [
            SELECT Id, Name
            FROM Schedule_Z__c
            WHERE Name = '18-0515 Oxford Barrett St. P1'
            LIMIT 1
        ];

        Utility_Account_Log__c ualog = [
            SELECT Id
            FROM Utility_Account_Log__c
            WHERE Name = '0000234'
        ];

        //create more opps
        Opportunity opp1 = [
            SELECT Id, Name, AccountId, Shared_Solar_System__c, Product__c
            FROM Opportunity
            WHERE Name = 'AOpp One With Long Name To Test Utility Account Subscription Bill and System Bill Lengths'
        ];
        Account accountParent = [SELECT Id FROM Account WHERE Name = 'Account Parent' LIMIT 1];

        Account accountC = new Account(
            name = 'Account C',
            Parent_Account__c = accountParent.Id
        );
        insert accountC;


        Opportunity opp4 = new Opportunity(
            Name = 'Opp Four',
            AccountId = accountC.Id,
            Shared_Solar_System__c = sssRadianGen.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Anchor',
            Product__c = opp1.Product__c,
            CloseDate = System.today());

        Opportunity opp5 = new Opportunity(
            Name = 'Opp Five',
            AccountId = accountC.Id,
            Shared_Solar_System__c = sssRadianGen.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Public Offtake',
            Product__c = opp1.Product__c,
            CloseDate = System.today());

        Opportunity opp6 = new Opportunity(
            Name = 'Opp Six',
            AccountId = accountC.Id,
            Shared_Solar_System__c = sssRadianGen.Id,
            StageName = 'PPA/NMCPA Signed',
            Customer_Group__c = 'Residential',
            Product__c = opp1.Product__c,
            CloseDate = System.today());

        insert new List<Opportunity> {opp4, opp5, opp6};

        Utility_Account_Subscription__c uas4 =
            new Utility_Account_Subscription__c(Name = '0000444',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opp4.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 4000,
                Calculated_Annual_Cost_of_Electricity__c = 4000,
                Customer_Subscription_KW_DC_STATIC__c = 25,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);

        Utility_Account_Subscription__c uas5 =
            new Utility_Account_Subscription__c(Name = '0000555',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opp5.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 4000,
                Calculated_Annual_Cost_of_Electricity__c = 4000,
                Customer_Subscription_KW_DC_STATIC__c = 25,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);

        Utility_Account_Subscription__c uas6 =
            new Utility_Account_Subscription__c(Name = '0000666',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opp6.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 4000,
                Calculated_Annual_Cost_of_Electricity__c = 4000,
                Customer_Subscription_KW_DC_STATIC__c = 25,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);

        insert new List<Utility_Account_Subscription__c> {uas4, uas5, uas6};
        Set<Id> uasIds = new Set<Id> { uas4.Id, uas5.Id, uas6.Id};

        Schedule_Z__c schedZ3 = new Schedule_Z__c(
            Name = 'Z3 Oxford Barrett St. P1',
            Shared_Solar_System__c = sssRadianGen.Id,
            Status__c = 'Billing'
        );
        insert schedZ3;

        List<Schedule_Z_Subscription__c> szs = [
            SELECT Id
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c = :schedZ3.Id
        ];

        Date myDateMay = Date.newInstance(2016, 5, 5);
        Date myDateApr = Date.newInstance(2016, 4, 4);

        Production__c productionA = new Production__c(
            Name = 'sssA RadianGen April Production',
            Shared_Solar_System__c = sssRadianGen.Id,
            Production_kWh__c = 90000,
            Start_Date__c = myDateApr,
            End_Date__c = mydateMay,
            Credits_Generated__c = 16632
        );
        insert productionA;

        Bill_Period__c bpA = new Bill_Period__c(
            Name = 'sssA - RadianGen Aprl 2016',
            Shared_Solar_System__c = sssRadianGen.Id,
            Bill_Date__c = myDateApr
        );

        insert bpA;

        Transfer__c transferA = new Transfer__c(
            Name = 'Main Transfer - sssA RadianGen April 2016',
            Bill_Period__c = bpA.Id,
            Shared_Solar_System__c = sssRadianGen.Id,
            Allocation_Schedule__c = schedZ3.Id,
            Attempted_Transfer__c = 16632,
            Attempted_kWh_Transfer__c = 90000,
            Transfer_Amount__c = 16632,
            Default_Credit_Value__c = 0.1848,
            Date_of_Transfer__c = myDateApr
        );
        insert transferA;
        transferA.Transfer_Type__c = 'Main';
        update transferA;


        Transfer__c transfer = [
            SELECT Id, Bill_Period__r.Bill_Date__c, Shared_Solar_System__c
            FROM Transfer__c
            WHERE Name = 'Main Transfer - sssA RadianGen April 2016'
            LIMIT 1
        ];

        //4 Opps total: 1 Complete, 1 PPA/NMCPA, 1 Anchor, 1 Public Offtake
        //The PPA/NMCPA Signed Opp should not be showing up in Previews

        List<Utility_Account_Subscription__c> uases = [
            SELECT Id, Externally_Serviced__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Shared_Solar_System__c = :sssRadianGen.Id
            AND  Next_Schedule_Z_Status__c = 'Active Subscription'
        ];

        for (Utility_Account_Subscription__c uas : uases) {
            System.assertEquals(false, uas.Externally_Serviced__c);
        }

        System.assertEquals(3, (PreviewProductionUpdateResults.getUASes(transfer.Id, TRUE, schedZ3.Id)).size());

        sssRadianGen.Billing_Anchors__c = 'RadianGen';
        update sssRadianGen;

        List<Utility_Account_Subscription__c> uasesRG = [
            SELECT Id, Externally_Serviced__c, Opportunity__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Shared_Solar_System__c = :sssRadianGen.Id
            AND  Next_Schedule_Z_Status__c = 'Active Subscription'
        ];

        System.assertEquals(4, uasesRG.size());

        for (Utility_Account_Subscription__c uasRG : uasesRG) {
            if ( uasRG.Opportunity__c == opp6.Id || uasRG.Opportunity__c == opp1.Id) {
                System.assertEquals(false, uasRG.Externally_Serviced__c);
            } else  {
                System.assertEquals(true, uasRG.Externally_Serviced__c);
            }
        }

        //RadianGen UASBs will show up in Preview Bills but will be tagged with "Externally Serviced"
        List<UASB__c> previewUASBs = PreviewProductionUpdateResults.getUASes(transfer.Id, TRUE, schedZ3.Id);
        System.assertEquals(3, previewUASBs.size());

        runBillPeriod(new List<Id>{bpA.Id});

        List<UASB__c> uasbs = [
            SELECT Id, Opportunity__c, Externally_Serviced__c, Opportunity__r.Name
            FROM UASB__c
            WHERE Shared_Solar_System__c = :sssRadianGen.Id
        ];


        for (UASB__c uasb : uasbs) {
            if (uasb.Opportunity__c == opp4.Id) {
                // Anchor
                System.assertEquals(true, uasb.Externally_Serviced__c);
            } else if (uasb.Opportunity__c == opp5.Id){
                // Public Offtake
                System.assertEquals(true, uasb.Externally_Serviced__c);
            } else {
                // Residential
                System.assertEquals(false, uasb.Externally_Serviced__c);
            }
        }

        Test.stopTest();
    }

    @IsTest
    public static void testGetScheduleZs() {
        Test.startTest();
        Transfer__c transfer = [
            SELECT Id, Name, Shared_Solar_System__c
            FROM Transfer__c
            ORDER BY Date_of_Transfer__c
            LIMIT 1
        ];

        Schedule_Z__c scheduleZ = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = transfer.Shared_Solar_System__c,
            Status__c = 'Enacted by Utility',
            Date_Enacted_by_Utility__c = Date.today()
        );

        insert scheduleZ;

        List<Schedule_Z__c> scheduleZS = PreviewProductionUpdateResults.getScheduleZs(transfer.Id);

        System.assertEquals(2, scheduleZS.size());
        Test.stopTest();
    }

    @IsTest
    public static void testAdjustments() {
        List<Account_Bill__c> accountbilllist = [SELECT Id, Name,
            Bill_Number__c, Property_Account_ID__c
        FROM Account_Bill__c];

        Account accountA = [SELECT Id, Name
        FROM Account
        WHERE Name = 'Account A'];

        Entity__c entity = [
            SELECT Id, Gateway__c
            FROM Entity__c
            WHERE Name = 'Oxford Barrett St. P1'
        ];


        Test.startTest();

        setBillsToPublished();

        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToUpdate = new List<ChargentOrders__Transaction__c>();
        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToNotUpdate = new List<ChargentOrders__Transaction__c>();
        for (Account_Bill__c accountbill : accountbilllist) {
            if(accountbill.Bill_Number__c == 2) {
                ChargentOrders__ChargentOrder__c orderA =
                    new ChargentOrders__ChargentOrder__c(
                        Entity__c = entity.Id,
                        ChargentOrders__Billing_First_Name__c = 'Cole',
                        ChargentOrders__Billing_Last_Name__c = 'Swain',
                        ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                        ChargentOrders__Billing_Zip_Postal__c = '02467',
                        ChargentOrders__Subtotal__c = 50,
                        ChargentOrders__Payment_Method__c = 'Credit Card',
                        Account_Bill__c = accountbill.Id,
                        ChargentOrders__Card_Type__c = 'Visa',
                        ChargentOrders__Card_Number__c = '411111111111',
                        ChargentOrders__Card_Expiration_Month__c = '02',
                        ChargentOrders__Card_Expiration_Year__c = '2018',
                        ChargentOrders__Card_Last_4__c = '1111');
                insert orderA;

                ChargentOrders__Transaction__c transA =
                    new ChargentOrders__Transaction__c(ChargentOrders__Order__c = orderA.id,
                        ChargentOrders__Amount__c = 50,
                        ChargentOrders__Response_Status__c ='Approved',
                        ChargentOrders__Gateway_ID__c = entity.Gateway__c,
                        ChargentOrders__Gateway__c = entity.Gateway__c,
                        Distributed_Among_System_Bills__c = false,
                        ChargentOrders__Response_Message__c = 'OK',
                        ChargentOrders__Type__c = 'Charge',
                        ChargentOrders__Payment_Method__c = 'Credit Card',
                        Activity_Type__c = 'Payment');

                chargentOrdersTransactionsToUpdate.add(transA);

                ChargentOrders__Transaction__c transB =
                    new ChargentOrders__Transaction__c(ChargentOrders__Order__c = orderA.id,
                        ChargentOrders__Amount__c = 700,
                        ChargentOrders__Response_Status__c ='Approved',
                        ChargentOrders__Recurring__c = true,
                        ChargentOrders__Gateway_ID__c = entity.Gateway__c,
                        ChargentOrders__Gateway__c = entity.Gateway__c,
                        Distributed_Among_System_Bills__c = false,
                        ChargentOrders__Response_Message__c = 'OK',
                        ChargentOrders__Type__c = 'Charge',
                        ChargentOrders__Payment_Method__c = 'Credit Card',
                        Activity_Type__c = 'Payment');
                chargentOrdersTransactionsToNotUpdate.add(transB);
            }
        }
        // running unnecessary code
        Util.disableTrigger('Disable_ChargentOrderTrigger__c');
        insert chargentOrdersTransactionsToUpdate;
        for (ChargentOrders__Transaction__c trans : chargentOrdersTransactionsToUpdate) {
            trans.Distributed_Among_System_Bills__c = true;
        }
        update chargentOrdersTransactionsToUpdate;
        insert chargentOrdersTransactionsToNotUpdate;

        List<Account> acctList = new List<Account>();
        acctList.add(accountA);
        Zuora_Setting__mdt zuoraSetting = ZuoraAPIHelper.getZuoraSetting();

        if (zuoraSetting.Zuora_Is_Live__c){
            system.AssertEquals( 0, (PreviewProductionUpdateResults.getTransactions(acctList)).size());
        } else {
        system.AssertEquals( 2, (PreviewProductionUpdateResults.getTransactions(acctList)).size());
        }

        Test.stopTest();
    }

    @IsTest
    public static void testScheduleZStatusIsSaved() {
        Test.startTest();

        List<Transfer__c> transfers = [
            SELECT Id, Allocation_Schedule__c, Shared_Solar_System__c
            FROM Transfer__c
        ];


        for (Transfer__c transfer : transfers) {
            transfer.Allocation_Schedule__c = null;
        }

        update transfers;

        Schedule_Z__c scheduleZ = new Schedule_Z__c(
            Name = '18-0615 Oxford Barrett St. P1',
            Shared_Solar_System__c = transfers[0].Shared_Solar_System__c,
            Status__c = 'Enacted by Utility',
            Date_Enacted_by_Utility__c = Date.today()
        );

        insert scheduleZ;

        List<Schedule_Z__c> scheduleZS = PreviewProductionUpdateResults.getScheduleZs(transfers[0].Id);
        System.assertEquals(2, scheduleZS.size());
        System.assertEquals('Billing', scheduleZS[0].Status__c);
        System.assertEquals('Enacted by Utility', scheduleZS[1].Status__c);
        Schedule_Z__c previousScheduleZ = scheduleZS[1];

        PreviewProductionUpdateResults.saveAllocationScheduleToTransfer(scheduleZS[1].Id, transfers[0].Id);
        /*
        After a schedule Z is saved to a transfer, if that schedule Z's status is 'Enacted by Utility'
        then update the status to 'Billing' and change other Schedule Z statuses to 'Replaced with newly Enacted Schedule Z'
         */

        Transfer__c transfer = [
            SELECT Id, Allocation_Schedule__c, Shared_Solar_System__c
            FROM Transfer__c
            WHERE Id = :transfers[0].Id
            LIMIT 1
        ];


        System.assertEquals(scheduleZS[1].Id, transfer.Allocation_Schedule__c);

        // Only getsSchedule Zs with status of 'Billing' or 'Enacted by Utility'
        List<Schedule_Z__c> scheduleZS2 = PreviewProductionUpdateResults.getScheduleZs(transfer.Id);

        System.assertEquals(1, scheduleZS2.size());
        System.assertEquals('Billing', scheduleZS2[0].Status__c);
        System.assertNotEquals(previousScheduleZ.Status__c, scheduleZS2[0].Status__c);

        // Make sure nothing changes if schedule Z status is already 'Billing'
        Schedule_Z__c previousScheduleZ2 = scheduleZS2[0];

        PreviewProductionUpdateResults.saveAllocationScheduleToTransfer(scheduleZS2[0].Id, transfers[1].Id);

        Transfer__c transfer2 = [
            SELECT Id, Allocation_Schedule__c, Shared_Solar_System__c
            FROM Transfer__c
            WHERE Id = :transfers[0].Id
        ];

        System.assertEquals(scheduleZS[1].Id, transfer2.Allocation_Schedule__c);

        List<Schedule_Z__c> scheduleZS3 = PreviewProductionUpdateResults.getScheduleZs(transfer2.Id);

        System.assertEquals(1, scheduleZS3.size());
        System.assertEquals('Billing', scheduleZS3[0].Status__c);
        System.assertEquals(previousScheduleZ2.Status__c, scheduleZS3[0].Status__c);

        Test.stopTest();
    }
}