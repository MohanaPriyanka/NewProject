@isTest
private class RecurringPaymentsHandlerTestClass{
    @testSetup public static void setupData() {
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c national_grid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{eversource, national_grid};
        // Create NMC
        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c (
            Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Current_Billing_Rate__c = true);

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c (
            Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = true);

        Utility_NMC_Tariff__c ngridbillNMC = new Utility_NMC_Tariff__c (
            Name = 'National Grid WCMA Class 2',
            Utility__c = 'National Grid',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Current_Billing_Rate__c = true);

        Utility_NMC_Tariff__c ngridsizeNMC = new Utility_NMC_Tariff__c (
            Name = 'National Grid WCMA Class 2',
            Utility__c = 'National Grid',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = true);

        insert everbillNMC;
        insert eversizeNMC;
        insert ngridsizeNMC;
        insert ngridbillNMC;


        // Create Load Zones and Service Territories

        Load_U__c everLZU = new Load_U__c (
            Name = '02633',
            Load_zone__c = 'SEMA Eversource',
            LZ__c = 'SEMA',
            Utility__C = 'Eversource',
            Town__c= 'Medfield');

        Load_U__c ngridLZU = new Load_U__c (
            Name = '01570',
            Load_zone__c= 'WCMA National Grid',
            LZ__c = 'WCMA',
            Utility__C = 'National Grid',
            Town__c= 'Westtown');

        insert everLZU;
        insert ngridLZU;

        Entity__c entityone = new Entity__c (
            Name = 'BarrettProjCo');

        insert entityone;


        Entity__c entitytwo = new Entity__c (
            Name = 'NotBarrettProjCo');

        insert entitytwo;
        insert new BW_Address__c(Name = 'BlueWave', Address_Line_One__c = '137 Newbury Street', Address_Line_Two__c = 'Boston, MA 02114');

        // Create Shared Solar Systems

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
        Service_Territories__c = 'SEMA',
        Open__c = true,
        BWC_Project_Entity_Manual__c = entityone.Id,
        Reserved_Capacity_kW_DC__c = '0',
        Capacity_Committed_kW_DC__c = 0,
        Total_System_Size_kWh_DC__c = 1445.86,
        Total_System_Size_kW_AC__c  = 996,
        System_Utility__c = 'Eversource',
        Credit_Score_Requirement__c = 200,
        Assignment_order__c = '1',
        Utility_NMC_Tariff__c = eversizeNMC.Id,
        Utility__c = eversource.Id,
        Expected_Yield_kWh_kW__c = 1300,
        Assemblage_Count__c = 1,
        Sales_Partners__c = 'All',
        Maximum_Subscription_Assemblage__c = 25);

