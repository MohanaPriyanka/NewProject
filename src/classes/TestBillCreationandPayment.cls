@isTest
public class TestBillCreationandPayment {
    @TestSetup public static void csTestRecordWarehouse() {
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
                Billing_Method__c = 'NMC',
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

        Energy_Usage_Update__c productionupdateA1 = new Energy_Usage_Update__c (
            Name = 'sssA - January 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.id,
            Production__c = 90000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateFeb,
            Total_System_NMCs__c = 16632,
            Date__c = myDateJan
        );

        Energy_Usage_Update__c productionupdateA2 = new Energy_Usage_Update__c (
            Name = 'sssA - February 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.id,
            Production__c = 120000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateMar,
            Total_System_NMCs__c = 22176,
            Date__c = myDateFeb
        );

        Energy_Usage_Update__c productionupdateA3 = new Energy_Usage_Update__c (
            Name = 'sssA - March 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.id,
            Production__c = 140000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateApr,
            Total_System_NMCs__c = 25872,
            Date__c = myDateMar
        );

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

        Energy_Usage_Update__c productionupdateB3 = new Energy_Usage_Update__c (
            Name = 'sssB - March 2016',
            Shared_Solar_System__c = sss2.id,
            Schedule_Z__c = scheduleZ2.id,
            Production__c = 102000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateApr,
            Total_System_NMCs__c = 21872,
            Date__c = myDateMar
        );
        insert new List<Energy_Usage_Update__c>{
            productionupdateA1, productionupdateA2, productionupdateA3, productionupdateB1, productionupdateB2, productionupdateB3
        };

        runProductionUpdate(new List<Id>{productionupdateA1.Id});

        InvocableCSBillOverpaymentApplication.applyOverpayments();

        setBillsToPublished();

        // As of Jan 2019, 65 of 100 queries used. Generating bills consumes 35 queries
        Test.stopTest();

        runProductionUpdate(new List<Id>{productionupdateA2.Id});
    }
    
    @IsTest
    private static void testAdjustmentRollups() {
        assertAccountTotalRollupsEqualToCalculatedTotals();

        Account accountA = [SELECT Id FROM Account WHERE Name = 'Account A'];
        List<Bill_Adjustment__c> billAdjustments = [
            SELECT Id, Credits_Allocated__c, Adjustment_Amount__c, UASB__c, Utility_Account_Subscription__c
            FROM Bill_Adjustment__c
            WHERE Utility_Account_Subscription__r.Utility_Account_Log__r.Account__c = : accountA.Id
            AND Approval_Status__c = 'Unapproved'
        ];
        System.assertEquals(1, billAdjustments.size());
        System.assertEquals(null, billAdjustments[0].Credits_Allocated__c);
        System.assertEquals(30, billAdjustments[0].Adjustment_Amount__c);
        System.assertEquals(null, billAdjustments[0].UASB__c);

        billAdjustments[0].Approval_Status__c = 'Approved';
        billAdjustments[0].Adjustment_Type__c = 'BW Credit';
        billAdjustments[0].Credits_Allocated__c = 30;
        update billAdjustments[0];

        Bill_Adjustment__c newAdjustment = new Bill_Adjustment__c(
            Utility_Account_Subscription__c = billAdjustments[0].Utility_Account_Subscription__c,
            Adjustment_Type__c = 'Production',
            Adjustment_Amount__c = 90,
            Credits_Allocated__c = 100,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Production adjustment'
        );
        insert newAdjustment;

        Test.startTest();
        // We need to create a new production update, generate bills, and publish it to get new adjustments reflected
        List<Energy_Usage_Update__c> energyUsageUpdates = [
            SELECT Id, Name, Shared_Solar_System__c, Schedule_Z__c, Production__c, Net_Metering_Rate_Applied__c,
                Billing_Period_End_Date__c, Total_System_NMCs__c, Date__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - March 2016'
        ];
        System.assertEquals(1, energyUsageUpdates.size());
        Energy_Usage_Update__c aprilEUU = energyUsageUpdates[0].clone(false);
        aprilEUU.Date__c = aprilEUU.Date__c.addMonths(1);
        insert aprilEUU;
               
        runProductionUpdate(new List<Id>{aprilEUU.Id});
        setBillsToPublished();

        billAdjustments = [
            SELECT Id, UASB__c, UASB__r.Adjustment_Amount__c, Adjustment_Amount__c
            FROM Bill_Adjustment__c
            WHERE Id IN (:billAdjustments[0].Id, :newAdjustment.Id)
        ];
        System.assertEquals(billAdjustments[0].Adjustment_Amount__c + billAdjustments[1].Adjustment_Amount__c, billAdjustments[0].UASB__r.Adjustment_Amount__c);
        assertAccountTotalRollupsEqualToCalculatedTotals();
        Test.stopTest();
    }

