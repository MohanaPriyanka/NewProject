@isTest
public class TestBillCreationandPayment {
    @testSetup public static void CSTestRecordWarehouse(){
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c national_grid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
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
        insert new BW_Address__c(Name = 'BlueWave', Address_Line_One__c = '137 Newbury Street', Address_Line_Two__c = 'Boston, MA 02114');

        Account clientAccount = new Account(name = 'Client Account',
            Client_Brand_Key__c = 'AmpBlack');
        insert clientAccount;

        Account clientAccount2 = new Account(name = 'Client Account 2',
            Client_Brand_Key__c = 'AmpBlack');
        insert clientAccount2;

        Entity__c entity1 = new Entity__c (Name = 'Oxford Barrett St. P1',
            Send_Checks_Address__c = 'Fake Lockbox Address, P.O Box 12345, Phoenix Arizona 02114',
            Client_Account__c = clientAccount.Id);
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
        Account accountParent2 = new Account(name = 'Account Parent2',
            RecordTypeId = parentAccountRT);
        insert new List<Account>{accountParent, accountParent2};

        Contact contactA = new Contact( FirstName = 'Contact',
            LastName = 'A',
            AccountId = accountParent.Id);
        Contact contactB = new Contact( FirstName = 'Contact',
            LastName = 'B',
            AccountId = accountParent2.Id);
        insert new List<Contact>{contactA, contactB};

        Account accountA = new Account(name = 'Account A',
            Parent_Account__c = accountParent.Id);
        Account accountB = new Account(name = 'Account B',
            Parent_Account__c = accountParent2.Id);
        insert new List<Account>{accountA, accountB};

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
                Shared_Solar_System__c = sss1.id,
                ChargentBase__Debug__c = True,
                Entity__c = entity1.Id,
                OwnerId = userRecord.Id,
                ChargentBase__Active__c = TRUE);
        insert chGateway;

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
            new Opportunity(Name = 'AOpp One',
                AccountId = accountA.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                CloseDate = System.today());

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
        insert new List<Opportunity>{opportunityone, opportunitytwo, opportunitythree};

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

        insert new List<Utility_Account_Subscription__c>{uasone, uastwo, uasthree, uasfour};

        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(  Name = 'UASoneAdjustment',
            Utility_Account_Subscription__c = uasOne.Id,
            Adjustment_Amount__c = 24);
        insert adjustOne;