        //  insert sss1;

        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
        Service_Territories__c = 'SEMA',
        Open__c = true,
        BWC_Project_Entity_Manual__c = entitytwo.Id,
        Reserved_Capacity_kW_DC__c = '0',
        Capacity_Committed_kW_DC__c = 0,
        Total_System_Size_kWh_DC__c = 1445.86,
        Total_System_Size_kW_AC__c  = 996,
        System_Utility__c = 'Eversource',
        Credit_Score_Requirement__c = 200,
        Assignment_order__c = '2',
        Utility_NMC_Tariff__c = eversizeNMC.Id,
        Utility__c = eversource.Id,
        Expected_Yield_kWh_kW__c = 1300,
        Assemblage_Count__c = 1,
        Sales_Partners__c = 'All',
        Maximum_Subscription_Assemblage__c = 25);


        insert new List<Shared_Solar_System__c>{sss1, sss2};


        // create Property Accounts

        Account accountA = new Account(name = 'Account A',
            RecordTypeId = '012j00000010Ha3',
            Recurring_Billing__c = true);

        Account accountB = new Account(name = 'Account B',
            RecordTypeId = '012j00000010Ha3',
            Recurring_Billing__c = true);

        Account accountC = new Account(name = 'Account C',
            RecordTypeId = '012j00000010Ha3',
            Recurring_Billing__c = true);

        Account accountD = new Account(name = 'Account D',
            RecordTypeId = '012j00000010Ha3',
            Recurring_Billing__c = true);

        insert new List<Account>{accountA, accountB, accountC, accountD};


        Utility_Account_Log__c ualog = new Utility_Account_Log__c(Name = '0000234',
            Account__c = accountA.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'jordan pentaleri');

        Utility_Account_Log__c ualogtwo = new Utility_Account_Log__c(Name = '0000256',
            Account__c = accountB.Id,
            Annual_Cost_of_Electricity__c = 15000,
            Name_on_Account__c = 'nick speyer');

        insert new List<Utility_Account_Log__c>{ualog, ualogtwo};

        Opportunity opportunityone = new Opportunity(Name = 'OppOne',
            AccountId = accountA.Id,
            Shared_Solar_System__c = sss1.Id,
            StageName = 'Complete',
            CloseDate = System.today());

        Opportunity opportunitytwo = new Opportunity(Name = 'OppTwo',
            AccountId = accountA.Id,
            Shared_Solar_System__c = sss2.Id,
            StageName = 'Complete',
            CloseDate = System.today());

        Opportunity opportunitythree = new Opportunity(Name = 'OppThree',
            AccountId = accountB.Id,
            Shared_Solar_System__c = sss2.Id,
            StageName = 'Complete',
            CloseDate = System.today());

        insert new List<Opportunity>{opportunityone, opportunitytwo, opportunitythree};

        Utility_Account_Subscription__c uasone = new Utility_Account_Subscription__c(
            Name = '0000234',
            Utility_Account_Log__c = ualog.Id,
            Opportunity__c = opportunityone.Id,
            Calculated_Annual_Cost_of_Electricity__c = 4000,
            Subscribed_Annual_Cost_of_Electricity__c = 4000);

        Utility_Account_Subscription__c uastwo = new Utility_Account_Subscription__c(
            Name = '000-0235',
            Utility_Account_Log__c = ualog.Id,
            Opportunity__c = opportunitytwo.Id,
            Calculated_Annual_Cost_of_Electricity__c = 6000,
            Subscribed_Annual_Cost_of_Electricity__c = 6000);

        Utility_Account_Subscription__c uasthree = new Utility_Account_Subscription__c(
            Name = '000-0236',
            Utility_Account_Log__c = ualogtwo.Id,
            Opportunity__c = opportunitythree.Id,
            Calculated_Annual_Cost_of_Electricity__c = 1800,
            Subscribed_Annual_Cost_of_Electricity__c = 1800);

        insert new List<Utility_Account_Subscription__c>{uasone, uastwo, uasthree};

        uasone.Customer_Subscription_KW_DC_STATIC__c = 25;
        uastwo.Customer_Subscription_KW_DC_STATIC__c = 20;
        uasthree.Customer_Subscription_KW_DC_STATIC__c = 20;

        update new List<Utility_Account_Subscription__c>{uasone, uastwo, uasthree};

        // Log Production Update - First Month

        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);

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

        Energy_Usage_Update__c productionupdateA2 = new Energy_Usage_Update__c (
            Name = 'sssA - February 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.Id,
            Production__c = 120000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateMar,
            Total_System_NMCs__c = 22176,
            Date__c = myDateFeb
            );

        insert productionupdateA2;

        Energy_Usage_Update__c productionupdateB2 = new Energy_Usage_Update__c (
            Name = 'sssB - February 2016',
            Shared_Solar_System__c = sss2.id,
            Schedule_Z__c = scheduleZ2.Id,
            Production__c = 14000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateApr,
            Total_System_NMCs__c = 25872,
            Date__c = myDateFeb
            );

        insert productionupdateB2;
        productionupdateA2.Generate_Bills__c = true;
        productionupdateB2.Generate_Bills__c = true;
        update productionupdateA2;
        update productionupdateB2;

        Map<String, System_Bill__c> systemBillMap = new Map<String, System_Bill__c> ();
        for ( System_Bill__c sb : [SELECT Id, Name, Account_Bill__r.Id, Opportunity__r.Name,
                                    Shared_Solar_System_Name__c 
                                  FROM System_Bill__c]){
            systemBillMap.put(sb.Opportunity__r.Name, sb);
        }

        Account_Bill__c noSystemBills = new Account_Bill__c (Name='Account Bill Cancelled',
            Bill_Number__c = 1,
            Parent_Account__c = AccountC.Id);

        Account_Bill__c noSystemBillsSecondMonth = new Account_Bill__c (Name='Account Bill Cancelled',
            Bill_Number__c = 2,
            Parent_Account__c = AccountC.Id);

        Account_Bill__c accountBillCancelled = new Account_Bill__c (Name='Account Bill Cancelled',
            Bill_Number__c = 1,
            Parent_Account__c = AccountD.Id);

        insert new List<Account_Bill__c>{noSystemBills, noSystemBillsSecondMonth, accountBillCancelled};

        ChargentBase__Gateway__c chGatewayone  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway One',
            ChargentBase__Merchant_ID__c = '235986',
            ChargentBase__Active__c = true,
            Entity__c = entityone.Id,
            Shared_Solar_System__c = sss1.id);
        insert chGatewayone;

        ChargentBase__Gateway__c chGatewaytwo  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway Two',
            ChargentBase__Merchant_ID__c = '235116',
            ChargentBase__Active__c = true,
            Entity__c = entitytwo.Id,
            Shared_Solar_System__c = sss2.id);
        insert chGatewaytwo;

        // 2 Recurring Orders for the 2 Opportunities (SSS1 and SS2 for Account A)
        ChargentOrders__ChargentOrder__c orderA1  = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Gateway__c = chGatewayone.Id,
            ChargentOrders__Shipping_Name__c = entityone.Id,
            ChargentOrders__Billing_First_Name__c = 'Jordan',
            ChargentOrders__Billing_Last_Name__c = 'Pentaleri',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 603.92,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillMap.get('OppOne').Account_Bill__r.Id,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Security_Code__c = '999',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Start_Date__c = system.today(),
            ChargentOrders__Charge_Date__c = '30');

        ChargentOrders__ChargentOrder__c orderA2  = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Gateway__c = chGatewaytwo.Id,
            ChargentOrders__Shipping_Name__c = entitytwo.id,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 100.22,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillMap.get('OppTwo').Account_Bill__r.Id,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Security_Code__c = '999',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Start_Date__c = system.today(),
            ChargentOrders__Charge_Date__c = '27');

        // 1 Recurring Order for the 1 Opportunity (SS2 for Account B)
        ChargentOrders__ChargentOrder__c orderA3  = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Gateway__c = chGatewaytwo.Id,
            ChargentOrders__Shipping_Name__c = entitytwo.id,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 100.22,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillMap.get('OppThree').Account_Bill__r.Id,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Security_Code__c = '999',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Start_Date__c = system.today(),
            ChargentOrders__Charge_Date__c = '25');

        // Test failures for Account C and Account D, which do not have any system bills and should change to stopped
        ChargentOrders__ChargentOrder__c orderNotLinkedToAccountBill  = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Gateway__c = chGatewaytwo.Id,
            ChargentOrders__Shipping_Name__c = entitytwo.id,
            ChargentOrders__Billing_First_Name__c = 'Jordan',
            ChargentOrders__Billing_Last_Name__c = 'Pentaleri',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 555.44,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Security_Code__c = '999',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Start_Date__c = system.today(),
            ChargentOrders__Charge_Date__c = '15');

        ChargentOrders__ChargentOrder__c orderNoSystemBills  = new ChargentOrders__ChargentOrder__c(
            Account_Bill__c = accountBillCancelled.Id,
            ChargentOrders__Gateway__c = chGatewaytwo.Id,
            ChargentOrders__Shipping_Name__c = entitytwo.id,
            ChargentOrders__Billing_First_Name__c = 'Jordan',
            ChargentOrders__Billing_Last_Name__c = 'Pentaleri',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 555.44,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Security_Code__c = '999',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Start_Date__c = system.today(),
            ChargentOrders__Charge_Date__c = '15');

        ChargentOrders__ChargentOrder__c orderCancelledCustomer  = new ChargentOrders__ChargentOrder__c(
            Account_Bill__c = noSystemBills.Id,
            ChargentOrders__Gateway__c = chGatewaytwo.Id,
            ChargentOrders__Shipping_Name__c = entitytwo.id,
            ChargentOrders__Billing_First_Name__c = 'Jordan',
            ChargentOrders__Billing_Last_Name__c = 'Pentaleri',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 555.44,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Security_Code__c = '999',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Start_Date__c = system.today(),
            ChargentOrders__Charge_Date__c = '15');


        insert new List<ChargentOrders__ChargentOrder__c>{orderA1, orderA2, orderA3, orderNotLinkedToAccountBill, orderNoSystemBills, orderCancelledCustomer};

        Energy_Usage_Update__c productionupdateC1 = new Energy_Usage_Update__c (
            Name = 'sssA - March 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.Id,
            Production__c = 120000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateMar,
            Total_System_NMCs__c = 22176,
            Date__c = myDateMar
            );

        insert productionupdateC1;

        Energy_Usage_Update__c productionupdateD1 = new Energy_Usage_Update__c (
            Name = 'sssB - March 2016',
            Shared_Solar_System__c = sss2.id,
            Schedule_Z__c = scheduleZ2.Id,
            Production__c = 14000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateApr,
            Total_System_NMCs__c = 25872,
            Date__c = myDateMar
            );

        insert productionupdateD1;
    }

    static testMethod void scheduleJob(){
        Test.startTest();

        // Test scheduling of batch:
        Datetime dt = Datetime.now().addMinutes(0);
        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        String CRON_EXP = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
        System.schedule('RecurringPaymentsHandler', CRON_EXP, batchToRun);

        Test.stopTest();
    }

    static testMethod void testScheduledJobResults() {
        Test.startTest();
        List<Energy_Usage_Update__c> productionUpdateList = [SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c,
                                                              YearDate__c, Credits_on_Bill_Period__c,
                                                              MonthDate__c, Total_System_NMCs__c, Production__c, 
                                                              Generate_Bills__c, Total_System_NMCs_2_of_4__c, 
                                                              Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c, 
                                                              Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c, 
                                                              Production_kWh_4_of_4__c, Net_Metering_Rate_Applied__c,
                                                              Size_off_NMCs__c, Date__c, Billing_Period_Start_Date__c,
                                                              Billing_Period_End_Date__c, Month_Number__c,
                                                              Net_Metering_Rate_Applied_2_of_4__c,
                                                              Net_Metering_Rate_Applied_3_of_4__c,
                                                              Net_Metering_Rate_Applied_4_of_4__c
                                                             FROM Energy_Usage_Update__c
                                                             WHERE Name = 'sssB - March 2016'
                                                             OR Name = 'sssA - March 2016'
                                                             LIMIT 2];
        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(productionUpdateList);
        ee.runBills();

        List<System_Bill__c> systemBillListtwo = [
            SELECT Id,
                 Name,
                 Account_Bill__c,
                 Waive_Late_Fees__c,
                 Total_Due__c,
                 Due_This_Month__c,
                 Shared_Solar_System__c,
                 Shared_Solar_System_ID__c,
                 Bill_Number__c,
                 Property_Account_ID__c
            FROM System_Bill__c
            ORDER BY Bill_Number__c DESC];

        // Two accounts: 
        // Account A has 2 opportunities, which have Feb and March Bill
        // Account B has 1 opportunity, which has Feb and March Bill
        System.assertEquals(6, systemBillListtwo.size());

        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        database.executeBatch(batchToRun,50);
        Test.stopTest();

        List<ChargentOrders__ChargentOrder__c> orderlist = [
              SELECT Id,
                     ChargentOrders__Payment_Status__c,
                     ChargentOrders__Charge_Date__c,
                     Reason_for_Recurring_Stop__c,
                     Account_Bill__r.Bill_Number__c,
                     Account_Bill__r.Name,
                     ChargentOrders__Charge_Amount__c,
                     Account_Bill__r.Parent_Account__r.Recurring_Billing__c
              FROM ChargentOrders__ChargentOrder__c];

        // Six Original Chargent Orders:
        // 3 that should be marked as stopped (all charge date of 15) because 0 SBs
        // 3 that should have been moved to the newer bill
        System.assertEquals(6,orderlist.size());

        for (ChargentOrders__ChargentOrder__c cho : orderlist) {
            if (cho.ChargentOrders__Charge_Date__c == '15') {
                System.assertEquals(0, cho.ChargentOrders__Charge_Amount__c);
                System.assertEquals('Stopped', cho.ChargentOrders__Payment_Status__c);
                System.assertNotEquals(NULL, cho.Reason_for_Recurring_Stop__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '30') {
                System.assertEquals('Account A March 2016', cho.Account_Bill__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '27') {
                System.assertEquals('Account A March 2016', cho.Account_Bill__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '25') {
                System.assertEquals('Account B March 2016', cho.Account_Bill__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            }
        }
    }

    static testMethod void cloneOrderCorrectly() {
        Test.startTest();
        List<Energy_Usage_Update__c> productionUpdateList = [SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c,
                                                              YearDate__c, Credits_on_Bill_Period__c,
                                                              MonthDate__c, Total_System_NMCs__c, Production__c, 
                                                              Generate_Bills__c, Total_System_NMCs_2_of_4__c, 
                                                              Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c, 
                                                              Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c, 
                                                              Production_kWh_4_of_4__c, Net_Metering_Rate_Applied__c,
                                                              Size_off_NMCs__c, Date__c, Billing_Period_Start_Date__c,
                                                              Billing_Period_End_Date__c, Month_Number__c,
                                                              Net_Metering_Rate_Applied_2_of_4__c,
                                                              Net_Metering_Rate_Applied_3_of_4__c,
                                                              Net_Metering_Rate_Applied_4_of_4__c
                                                             FROM Energy_Usage_Update__c
                                                             WHERE Name = 'sssB - March 2016'
                                                             OR Name = 'sssA - March 2016'
                                                             LIMIT 2];
        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(productionUpdateList);
        ee.runBills();

        // Remove the Recurring Order on Account A, SSS1 and check that it is created off a clone:
        ChargentOrders__ChargentOrder__c orderToDelete = [  SELECT Id
                                                            FROM ChargentOrders__ChargentOrder__c
                                                            WHERE ChargentOrders__Gateway__r.Name = 'Chargent Gateway One'
                                                            AND ChargentOrders__Charge_Date__c = '30'
                                                            LIMIT 1];
        delete orderToDelete;

        List<ChargentOrders__ChargentOrder__c> originalOrderCount = [SELECT Id
                                                                    FROM ChargentOrders__ChargentOrder__c];
        System.assertEquals(5,originalOrderCount.size());

        List<System_Bill__c> systemBillListtwo = [
            SELECT Id,
                 Name,
                 Account_Bill__c,
                 Waive_Late_Fees__c,
                 Total_Due__c,
                 Due_This_Month__c,
                 Shared_Solar_System__c,
                 Shared_Solar_System_ID__c,
                 Bill_Number__c,
                 Property_Account_ID__c
            FROM System_Bill__c
            ORDER BY Bill_Number__c DESC];

        // Two accounts: 
        // Account A has 2 opportunities, which have Feb and March Bill
        // Account B has 1 opportunity, which has Feb and March Bill
        System.assertEquals(6, systemBillListtwo.size());

        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        database.executeBatch(batchToRun,50);
        Test.stopTest();

        List<ChargentOrders__ChargentOrder__c> orderlist = [
              SELECT Id,
                     ChargentOrders__Payment_Status__c,
                     ChargentOrders__Charge_Date__c,
                     Reason_for_Recurring_Stop__c,
                     Account_Bill__r.Bill_Number__c,
                     Account_Bill__r.Name,
                     ChargentOrders__Charge_Amount__c,
                     Account_Bill__r.Parent_Account__r.Recurring_Billing__c
              FROM ChargentOrders__ChargentOrder__c];

        // Six Original Chargent Orders: 
        // 3 that should be marked as stopped (all charge date of 15) because 0 SBs
        // 2 that should have been moved to the newer bill
        // 1 that should have been cloned
        System.assertEquals(6,orderlist.size());

        for (ChargentOrders__ChargentOrder__c cho : orderlist) {
            if (cho.ChargentOrders__Charge_Date__c == '15') {
                System.assertEquals(0, cho.ChargentOrders__Charge_Amount__c);
                System.assertEquals('Stopped', cho.ChargentOrders__Payment_Status__c);
                System.assertNotEquals(NULL, cho.Reason_for_Recurring_Stop__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '30') {
                System.assertEquals('Account A March 2016', cho.Account_Bill__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
                System.assertEquals('Cloned Order', cho.Comments__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '27') {
                System.assertEquals('Account A March 2016', cho.Account_Bill__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '25') {
                System.assertEquals('Account B March 2016', cho.Account_Bill__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            }
        }
    }

    static testMethod void updateParentAccountOnStop() {
        Account oldAccountC = [
            SELECT Id,
                   Recurring_Billing__c
            FROM Account
            WHERE Name = 'Account C'];

        List<ChargentOrders__ChargentOrder__c> accountOrders = new List<ChargentOrders__ChargentOrder__c>([
            SELECT Id,
                   ChargentOrders__Payment_Status__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Account_Bill__r.Parent_Account__r.id = : oldAccountC.Id
        ]);

        System.assertEquals(true, oldAccountC.Recurring_Billing__c);

        Test.startTest();
        for (ChargentOrders__ChargentOrder__c order : accountOrders) {
            order.ChargentOrders__Payment_Status__c = 'Stopped';
        }
        update accountOrders;
        Test.stopTest();

        Account newAccountC = [
            SELECT Id,
                   Recurring_Billing__c
            FROM Account
            WHERE Name = 'Account C'];

        System.assertEquals(false, newAccountC.Recurring_Billing__c);
    }

    static testMethod void updateParentAccountOnRecurring() {
        Account oldAccountC = [
            SELECT Id,
                   Recurring_Billing__c
            FROM Account
            WHERE Name = 'Account C'];

        List<ChargentOrders__ChargentOrder__c> accountOrders = new List<ChargentOrders__ChargentOrder__c>([
            SELECT Id,
                   ChargentOrders__Payment_Status__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Account_Bill__r.Parent_Account__r.id = : oldAccountC.Id
        ]);

        System.assertEquals(true, oldAccountC.Recurring_Billing__c);

        Test.startTest();
        for (ChargentOrders__ChargentOrder__c order : accountOrders) {
            order.ChargentOrders__Payment_Status__c = 'Stopped';
        }
        update accountOrders;

        for (ChargentOrders__ChargentOrder__c order : accountOrders) {
            order.ChargentOrders__Payment_Status__c = 'Recurring';
        }
        update accountOrders;
        Test.stopTest();

        Account newAccountC = [
            SELECT Id,
                   Recurring_Billing__c
            FROM Account
            WHERE Name = 'Account C'];

        System.assertEquals(true, newAccountC.Recurring_Billing__c);
    }

    static testMethod void doNotUpdateParentAccountIfOneRecurringOrder() {
        /*
        Tests if a chargent order is updated and the account has active
        recurring payments. Then, the parent account still has recurring_billing
        marked as true.
        */
        Account oldAccountC = [
            SELECT Id,
                   Recurring_Billing__c
            FROM Account
            WHERE Name = 'Account C'];

        List<ChargentOrders__ChargentOrder__c> accountOrders = new List<ChargentOrders__ChargentOrder__c>([
            SELECT Id,
                   ChargentOrders__Payment_Status__c,
                   Account_Bill__c,
                   ChargentOrders__Gateway__c,
                   ChargentOrders__Shipping_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Account_Bill__r.Parent_Account__r.id = : oldAccountC.Id
        ]);

        /*
        insert a recurring ChargentOrder after collecting all the other account orders
        because we'll change those, but we want the account to stay flagged as 'autopay'
        */
        ChargentOrders__ChargentOrder__c recurringPayment1  = new ChargentOrders__ChargentOrder__c(
            Account_Bill__c = accountOrders[0].Account_Bill__c,
            ChargentOrders__Gateway__c = accountOrders[0].ChargentOrders__Gateway__c,
            ChargentOrders__Shipping_Name__c = accountOrders[0].ChargentOrders__Shipping_Name__c,
            ChargentOrders__Billing_First_Name__c = 'Jordan',
            ChargentOrders__Billing_Last_Name__c = 'Pentaleri',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 555.44,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Security_Code__c = '999',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Start_Date__c = system.today(),
            ChargentOrders__Charge_Date__c = '15');

        ChargentOrders__ChargentOrder__c recurringPayment2  = new ChargentOrders__ChargentOrder__c(
            Account_Bill__c = accountOrders[0].Account_Bill__c,
            ChargentOrders__Gateway__c = accountOrders[0].ChargentOrders__Gateway__c,
            ChargentOrders__Shipping_Name__c = accountOrders[0].ChargentOrders__Shipping_Name__c,
            ChargentOrders__Billing_First_Name__c = 'Jordan',
            ChargentOrders__Billing_Last_Name__c = 'Pentaleri',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 555.44,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Security_Code__c = '999',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Start_Date__c = system.today(),
            ChargentOrders__Charge_Date__c = '15');


        insert new List<ChargentOrders__ChargentOrder__c>{recurringPayment1, recurringPayment2};

        System.assertEquals(true, oldAccountC.Recurring_Billing__c);

        Test.startTest();
        for (ChargentOrders__ChargentOrder__c order : accountOrders) {
            order.ChargentOrders__Payment_Status__c = 'Stopped';
        }
        update accountOrders;
        Test.stopTest();

        Account newAccountC = [
            SELECT Id,
                   Recurring_Billing__c
            FROM Account
            WHERE Name = 'Account C'];

        System.assertEquals(true, newAccountC.Recurring_Billing__c);
    }

    static testMethod void moveChargentOrderFromPropertyAcctToFirstAcctBill (){
       //Tests the moving of the Chargent Order from the Property Account to the first Account Bill

        Account propAccountA = new Account(name = 'Property Account A',
            RecordTypeId = '012j00000010HeQ');

        insert propAccountA;

        Utility_Account_Log__c ualog3 = new Utility_Account_Log__c(Name = '0000333',
            Account__c = propAccountA.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'sarah renfro');

        insert ualog3;

        Entity__c entityA = new Entity__c (
            Name = 'BarrettProjCo');

        insert entityA;
        System.debug('4.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        Test.startTest();

        Shared_Solar_System__c sssA = [ SELECT Id
                                            FROM Shared_Solar_System__c
                                            WHERE name = 'Oxford Barrett St. P1'];

        ChargentBase__Gateway__c chGatewayA  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway A',
            ChargentBase__Merchant_ID__c = '235986',
            ChargentBase__Active__c = true,
            Entity__c = entityA.Id,
            Shared_Solar_System__c = sssA.id);
        insert chGatewayA;

        Opportunity opportunityA = new Opportunity(Name = 'OppA',
            AccountId = propAccountA.Id,
            Shared_Solar_System__c = sssA.Id,
            StageName = 'Complete',
            CloseDate = System.today());

        insert opportunityA;

        Utility_Account_Subscription__c uasA = new Utility_Account_Subscription__c(
            Name = '0000333',
            Utility_Account_Log__c = ualog3.Id,
            Opportunity__c = opportunityA.Id,
            Calculated_Annual_Cost_of_Electricity__c = 10000,
            Subscribed_Annual_Cost_of_Electricity__c = 10000);

        insert uasA;

        uasA.Customer_Subscription_KW_DC_STATIC__c = 25;

        update uasA;

        Schedule_Z__c scheduleZA = new Schedule_Z__c(
            Name = '18-0333 Oxford Barrett St. P1',
            Shared_Solar_System__c = sssA.Id,
            Status__c = 'Billing');

        insert scheduleZA;
        System.debug('4.Number of Queries used in this apex code so far: ' + Limits.getQueries());

        //Test first Account Bill - Chargent Order linked to Property Account
        ChargentOrders__ChargentOrder__c orderFirstAcctBill  = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c = propAccountA.Id,
            ChargentOrders__Gateway__c = chGatewayA.Id,
            ChargentOrders__Shipping_Name__c = entityA.Id,
            ChargentOrders__Billing_First_Name__c = 'SarahRenfro',
            ChargentOrders__Billing_Last_Name__c = 'Renfro',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 555.44,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Security_Code__c = '999',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Payment_Frequency__c = 'Once');

        insert orderFirstAcctBill;

        //Create first Account Bill. Created through Production Updates
        Energy_Usage_Update__c productionupdateA = [SELECT Id
                                                    FROM Energy_Usage_Update__c
                                                    WHERE Name = 'sssA - March 2016'];

        productionupdateA.Schedule_Z__c = scheduleZA.id;

        update productionUpdateA;
        update sssA;


        List<Account_Bill__c> acctBills = [ SELECT Id, Name, Is_First_Bill__c
                                            FROM Account_Bill__c ];

        System.assertEquals(5, acctBills.size() );

        List<Energy_Usage_Update__c> productionUpdateList = [ SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c,
                                                                YearDate__c, Credits_on_Bill_Period__c,
                                                                MonthDate__c, Total_System_NMCs__c, Production__c,
                                                                Generate_Bills__c, Total_System_NMCs_2_of_4__c,
                                                                Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c,
                                                                Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c,
                                                                Production_kWh_4_of_4__c, Net_Metering_Rate_Applied__c,
                                                                Size_off_NMCs__c, Date__c, Billing_Period_Start_Date__c,
                                                                Billing_Period_End_Date__c, Month_Number__c,
                                                                Net_Metering_Rate_Applied_2_of_4__c,
                                                                Net_Metering_Rate_Applied_3_of_4__c,
                                                                Net_Metering_Rate_Applied_4_of_4__c
                                                            FROM Energy_Usage_Update__c
                                                            WHERE Name = 'sssA - March 2016'];



        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(productionUpdateList);
        ee.runBills();

        List<Account_Bill__c> acctBillsList = [ SELECT Id, Name
                                                FROM Account_Bill__c ];

        System.assertEquals(7, acctBillsList.size() );

        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        database.executeBatch(batchToRun,50);
        Test.stopTest();

        //Check to see if Chargent Order's Account Name is null and Account Bill is = to AB
        ChargentOrders__ChargentOrder__c checkCO = [SELECT Id, Account_Bill__c, ChargentOrders__Account__c, ChargentOrders__Card_Security_Code__c, Entity_Name__c
                                                    FROM ChargentOrders__ChargentOrder__c
                                                    WHERE ChargentOrders__Billing_First_Name__c = 'SarahRenfro'  ];

        Account_Bill__c checkAB = [ SELECT Id, Property_Account_Name__c, Is_First_Bill__c, Parent_Account__c
                                    FROM Account_Bill__c
                                    WHERE Parent_Account__c = :propAccountA.Id];

        //Check if CO and AB were created
        System.assertNotEquals(null, checkCO.Account_Bill__c);
        System.assertEquals(null, checkCO.ChargentOrders__Account__c);
        System.assertEquals(checkCO.Account_Bill__c, checkAB.Id);
        System.assertEquals(false, checkAB.Is_First_Bill__c);

    }

    static testMethod void updateParentAccountIfOtherOrdersNotRecurring() {
        /*
        Tests if a chargent order is updated and the account does not have active
        recurring payments. Then, the parent account is not longer autopay
        */
        Account oldAccountC = [
            SELECT Id,
                   Recurring_Billing__c
            FROM Account
            WHERE Name = 'Account C'];

        List<ChargentOrders__ChargentOrder__c> accountOrders = new List<ChargentOrders__ChargentOrder__c>([
            SELECT Id,
                   ChargentOrders__Payment_Status__c,
                   Account_Bill__c,
                   ChargentOrders__Gateway__c,
                   ChargentOrders__Shipping_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Account_Bill__r.Parent_Account__r.id = : oldAccountC.Id
        ]);

        /*
        insert a recurring ChargentOrder after collecting all the other account orders
        because we'll change those, but we want the account to no longer be 'autopay'
        */
        ChargentOrders__ChargentOrder__c recurringPayment  = new ChargentOrders__ChargentOrder__c(
            Account_Bill__c = accountOrders[0].Account_Bill__c,
            ChargentOrders__Gateway__c = accountOrders[0].ChargentOrders__Gateway__c,
            ChargentOrders__Shipping_Name__c = accountOrders[0].ChargentOrders__Shipping_Name__c,
            ChargentOrders__Billing_First_Name__c = 'Jordan',
            ChargentOrders__Billing_Last_Name__c = 'Pentaleri',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 555.44,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Security_Code__c = '999',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Payment_Status__c = 'Stopped',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Start_Date__c = system.today(),
            ChargentOrders__Charge_Date__c = '15');

        insert recurringPayment;

        System.assertEquals(true, oldAccountC.Recurring_Billing__c);

        Test.startTest();
        for (ChargentOrders__ChargentOrder__c order : accountOrders) {
            order.ChargentOrders__Payment_Status__c = 'Stopped';
        }
        update accountOrders;
        Test.stopTest();

        Account newAccountC = [
            SELECT Id,
                   Recurring_Billing__c
            FROM Account
            WHERE Name = 'Account C'];

        System.assertEquals(false, newAccountC.Recurring_Billing__c);
    }
}