    private static void assertAccountTotalRollupsEqualToCalculatedTotals() {
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Name, Total_Savings__c, Total_Net_Metering_Credits_Allocated__c, Savings_Adjustments__c, Credit_Adjustments__c,
            (
                SELECT Id, Savings__c FROM System_Bills__r
            )
            FROM Account
            WHERE Total_Savings__c > 0
        ]);

        Map<Id, AccountWrapper> calculatedAccountTotalMap = getCalculatedAccountTotalsMap();
        for (Account account : accountMap.values()) {
            if (calculatedAccountTotalMap.containsKey(account.Id)) {
                System.assertEquals(calculatedAccountTotalMap.get(account.Id).totalSavings, account.Total_Savings__c + account.Savings_Adjustments__c);
                System.assertEquals(calculatedAccountTotalMap.get(account.Id).totalNMCs, account.Total_Net_Metering_Credits_Allocated__c + account.Credit_Adjustments__c);
            } else {
                System.assert(false, 'Expected all accounts with a total savings to have a calculated total too:' + account);
            }
        }
    }

    private static Map<Id, AccountWrapper> getCalculatedAccountTotalsMap() {
        List<UASB__c> uasbs = [
            SELECT Id, System_Bill__r.Account_Bill__r.Parent_Account__c, Credits_Allocated__c, Discounted_Bill__c, Savings__c,
            (
                SELECT Id, Credits_Allocated__c, Discount__c, Adjustment_Amount__c
                FROM Bill_Adjustments__r
                WHERE Adjustment_Type__c = 'Production'
            )
            FROM UASB__c
        ];

        Map<Id, AccountWrapper> accountIdToAccountMap = new Map<Id, AccountWrapper>();
        // Calculate Total Savings and Total Credits Allocated including adjustments
        for (UASB__c uasb : uasbs) {
            Decimal adjustedSavings = 0, adjustedCredits = 0;
            for (Bill_Adjustment__c billAdjustment : uasb.Bill_Adjustments__r) {
                adjustedSavings += Util.nullToZero(billAdjustment.Discount__c);
                adjustedCredits += Util.nullToZero(billAdjustment.Credits_Allocated__c);
            }

            AccountWrapper acct = accountIdToAccountMap.get(uasb.System_Bill__r.Account_Bill__r.Parent_Account__c);
            if (acct == null) {
                acct = new AccountWrapper();
                accountIdToAccountMap.put(uasb.System_Bill__r.Account_Bill__r.Parent_Account__c, acct);
            }
            acct.accountId = uasb.System_Bill__r.Account_Bill__r.Parent_Account__c;
            acct.totalSavings += uasb.Credits_Allocated__c + adjustedSavings - uasb.Discounted_Bill__c;
            acct.totalNMCs += uasb.Credits_Allocated__c + adjustedCredits;
        }
        return accountIdToAccountMap;
    }

    private class AccountWrapper {
        public Id accountId;
        public Decimal totalSavings;
        public Decimal totalNMCs;

        public AccountWrapper() {
            totalSavings = 0;
            totalNMCs = 0;
        }
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

    public static void runProductionUpdate(List<Id> prodUpdateIdList) {
        List<Energy_Usage_Update__c> trigProdUp = ProductionUpdateSelector.getAllProductionUpdatesById(prodUpdateIdList);
        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(trigProdUp);
        ee.runBills();
    }

    @isTest public static void testPreviewBills(){
        Test.startTest();
        List<Energy_Usage_Update__c> productionUpdateList = [
            SELECT Id, Name, Schedule_Z__r.Name
            FROM Energy_Usage_Update__c
            ORDER BY Date__c
        ];
        Account accountA = [SELECT Id, Name, Parent_Account__r.Id
        FROM Account
        WHERE Name = 'Account A'];

        String parId = accountA.Parent_Account__r.Id;
        String acctId = accountA.Id;
        System.assertEquals( 1, (PreviewProductionUpdateResults.getUASes(productionUpdateList[0].Id, true, productionUpdateList[0].Schedule_Z__r.Id)).size());
        System.assertEquals( 2, (PreviewProductionUpdateResults.getUASes(productionUpdateList[1].Id, true, productionUpdateList[1].Schedule_Z__r.Id)).size());
        System.assertEquals( 1, (PreviewProductionUpdateResults.getProperties(parId.substring(0,15), true)).size());
        System.assertEquals( 6, (PreviewProductionUpdateResults.getUASes(acctId.substring(0,15), false, null)).size());
        Energy_Usage_Update__c productionUpdate = [
            SELECT Id, Name,  Schedule_Z__r.Id, Schedule_Z__r.Name
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - February 2016'
        ];

        List<UASB__c> uasbList = PreviewProductionUpdateResults.getUASes(productionUpdate.Id, true, productionUpdate.Schedule_Z__r.Id);
        System.assertEquals(345.28, uasbList[0].PreGen_Discounted_Bill__c);
        System.assertEquals(383.64, uasbList[0].PreGen_NMCs_Allocated__c);
        Test.stopTest();
    }

    @IsTest public static void testRadianGenAnchorBills(){
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

        Account accountC = new Account(name = 'Account C',
            Parent_Account__c = accountParent.Id);

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

        Schedule_Z__c schedZ3 = new Schedule_Z__c(
            Name = 'Z3 Oxford Barrett St. P1',
            Shared_Solar_System__c = sssRadianGen.Id,
            Status__c = 'Billing'
        );
        insert schedZ3;

        Date myDateMay = Date.newInstance(2016, 5, 5);
        Date myDateApr = Date.newInstance(2016, 4, 4);

        Energy_Usage_Update__c prodUpdateA = new Energy_Usage_Update__c (
            Name = 'sssA RadianGen - April 2016',
            Shared_Solar_System__c = sssRadianGen.Id,
            Schedule_Z__c = schedZ3.Id,
            Production__c = 90000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateMay,
            Total_System_NMCs__c = 16632,
            Date__c = myDateApr
        );

        insert prodUpdateA;

        //Query to have Month_Number for bill generation
        Energy_Usage_Update__c prodUpdate = [
            SELECT Id, Generate_Bills__c, Month_Number__c, Date__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA RadianGen - April 2016'
        ];

        //4 Opps total: 1 Complete, 1 PPA/NMCPA, 1 Anchor, 1 Public Offtake
        //The PPA/NMCPA Signed Opp should not be showing up in Previews
        System.assertEquals(3, (PreviewProductionUpdateResults.getUASes(prodUpdate.Id, TRUE, schedZ3.Id)).size());

        sssRadianGen.Billing_Anchors__c = 'RadianGen';
        update sssRadianGen;
        System.assertEquals(1,(PreviewProductionUpdateResults.getUASes(prodUpdate.Id, TRUE, schedZ3.Id)).size());

        //Test whether bills have been generated for anchor bills
        runProductionUpdate(new List<Id>{prodUpdate.Id});

        List<System_Bill__c> systemBills1 = [
            SELECT Id, Opportunity__c, Name
            FROM System_Bill__c
            WHERE Opportunity__c = : opp1.Id
            AND Month__c = :prodUpdate.Month_Number__c
            AND CALENDAR_YEAR(Date__c) = :prodUpdate.Date__c.year()
        ];

        List<Account_Bill__c> accountBills1 = [
            SELECT Id
            FROM Account_Bill__c
            WHERE Parent_Account__c = : opp1.AccountId
            AND Month__c = :prodUpdate.Month_Number__c
            AND CALENDAR_YEAR(Date__c) = :prodUpdate.Date__c.year()
        ];

        List<System_Bill__c> systemBills4 = [
            SELECT Id, Opportunity__c
            FROM System_Bill__c
            WHERE Opportunity__c = : opp4.Id
            AND Month__c = :prodUpdate.Month_Number__c
            AND CALENDAR_YEAR(Date__c) = :prodUpdate.Date__c.year()
        ];

        List<Account_Bill__c> accountBills4 = [
            SELECT Id
            FROM Account_Bill__c
            WHERE Parent_Account__c = : opp4.AccountId
            AND Month__c = :prodUpdate.Month_Number__c
            AND CALENDAR_YEAR(Date__c) = :prodUpdate.Date__c.year()
        ];

        //Check that bills are generated for Complete Opp
        System.assertEquals(1, systemBills1.size());
        System.assertEquals(1, accountBills1.size());

        //No bills generated for Anchor Opp
        System.assertEquals(0, systemBills4.size());
        System.assertEquals(0, accountBills4.size());

        Test.stopTest();
    }

    @isTest public static void testGetScheduleZs() {
        Test.startTest();
        Energy_Usage_Update__c productionUpdate = [
            SELECT Id, Name, Shared_Solar_System__c
            FROM Energy_Usage_Update__c
            ORDER BY Date__c
            LIMIT 1
        ];

        Schedule_Z__c scheduleZ = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = productionUpdate.Shared_Solar_System__c,
            Status__c = 'Enacted by Utility',
            Date_Enacted_by_Utility__c = Date.today()
        );

        insert scheduleZ;

        List<Schedule_Z__c> scheduleZS = PreviewProductionUpdateResults.getScheduleZs(productionUpdate.id);

        System.assertEquals(2, scheduleZS.size());
        Test.stopTest();
    }

    @isTest public static void testPaymentPlan() {
        Test.startTest();
        List<System_Bill__c> systemBillList = SystemBillsSelector.selectAllSystemBills();

        List <UASB__c> uablist =
        [SELECT Id, Name, Bill_Date__c, System_Bill__r.Bill_Number__c,
            Due_Date__c, Billing_Period_End_Date__c, Utility_Account_Subscription__c
        FROM UASB__c
        ORDER BY Bill_Date__c ];

        Date threeMonthsAgo = Date.newInstance(Date.today().year(), Date.today().month()-3, 15);
        Date twoMonthsAgo = threeMonthsAgo.addMonths(1);
        Date lastMonth = threeMonthsAgo.addMonths(2);

        for (UASB__c uabill : uablist) {
            if (uabill.System_Bill__r.Bill_Number__c == 1){
                System.assertEquals(twoMonthsAgo, uabill.Billing_Period_End_Date__c);
            }
            if (uabill.System_Bill__r.Bill_Number__c == 2){
                System.assertEquals(lastMonth, uabill.Billing_Period_End_Date__c);
            }
        }

        String acctId = systemBillList[1].Property_Account_ID__c;
        System.assertEquals(6, (PreviewProductionUpdateResults.getUASes(acctId, false, null)).size());

        systemBillList[1].Waive_Late_Fees__c = true;
        systemBillList[1].Distribute_This_Balance_as_Payment_Plan__c = true;
        update systemBillList[1];

        List<Account_Bill__c> abList = new List<Account_Bill__c>();
        List<System_Bill__c> sbstoupdate = new List<System_Bill__c>();

        for (Integer j = 3; j < 10 ; j++) {
            Boolean latefee = FALSE;
            Boolean published = TRUE;

            if (j==5) {
                latefee = TRUE;
            } else if (j==9) {
                published = FALSE;
            }

            Account_Bill__c accBillThree =
                new Account_Bill__c (Bill_Number__c = j,
                    Parent_Account__c = systemBillList[1].Property_Account_Id__c,
                    Name = 'First Last Month 2016' + j,
                    Published__c = false,
                    Reason_For_Unpublish__c = 'test run reason for unpublishing bill',
                    Unique_ID__c = '000111000111000111FAS' + j );
            insert accBillThree;
            if (published) {
                abList.add(accBillThree);
            }
            System_Bill__c billThree =
                new System_Bill__c (Shared_Solar_System__c = systemBillList[1].Shared_Solar_System_Id__c,
                    Shared_Solar_System_ID2__c = systemBillList[1].Shared_Solar_System_Id__c,
                    Bill_Number__c = j,
                    Opportunity__c = systemBillList[1].Opportunity__r.Id,
                    Account_Bill__c = accBillThree.id,
                    Property_Account__c = systemBillList[1].Property_Account_Id__c,
                    Waive_Late_Fees__c = latefee,
                    Name = 'First Last March 2016' + j,
                    Unique_ID__c = '000111000111000111FAS' + j);
            sbstoupdate.add(billThree);
        }

        insert sbstoupdate;

        for (Account_Bill__c abToPub : abList){
            abToPub.Published__c = true;
        }
        update abList;

        List<System_Bill__c> updatedsystemBillList = SystemBillsSelector.selectAllSystemBills();

        System.assertEquals(9, updatedsystemBillList.size());
        for (System_Bill__c sbs : updatedsystemBillList) {
            if (sbs.Bill_Number__c == 2) {
                System.assertEquals(628.24, sbs.Payment_Plan_Balance_to_Distribute__c);
            } else if (sbs.Bill_Number__c >= 3 && sbs.Bill_Number__c <= 7) {
                System.assertEquals(104.71, sbs.Payment_Plan_Balance__c);
            } else if (sbs.Bill_Number__c == 8) {
                System.assertEquals(104.69, sbs.Payment_Plan_Balance__c);
            } else if (sbs.Bill_Number__c == 9) {
                System.assertEquals(0, sbs.Payment_Plan_Balance__c);
            }
        }
        Test.stopTest();
    }

    @isTest public static void testSystemBills() {
        Test.startTest();
        List<System_Bill__c> systemBillList = SystemBillsSelector.selectAllSystemBills();

        // Month 1 [0]: 258.96 (due this month) + 24 (adjust) = 282.96 (total due)
        // Month 2 [1]: 345.28 (due this month) + 282.96 (previous overdue) + 2.83 (late fees) = 631.07 (total due)
        // Waiving late fees --> Month 2 [1]: 345.28 (due this month) + 282.96 (previous overdue) = 628.24 (total due)
        System.assertEquals(282.96,systemBillList[0].Total_Due__c);
        System.assertEquals(628.24, systemBillList[1].Total_Due__c);
        System.assertEquals(258.96,systembillList[0].Due_This_Month__c);
        System.assertEquals(345.28,systembillList[1].Due_This_Month__c);
        System.assertEquals(24,systembillList[0].Adjustments_UASB__c);
        System.assertEquals(0,systembillList[1].Adjustments_UASB__c);
        System.assertEquals(24,systembillList[0].Balance_Adjustment__c);
        System.assertEquals(0,systembillList[1].Balance_Adjustment__c);
        System.assertEquals(0,systembillList[1].Previous_Overpayment__c);

        // If NOT waiving late fees:
        //System.assertEquals(631.07,systembillList[1].Total_Due__c);

        Test.stopTest();
    }

    @isTest public static void publishedBillsUnEditable() {
        Test.startTest();
        setBillsToPublished();

        List<System_Bill__c> systemBillList = SystemBillsSelector.selectAllSystemBills('Account_Bill__r.Published__c = TRUE', null);

        // Month 1 [0]: 258.96 (due this month) + 24 (adjust) = 282.96 (total due)
        // Month 2 [1]: 345.28 (due this month) + 282.96 (previous overdue) + 2.83 (late fees) = 631.07 (total due)
        // Waiving late fees --> Month 2 [1]: 345.28 (due this month) + 282.96 (previous overdue) = 628.24 (total due)
        // If NOT waiving late fees:
        // System.assertEquals(631.07,systemBillList[1].Total_Due__c);
        // System.assertEquals(2.83,systemBillList[1].Late_Fees__c);
        System.assertEquals(282.96,systemBillList[0].Total_Due__c);
        System.assertEquals(628.24,systemBillList[1].Total_Due__c);
        System.assertEquals(0,systemBillList[0].Late_Fees__c);
        System.assertEquals(0,systemBillList[1].Late_Fees__c);
        System.assertEquals(258.96,systemBillList[0].Due_This_Month__c);
        System.assertEquals(345.28,systemBillList[1].Due_This_Month__c);
        System.assertEquals(0,systemBillList[1].Total_Payments_This_Month__c);

        // This should work without throwing an error
        systemBillList[1].Total_Payments_This_Month__c = 200;
        update systemBillList[1];

        systemBillList[1].Waive_Late_Fees__c = false;
        systemBillList[1].Total_Payments_This_Month__c = 200;

        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='API Only'];
        String orgId = UserInfo.getOrganizationId();
        String dateString =
            String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random()));
        String uniqueName = orgId + dateString + randomInt;
        User userRecord = new User(
            FirstName = 'User With',
            LastName ='System Bill Edit',
            Alias = 'xxx234',
            Email = 'user@bluewavesolar.com',
            EmailEncodingKey ='UTF-8',
            LanguageLocaleKey ='en_US',
            LocaleSidKey ='en_US',
            ProfileId = profileRecord.Id,
            Country ='United States',
            IsActive = true,
            TimeZoneSidKey='America/Los_Angeles',
            Username=uniqueName+'@'+ uniqueName +'.com');

        System.runAs(userRecord) {
            Boolean hitError = false;
            try {
                update systemBillList[1];
            } catch (DmlException dmx) {
                System.assert(dmx.getMessage().contains('Cannot update Late Fees'),
                    'System Bill Late Fees validation failed, got this instead: ' + dmx.getMessage());
                hitError = true;
            }
            System.assert(hitError, 'Should have hit validation \'Cannot update Late Fees on an already published bill\', but didn\'t');

            systemBillList[1].Due_This_Month__c = 0;
            systemBillList[1].Total_Payments_This_Month__c = 200;
            hitError = false;
            try {
                update systemBillList[1];
            } catch (DmlException dmx) {
                System.assert(dmx.getMessage().contains('Cannot update Due This Month'),
                    'System Bill Due This Month validation failed, got this instead: ' + dmx.getMessage());
                hitError = true;
            }
            System.assert(hitError, 'Should have hit validation \'Cannot update Due This Month on an already published bill\' but didn\'t');

            List<System_Bill__c> updatedSBs = SystemBillsSelector.selectAllSystemBills('Account_Bill__r.Published__c = TRUE', null);

            // Bill fields should NOT change:
            System.assertEquals(282.96,updatedSBs[0].Total_Due__c);
            System.assertEquals(628.24,updatedSBs[1].Total_Due__c);
            System.assertEquals(0,updatedSBs[0].Late_Fees__c);
            System.assertEquals(0,updatedSBs[1].Late_Fees__c);
            System.assertEquals(258.96,updatedSBs[0].Due_This_Month__c);
            System.assertEquals(345.28,updatedSBs[1].Due_This_Month__c);

            //If NOT waiving late fees:
            //System.assertEquals(2.83,updatedSBs[1].Late_Fees__c);
            //System.assertEquals(631.07,updatedSBs[1].Total_Due__c);

            // Total payments should change:
            System.assertEquals(200,updatedSBs[1].Total_Payments_This_Month__c);
        }

        Test.stopTest();
    }

    @isTest public static void overpaymentMultipleSBSameEntity(){
        Entity__c entity = [
            SELECT Id, Gateway__c, Client_Account__r.Id
            FROM Entity__c
            WHERE Name = 'Oxford Barrett St. P1'
        ];

        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Name,
                BWC_Project_Entity_Manual__c
            FROM Shared_Solar_System__c];

        // Want to test when a customer has 2 SBs for the same entity in a bill period
        sssList[0].BWC_Project_Entity_Manual__c = entity.Id;
        sssList[0].Client_Account__c = entity.Client_Account__r.Id;
        sssList[1].BWC_Project_Entity_Manual__c = entity.Id;
        sssList[1].Client_Account__c = entity.Client_Account__r.Id;
        update sssList;

        Util.disableTrigger('Disable_AccountBillTrigger__c'); // TO Avoid SOQL Limits in data setup

        List<Energy_Usage_Update__c> productionUpdates = [
            SELECT Id, Generate_Bills__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - March 2016'
            OR Name = 'sssB - February 2016'
            OR Name = 'sssB - January 2016'
            OR Name = 'sssB - March 2016'
            ORDER BY Name
        ];

        // Second project comes on in second month:
        runProductionUpdate(new List<Id>{productionUpdates[1].Id});
        setBillsToPublished();

        List<System_Bill__c> systemBillList = SystemBillsSelector.selectAllSystemBills(null, 'Opportunity__r.Name, Bill_Number__c');

        System.assertEquals(4,systemBillList.size());

        // [0] Month 1 - SSS1 - Opp1: 258.96 (due this month) + 24 (adjust) = 282.96 (total due)
        System.assertEquals(282.96, systemBillList[0].Total_Due__c);

        // [1] Month 2 - SSS1 - Opp1: 345.28 (due this month) + 282.96 (previous overdue) = 628.24 (total due)
        // [2] Month 2 - SSS2 - Opp3: 275.43 (due this month) = 275.43 (total due)
        // [3] Month 2 - SSS2 - Opp2: 137.71 (due this month) = 137.71 (total due)
        System.assertEquals(628.24, systemBillList[1].Total_Due__c);
        System.assertEquals(275.43,systemBillList[2].Total_Due__c);
        System.assertEquals(137.71,systemBillList[3].Total_Due__c);

        System.assertEquals(1,systemBillList[0].Bill_Number__c);
        System.assertEquals(2, systemBillList[1].Bill_Number__c);
        System.assertEquals(1,systemBillList[2].Bill_Number__c);
        System.assertEquals(1, systemBillList[3].Bill_Number__c);

        System.assertEquals(0,systembillList[0].Previous_Overpayment__c);
        System.assertEquals(0,systembillList[1].Previous_Overpayment__c);
        System.assertEquals(0,systembillList[2].Previous_Overpayment__c);
        System.assertEquals(0,systembillList[3].Previous_Overpayment__c);

        ChargentOrders__ChargentOrder__c orderA =
            new ChargentOrders__ChargentOrder__c(
                Entity__c = entity.Id,
                ChargentOrders__Billing_First_Name__c = 'Cole',
                ChargentOrders__Billing_Last_Name__c = 'Swain',
                ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                ChargentOrders__Billing_Zip_Postal__c = '02467',
                ChargentOrders__Subtotal__c = 50,
                ChargentOrders__Payment_Method__c = 'Credit Card',
                Account_Bill__c = systemBillList[1].Account_Bill__r.Id,
                ChargentOrders__Card_Type__c = 'Visa',
                ChargentOrders__Card_Number__c = '411111111111',
                ChargentOrders__Card_Expiration_Month__c = '02',
                ChargentOrders__Card_Expiration_Year__c = '2018',
                ChargentOrders__Card_Last_4__c = '1111');
        insert orderA;

        ChargentOrders__Transaction__c transA =
            new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = orderA.id,
                ChargentOrders__Amount__c = systemBillList[1].Account_Bill__r.Total_Due__c + 120,
                ChargentOrders__Response_Status__c ='Approved',
                ChargentOrders__Gateway_ID__c = entity.Gateway__c,
                ChargentOrders__Gateway__c = entity.Gateway__c,
                Distributed_Among_System_Bills__c = false,
                ChargentOrders__Response_Message__c = 'OK',
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Payment_Method__c = 'Credit Card',
                Activity_Type__c = 'Payment');
        insert transA;

        transA.Distributed_Among_System_Bills__c = true;
        update transA;

        Test.startTest();

        List<Overpayment__c> overpayList = [
            SELECT Id, Name, Overpayment_Amount__c
            FROM Overpayment__c];

        System.assertEquals(1, overpayList.size());
        System.assertEquals(120.00, overpayList[0].Overpayment_Amount__c);

        // New Bills are generated for SSS1 & SSS2:
        runProductionUpdate(new List<Id>{productionUpdates[0].Id});
        runProductionUpdate(new List<Id>{productionUpdates[3].Id});

        Util.enableTrigger('Disable_AccountBillTrigger__c');

        InvocableCSBillOverpaymentApplication.applyOverpayments();

        List<AggregateResult> sbListUpdated = [
            SELECT SUM(Previous_Overpayment__c) sumOverpay,
                MIN(Previous_Overpayment__c) minOverpay,
                MAX(Previous_Overpayment__c) maxOverpay
            FROM System_Bill__c];

        System.assertEquals(-120.00,  (Decimal)sbListUpdated[0].get('sumOverpay'));
        System.assertEquals(-120.00, (Decimal)sbListUpdated[0].get('minOverpay'));
        System.assertEquals(0.00, (Decimal)sbListUpdated[0].get('maxOverpay'));

        Test.stopTest();
    }

    @isTest public static void testAdjustments() {
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
        system.AssertEquals( 2, (PreviewProductionUpdateResults.getTransactions(acctList)).size());

        List<Overpayment__c> overpayList = [  SELECT Id, Name,
            Overpayment_Amount__c
        FROM Overpayment__c];

        System.assertEquals(1, overpayList.size());
        System.assertEquals(121.76, overpayList[0].Overpayment_Amount__c);

        // If NOT waiving late fees: -2.83
        //System.assertEquals(-118.93, adjustList[0].Adjustment_Amount__c);

        List<Adjustment_Application__c> adjustApp = [SELECT Id, Name, Bill_Adjustment__c, System_Bill__c,
            Overpayment_Amount__c, Adjustment_Amount__c,
            Bill_Adjustment__r.Outstanding__c,
            Bill_Adjustment__r.Overpayment__c
        FROM Adjustment_Application__c];
        System.assertEquals(1, adjustApp.size());
        System.assertEquals(0, adjustApp[0].Bill_Adjustment__r.Outstanding__c);

        List<System_Bill__c> updatedsystemBillListOne = SystemBillsSelector.selectAllSystemBills();

        System.assertEquals(282.96, updatedsystemBillListOne[0].Total_Due__c);
        System.assertEquals(282.96, updatedsystemBillListOne[0].Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Total_Payments_This_Month__c);
        System.Assert(updatedsystemBillListOne[1].Total_Due__c > 0);
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Payments__c );
        System.assertEquals(628.24, updatedsystemBillListOne[1].Total_Payments_This_Month__c );


        // If NOT waiving late fees:
        // System.AssertNotEquals(0, updatedsystemBillListOne[1].Late_Fees__c );
        // System.assertEquals(631.07, updatedsystemBillListOne[1].Total_Payments_This_Month__c );

        Test.stopTest();
    }

    @isTest public static void testAdjustments2() {
        Test.startTest();

        List<Account_Bill__c> accountbilllist = [SELECT Id, Name,
            Bill_Number__c, Property_Account_ID__c
        FROM Account_Bill__c];

        Entity__c entity = [
            SELECT Id, Gateway__c
            FROM Entity__c
            WHERE Name = 'Oxford Barrett St. P1'
        ];

        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToUpdate = new List<ChargentOrders__Transaction__c>();
        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToNotUpdate = new List<ChargentOrders__Transaction__c>();
        for (Account_Bill__c accountbill : accountbilllist) {
            if(accountbill.Bill_Number__c == 2) {
                ChargentOrders__ChargentOrder__c orderA =
                    new ChargentOrders__ChargentOrder__c(
                        Entity__c = entity.Id,
                        ChargentOrders__Gateway__c = entity.Gateway__c,
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

        Energy_Usage_Update__c prodUpdate = [SELECT Id, Name, Generate_Bills__c FROM Energy_Usage_Update__c WHERE Name = 'sssA - March 2016'];
        runProductionUpdate(new List<Id>{prodUpdate.Id});

        InvocableCSBillOverpaymentApplication.applyOverpayments();

        Test.stopTest();

        List<Overpayment_Application__c> secondOverpay =   [SELECT Id, Name, Overpayment__c, System_Bill__c,
            Overpayment_Amount__c
        FROM Overpayment_Application__c];
        System.assertEquals(1, secondOverpay.size());
        System.assertEquals(-121.76, secondOverpay[0].Overpayment_Amount__c);

        List<System_Bill__c> updatedsystemBillList = SystemBillsSelector.selectAllSystemBills();

        // Waiving late fees
        System.assertEquals(281.07, updatedsystemBillList[2].Total_Due__c );
        System.assertEquals(281.07, updatedsystemBillList[2].Balance_Net_late_Payments__c );
        System.assertEquals(-121.76, updatedsystemBillList[2].Previous_Overpayment__c );
        System.assertEquals(0, updatedsystemBillList[2].Adjustments_UASB__c );
    }

    @isTest public static void testMultipleEntities() {
        Test.startTest();
        List<Opportunity> oppSSS2 = [SELECT Id, Name, Shared_Solar_System__c, AccountId FROM Opportunity ORDER BY Name];

        Account_Bill__c acctBillToInsert = new Account_Bill__c (Bill_Number__c = 10,
            Parent_Account__c = oppSSS2[0].AccountId,
            Name = 'First Last Month 2016 B',
            Published__c = false,
            Reason_For_Unpublish__c = 'test run reason for unpublishing bill',
            Unique_ID__c = '0001110001110022222AS');
        insert acctBillToInsert;

        System_Bill__c sysBillToInsert = new System_Bill__c (Opportunity__c = oppSSS2[0].Id,
            Shared_Solar_System__c = oppSSS2[0].Shared_Solar_System__c,
            Shared_Solar_System_ID2__c = oppSSS2[0].Shared_Solar_System__c,
            Bill_Number__c = 10,
            Account_Bill__c = acctBillToInsert.id,
            Property_Account__c = oppSSS2[0].AccountId,
            Name = 'First Last March 2016 B',
            Unique_ID__c = '0001110001222211FAS');
        insert sysBillToInsert;

        System_Bill__c sysBillToInsertTwo = new System_Bill__c (Opportunity__c = oppSSS2[1].Id,
            Shared_Solar_System__c = oppSSS2[1].Shared_Solar_System__c,
            Shared_Solar_System_ID2__c = oppSSS2[1].Shared_Solar_System__c,
            Bill_Number__c = 10,
            Account_Bill__c = acctBillToInsert.id,
            Property_Account__c = oppSSS2[1].AccountId,
            Name = 'First Last March 2016 B',
            Unique_ID__c = '0001110001222222FAS');
        insert sysBillToInsertTwo;

        acctBillToInsert.Published__c = true;
        update acctBillToInsert;

        Account propertyAccount = [ SELECT Id, Name, Client_Brand_Key__c
        FROM Account
        WHERE Name = 'Account A'];

        System.assertEquals('AmpBlack', propertyAccount.Client_Brand_Key__c);
        Test.stopTest();

    }

    @isTest public static void testOnlinePayment(){
        List<SObject> chOrderList = new List<SObject>();
        User userA = [  SELECT Id
        FROM User
        WHERE Username='testBillCreationandPay@bluewavesolar.com'];

        Account accountA = [SELECT Id, Name
        FROM Account
        WHERE Name = 'Account A'];
        Test.StartTest();

        setBillsToPublished();

        System.runAs(userA){
            List<AggregateResult> systemBills = MyAccountController.getSystemBills(accountA.Id);
            for (AggregateResult lineItem : systemBills) {
                ChargentOrders__ChargentOrder__c billsToCharge = new ChargentOrders__ChargentOrder__c(
                    Account_Bill__c = (Id)lineItem.get('Account_Bill__c'),
                    ChargentOrders__Subtotal__c = (Decimal)lineItem.get('ChargentOrders__Subtotal__c'),
                    Entity__c = (String)lineItem.get('Entity__c'));
                chOrderList.add(billsToCharge);
            }
            System.assertEquals(1, chOrderList.size());
            ChargentOrders__ChargentOrder__c paymentInfoACH =
                new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Payment_Method__c = 'Check',
                    ChargentOrders__Bank_Name__c = 'Bank of America',
                    ChargentOrders__Bank_Routing_Number__c = '123456789',
                    ChargentOrders__Bank_Account_Type__c = 'Checking',
                    ChargentOrders__Bank_Account_Number__c = '123456533',
                    ChargentOrders__Bank_Account_Name__c = 'Jordan Testcase',
                    ChargentOrders__Card_Type__c = '',
                    ChargentOrders__Card_Number__c = '',
                    ChargentOrders__Card_Expiration_Month__c = '',
                    ChargentOrders__Card_Expiration_Year__c = '',
                    ChargentOrders__Billing_Address__c = '',
                    ChargentOrders__Billing_City__c = '',
                    ChargentOrders__Billing_State__c = '',
                    ChargentOrders__Billing_Zip_Postal__c  = '',
                    ChargentOrders__Billing_First_Name__c = '',
                    ChargentOrders__Billing_Last_Name__c = '');

            ChargentOrders__ChargentOrder__c paymentInfoCC =
                new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    ChargentOrders__Bank_Name__c = '',
                    ChargentOrders__Bank_Routing_Number__c = '',
                    ChargentOrders__Bank_Account_Type__c = '',
                    ChargentOrders__Bank_Account_Number__c = '',
                    ChargentOrders__Bank_Account_Name__c = '',
                    ChargentOrders__Card_Number__c = '111111111',
                    ChargentOrders__Card_Expiration_Month__c = '02',
                    ChargentOrders__Card_Expiration_Year__c = '2020',
                    ChargentOrders__Billing_Address__c = '200 Street',
                    ChargentOrders__Billing_City__c = 'City',
                    ChargentOrders__Billing_State__c = 'MA',
                    ChargentOrders__Billing_Zip_Postal__c  = '02114',
                    ChargentOrders__Billing_First_Name__c = 'Jordan',
                    ChargentOrders__Billing_Last_Name__c = 'Testcase');
            List<String> getStatesList = CreateOrderandPaymentRequest.getStates();
            List<ChargentOrders__ChargentOrder__c> resultOne = CreateOrderandPaymentRequest.setChargeAmountAndInsert(chOrderList, paymentInfoACH, false);
            List<ChargentOrders__ChargentOrder__c> resultTwo = CreateOrderandPaymentRequest.setChargeAmountAndInsert(chOrderList, paymentInfoCC, true);

            List<ChargentOrders__ChargentOrder__c> newOrders = [
                SELECT Id, Name, ChargentOrders__Subtotal__c, ChargentOrders__Shipping_Name__c, Entity__c,
                    Account_Bill__c, ChargentOrders__Bank_Name__c, ChargentOrders__Card_Expiration_Year__c
                FROM ChargentOrders__ChargentOrder__c
                ORDER BY ChargentOrders__Payment_Method__c
            ];
            System.assertEquals(50, getStatesList.size());

            // Checking that the orders were inserted and that the merged data mapped correctly:
            System.assertEquals(2, newOrders.size());
            System.assertNotEquals(null, newOrders[0].Account_Bill__c);
            System.assertNotEquals(null, newOrders[1].Account_Bill__c);

            System.assertEquals(628.24, newOrders[0].ChargentOrders__Subtotal__c);
            System.assertEquals(628.24, newOrders[1].ChargentOrders__Subtotal__c);
            System.assertEquals('2020', newOrders[0].ChargentOrders__Card_Expiration_Year__c);
            System.assertEquals('Bank of America', newOrders[1].ChargentOrders__Bank_Name__c);

            // If NOT waiving late fees
            // System.assertEquals(631.07, newOrders[0].ChargentOrders__Subtotal__c);
            // System.assertEquals(631.07, newOrders[1].ChargentOrders__Subtotal__c);

            String chargeResultOne = CreateOrderandPaymentRequest.chargeOrder(resultOne[0]);
            String chargeResultTwo = CreateOrderandPaymentRequest.chargeOrder(resultTwo[0]);

            System.assertEquals('Approved', chargeResultOne.right(8));
            System.assertEquals('Approved', chargeResultTwo.right(8));

            List<ChargentOrders__Transaction__c> newTransactions = [SELECT Id, Distributed_Among_System_Bills__c,
                ChargentOrders__Order__r.ChargentOrders__Payment_Status__c
            FROM ChargentOrders__Transaction__c
            ORDER BY ChargentOrders__Order__r.ChargentOrders__Payment_Method__c];

            System.assertEquals(2,newTransactions.size());

            Boolean resultThree = CreateOrderandPaymentRequest.processingPostSubmit(new List<Id>{newTransactions[0].Id});
            Boolean resultFour = CreateOrderandPaymentRequest.processingPostSubmit(new List<Id>{newTransactions[1].Id});

            List<ChargentOrders__Transaction__c> updatedTransactions = [SELECT Id, Distributed_Among_System_Bills__c,
                ChargentOrders__Order__r.ChargentOrders__Payment_Status__c,
                Property_Account_ID__c
            FROM ChargentOrders__Transaction__c
            ORDER BY ChargentOrders__Order__r.ChargentOrders__Payment_Method__c];

            System.assertEquals('Recurring', updatedTransactions[0].ChargentOrders__Order__r.ChargentOrders__Payment_Status__c);
            System.assertNotEquals('Recurring', updatedTransactions[1].ChargentOrders__Order__r.ChargentOrders__Payment_Status__c);
        }
        Test.StopTest();

    }

    @IsTest public static void testCreditCardFailures(){
        List<SObject> chOrderList = new List<SObject>();
        User userA = [SELECT Id FROM User WHERE Username='testBillCreationandPay@bluewavesolar.com'];
        Account accountA = [SELECT Id, Name FROM Account WHERE Name = 'Account A'];

        Test.startTest();

        setBillsToPublished();

        System.runAs(userA){
            List<AggregateResult> systemBills = MyAccountController.getSystemBills(accountA.Id);
            for (AggregateResult lineItem : systemBills) {
                ChargentOrders__ChargentOrder__c billsToCharge = new ChargentOrders__ChargentOrder__c(
                    Account_Bill__c = (Id)lineItem.get('Account_Bill__c'),
                    ChargentOrders__Subtotal__c = (Decimal)lineItem.get('ChargentOrders__Subtotal__c'),
                    Entity__c = (String)lineItem.get('Entity__c'));
                chOrderList.add(billsToCharge);
            }
            System.assertEquals(1, chOrderList.size());
            ChargentOrders__ChargentOrder__c paymentInfoCCTooLong =
                new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    ChargentOrders__Bank_Name__c = '',
                    ChargentOrders__Bank_Routing_Number__c = '',
                    ChargentOrders__Bank_Account_Type__c = '',
                    ChargentOrders__Bank_Account_Number__c = '',
                    ChargentOrders__Bank_Account_Name__c = '',
                    ChargentOrders__Card_Number__c = '12345678901234567',
                    ChargentOrders__Card_Expiration_Month__c = '02',
                    ChargentOrders__Card_Expiration_Year__c = '2020',
                    ChargentOrders__Card_Type__c = 'Master Card',
                    ChargentOrders__Billing_Address__c = '200 Street',
                    ChargentOrders__Billing_City__c = 'City',
                    ChargentOrders__Billing_State__c = 'MA',
                    ChargentOrders__Billing_Zip_Postal__c  = '02114',
                    ChargentOrders__Billing_First_Name__c = 'Jordan',
                    ChargentOrders__Billing_Last_Name__c = 'Testcase');

            ChargentOrders__ChargentOrder__c paymentInfoCSCTooLong =
                new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    ChargentOrders__Bank_Name__c = '',
                    ChargentOrders__Bank_Routing_Number__c = '',
                    ChargentOrders__Bank_Account_Type__c = '',
                    ChargentOrders__Bank_Account_Number__c = '',
                    ChargentOrders__Bank_Account_Name__c = '',
                    ChargentOrders__Card_Number__c = '123456789012345',
                    ChargentOrders__Card_Expiration_Month__c = '02',
                    ChargentOrders__Card_Expiration_Year__c = '2020',
                    ChargentOrders__Card_Type__c = 'Mastercard',
                    ChargentOrders__Billing_Address__c = '200 Street',
                    ChargentOrders__Billing_City__c = 'City',
                    ChargentOrders__Billing_State__c = 'MA',
                    ChargentOrders__Billing_Zip_Postal__c  = '02114',
                    ChargentOrders__Billing_First_Name__c = 'Jordan',
                    ChargentOrders__Billing_Last_Name__c = 'Testcase');

            Boolean caughtException = false;
            try {
                CreateOrderandPaymentRequest.setChargeAmountAndInsert(chOrderList, paymentInfoCCTooLong, true);
            } catch (AuraHandledException ahe) {
                caughtException = true;
            }
            // We should catch credit cards that are too long and throw an AHE for the lighting component to handle
            System.assertEquals(true, caughtException);
        }
        Test.stopTest();
    }

    @isTest public static void testMultipleAdjustments() {
        Test.startTest();
        Account accountA = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Account A'
        ];
        List<Account_Bill__c> accountbilllist = [
            SELECT Id, Name, Bill_Number__c, Property_Account_ID__c
            FROM Account_Bill__c
        ];
        Utility_Account_Subscription__c uas = [
            SELECT Id
            FROM Utility_Account_Subscription__c
            WHERE Utility_Account_Log__r.Account__c = : accountA.Id
            AND Name = '0000234'
            Limit 1
        ];

        Entity__c entity = [
            SELECT Id, Gateway__c
            FROM Entity__c
            WHERE Name = 'Oxford Barrett St. P1'
        ];

        List<Bill_Adjustment__c> newBillAdjustments = new List<Bill_Adjustment__c>();
        List<Overpayment__c> newOverpayments = new List<Overpayment__c>();

        for (Account_Bill__c accountbill : accountbilllist) {
            if(accountbill.Bill_Number__c == 2) {
                Overpayment__c overpayment1 = new Overpayment__c(
                    Overpayment_Amount__c = 1000,
                    Account_Bill__c = accountbill.Id,
                    Entity__c = entity.Id
                );
                newOverpayments.add(overpayment1);

                Overpayment__c overpayment2 = new Overpayment__c(
                    Overpayment_Amount__c = 100,
                    Account_Bill__c = accountbill.Id,
                    Entity__c = entity.Id
                );
                newOverpayments.add(overpayment2);

                Bill_Adjustment__c adjustment1 = new Bill_Adjustment__c(
                    Name = 'Returned Payment 1',
                    Adjustment_Amount__c = 50,
                    Credits_Allocated__c = 50,
                    Adjustment_Type__c = 'Production',
                    Utility_Account_Subscription__c = uas.Id,
                    Approval_Status__c = 'Approved',
                    Reason_For_Adjustment__c = 'Test'
                );
                newBillAdjustments.add(adjustment1);

                Bill_Adjustment__c adjustment2 = new Bill_Adjustment__c(
                    Name = 'Returned Payment 2',
                    Adjustment_Amount__c = 5,
                    Credits_Allocated__c = 5,
                    Adjustment_Type__c = 'Production',
                    Utility_Account_Subscription__c = uas.Id,
                    Approval_Status__c = 'Approved',
                    Reason_For_Adjustment__c = 'Test'
                );
                newBillAdjustments.add(adjustment2);
            }
        }

        insert newBillAdjustments;
        insert newOverpayments;

        List<Overpayment__c> overpayList = [
            SELECT Id, Name, Account_Bill__c,
                Entity__r.Id,
                Account_Bill__r.Bill_Number__c,
                Account_Bill__r.Property_Account_ID__c,
                Outstanding__c
            FROM Overpayment__c
            WHERE Outstanding__c != 0
            ORDER BY Overpayment_Amount__c
        ];

        System.assertEquals(2, overpayList.size());
        for (Overpayment__c billAdjustment : overpayList) {
            System.assertNotEquals(0, billAdjustment.Outstanding__c);
        }

        Energy_Usage_Update__c prodUpdate = [
            SELECT Id, Name, Generate_Bills__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - March 2016'
        ];

        runProductionUpdate(new List<Id>{prodUpdate.Id});

        List<System_Bill__c> originalSystemBillList = SystemBillsSelector.selectAllSystemBills();

        OverpaymentApplication.triggerApplication();
        Test.stopTest();

        List<System_Bill__c> updatedSystemBillList = SystemBillsSelector.selectAllSystemBills();

        // don't apply overpayments to already published bills
        System.assertEquals(true, originalSystemBillList[0].Account_Bill__r.Published__c);
        System.assertEquals(updatedSystemBillList[0].Id, originalSystemBillList[0].Id);
        System.assertEquals(1, updatedSystemBillList[0].Bill_Number__c);
        System.assertEquals(0, updatedSystemBillList[0].Previous_Overpayment__c );
        System.assertEquals(282.96, updatedSystemBillList[0].Balance_Net_Late_Payments__c);

        System.assertEquals(false, originalSystemBillList[1].Account_Bill__r.Published__c);
        System.assertEquals(updatedSystemBillList[1].Id, originalSystemBillList[1].Id);
        System.assertEquals(2, updatedSystemBillList[1].Bill_Number__c);
        System.assertEquals(-400.28, updatedSystemBillList[1].Previous_Overpayment__c );
        System.assertEquals(0, updatedSystemBillList[1].Balance_Net_Late_Payments__c);

        System.assertEquals(false, originalSystemBillList[1].Account_Bill__r.Published__c);
        System.assertEquals(updatedSystemBillList[2].Id, originalSystemBillList[2].Id);
        System.assertEquals(3, updatedSystemBillList[2].Bill_Number__c);
        System.assertEquals(-402.83, updatedSystemBillList[2].Previous_Overpayment__c );
        System.assertEquals(0, updatedsystemBillList[2].Balance_Net_Late_Payments__c);

        List<Overpayment_Application__c> secondAdjustApp = [
            SELECT Id, Name, Overpayment__c, System_Bill__c,
                Overpayment_Amount__c
            FROM Overpayment_Application__c
            ORDER BY Overpayment_Amount__c ASC
        ];

        System.assertEquals(2, secondAdjustApp.size());
        // pay off full system bill 3 with $1000 overpayment
        System.assertEquals(-402.83, secondAdjustApp[0].Overpayment_Amount__c);
        // First, pay off system bill 2 with $100 overpayment
        System.assertEquals(-400.28, secondAdjustApp[1].Overpayment_Amount__c);

        List<Overpayment__c> overpayments = [
            SELECT Id,
                Outstanding__c
            FROM Overpayment__c
            WHERE Id IN : overpayList
        ];

        Decimal outstanding = 0;
        for (Overpayment__c billAdjustment : overpayments) {
            outstanding += billAdjustment.Outstanding__c;
        }
        // original overpayments $1100 - system bill 2 $400.28 - system bill 3 $402.83
        System.assertEquals(296.89, outstanding);
    }

    @IsTest
    public static void testPriorBillHandling(){
        List<SObject> chOrderList = new List<SObject>();
        User userA = [SELECT Id FROM User WHERE Username='testBillCreationandPay@bluewavesolar.com'];

        Account accountA = [SELECT Id, Name FROM Account WHERE Name = 'Account A'];

        List<Account_Bill__c> accountBillList = [ SELECT Id, Published__c FROM Account_Bill__c];

        for (Account_Bill__c acctBill : accountBillList) {
            acctBill.Published__c = true;
        }
        Test.startTest();
        update accountBillList;

        System.runAs(userA){
            List<AggregateResult> systemBills = MyAccountController.getSystemBills(accountA.Id);
            for (AggregateResult lineItem : systemBills) {
                ChargentOrders__ChargentOrder__c billsToCharge = new ChargentOrders__ChargentOrder__c(
                    Account_Bill__c = (Id)lineItem.get('Account_Bill__c'),
                    ChargentOrders__Subtotal__c = (Decimal)lineItem.get('ChargentOrders__Subtotal__c'),
                    Entity__c = (String)lineItem.get('Entity__c'));
                chOrderList.add(billsToCharge);
            }
            System.assertEquals(1, chOrderList.size());
            ChargentOrders__ChargentOrder__c paymentInfoACH =
                new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Payment_Method__c = 'Check',
                    ChargentOrders__Bank_Name__c = 'Bank of America',
                    ChargentOrders__Bank_Routing_Number__c = '123456789',
                    ChargentOrders__Bank_Account_Type__c = 'Checking',
                    ChargentOrders__Bank_Account_Number__c = '123456533',
                    ChargentOrders__Bank_Account_Name__c = 'Jordan Testcase',
                    ChargentOrders__Card_Type__c = '',
                    ChargentOrders__Card_Number__c = '',
                    ChargentOrders__Card_Expiration_Month__c = '',
                    ChargentOrders__Card_Expiration_Year__c = '',
                    ChargentOrders__Billing_Address__c = '',
                    ChargentOrders__Billing_City__c = '',
                    ChargentOrders__Billing_State__c = '',
                    ChargentOrders__Billing_Zip_Postal__c  = '',
                    ChargentOrders__Billing_First_Name__c = '',
                    ChargentOrders__Billing_Last_Name__c = '');

            ChargentOrders__ChargentOrder__c paymentInfoCC =
                new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    ChargentOrders__Bank_Name__c = '',
                    ChargentOrders__Bank_Routing_Number__c = '',
                    ChargentOrders__Bank_Account_Type__c = '',
                    ChargentOrders__Bank_Account_Number__c = '',
                    ChargentOrders__Bank_Account_Name__c = '',
                    ChargentOrders__Card_Number__c = '111111111',
                    ChargentOrders__Card_Expiration_Month__c = '02',
                    ChargentOrders__Card_Expiration_Year__c = '2020',
                    ChargentOrders__Billing_Address__c = '200 Street',
                    ChargentOrders__Billing_City__c = 'City',
                    ChargentOrders__Billing_State__c = 'MA',
                    ChargentOrders__Billing_Zip_Postal__c  = '02114',
                    ChargentOrders__Billing_First_Name__c = 'Jordan',
                    ChargentOrders__Billing_Last_Name__c = 'Testcase');
            CreateOrderandPaymentRequest.setChargeAmountAndInsert(chOrderList, paymentInfoACH, false);
            CreateOrderandPaymentRequest.setChargeAmountAndInsert(chOrderList, paymentInfoCC, true);

            List<ChargentOrders__ChargentOrder__c> orders = [
                SELECT Id, Name, ChargentOrders__Subtotal__c, ChargentOrders__Shipping_Name__c, Entity__c,
                    Account_Bill__c, ChargentOrders__Bank_Name__c, ChargentOrders__Card_Expiration_Year__c
                FROM ChargentOrders__ChargentOrder__c
                ORDER BY ChargentOrders__Payment_Method__c
            ];

            // Checking that the orders were inserted and that the merged data mapped correctly:
            System.assertEquals(2, orders.size());
            ChargentOrders__ChargentOrder__c ccOrder = orders[0];
            ChargentOrders__ChargentOrder__c achOrder = orders[1];
            System.assertNotEquals(null, ccOrder.Account_Bill__c);
            System.assertNotEquals(null, achOrder.Account_Bill__c);

            System.assertEquals(628.24, ccOrder.ChargentOrders__Subtotal__c);
            System.assertEquals(628.24, achOrder.ChargentOrders__Subtotal__c);
            System.assertEquals('2020', ccOrder.ChargentOrders__Card_Expiration_Year__c);
            System.assertEquals('Bank of America', achOrder.ChargentOrders__Bank_Name__c);

            // If NOT waiving late fees
            //System.assertEquals(631.07, ccOrder.ChargentOrders__Subtotal__c);
            //System.assertEquals(631.07, achOrder.ChargentOrders__Subtotal__c);

            // Set the non-recurring payment to be Error, this should get set to Complete when a new order is added
            achOrder.ChargentOrders__Payment_Status__c = 'Error';
            update achOrder;

            paymentInfoACH.ChargentOrders__Bank_Name__c = 'New Bank';
            CreateOrderandPaymentRequest.setChargeAmountAndInsert(chOrderList, paymentInfoACH, false);
            orders = [
                SELECT Id, Name, ChargentOrders__Subtotal__c, ChargentOrders__Shipping_Name__c, Entity__c,
                    Account_Bill__c, ChargentOrders__Bank_Name__c, ChargentOrders__Payment_Status__c
                FROM ChargentOrders__ChargentOrder__c
                ORDER BY ChargentOrders__Payment_Method__c
            ];
            System.assertEquals(3, orders.size());
            for (ChargentOrders__ChargentOrder__c order : orders) {
                if (order.Id == ccOrder.Id) {
                    System.assertEquals('Stopped', order.ChargentOrders__Payment_Status__c);
                } else if (order.Id == achOrder.Id) {
                    System.assertEquals('Complete', order.ChargentOrders__Payment_Status__c);
                } else {
                    System.assertEquals(null, order.ChargentOrders__Payment_Status__c);
                }
            }
        }
        Test.stopTest();
    }

    @isTest public static void testScheduleZStatusIsSaved() {
        Test.startTest();

        List<Energy_Usage_Update__c> productionUpdates = [
            SELECT Id, Schedule_Z__c, Shared_Solar_System__c
            FROM Energy_Usage_Update__c
        ];

        for (Energy_Usage_Update__c prodUpdate : productionUpdates) {
            prodUpdate.Schedule_Z__c = null;
        }

        update productionUpdates;

        Schedule_Z__c scheduleZ = new Schedule_Z__c(
            Name = '18-0615 Oxford Barrett St. P1',
            Shared_Solar_System__c = productionUpdates[0].Shared_Solar_System__c,
            Status__c = 'Enacted by Utility',
            Date_Enacted_by_Utility__c = Date.today()
        );

        insert scheduleZ;

        List<Schedule_Z__c> scheduleZS = PreviewProductionUpdateResults.getScheduleZs(productionUpdates[0].Id);
        System.assertEquals(2, scheduleZS.size());
        System.assertEquals('Billing', scheduleZS[0].Status__c);
        System.assertEquals('Enacted by Utility', scheduleZS[1].Status__c);
        Schedule_Z__c previousScheduleZ = scheduleZS[1];
        PreviewProductionUpdateResults.saveSchedZToProdUpdate(scheduleZS[1].Id, productionUpdates[0].Id);
        /*
        After a schedule Z is saved to a production update, if that schedule Z's status is 'Enacted by Utility'
        then update the status to 'Billing' and change other Schedule Z statuses to 'Replaced with newly Enacted Schedule Z'
         */

        Energy_Usage_Update__c productionUpdate = [
            SELECT Id, Schedule_Z__c, Shared_Solar_System__c
            FROM Energy_Usage_Update__c
            WHERE Id = : productionUpdates[0].Id
            LIMIT 1
        ];

        System.assertEquals(scheduleZS[1].Id, productionUpdate.Schedule_Z__c);

        // Only getsSchedule Zs with status of 'Billing' or 'Enacted by Utility'
        List<Schedule_Z__c> scheduleZS2 = PreviewProductionUpdateResults.getScheduleZs(productionUpdate.Id);

        System.assertEquals(1, scheduleZS2.size());
        System.assertEquals('Billing', scheduleZS2[0].Status__c);
        System.assertNotEquals(previousScheduleZ.Status__c, scheduleZS2[0].Status__c);

        // Make sure nothing changes if schedule Z status is already 'Billing'
        Schedule_Z__c previousScheduleZ2 = scheduleZS2[0];
        PreviewProductionUpdateResults.saveSchedZToProdUpdate(scheduleZS2[0].Id, productionUpdates[1].Id);

        Energy_Usage_Update__c productionUpdate2 = [
            SELECT Id, Schedule_Z__c, Shared_Solar_System__c
            FROM Energy_Usage_Update__c
            WHERE Id = : productionUpdates[0].Id
            LIMIT 1
        ];

        System.assertEquals(scheduleZS[1].Id, productionUpdate2.Schedule_Z__c);

        List<Schedule_Z__c> scheduleZS3 = PreviewProductionUpdateResults.getScheduleZs(productionUpdate2.Id);

        System.assertEquals(1, scheduleZS3.size());
        System.assertEquals('Billing', scheduleZS3[0].Status__c);
        System.assertEquals(previousScheduleZ2.Status__c, scheduleZS3[0].Status__c);

        Test.stopTest();
    }

    @isTest public static void testMultipleUALs() {
        Test.startTest();
        Energy_Usage_Update__c productionupdateA3 = [
            SELECT Id, Generate_Bills__c, Month_Number__c, Schedule_Z__c, Shared_Solar_System__c, YearDate__c, Date__c,
                MonthDate__c, Net_Metering_Rate_Applied__c, Production__c, Total_System_NMCs__c, Total_System_NMCs_2_of_4__c,
                Billing_Method__c, Billing_Period_Start_Date__c, Billing_Period_End_Date__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - March 2016'
            LIMIT 1
        ];

        Opportunity opportunity = [
            SELECT Id, Name, StageName, Shared_Solar_System__c, AccountId
            FROM Opportunity
            WHERE Name = 'AOpp One With Long Name To Test Utility Account Subscription Bill and System Bill Lengths'
            LIMIT 1
        ];

        Utility_Account_Log__c ualog = new Utility_Account_Log__c(
            Name = '12300234',
            Account__c = opportunity.AccountId,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'jordan jordan'
        );

        insert ualog;

        Utility_Account_Subscription__c newUAS = new Utility_Account_Subscription__c(
            Name = '12300234',
            Utility_Account_Log__c = ualog.Id,
            Opportunity__c = opportunity.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Annual_kwh_subscription_future__c = 6500,
            Calculated_Annual_Cost_of_Electricity__c = 6500,
            Customer_Subscription_KW_DC_STATIC__c = 20,
            Subscribed_Annual_Cost_of_Electricity__c = 6500
        );

        insert newUAS;

        Schedule_Z__c scheduleZ = [
            SELECT Id, Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c,
                Shared_Solar_System__r.Total_System_Size_kW_DC_QC__c
            FROM Schedule_Z__c
            WHERE Name = '18-0515 Oxford Barrett St. P1'
        ];

        Schedule_Z_Subscription__c newSZS = new Schedule_Z_Subscription__c(
            Schedule_Z__c = scheduleZ.Id,
            Utility_Account_Subscription__c = newUAS.Id,
            Customer_Subscription_kW_DC__c = 20,
            Number_of_Decimal_Places__c = scheduleZ.Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c,
            System_Size_kW_DC__c = scheduleZ.Shared_Solar_System__r.Total_System_Size_kW_DC_QC__c
        );

        insert newSZS;

        simulateBatchBillCreation(new List<Energy_Usage_Update__c>{productionupdateA3});
        Test.stopTest();

        List<UASB__c> uasbList = [
            SELECT Id, Opportunity__c, Utility_Account_Subscription__c, Production_Update__c
            FROM UASB__c
            WHERE Opportunity__c = : opportunity.Id
        ];

        System.assertEquals(4, uasbList.size());
    }


    public static void simulateBatchBillCreation(List<Energy_Usage_Update__c> productionUpdates) {
        Set<Id> scheduleZs = new Set<Id>();
        for (Energy_Usage_Update__c productionUpdate : productionUpdates) {
            scheduleZs.add(productionUpdate.Schedule_Z__c);
        }

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

        EnergyUsageUpdateTriggerHandler handler = new EnergyUsageUpdateTriggerHandler(productionUpdates);
        //simulate batching in production
        handler.createBills(batch1);
        handler.createBills(batch2);
    }

    static testMethod void testOnlyAllowApprovedAdjustments() {
        Test.startTest();

        List<System_Bill__c> systemBillBefore = SystemBillsSelector.selectAllSystemBills();

        // Before the adjustment is set to approved, only the 1 approved adjustment of $24 in testSetup is applied
        System.assertEquals(282.96, systemBillBefore[0].Total_Due__c);
        System.assertEquals(24, systemBillBefore[0].Adjustments__c);

        Energy_Usage_Update__c prodUpdate = [
            SELECT Id, Name
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - January 2016'
        ];

        List<Account_Bill__c> abs = [
            SELECT Id, Name
            FROM Account_Bill__c
        ];

        delete abs;

        Bill_Adjustment__c unapprovedAdjustment = [
            SELECT Id, Adjustment_Amount__c, Approval_Status__c, UASB__c
            FROM Bill_Adjustment__c
            WHERE Approval_Status__c = 'Unapproved'
        ];

        unapprovedAdjustment.Approval_Status__c = 'Approved';
        update unapprovedAdjustment;

        runProductionUpdate(new List<Id>{prodUpdate.Id});

        OverpaymentApplication.triggerApplication();

        // This time the bill should be for $30 more since the adjustment should be applied
        List<System_Bill__c> systemBillsAfter = SystemBillsSelector.selectAllSystemBills();

        // The $30 adjustment is now applied
        System.assertEquals(312.96, systemBillsAfter[0].Total_Due__c);


        Test.stopTest();
    }

    @IsTest
    public static void testPaymentPlanBalanceCalculation() {
        System.assertEquals(16.67, SystemBillAccountingLogicHandler.calculatePaymentPlanBalance(1, 6, 100));
        System.assertEquals(16.67, SystemBillAccountingLogicHandler.calculatePaymentPlanBalance(5, 6, 100));
        System.assertEquals(16.65, SystemBillAccountingLogicHandler.calculatePaymentPlanBalance(6, 6, 100));
        System.assertEquals(16.66, SystemBillAccountingLogicHandler.calculatePaymentPlanBalance(6, 6, 100.006789));
        System.assertEquals(0, SystemBillAccountingLogicHandler.calculatePaymentPlanBalance(0, 6, 100));
        System.assertEquals(0, SystemBillAccountingLogicHandler.calculatePaymentPlanBalance(7, 6, 100));
        System.assertEquals(0, SystemBillAccountingLogicHandler.calculatePaymentPlanBalance(1, 6, 0));
    }

    @IsTest
    private static void testFinaledUASWithoutCarryoverBalance() {
        Utility_Account_Subscription__c uas = [
            SELECT Id, Utility_Account_Log__c, Utility_Account_Log__r.Account__c, (
                SELECT Id, Schedule_Z__c, Schedule_Z__r.Shared_Solar_System__c FROM Schedule_Z_Subscriptions__r
            )
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000234'
            LIMIT 1
        ];

        List<System_Bill__c> systemBills = [
            SELECT Id, Date__c, Carry_Over_Balance__c, Balance_Net_Late_Payments__c
            FROM System_Bill__c
            WHERE Property_Account__c = :uas.Utility_Account_Log__r.Account__c
            ORDER BY Date__c DESC
        ];
        // There should be two system bills, one for each production update created in testSetup, the last one for two months ago
        System.assertEquals(2, systemBills.size());
        System.assertEquals(Date.newInstance(Date.today().year(), Date.today().month()-2,15), systemBills[0].Date__c);

        // We'll pay off this account so that there isn't a carryover balance or overdue amount
        systemBills[0].Total_Payments_This_Month__c = systemBills[0].Carry_Over_Balance__c;
        systemBills[0].Late_Payments__c = systemBills[0].Balance_Net_Late_Payments__c;
        systemBills[1].Late_Payments__c = systemBills[1].Balance_Net_Late_Payments__c;
        update systemBills;

        systemBills = [
            SELECT Id, Date__c, Carry_Over_Balance__c, Balance_Net_Late_Payments__c
            FROM System_Bill__c
            WHERE Property_Account__c = :uas.Utility_Account_Log__r.Account__c
            ORDER BY Date__c DESC
        ];
        System.assertEquals(0, systemBills[0].Balance_Net_Late_Payments__c);

        // We'll create a new schedule z to check that the Cancelled tab on the preview bills screen can show results
        // specific to schedule z's.
        Schedule_Z__c scheduleZ = [
            SELECT Id, Shared_Solar_System__c
            FROM Schedule_Z__c
            WHERE Name = '18-0515 Oxford Barrett St. P1'
            LIMIT 1
        ];
        Schedule_Z__c newSZ = scheduleZ.clone(false);
        insert newSZ;

        // Next we'll mark the UAL as Finaled, the UAS as removed, and the SZS as Stopped for Credit Transfer
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Id = uas.Utility_Account_Log__c,
            Date_Utility_Account_Cancelled__c = System.today()
        );
        update ual;

        uas.Date_Removed_from_Project__c = System.today();
        update uas;

        System.assertEquals(1, uas.Schedule_Z_Subscriptions__r.size());
        uas.Schedule_Z_Subscriptions__r[0].Stop_Credit_Transfer__c = true;
        update uas.Schedule_Z_Subscriptions__r[0];

        // Now, a new production update and bill run shouldn't create a bill for this customer, even though they have a
        // uas
        Energy_Usage_Update__c prodUpdate = [
            SELECT Id, Shared_Solar_System__c, Schedule_Z__c, Production__c, Net_Metering_Rate_Applied__c, Billing_Period_End_Date__c,
                Total_System_NMCs__c, Date__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - March 2016'
            LIMIT 1
        ];
        prodUpdate = prodUpdate.clone(false,false,false,false);
        prodUpdate.Name = 'sssA - April 2016';
        prodUpdate.Billing_Period_End_Date__c = prodUpdate.Billing_Period_End_Date__c.addMonths(1);
        prodUpdate.Date__c = prodUpdate.Date__c.addMonths(1);
        insert prodUpdate;
        Test.startTest();
        runProductionUpdate(new List<Id>{prodUpdate.Id});
        InvocableCSBillOverpaymentApplication.applyOverpayments();
        Test.stopTest();

        systemBills = [
            SELECT Id, Date__c, Total_Due__c, Due_This_Month__c
            FROM System_Bill__c
            WHERE Property_Account__c = :uas.Utility_Account_Log__r.Account__c
            ORDER BY Date__c DESC
        ];
        // There should still be two account bills, one for each production update created in testSetup
        System.assertEquals(2, systemBills.size());
        System.assertEquals(Date.newInstance(Date.today().year(), Date.today().month()-2,15), systemBills[0].Date__c);

        // The preview bills screen shouldn't show the anything for the new prod update, since there wasn't a bill created
        List<UASB__c> uasbs = PreviewProductionUpdateResults.getUASes(prodUpdate.Id, true, prodUpdate.Schedule_Z__c);
        System.assertEquals(0, uasbs.size());
        // But the cancelled screen should
        List<UASB__c> cancelledBillListA = PreviewProductionUpdateResults.getCancelledBills(prodUpdate.Id, new List<String>(), prodUpdate.Schedule_Z__c);
        System.assertEquals(1, cancelledBillListA.size());
        // And previewing bills with the new schedule z (which didn't get Stop Credit Transfer) shouldn't show any cancelled bills
        cancelledBillListA = PreviewProductionUpdateResults.getCancelledBills(prodUpdate.Id, new List<String>(), newSZ.Id);
        System.assertEquals(0, cancelledBillListA.size());
    }

    @IsTest
    private static void testFinaledUASWithCarryoverBalance() {
        Utility_Account_Subscription__c uas = [
            SELECT Id, Utility_Account_Log__c, Utility_Account_Log__r.Account__c, (
                SELECT Id FROM Schedule_Z_Subscriptions__r
            )
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000234'
            LIMIT 1
        ];

        List<System_Bill__c> systemBills = [
            SELECT Id, Date__c, Total_Due__c, Due_This_Month__c
            FROM System_Bill__c
            WHERE Property_Account__c = :uas.Utility_Account_Log__r.Account__c
        ];
        // There should be two account bills, one for each production update created in testSetup
        System.assertEquals(2, systemBills.size());

        // Next we'll mark the UAL as Finaled, the UAS as removed, and the SZS as Stopped for Credit Transfer
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Id = uas.Utility_Account_Log__c,
            Date_Utility_Account_Cancelled__c = System.today()
        );
        update ual;

        uas.Date_Removed_from_Project__c = System.today();
        update uas;

        System.assertEquals(1, uas.Schedule_Z_Subscriptions__r.size());
        uas.Schedule_Z_Subscriptions__r[0].Stop_Credit_Transfer__c = true;
        update uas.Schedule_Z_Subscriptions__r[0];

        // Now, a new production update and bill run shouldn't create a bill for this customer, even though the
        Energy_Usage_Update__c prodUpdate = [
            SELECT Id, Shared_Solar_System__c, Schedule_Z__c, Production__c, Net_Metering_Rate_Applied__c, Billing_Period_End_Date__c,
                Total_System_NMCs__c, Date__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - March 2016'
            LIMIT 1
        ];
        prodUpdate = prodUpdate.clone(false,false,false,false);
        prodUpdate.Name = 'sssA - April 2016';
        prodUpdate.Billing_Period_End_Date__c = prodUpdate.Billing_Period_End_Date__c.addMonths(1);
        prodUpdate.Date__c = prodUpdate.Date__c.addMonths(1);
        insert prodUpdate;
        Test.startTest();
        runProductionUpdate(new List<Id>{prodUpdate.Id});
        InvocableCSBillOverpaymentApplication.applyOverpayments();
        Test.stopTest();

        systemBills = [
            SELECT Id, Date__c, Total_Due__c, Due_This_Month__c
            FROM System_Bill__c
            WHERE Property_Account__c = :uas.Utility_Account_Log__r.Account__c
            ORDER BY Date__c
        ];
        // Now, there should be three account bills, but the total due for the last one should be the same as the
        // second one, since there are no new charges
        System.assertEquals(3, systemBills.size());
        System.assertEquals(systemBills[1].Total_Due__c, systemBills[2].Total_Due__c);

        // The stopped subscription should still show up on the cancelled list, not the new credits list
        List<UASB__c> uasbs = PreviewProductionUpdateResults.getUASes(prodUpdate.Id, true, prodUpdate.Schedule_Z__c);
        System.assertEquals(0, uasbs.size());
        List<UASB__c> cancelledBillListA = PreviewProductionUpdateResults.getCancelledBills(prodUpdate.Id, new List<String>());
        System.assertEquals(1, cancelledBillListA.size());
    }
}