        uasone.Customer_Subscription_KW_DC_STATIC__c = 25;
        uastwo.Customer_Subscription_KW_DC_STATIC__c = 20;
        update new List<Utility_Account_Subscription__c>{uasone, uastwo};

        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);

        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Status__c = 'Billing'
        );

        insert scheduleZ1;

        Schedule_Z__c scheduleZ2 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P2',
            Shared_Solar_System__c = sss2.Id,
            Status__c = 'Billing'
        );

        insert scheduleZ2;

        Energy_Usage_Update__c productionupdateA1 = new Energy_Usage_Update__c (
            Name = 'sssA - January 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.id,
            Production__c = 90000,
            Size_off_NMCs__c = true,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateFeb,
            Total_System_NMCs__c = 16632,
            Date__c = myDateJan
        );

        insert productionupdateA1;

        Energy_Usage_Update__c productionupdateA2 = new Energy_Usage_Update__c (
            Name = 'sssA - February 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.id,
            Production__c = 120000,
            Size_off_NMCs__c = true,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateMar,
            Total_System_NMCs__c = 22176,
            Date__c = myDateFeb
        );

        insert productionupdateA2;

        Energy_Usage_Update__c productionupdateA3 = new Energy_Usage_Update__c (
            Name = 'sssA - March 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.id,
            Production__c = 140000,
            Size_off_NMCs__c = true,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateApr,
            Total_System_NMCs__c = 25872,
            Date__c = myDateMar
        );

        insert productionupdateA3;

        Energy_Usage_Update__c productionupdateB1 = new Energy_Usage_Update__c (
            Name = 'sssB - January 2016',
            Shared_Solar_System__c = sss2.id,
            Schedule_Z__c = scheduleZ2.id,
            Production__c = 90000,
            Size_off_NMCs__c = true,
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
            Size_off_NMCs__c = true,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateMar,
            Total_System_NMCs__c = 22176,
            Date__c = myDateFeb
        );

        insert productionupdateB2;



        productionupdateA1.Generate_Bills__c = TRUE;
        productionupdateA2.Generate_Bills__c = TRUE;
        update productionupdateA1;
        update productionupdateA2;


        APXT_BPM__Conductor__c newConga = new APXT_BPM__Conductor__c (APXT_BPM__Title__c = 'Conga Record');
        insert newConga;
        newConga.Apply_Overpay_Adjust__c = true;
        update newConga;
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
        System.AssertEquals( 1, (PreviewProductionUpdateResults.getUASes(productionUpdateList[0].Id, true, productionUpdateList[0].Schedule_Z__r.Id)).size());
        System.AssertEquals( 1, (PreviewProductionUpdateResults.getUASes(productionUpdateList[1].Id, true, productionUpdateList[1].Schedule_Z__r.Id)).size());
        System.AssertEquals( 1, (PreviewProductionUpdateResults.getProperties(parId.substring(0,15), true)).size());
        System.AssertEquals( 5, (PreviewProductionUpdateResults.getUASes(acctId.substring(0,15), false, null)).size());
        Energy_Usage_Update__c productionUpdate = [
          SELECT Id, Name,  Schedule_Z__r.Id, Schedule_Z__r.Name
          FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - February 2016'
        ];

        List<UASB__c> uasbList = PreviewProductionUpdateResults.getUASes(productionUpdate.Id, true, productionUpdate.Schedule_Z__r.Id);
        System.AssertEquals(345.28, uasbList[0].PreGen_Discounted_Bill__c);
        System.AssertEquals(383.64, uasbList[0].PreGen_NMCs_Allocated__c);
        Test.stopTest();
    }

    @isTest public static void testDontGenerateBills(){
        Test.startTest();
        Energy_Usage_Update__c productionupdateA3 = [
            SELECT Id, Name, Shared_Solar_System__c, Schedule_Z__c, Generate_Bills__c, Month_Number__c,
                MonthDate__c, YearDate__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - March 2016'
            LIMIT 1
        ];

        List<Schedule_Z_Subscription__c> scheduleZSubscriptions = [
            SELECT Id, Utility_Account_Subscription__r.Opportunity__c, Utility_Account_Subscription__r.Name
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c = : productionupdateA3.Schedule_Z__c
            AND Utility_Account_Subscription__r.Opportunity__r.Name = 'AOpp One'
        ];

        Opportunity opportunity = [
            SELECT Id, Name, StageName, Shared_Solar_System__c, AccountId
            FROM Opportunity
            WHERE Name = 'AOpp One'
            LIMIT 1
        ];

        opportunity.StageName = 'Cancelled';

        update opportunity;

        productionupdateA3.Generate_Bills__c = true;
        update  productionupdateA3;

        List<System_Bill__c> systemBills = [
            SELECT Id, Opportunity__c
            FROM System_Bill__c
            WHERE Month__c = : productionupdateA3.Month_Number__c
            AND Opportunity__c = : opportunity.Id
        ];

        List<Account_Bill__c> accountBills = [
            SELECT Id
            FROM Account_Bill__c
            WHERE Month__c = : productionupdateA3.Month_Number__c
            AND Parent_Account__c = : opportunity.AccountId
        ];

        String utilityAccountBillName = (
            opportunity.Name + ' '
            + productionupdateA3.MonthDate__c + ' '
            + productionupdateA3.YearDate__c + ' '
            + scheduleZSubscriptions[0].Utility_Account_Subscription__r.Name
        );

        List<Utility_Account_Bill__c> utilityAccountBills = [
            SELECT Id
            FROM Utility_Account_Bill__c
            WHERE Name = : utilityAccountBillName
        ];

        List<UASB__c> utilityAccountSubscriptionBills = [
            SELECT Id
            FROM UASB__c
            WHERE Opportunity__c = : opportunity.Id
            AND Date__c = : productionupdateA3.Date__c
        ];

        System.assertEquals(1, scheduleZSubscriptions.size());
        System.assertEquals(0, systemBills.size());
        System.assertEquals(0, accountBills.size());
        System.assertEquals(0, utilityAccountBills.size());
        System.assertEquals(0, utilityAccountSubscriptionBills.size());
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
            Status__c = 'Enacted by Utility'
        );

        insert scheduleZ;

        List<Schedule_Z__c> scheduleZS = PreviewProductionUpdateResults.getScheduleZs(productionUpdate.id);

        System.assertEquals(2, scheduleZS.size());
        Test.stopTest();
    }

    @isTest public static void testPaymentPlan() {
        Test.startTest();
        List<System_Bill__c> systemBillList =
        [SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
            Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
            Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
            Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c,
            Property_Account__r.Directions_To_Write_Paper_Check__c,
            Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
            Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
            Adjustments__c, Bill_Date__c, Refund_this_Balance__c,
            Waive_Late_Fees__c, Previous_Overpayments__c, Balance_Adjustment__c,
            Adjustments_UASB__c,
            Billing_Period_End_Date__c, Billing_Period_Start_Date__c
        FROM System_Bill__c
        ORDER BY Bill_Number__c];

        List <UASB__c> uablist =
        [SELECT Id, Name, Bill_Date__c, System_Bill__r.Bill_Number__c,
            Due_Date__c, Billing_Period_End_Date__c, Utility_Account_Subscription__c
        FROM UASB__c
        ORDER BY Bill_Date__c ];

        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);

        for (UASB__c uabill : uablist) {
            if (uabill.System_Bill__r.Bill_Number__c == 1){
                System.assertEquals(myDateFeb, uabill.Billing_Period_End_Date__c);
            }
            if (uabill.System_Bill__r.Bill_Number__c == 2){
                System.assertEquals(myDateMar, uabill.Billing_Period_End_Date__c);
            }
        }

        String acctId = systemBillList[1].Property_Account_Id__c;
        system.AssertEquals(5, (PreviewProductionUpdateResults.getUASes(acctId, FALSE, null)).size());

        systemBillList[1].Waive_Late_Fees__c = TRUE;
        systemBillList[1].Distribute_This_Balance_As_Payment_Plan__c = TRUE;
        update systemBillList[1];

        List <System_Bill__c> sbstoupdate = new list <System_Bill__c>();

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
                    Published__c = published,
                    Unique_ID__c = '000111000111000111FAS' + j );
            insert accBillThree;

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

        List<System_Bill__c> updatedsystemBillList = 
            [SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c, 
             Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c, 
             Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, 
             Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c, 
             Property_Account__r.Directions_To_Write_Paper_Check__c,
             Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
             Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c, 
             Adjustments__c, Bill_Date__c, Refund_this_Balance__c,
             Waive_Late_Fees__c, Previous_Overpayments__c, Balance_Adjustment__c,
             Adjustments_UASB__c, 
             Billing_Period_End_Date__c, Billing_Period_Start_Date__c
             FROM System_Bill__c
             ORDER BY Bill_Number__c];

        System.assertEquals(9, updatedsystemBillList.size());
        for (System_Bill__c sbs : updatedsystemBillList) {
            if (sbs.Bill_Number__c == 2) {
                System.assertEquals(628.24, sbs.Payment_Plan_Balance_to_Distribute__c);
            } else if (sbs.Bill_Number__c == 3 || sbs.Bill_Number__c == 4  || sbs.Bill_Number__c == 8) {
                System.assertEquals(104.71, sbs.Payment_Plan_Balance__c);
            } else if (sbs.Bill_Number__c == 9) {
                System.assertEquals(0, sbs.Payment_Plan_Balance__c);
            }
        }
        Test.stopTest();
    }

    @isTest public static void testBillNumbering() {
        Test.startTest();

        Energy_Usage_Update__c productionupdateB1 = [
          SELECT Id, Generate_Bills__c, Month_Number__c
          FROM Energy_Usage_Update__c
            WHERE Name = 'sssB - January 2016'
            LIMIT 1
        ];

        Energy_Usage_Update__c productionupdateB2 = [
          SELECT Id, Generate_Bills__c, Month_Number__c, Schedule_Z__c, Shared_Solar_System__c, YearDate__c, Date__c,
              MonthDate__c, Net_Metering_Rate_Applied__c, Production__c, Total_System_NMCs__c, Total_System_NMCs_2_of_4__c,
              Size_off_NMCs__c, Billing_Period_Start_Date__c, Billing_Period_End_Date__c
          FROM Energy_Usage_Update__c
            WHERE Name = 'sssB - February 2016'
            LIMIT 1
        ];

        productionupdateB1.Generate_Bills__c = TRUE;
        update productionupdateB1;

        simulateBatchBillCreation(new List<Energy_Usage_Update__c>{productionupdateB2});

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

    @isTest public static void testSystemBills() {
        Test.startTest();
        List<System_Bill__c> systemBillList =
        [SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
            Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
            Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
            Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c,
            Property_Account__r.Directions_To_Write_Paper_Check__c,
            Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
            Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
            Adjustments__c, Bill_Date__c, Refund_this_Balance__c,
            Waive_Late_Fees__c, Previous_Overpayments__c, Balance_Adjustment__c,
            Adjustments_UASB__c,
            Billing_Period_End_Date__c, Billing_Period_Start_Date__c
        FROM System_Bill__c
        ORDER BY Bill_Number__c];

        System.AssertEquals(282.96,systemBillList[0].Total_Due__c);
        System.AssertEquals(606.83,systembillList[1].Total_Due__c);
        System.AssertEquals(258.96,systembillList[0].Due_This_Month__c);
        System.AssertEquals(345.28,systembillList[1].Due_This_Month__c);
        System.AssertEquals(24,systembillList[0].Adjustments_UASB__c);
        System.AssertEquals(0,systembillList[1].Adjustments_UASB__c);
        System.AssertEquals(24,systembillList[0].Balance_Adjustment__c);
        System.AssertEquals(0,systembillList[1].Balance_Adjustment__c);
        System.AssertEquals(0,systembillList[1].Previous_Overpayments__c);
        Test.stopTest();


    }

    @isTest public static void testAdjustments() {
        List<Account_Bill__c> accountbilllist = [SELECT Id, Name,
            Bill_Number__c, Property_Account_ID__c
        FROM Account_Bill__c];

        Account accountA = [SELECT Id, Name
        FROM Account
        WHERE Name = 'Account A'];

        ChargentBase__Gateway__c chGateway  = [SELECT Id, Name, Entity__c
        FROM ChargentBase__Gateway__c
        LIMIT 1];
        Test.startTest();

        for (Account_Bill__c abill : accountbilllist) {
            abill.Published__c = True;
        }
        update accountbilllist;

        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToUpdate = new List<ChargentOrders__Transaction__c>();
        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToNotUpdate = new List<ChargentOrders__Transaction__c>();
        for (Account_Bill__c accountbill : accountbilllist) {
            if(accountbill.Bill_Number__c == 2) {
                ChargentOrders__ChargentOrder__c orderA =
                    new ChargentOrders__ChargentOrder__c(ChargentOrders__Gateway__c = chGateway.Id,
                        ChargentOrders__Shipping_Name__c = chGateway.Entity__c,
                        ChargentOrders__Billing_First_Name__c = 'Cole',
                        ChargentOrders__Billing_Last_Name__c = 'Swain',
                        ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                        ChargentOrders__Billing_Zip_Postal__c = '02467',
                        ChargentOrders__Subtotal__c = 50,
                        ChargentOrders__Payment_Method__c = 'Credit Card',
                        Account_Bill__c = accountbill.Id,
                        ChargentOrders__Card_Type__c = 'Visa',
                        ChargentOrders__Card_Number__c = '411111111111',
                        ChargentOrders__Card_Security_Code__c = '999',
                        ChargentOrders__Card_Expiration_Month__c = '02',
                        ChargentOrders__Card_Expiration_Year__c = '2018',
                        ChargentOrders__Card_Last_4__c = '1111');
                insert orderA;

                ChargentOrders__Transaction__c transA =
                    new ChargentOrders__Transaction__c(ChargentOrders__Order__c = orderA.id,
                        ChargentOrders__Amount__c = 50,
                        ChargentOrders__Response_Status__c ='Approved',
                        ChargentOrders__Gateway_ID__c = chGateway.id,
                        ChargentOrders__Gateway__c = chGateway.id,
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
                        ChargentOrders__Gateway_ID__c = chGateway.id,
                        ChargentOrders__Gateway__c = chGateway.id,
                        Distributed_Among_System_Bills__c = false,
                        ChargentOrders__Response_Message__c = 'OK',
                        ChargentOrders__Type__c = 'Charge',
                        ChargentOrders__Payment_Method__c = 'Credit Card',
                        Activity_Type__c = 'Payment');
                chargentOrdersTransactionsToNotUpdate.add(transB);
            }
        }

        insert chargentOrdersTransactionsToUpdate;
        for (ChargentOrders__Transaction__c trans : chargentOrdersTransactionsToUpdate) {
            trans.Distributed_Among_System_Bills__c = true;
        }
        update chargentOrdersTransactionsToUpdate;
        insert chargentOrdersTransactionsToNotUpdate;

        List<Account> acctList = new List<Account>();
        acctList.add(accountA);
        system.AssertEquals( 2, (PreviewProductionUpdateResults.getTransactions(acctList)).size());

        List<Bill_Adjustment__c> adjustList = [  SELECT Id, Name,
            Adjustment_Amount__c
        FROM Bill_Adjustment__c
        WHERE Overpayment__c = TRUE];
        System.AssertEquals(1, adjustList.size());
        System.AssertEquals(-118.93, adjustList[0].Adjustment_Amount__c);

        List<Adjustment_Application__c> adjustApp = [SELECT Id, Name, Bill_Adjustment__c, System_Bill__c,
            Overpayment_Amount__c, Adjustment_Amount__c,
            Bill_Adjustment__r.Outstanding__c,
            Bill_Adjustment__r.Overpayment__c
        FROM Adjustment_Application__c];
        System.AssertEquals(1, adjustApp.size());
        System.AssertEquals(0, adjustApp[0].Bill_Adjustment__r.Outstanding__c);

        List<System_Bill__c> updatedsystemBillListOne = 
            [SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c, 
             Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c, 
             Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, 
             Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c, 
             Property_Account__r.Directions_To_Write_Paper_Check__c, Payments_Net_Previous_Balances__c,
             Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
             Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c, 
             Adjustments__c, Bill_Date__c, Refund_this_Balance__c,
             Waive_Late_Fees__c, Previous_Overpayments__c, Balance_Adjustment__c,
             Adjustments_UASB__c, 
             Billing_Period_End_Date__c, Billing_Period_Start_Date__c
             FROM System_Bill__c
             ORDER BY Bill_Number__c];

        System.AssertEquals(282.96, updatedsystemBillListOne[0].Total_Due__c);
        System.AssertEquals(282.96, updatedsystemBillListOne[0].Late_Payments__c);
        System.AssertEquals(0, updatedsystemBillListOne[0].Balance_Net_Late_Payments__c);
        System.AssertEquals(0, updatedsystemBillListOne[0].Total_Payments_This_Month__c);

        System.Assert(updatedsystemBillListOne[1].Total_Due__c > 0);
        System.AssertNotEquals(0, updatedsystemBillListOne[1].Late_Fees__c );
        System.AssertEquals(0, updatedsystemBillListOne[1].Late_Payments__c );
        System.AssertEquals(631.07, updatedsystemBillListOne[1].Total_Payments_This_Month__c );
        Test.stopTest();
    }

    @isTest public static void testAdjustments2() {
        Test.startTest();
        List<Account_Bill__c> accountbilllist = [SELECT Id, Name,
            Bill_Number__c, Property_Account_ID__c
        FROM Account_Bill__c];

        Account accountA = [SELECT Id, Name
        FROM Account
        WHERE Name = 'Account A'];

        ChargentBase__Gateway__c chGateway  = [SELECT Id, Name, Entity__c
        FROM ChargentBase__Gateway__c
        LIMIT 1];

        for (Account_Bill__c abill : accountbilllist) {
            abill.Published__c = True;
        }
        update accountbilllist;

        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToUpdate = new List<ChargentOrders__Transaction__c>();
        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToNotUpdate = new List<ChargentOrders__Transaction__c>();
        for (Account_Bill__c accountbill : accountbilllist) {
            if(accountbill.Bill_Number__c == 2) {
                ChargentOrders__ChargentOrder__c orderA =
                    new ChargentOrders__ChargentOrder__c(ChargentOrders__Gateway__c = chGateway.Id,
                        ChargentOrders__Shipping_Name__c = chGateway.Entity__c,
                        ChargentOrders__Billing_First_Name__c = 'Cole',
                        ChargentOrders__Billing_Last_Name__c = 'Swain',
                        ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                        ChargentOrders__Billing_Zip_Postal__c = '02467',
                        ChargentOrders__Subtotal__c = 50,
                        ChargentOrders__Payment_Method__c = 'Credit Card',
                        Account_Bill__c = accountbill.Id,
                        ChargentOrders__Card_Type__c = 'Visa',
                        ChargentOrders__Card_Number__c = '411111111111',
                        ChargentOrders__Card_Security_Code__c = '999',
                        ChargentOrders__Card_Expiration_Month__c = '02',
                        ChargentOrders__Card_Expiration_Year__c = '2018',
                        ChargentOrders__Card_Last_4__c = '1111');

                insert orderA;

                ChargentOrders__Transaction__c transA =
                    new ChargentOrders__Transaction__c(ChargentOrders__Order__c = orderA.id,
                        ChargentOrders__Amount__c = 50,
                        ChargentOrders__Response_Status__c ='Approved',
                        ChargentOrders__Gateway_ID__c = chGateway.id,
                        ChargentOrders__Gateway__c = chGateway.id,
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
                        ChargentOrders__Gateway_ID__c = chGateway.id,
                        ChargentOrders__Gateway__c = chGateway.id,
                        Distributed_Among_System_Bills__c = false,
                        ChargentOrders__Response_Message__c = 'OK',
                        ChargentOrders__Type__c = 'Charge',
                        ChargentOrders__Payment_Method__c = 'Credit Card',
                        Activity_Type__c = 'Payment');
                chargentOrdersTransactionsToNotUpdate.add(transB);
            }
        }

        insert chargentOrdersTransactionsToUpdate;
        for (ChargentOrders__Transaction__c trans : chargentOrdersTransactionsToUpdate) {
            trans.Distributed_Among_System_Bills__c = true;
        }
        update chargentOrdersTransactionsToUpdate;
        insert chargentOrdersTransactionsToNotUpdate;

        List<System_Bill__c> updatedsystemBillListOne =
        [SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
            Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
            Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
            Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
            Property_Account__r.Directions_To_Write_Paper_Check__c, Payments_Net_Previous_Balances__c,
            Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
            Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
            Adjustments__c, Bill_Date__c, Due_Date__c, Refund_this_Balance__c,
            Waive_Late_Fees__c, Previous_Overpayments__c, Balance_Adjustment__c,
            Adjustments_UASB__c,
            Billing_Period_End_Date__c, Billing_Period_Start_Date__c
        FROM System_Bill__c
        ORDER BY Bill_Number__c];

        String oldCheckAddressField;
        String propertyAccountId;

        for (System_Bill__c editBill : updatedsystemBillListOne) {
            if (editBill.Bill_Number__c == 2) {
                oldCheckAddressField = editBill.Property_Account__r.Directions_To_Write_Paper_Check__c;
                propertyAccountId = editBill.Property_Account__r.Id;
                editBill.Waive_Late_Fees__c = True;
            }
        }
        update updatedsystemBillListOne;

        Account propertyAccount = [ SELECT Id, Name, Directions_To_Write_Paper_Check__c,
            Send_Checks_Address__c, Client_Brand_Key__c
        FROM Account
        WHERE Id = : propertyAccountId];

        System.assertNotEquals(oldCheckAddressField, propertyAccount.Directions_To_Write_Paper_Check__c);
        System.assert(propertyAccount.Directions_To_Write_Paper_Check__c.contains('Oxford Barrett St. P1'));
        System.assertEquals('Fake Lockbox Address, P.O Box 12345, Phoenix Arizona 02114', propertyAccount.Send_Checks_Address__c);
        System.assertEquals('AmpBlack', propertyAccount.Client_Brand_Key__c);

        Energy_Usage_Update__c prodUpdate = [SELECT Id, Name, Generate_Bills__c FROM Energy_Usage_Update__c WHERE Name = 'sssA - March 2016'];
        prodUpdate.Generate_Bills__c = True;
        update prodUpdate;

        APXT_BPM__Conductor__c congaRecord = new APXT_BPM__Conductor__c (APXT_BPM__Title__c = 'Conga Record');
        insert congaRecord;
        congaRecord.Apply_Overpay_Adjust__c = true;
        Test.stopTest();
        update congaRecord;

        List<Adjustment_Application__c> secondAdjustApp =   [SELECT Id, Name, Bill_Adjustment__c, System_Bill__c,
            Overpayment_Amount__c, Adjustment_Amount__c,
            Bill_Adjustment__r.Overpayment__c
        FROM Adjustment_Application__c
        WHERE Bill_Adjustment__r.Overpayment__c = true];
        System.AssertEquals(1, secondAdjustApp.size());
        System.AssertEquals(-118.93, secondAdjustApp[0].Overpayment_Amount__c);

        List<System_Bill__c> updatedsystemBillList = 
            [SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c, 
             Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c, 
             Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, 
             Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c, 
             Property_Account__r.Directions_To_Write_Paper_Check__c,
             Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
             Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c, 
             Adjustments__c, Bill_Date__c, Refund_this_Balance__c,
             Waive_Late_Fees__c, Previous_Overpayments__c, Balance_Adjustment__c,
             Adjustments_UASB__c, 
             Billing_Period_End_Date__c, Billing_Period_Start_Date__c
             FROM System_Bill__c
             ORDER BY Bill_Number__c];

        System.assertEquals(281.07, updatedsystemBillList[2].Total_Due__c );
        System.assertEquals(283.90, updatedsystemBillList[2].Balance_Net_late_Payments__c );
        System.assertEquals(-118.93, updatedsystemBillList[2].Previous_Overpayments__c );
        System.assertEquals(0, updatedsystemBillList[2].Adjustments_UASB__c );
    }

    @isTest public static void testMultipleEntities() {
        Test.startTest();
        List<Opportunity> oppSSS2 = [SELECT Id, Name, Shared_Solar_System__c, AccountId FROM Opportunity ORDER BY Name];

        Account_Bill__c acctBillToInsert = new Account_Bill__c (Bill_Number__c = 10,
            Parent_Account__c = oppSSS2[0].AccountId,
            Name = 'First Last Month 2016 B',
            Published__c = true,
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

        Account propertyAccount = [ SELECT Id, Name, Directions_To_Write_Paper_Check__c,
            Send_Checks_Address__c, Client_Brand_Key__c
        FROM Account
        WHERE Name = 'Account A'];

        System.assertEquals('No Payment Due', propertyAccount.Directions_To_Write_Paper_Check__c);
        System.assertEquals('BlueWave 137 Newbury Street Boston, MA 02114', propertyAccount.Send_Checks_Address__c);
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

        List<Account_Bill__c> listaccountBills = [ SELECT Id, Published__c
        FROM Account_Bill__c];

        for (Account_Bill__c acctBill : listaccountBills) {
            acctBill.Published__c = True;
        }

        update listaccountBills;
        Test.StartTest();

        System.runAs(userA){
            List<AggregateResult> systemBills = MyAccountController.getSystemBills(accountA.Id);
            for (AggregateResult lineItem : systemBills) {
                ChargentOrders__ChargentOrder__c billsToCharge = new ChargentOrders__ChargentOrder__c(
                    Account_Bill__c = (Id)lineItem.get('Account_Bill__c'),
                    ChargentOrders__Subtotal__c = (Decimal)lineItem.get('ChargentOrders__Subtotal__c'),
                    ChargentOrders__Shipping_Name__c = (String)lineItem.get('ChargentOrders__Shipping_Name__c'));
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
                    ChargentOrders__Card_Security_Code__c = '',
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
                    ChargentOrders__Card_Security_Code__c = '121',
                    ChargentOrders__Card_Expiration_Month__c = '02',
                    ChargentOrders__Card_Expiration_Year__c = '2020',
                    ChargentOrders__Billing_Address__c = '200 Street',
                    ChargentOrders__Billing_City__c = 'City',
                    ChargentOrders__Billing_State__c = 'MA',
                    ChargentOrders__Billing_Zip_Postal__c  = '02114',
                    ChargentOrders__Billing_First_Name__c = 'Jordan',
                    ChargentOrders__Billing_Last_Name__c = 'Testcase');
            List<String> getStatesList = CreateOrderandPaymentRequest.getStates();
            List<ChargentOrders__ChargentOrder__c> resultOne = CreateOrderandPaymentRequest.setChargeAmountandInsert(chOrderList, paymentInfoACH, true);
            List<ChargentOrders__ChargentOrder__c> resultTwo = CreateOrderandPaymentRequest.setChargeAmountandInsert(chOrderList, paymentInfoCC, false);

            List<ChargentOrders__ChargentOrder__c> newOrders = [SELECT Id, Name, ChargentOrders__Subtotal__c, ChargentOrders__Shipping_Name__c,
                Account_Bill__c, ChargentOrders__Bank_Name__c, ChargentOrders__Card_Expiration_Year__c
            FROM ChargentOrders__ChargentOrder__c
            ORDER BY ChargentOrders__Payment_Method__c];
            System.assertEquals(50, getStatesList.size());

            // Checking that the orders were inserted and that the merged data mapped correctly:
            System.assertEquals(2, newOrders.size());
            System.assertNotEquals(null, newOrders[0].Account_Bill__c);
            System.assertNotEquals(null, newOrders[1].Account_Bill__c);
            System.assertEquals(606.83, newOrders[0].ChargentOrders__Subtotal__c);
            System.assertEquals(606.83, newOrders[1].ChargentOrders__Subtotal__c);
            System.assertEquals('2020', newOrders[0].ChargentOrders__Card_Expiration_Year__c);
            System.assertEquals('Bank of America', newOrders[1].ChargentOrders__Bank_Name__c);

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

        //    System.assertEquals('Recurring', updatedTransactions[0].ChargentOrders__Order__r.ChargentOrders__Payment_Status__c);
            System.assertNotEquals('Recurring', updatedTransactions[1].ChargentOrders__Order__r.ChargentOrders__Payment_Status__c);
        }
        Test.StopTest();

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
            Status__c = 'Enacted by Utility'
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
}