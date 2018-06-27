@isTest
private class RecurringPaymentsHandlerTestClass{
    @testSetup public static void setupData() {
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

        ChargentBase__Gateway__c chGatewayone  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway One',
            ChargentBase__Merchant_ID__c = '235986',
            ChargentBase__Active__c = true);
        insert chGatewayone;

        ChargentBase__Gateway__c chGatewaytwo  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway Two',
            ChargentBase__Merchant_ID__c = '235116',
            ChargentBase__Active__c = true);
        insert chGatewaytwo;

        Entity__c entityone = new Entity__c (
            Name = 'BarrettProjCo',
            Gateway__c = chGatewayone.Id
        );

        insert entityone;


        Entity__c entitytwo = new Entity__c (
            Name = 'NotBarrettProjCo',
            Gateway__c = chGatewaytwo.Id
        );

        insert entitytwo;
        insert new BW_Address__c(Name = 'BlueWave', Address_Line_One__c = '137 Newbury Street', Address_Line_Two__c = 'Boston, MA 02114');

        // Create Shared Solar Systems

        Shared_Solar_System__c sss1 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
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
        Expected_Yield_kWh_kW__c = 1300,
        Assemblage_Count__c = 1,
        Sales_Partners__c = 'All',
        Maximum_Subscription_Assemblage__c = 25));

        //  insert sss1;

        Shared_Solar_System__c sss2 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
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
        Expected_Yield_kWh_kW__c = 1300,
        Assemblage_Count__c = 1,
        Sales_Partners__c = 'All',
        Maximum_Subscription_Assemblage__c = 25));


        insert new List<Shared_Solar_System__c>{sss1, sss2};


        // create Parent Accounts

        Account accountA = new Account(name = 'Account A',
            RecordTypeId = '012j00000010Ha3',
            Recurring_Billing__c = true);
        insert accountA;

        Account accountB = new Account(name = 'Account B',
            RecordTypeId = '012j00000010Ha3',
            Recurring_Billing__c = true);
        insert accountB;

        Account accountC = new Account(name = 'Account C',
            RecordTypeId = '012j00000010Ha3',
            Recurring_Billing__c = true);
        insert accountC;

        Account accountD = new Account(name = 'Account D',
            RecordTypeId = '012j00000010Ha3',
            Recurring_Billing__c = true);
        insert accountD;

        Utility_Account_Log__c ualog = (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Name = '0000234',
            Account__c = accountA.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'jordan pentaleri'));
        insert ualog;

        Utility_Account_Log__c ualogtwo = (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Name = '0000256',
            Account__c = accountB.Id,
            Annual_Cost_of_Electricity__c = 15000,
            Name_on_Account__c = 'nick speyer'));
        insert ualogtwo;


        Opportunity opportunityone = (Opportunity)TestFactory.createSObject(new Opportunity(Name = 'Jordan Jordan',
            AccountId = accountA.Id,
            Shared_Solar_System__c = sss1.Id,
            StageName = 'Complete',
            CloseDate = System.today()));

        Opportunity opportunitytwo = (Opportunity)TestFactory.createSObject(new Opportunity(Name = 'Jordan Jordan',
            AccountId = accountA.Id,
            Shared_Solar_System__c = sss2.Id,
            StageName = 'Complete',
            CloseDate = System.today()));

        Opportunity opportunitythree = (Opportunity)TestFactory.createSObject(new Opportunity(Name = 'Nick Speyer',
            AccountId = accountB.Id,
            Shared_Solar_System__c = sss2.Id,
            StageName = 'Complete',
            CloseDate = System.today()));

        insert opportunityone;
        insert opportunitytwo;
        insert opportunitythree;

        Utility_Account_Subscription__c uasone = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
            Name = '0000234',
            Utility_Account_Log__c = ualog.Id,
            Opportunity__c = opportunityone.Id,
            Calculated_Annual_Cost_of_Electricity__c = 4000,
            Subscribed_Annual_Cost_of_Electricity__c = 4000));

        Utility_Account_Subscription__c uastwo = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
            Name = '000-0235',
            Utility_Account_Log__c = ualog.Id,
            Opportunity__c = opportunitytwo.Id,
            Calculated_Annual_Cost_of_Electricity__c = 6000,
            Subscribed_Annual_Cost_of_Electricity__c = 6000));

        Utility_Account_Subscription__c uasthree = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
            Name = '000-0236',
            Utility_Account_Log__c = ualogtwo.Id,
            Opportunity__c = opportunitythree.Id,
            Calculated_Annual_Cost_of_Electricity__c = 1800,
            Subscribed_Annual_Cost_of_Electricity__c = 1800));

        insert uasone;
        insert uastwo;
        insert uasthree;

        uasone.Customer_Subscription_KW_DC_STATIC__c = 25;
        uastwo.Customer_Subscription_KW_DC_STATIC__c = 20;
        uasthree.Customer_Subscription_KW_DC_STATIC__c = 20;

        update uasone;
        update uastwo;
        update uasthree;

        // Log Production Update - First Month

        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);

        Energy_Usage_Update__c productionupdateA2 = new Energy_Usage_Update__c (
            Name = 'sssA - February 2016',
            Shared_Solar_System__c = sss1.id,
            Production__c = 120000,
            Date__c = myDateFeb
            );

        insert productionupdateA2;

        Energy_Usage_Update__c productionupdateB2 = new Energy_Usage_Update__c (
            Name = 'sssB - February 2016',
            Shared_Solar_System__c = sss2.id,
            Production__c = 14000,
            Date__c = myDateFeb
            );

        insert productionupdateB2;
        productionupdateA2.Generate_Bills__c = true;
        productionupdateB2.Generate_Bills__c = true;
        update productionupdateA2;
        update productionupdateB2;

        Account_Bill__c noSystemBills = new Account_Bill__c (Name='Account Bill Cancelled',
            Bill_Number__c = 1,
            Parent_Account__c = AccountC.Id);
        insert noSystemBills;

        Account_Bill__c noSystemBillsSecondMonth = new Account_Bill__c (Name='Account Bill Cancelled',
            Bill_Number__c = 2,
            Parent_Account__c = AccountC.Id);
        insert noSystemBillsSecondMonth;

        Account_Bill__c accountBillCancelled = new Account_Bill__c (Name='Account Bill Cancelled',
            Bill_Number__c = 1,
            Parent_Account__c = AccountD.Id);
        insert accountBillCancelled;

        List<System_Bill__c> systemBillList = [SELECT Id, Name, Waive_Late_Fees__c, Account_Bill__c, Total_Due__c, Due_This_Month__c,
        Shared_Solar_System__c, Shared_Solar_System_ID__c, Bill_Number__c, Property_Account_ID__c
        FROM System_Bill__c
        ORDER BY Bill_NUmber__c DESC];

        // Query for system bills that were created from the production update
        for (System_Bill__c systemBill : systemBillList) {

            if (systembill.Shared_Solar_System__c == sss1.id) {
                ChargentOrders__ChargentOrder__c orderA1  = new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Account__c = systemBill.Property_Account_Id__c,
                    ChargentOrders__Gateway__c = chGatewayone.Id,
                    ChargentOrders__Shipping_Name__c = entityone.Id,
                    ChargentOrders__Billing_First_Name__c = 'Jordan',
                    ChargentOrders__Billing_Last_Name__c = 'Pentaleri',
                    ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                    ChargentOrders__Billing_Zip_Postal__c = '02467',
                    ChargentOrders__Subtotal__c = 603.92,
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    Account_Bill__c = systembill.Account_Bill__c,
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
            insert orderA1;
            }

            if (systembill.Shared_Solar_System__c == sss2.id) {
                ChargentOrders__ChargentOrder__c orderA2  = new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Account__c = systemBill.Property_Account_Id__c,
                    ChargentOrders__Gateway__c = chGatewaytwo.Id,
                    ChargentOrders__Shipping_Name__c = entitytwo.id,
                    ChargentOrders__Billing_First_Name__c = 'Cole',
                    ChargentOrders__Billing_Last_Name__c = 'Swain',
                    ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                    ChargentOrders__Billing_Zip_Postal__c = '02467',
                    ChargentOrders__Subtotal__c = 100.22,
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    Account_Bill__c = systembill.Account_Bill__c,
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
            insert orderA2;

            }
        }

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

        insert orderNotLinkedToAccountBill;

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

        insert orderNoSystemBills;

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

        insert orderCancelledCustomer;

        List<System_Bill__c> updatedsystemBillList = [SELECT Id, Late_Fees__c, Recurring_Payment_ID__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c, Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c, Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c, Shared_Solar_System__c, Property_Account_ID__c FROM System_Bill__c];


        Energy_Usage_Update__c productionupdateC1 = new Energy_Usage_Update__c (
            Name = 'sssB - March 2016',
            Shared_Solar_System__c = sss2.id,
            Production__c = 24000,
            Date__c = myDateMar);

        insert productionupdateC1;


        Energy_Usage_Update__c productionupdateC2 = new Energy_Usage_Update__c (
            Name = 'sssA - March 2016',
            Shared_Solar_System__c = sss1.id,
            Production__c = 31000,
            Date__c = myDateMar);

        insert productionupdateC2;
        productionupdateC1.Generate_Bills__c = true;
        productionupdateC2.Generate_Bills__c = true;
        update productionupdateC1;
        update productionupdateC2;
    }

    static testMethod void scheduleJob() {
        Test.startTest();

        // Test scheduling of batch:
        Datetime dt = Datetime.now().addMinutes(0);
        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        String CRON_EXP = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
        System.schedule('RecurringPaymentsHandler', CRON_EXP, batchToRun);

        // Run batch directly to be able to test results:
        database.executeBatch(batchToRun,50);

        Test.stopTest();

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

        System.assertEquals(orderlist.size(),3);
        for (ChargentOrders__ChargentOrder__c cho : orderlist) {
            if (cho.ChargentOrders__Charge_Date__c == '25') {
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
                System.assertEquals(87.75, cho.ChargentOrders__Charge_Amount__c);
                System.assertEquals(true, cho.Account_Bill__r.Parent_Account__r.Recurring_Billing__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '30') {
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
                System.assertEquals(437.70, cho.ChargentOrders__Charge_Amount__c);
                System.assertEquals(true, cho.Account_Bill__r.Parent_Account__r.Recurring_Billing__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '15') {
                System.assertEquals(0, cho.ChargentOrders__Charge_Amount__c);
                System.assertEquals('Stopped', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(false, cho.Account_Bill__r.Parent_Account__r.Recurring_Billing__c);
                System.assertNotEquals(NULL, cho.Reason_for_Recurring_Stop__c);
            }
        }
    }

    static testMethod void cloneOrderCorrectly() {
        ChargentOrders__ChargentOrder__c orderToDelete = [  SELECT Id
                                                            FROM ChargentOrders__ChargentOrder__c
                                                            WHERE ChargentOrders__Gateway__r.Name = 'Chargent Gateway One'
                                                            LIMIT 1];

        delete orderToDelete;

        List<ChargentOrders__ChargentOrder__c> chOrderList = [  SELECT Id              
                                                                FROM ChargentOrders__ChargentOrder__c];
        System.assertEquals(2, chOrderList.size());

        Test.startTest();

        // Test scheduling of batch:
        Datetime dt = Datetime.now().addMinutes(0);
        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        String CRON_EXP = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
        System.schedule('RecurringPaymentsHandler', CRON_EXP, batchToRun);

        // Run batch directly to be able to test results:
        Database.executeBatch(batchToRun,50);

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

        System.assertEquals(orderlist.size(),3);
        for (ChargentOrders__ChargentOrder__c cho : orderlist) {
            if (cho.ChargentOrders__Charge_Date__c == '25') {
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
                System.assertEquals(87.75, cho.ChargentOrders__Charge_Amount__c);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(true, cho.Account_Bill__r.Parent_Account__r.Recurring_Billing__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '30') {
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
                System.assertEquals(437.70, cho.ChargentOrders__Charge_Amount__c);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(true, cho.Account_Bill__r.Parent_Account__r.Recurring_Billing__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '15') {
                System.assertEquals(0, cho.ChargentOrders__Charge_Amount__c);
                System.assertEquals('Stopped', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(false, cho.Account_Bill__r.Parent_Account__r.Recurring_Billing__c);
                System.assertNotEquals(NULL, cho.Reason_for_Recurring_Stop__c);
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
