@IsTest
private class RecurringPaymentsHandlerTestClass {
    @TestSetup public static void setupData() {
        insert new BW_Address__c(
            Name = 'BlueWave', Address_Line_One__c = '137 Newbury Street 4th Floor',
            Address_Line_Two__c = 'Boston, MA 02114'
        );
        Test.loadData(Utility__c.SObjectType, 'TestCSUtility');
        Test.loadData(Utility_NMC_Tariff__c.SObjectType, 'TestCSUtilityNMCTariff');
        Test.loadData(Load_U__c.SObjectType, 'TestCSLoadU');
        Test.loadData(ChargentBase__Gateway__c.SObjectType, 'TestCSGateway');
        Test.loadData(Entity__c.SObjectType, 'TestCSEntity');
        Test.loadData(Shared_Solar_System__c.SObjectType, 'TestCSSharedSolarSystem');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Test.loadData(Utility_Account_Log__c.SObjectType, 'TestCSUtilityAccountLog');
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Test.loadData(Utility_Account_Subscription__c.SObjectType, 'TestCSUtilityAccountSubscription');
        Test.loadData(Schedule_Z__c.SObjectType, 'TestCSScheduleZ');
        Test.loadData(Schedule_Z_Subscription__c.SObjectType, 'TestCSScheduleZSubscription');
        Test.loadData(Energy_Usage_Update__c.SObjectType, 'TestCSProdUpdate');
        Test.loadData(Account_Bill__c.SObjectType, 'TestCSAccountBill');
        Test.loadData(System_Bill__c.SObjectType, 'TestCSSystemBill');
        Test.loadData(Utility_Account_Bill__c.SObjectType, 'TestCSUtilityAccountBill');
        Test.loadData(UASB__c.SObjectType, 'TestCSUASB');
        Test.loadData(ChargentOrders__ChargentOrder__c.SObjectType, 'TestCSChargentOrder');
    }

    @IsTest static void scheduleJob(){
        Test.startTest();

        // Test scheduling of batch:
        Datetime dt = Datetime.now().addMinutes(0);
        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        String CRON_EXP = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
        System.schedule('RecurringPaymentsHandler', CRON_EXP, batchToRun);

        Test.stopTest();
    }

    @IsTest static void testScheduledJobResults() {
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
            WHERE Account_Bill__r.Parent_Account__r.Name = 'Account A'
            OR Account_Bill__r.Parent_Account__r.Name = 'Account B'
            OR Account_Bill__r.Parent_Account__r.Name = 'Account C'
            OR Account_Bill__r.Parent_Account__r.Name = 'Account D'
            ORDER BY Bill_Number__c DESC];

        // Two accounts:
        // Account A has 2 opportunities, which have Feb and March Bill
        // Account B has 1 opportunity, which has Feb and March Bill
        System.assertEquals(6, systemBillListtwo.size());

        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        Database.executeBatch(batchToRun,50);
        Test.stopTest();

        List<ChargentOrders__ChargentOrder__c> orderlist = [
              SELECT Id,
                     Entity_Name__c,
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
                System.assertNotEquals(null, cho.Reason_for_Recurring_Stop__c);
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

    @IsTest static void cloneOrderCorrectly() {
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
            WHERE Account_Bill__r.Parent_Account__r.Name = 'Account A'
            OR Account_Bill__r.Parent_Account__r.Name = 'Account B'
            OR Account_Bill__r.Parent_Account__r.Name = 'Account C'
            OR Account_Bill__r.Parent_Account__r.Name = 'Account D'
            ORDER BY Bill_Number__c DESC];

        // Two accounts:
        // Account A has 2 opportunities, which have Feb and March Bill
        // Account B has 1 opportunity, which has Feb and March Bill
        System.assertEquals(6, systemBillListtwo.size());

        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
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

        // Six Original Chargent Orders:
        // 3 that should be marked as stopped (all charge date of 15) because 0 SBs
        // 2 that should have been moved to the newer bill
        // 1 that should have been cloned
        System.assertEquals(6,orderlist.size());

        for (ChargentOrders__ChargentOrder__c cho : orderlist) {
            if (cho.ChargentOrders__Charge_Date__c == '15') {
                System.assertEquals(0, cho.ChargentOrders__Charge_Amount__c);
                System.assertEquals('Stopped', cho.ChargentOrders__Payment_Status__c);
                System.assertNotEquals(null, cho.Reason_for_Recurring_Stop__c);
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

    @IsTest static void updateParentAccountOnStop() {
        Account oldAccountC = [
            SELECT Id,
                   Recurring_Billing__c
            FROM Account
            WHERE Name = 'Account C'];

        List<ChargentOrders__ChargentOrder__c> accountOrders = new List<ChargentOrders__ChargentOrder__c>([
            SELECT Id,
                   ChargentOrders__Payment_Status__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Account_Bill__r.Parent_Account__r.Id = : oldAccountC.Id
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

    @IsTest static void updateParentAccountOnRecurring() {
        Account oldAccountC = [
            SELECT Id,
                   Recurring_Billing__c
            FROM Account
            WHERE Name = 'Account C'];

        List<ChargentOrders__ChargentOrder__c> accountOrders = new List<ChargentOrders__ChargentOrder__c>([
            SELECT Id,
                   ChargentOrders__Payment_Status__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Account_Bill__r.Parent_Account__r.Id = : oldAccountC.Id
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

    @IsTest static void doNotUpdateParentAccountIfOneRecurringOrder() {
        /*
        Tests if a chargent order is updated and the account has active
        recurring payments. Then, the parent account still has recurring_billing
        marked as true.
        */
        Test.startTest();
        Account oldAccountC = [
            SELECT Id,
                   Recurring_Billing__c
            FROM Account
            WHERE Name = 'Account C'];

        List<ChargentOrders__ChargentOrder__c> accountOrders = new List<ChargentOrders__ChargentOrder__c>([
            SELECT Id, ChargentOrders__Payment_Status__c, Account_Bill__c, ChargentOrders__Gateway__c,
                Entity__c, ChargentOrders__Shipping_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Account_Bill__r.Parent_Account__r.Id = : oldAccountC.Id
        ]);

        /*
        insert a recurring ChargentOrder after collecting all the other account orders
        because we'll change those, but we want the account to stay flagged as 'autopay'
        */
        ChargentOrders__ChargentOrder__c recurringPayment1  = new ChargentOrders__ChargentOrder__c(
            Account_Bill__c = accountOrders[0].Account_Bill__c,
            ChargentOrders__Gateway__c = accountOrders[0].ChargentOrders__Gateway__c,
            Entity__c = accountOrders[0].Entity__c,
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
            ChargentOrders__Payment_Start_Date__c = System.today(),
            ChargentOrders__Charge_Date__c = '15');

        ChargentOrders__ChargentOrder__c recurringPayment2  = new ChargentOrders__ChargentOrder__c(
            Account_Bill__c = accountOrders[0].Account_Bill__c,
            ChargentOrders__Gateway__c = accountOrders[0].ChargentOrders__Gateway__c,
            Entity__c = accountOrders[0].Entity__c,
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
            ChargentOrders__Payment_Start_Date__c = System.today(),
            ChargentOrders__Charge_Date__c = '15');


        insert new List<ChargentOrders__ChargentOrder__c>{recurringPayment1, recurringPayment2};

        System.assertEquals(true, oldAccountC.Recurring_Billing__c);

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

    @IsTest static void moveChargentOrderFromPropertyAcctToFirstAcctBill (){
        //Tests the moving of the Chargent Order from the Property Account to the first Account Bill

        Account propAccountA = new Account(Name = 'Property Account A', RecordTypeId = '012j00000010HeQ');
        insert propAccountA;

        Utility_Account_Log__c ualog3 = new Utility_Account_Log__c(
            Name = '0000333',
            Account__c = propAccountA.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'sarah renfro'
        );
        insert ualog3;

        ChargentBase__Gateway__c chGatewayA  = new ChargentBase__Gateway__c(
            Name = 'Chargent Gateway A',
            ChargentBase__Merchant_ID__c = '235986',
            ChargentBase__Active__c = true
        );
        insert chGatewayA;

        Entity__c entityA = new Entity__c (Name = 'BarrettProjCo', Gateway__c = chGatewayA.Id);

        insert entityA;
        Test.startTest();
        Shared_Solar_System__c sssA = [SELECT Id FROM Shared_Solar_System__c WHERE Name = 'Oxford Barrett St. P1'];

        Opportunity opportunityA = new Opportunity(
            Name = 'OppA',
            AccountId = propAccountA.Id,
            Shared_Solar_System__c = sssA.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Non-Residential',
            CloseDate = System.today());

        insert opportunityA;

        Utility_Account_Subscription__c uasA = new Utility_Account_Subscription__c(
            Name = '0000333',
            Utility_Account_Log__c = ualog3.Id,
            Opportunity__c = opportunityA.Id,
            calculated_annual_cost_of_electricity__c = 10000,
            Subscribed_Annual_Cost_of_Electricity__c = 10000);
        insert uasA;

        uasA.Customer_Subscription_KW_DC_STATIC__c = 25;
        update uasA;

        Schedule_Z__c scheduleZA = new Schedule_Z__c(
            Name = '18-0333 Oxford Barrett St. P1',
            Shared_Solar_System__c = sssA.Id,
            Status__c = 'Billing'
        );
        insert scheduleZA;

        //Test first Account Bill - Chargent Order linked to Property Account
        ChargentOrders__ChargentOrder__c orderFirstAcctBill = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c = propAccountA.Id,
            ChargentOrders__Gateway__c = chGatewayA.Id,
            ChargentOrders__Shipping_Name__c = entityA.Id,
            Entity__c = entityA.Id,
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
        Energy_Usage_Update__c productionUpdateA = [
            SELECT Id
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - March 2016'
        ];
        productionUpdateA.Schedule_Z__c = scheduleZA.Id;
        update productionUpdateA;
        update sssA;

        List<Account_Bill__c> acctBills = [
            SELECT Id, Name, Is_First_Bill__c
            FROM Account_Bill__c
            WHERE Parent_Account__r.Name = 'Account A'
            OR Parent_Account__r.Name = 'Account B'
            OR Parent_Account__r.Name = 'Account C'
            OR Parent_Account__r.Name = 'Account D'
            OR Parent_Account__r.Name = 'Property Account A'
        ];
        System.assertEquals(5, acctBills.size());

        List<Energy_Usage_Update__c> productionUpdateList = [
            SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c,
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
            WHERE Name = 'sssA - March 2016'
        ];

        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(productionUpdateList);
        ee.runBills();

        List<Account_Bill__c> acctBillsList = [
            SELECT Id, Name
            FROM Account_Bill__c
            WHERE Parent_Account__r.Name = 'Account A'
            OR Parent_Account__r.Name = 'Account B'
            OR Parent_Account__r.Name = 'Account C'
            OR Parent_Account__r.Name = 'Account D'
            OR Parent_Account__r.Name = 'Property Account A'
        ];
        System.assertEquals(7, acctBillsList.size() );

        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        Database.executeBatch(batchToRun,50);
        Test.stopTest();

        //Check to see if Chargent Order's Account Name is null and Account Bill is = to AB
        ChargentOrders__ChargentOrder__c checkCO = [
            SELECT Id, Account_Bill__c, ChargentOrders__Account__c, ChargentOrders__Card_Security_Code__c, Entity_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Billing_First_Name__c = 'SarahRenfro'
        ];

        Account_Bill__c checkAB = [
            SELECT Id, Property_Account_Name__c, Is_First_Bill__c, Parent_Account__c
            FROM Account_Bill__c
            WHERE Parent_Account__c = :propAccountA.Id
        ];

        //Check if CO and AB were created
        System.assertNotEquals(null, checkCO.Account_Bill__c);
        System.assertEquals(null, checkCO.ChargentOrders__Account__c);
        System.assertEquals(checkCO.Account_Bill__c, checkAB.Id);
        System.assertEquals(false, checkAB.Is_First_Bill__c);
    }

    @IsTest static void updateParentAccountIfOtherOrdersNotRecurring() {
        /*
        Tests if a chargent order is updated and the account does not have active
        recurring payments. Then, the parent account is not longer autopay
        */
        Test.startTest();
        Account oldAccountC = [
            SELECT Id,
                   Recurring_Billing__c
            FROM Account
            WHERE Name = 'Account C'];

        List<ChargentOrders__ChargentOrder__c> accountOrders = new List<ChargentOrders__ChargentOrder__c>([
            SELECT Id, ChargentOrders__Payment_Status__c, Account_Bill__c, ChargentOrders__Gateway__c,
                Entity__c, ChargentOrders__Shipping_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Account_Bill__r.Parent_Account__r.Id = : oldAccountC.Id
        ]);

        /*
        insert a recurring ChargentOrder after collecting all the other account orders
        because we'll change those, but we want the account to no longer be 'autopay'
        */
        ChargentOrders__ChargentOrder__c recurringPayment  = new ChargentOrders__ChargentOrder__c(
            Account_Bill__c = accountOrders[0].Account_Bill__c,
            ChargentOrders__Gateway__c = accountOrders[0].ChargentOrders__Gateway__c,
            Entity__c = accountOrders[0].Entity__c,
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
            ChargentOrders__Payment_Start_Date__c = System.today(),
            ChargentOrders__Charge_Date__c = '15');

        insert recurringPayment;

        System.assertEquals(true, oldAccountC.Recurring_Billing__c);

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

    @IsTest static void testZeroDollarCharges() {
        List<Energy_Usage_Update__c> prodUpdates = [
            SELECT Id, Name
            FROM Energy_Usage_Update__c
            WHERE Name IN ('sssA - March 2016', 'sssB - March 2016')
        ];
        for (Energy_Usage_Update__c prodUpdate : prodUpdates) {
            // Generate $0 bills for one system
            if (prodUpdate.Name == 'sssA - March 2016') {
                prodUpdate.Production__c = 0;
                prodUpdate.Total_System_NMCs__c = 0;
            }
            prodUpdate.Generate_Bills__c = true;
        }
        update prodUpdates;

        Account accountA, accountB;
        List<Account> parentAccounts = [SELECT Id, Name FROM Account];
        for (Account account : parentAccounts) {
            if (account.Name == 'Account A') {
                accountA = account;
            } else if (account.Name == 'Account B') {
                accountB = account;
            }
        }
        List<Account_Bill__c> accountBills = [
            SELECT Id
            FROM Account_Bill__c
            WHERE Parent_Account__c = :accountA.Id
            OR Parent_Account__c = :accountB.Id
        ];
        // Should be four Account Bills, two for Feb that were loaded, and two for Mar just generated
        System.assertEquals(4, accountBills.size());
            List<System_Bill__c> systemBills = [
                SELECT Id, Total_Due__c, Property_Account__r.Name, Shared_Solar_System__r.Name
                FROM System_Bill__c
                WHERE (Property_Account__c = :accountA.Id
                OR Property_Account__c = :accountB.Id)
                AND Bill_Number__c = 2
            ];
        // Should be three new System Bills, two for Account A and one for Account B.
        // The two for Account A should be $0 since the Production Update was 0
        System.assertEquals(3, systemBills.size());
        for (System_Bill__c systemBill : systemBills) {
            if (systemBill.Property_Account__r.Name == 'Account A') {
                System.assertEquals(0, systemBill.Total_Due__c);
            } else if (systemBill.Property_Account__r.Name == 'Account B') {
                System.assertEquals(321.33, systemBill.Total_Due__c);
            } else {
                System.assertEquals('Account A or B', systemBill.Property_Account__r.Name );
            }
        }

        List<ChargentOrders__ChargentOrder__c> chargentOrders = [
            SELECT Id, ChargentOrders__Payment_Start_Date__c, ChargentOrders__Charge_Amount__c,
                ChargentOrders__Charge_Date__c, Account_Bill__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Opportunity__r.AccountId = :accountA.Id
            OR Opportunity__r.AccountId = :accountB.Id
        ];
        // The three Chargent Orders will still be on the old Account Bills for the old amounts and an old Start Date.
        // They haven't moved to the new Account Bill yet (which the RecurringPaymentsHandler does below), so the
        // amounts were the previous billed amounts
        System.assertEquals(3, chargentOrders.size());
        for (ChargentOrders__ChargentOrder__c chargentOrder : chargentOrders) {
            System.assert(chargentOrder.ChargentOrders__Charge_Amount__c > 0);
            System.assert(chargentOrder.ChargentOrders__Payment_Start_Date__c < System.today());
        }

        Test.startTest();
        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        Database.executeBatch(batchToRun,50);
        Test.stopTest();

        chargentOrders = [
            SELECT Id, ChargentOrders__Payment_Start_Date__c, ChargentOrders__Charge_Amount__c,
                ChargentOrders__Charge_Date__c, Account_Bill__c, Opportunity__r.Account.Name
            FROM ChargentOrders__ChargentOrder__c
            WHERE Opportunity__r.AccountId = :accountA.Id
            OR Opportunity__r.AccountId = :accountB.Id
        ];
        // Two Chargent Orders for Account A should be 0 and have a Payment Start Date of the next month's charge date
        for (ChargentOrders__ChargentOrder__c chargentOrder : chargentOrders) {
            if (chargentOrder.Opportunity__r.Account.Name == 'Account A') {
                Date nextMonth = System.today().addMonths(1);
                Date expectedChargeDate = Date.newInstance(
                    nextMonth.year(),
                    nextMonth.month(),
                    Integer.valueOf(chargentOrder.ChargentOrders__Charge_Date__c)
                );
                System.assertEquals(0, chargentOrder.ChargentOrders__Charge_Amount__c);
                System.assertEquals(expectedChargeDate, chargentOrder.ChargentOrders__Payment_Start_Date__c);
            } else if (chargentOrder.Opportunity__r.Account.Name == 'Account B') {
                System.assertEquals(321.33, chargentOrder.ChargentOrders__Charge_Amount__c);
                System.assert(chargentOrder.ChargentOrders__Payment_Start_Date__c < System.today());
            } else {
                System.assertEquals('Account A or B', chargentOrder.Opportunity__r.Account.Name);
            }
        }
    }

    @IsTest static void testCloseDuplicateEntityAccountOrders() {

        Test.startTest();

        Account accA = [ SELECT Id, Name
        FROM Account
        WHERE Name = 'Account A'];

        Entity__c entity1 = [ SELECT Id, Name
        FROM Entity__c
        WHERE Name = 'BarrettProjCo'];

        Entity__c entity2 = [ SELECT Id, Name
        FROM Entity__c
        WHERE Name = 'NotBarrettProjCo'];

        List<ChargentOrders__ChargentOrder__c> ordersWithAccAEntity1Before =
        [SELECT Id, Account_Bill__r.Parent_Account__c,
            Entity_Name__c, ChargentOrders__Payment_Status__c, ChargentOrders__Gateway__c, Account_Bill__c
        FROM ChargentOrders__ChargentOrder__c
        WHERE Account_Bill__r.Parent_Account__c =: accA.Id
        AND Entity_Name__c =: entity1.Name
        AND ChargentOrders__Payment_Status__c = 'Recurring'];

        List<ChargentOrders__ChargentOrder__c> ordersWithAccAEntity2Before =
        [SELECT Id, Account_Bill__r.Parent_Account__c,
            Entity_Name__c, ChargentOrders__Payment_Status__c, ChargentOrders__Gateway__c, Account_Bill__c
        FROM ChargentOrders__ChargentOrder__c
        WHERE Account_Bill__r.Parent_Account__c =: accA.Id
        AND Entity_Name__c =: entity2.Name
        AND ChargentOrders__Payment_Status__c = 'Recurring'];

        Integer previousNumOrdersAccAEnt1 = ordersWithAccAEntity1Before.size();
        Integer previousNumOrdersAccAEnt2 = ordersWithAccAEntity2Before.size();

        Account_Bill__c ab = new Account_Bill__c (Name='Similar Account Bill',
            Bill_Number__c = 1,
            Parent_Account__c = accA.Id);

        insert ab;

        ChargentOrders__ChargentOrder__c newOrderWithSameEntity2AndAcc  = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Gateway__c = ordersWithAccAEntity2Before.get(0).ChargentOrders__Gateway__c,
            Entity__c = entity2.Id,
            ChargentOrders__Shipping_Name__c = entity2.Id,
            ChargentOrders__Billing_First_Name__c = 'Jordan',
            ChargentOrders__Billing_Last_Name__c = 'Unique Last Name 2 for order that should be still recurring',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 603.92,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Account__c = accA.Id,
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

        // Account is set through the Account__c field in this one, rather than through the account bill
        ChargentOrders__ChargentOrder__c newOrderWithSameEntity1AndAcc  = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Gateway__c = ordersWithAccAEntity1Before.get(0).ChargentOrders__Gateway__c,
            Entity__c = entity1.Id,
            ChargentOrders__Shipping_Name__c = entity1.Id,
            ChargentOrders__Billing_First_Name__c = 'Jordan',
            ChargentOrders__Billing_Last_Name__c = 'Unique Last Name 1 for order that should be still recurring',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 603.92,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = ab.Id,
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

        // inserting this should set the old order to Payment Status of 'Complete'
        insert newOrderWithSameEntity1AndAcc;
        insert newOrderWithSameEntity2AndAcc;


        List<ChargentOrders__ChargentOrder__c> ordersWithAccAEntity1After =
        [SELECT Id, Account_Bill__r.Parent_Account__c,
            Entity_Name__c, ChargentOrders__Payment_Status__c, ChargentOrders__Billing_Last_Name__c
        FROM ChargentOrders__ChargentOrder__c
        WHERE Account_Bill__r.Parent_Account__c =: accA.Id
        AND Entity_Name__c =: entity1.Name
        AND ChargentOrders__Payment_Status__c = 'Recurring'];

        List<ChargentOrders__ChargentOrder__c> ordersWithAccAEntity2After =
        [SELECT Id, Account_Bill__r.Parent_Account__c,
            Entity_Name__c, ChargentOrders__Payment_Status__c, ChargentOrders__Billing_Last_Name__c
        FROM ChargentOrders__ChargentOrder__c
        WHERE ChargentOrders__Account__c =: accA.Id
        AND Entity_Name__c =: entity2.Name
        AND ChargentOrders__Payment_Status__c = 'Recurring'];

        Test.stopTest();

        Integer finalNumOrdersAccAEnt1 = ordersWithAccAEntity1After.size();
        Integer finalNumOrdersAccAEnt2 = ordersWithAccAEntity2After.size();


        System.assertNotEquals(previousNumOrdersAccAEnt1, 0); // There was at least one previous order with duplicate (1, a) criteria
        System.assertEquals(finalNumOrdersAccAEnt1, 1); // There is now ONLY 1 recurring order with this entity+account
        System.assertEquals(ordersWithAccAEntity1After.get(0).ChargentOrders__Billing_Last_Name__c,
            'Unique Last Name 1 for order that should be still recurring'); // The one that's still recurring is the order just inserted

        // Same assertions but for an inserted chargent order with just the account field set, not the account bill
        System.assertNotEquals(previousNumOrdersAccAEnt2, 0); // There was at least one previous order with duplicate (2, a) criteria
        System.assertEquals(finalNumOrdersAccAEnt2, 1); // There is now ONLY 1 recurring order with this entity+account
        System.assertEquals(ordersWithAccAEntity2After.get(0).ChargentOrders__Billing_Last_Name__c,
            'Unique Last Name 2 for order that should be still recurring'); // The one that's still recurring is the order just inserted
    }
    
    @IsTest static void testCloseDuplicatesWithManyRecords() {

        Account accA = [ SELECT Id, Name
        FROM Account
        WHERE Name = 'Account A'];

        Entity__c entity1 = [ SELECT Id, Name
        FROM Entity__c
        WHERE Name = 'BarrettProjCo'];

        Account_Bill__c ab = new Account_Bill__c (Name='Similar Account Bill',
            Bill_Number__c = 1,
            Parent_Account__c = accA.Id);

        insert ab;
        Test.startTest();

        List<ChargentOrders__ChargentOrder__c> ordersWithAccAEntity1Before =
        [SELECT Id, Account_Bill__r.Parent_Account__c,
            Entity_Name__c, ChargentOrders__Payment_Status__c, ChargentOrders__Gateway__c, Account_Bill__c
        FROM ChargentOrders__ChargentOrder__c
        WHERE Account_Bill__r.Parent_Account__c =: accA.Id
        AND Entity_Name__c =: entity1.Name
        AND ChargentOrders__Payment_Status__c = 'Recurring'];

        List<ChargentOrders__ChargentOrder__c> newOrders = new List<ChargentOrders__ChargentOrder__c>();

        for (Integer i = 0; i < 100; i++) {
            ChargentOrders__ChargentOrder__c newOrder = new ChargentOrders__ChargentOrder__c(
                ChargentOrders__Gateway__c = ordersWithAccAEntity1Before.get(0).ChargentOrders__Gateway__c,
                Entity__c = entity1.Id,
                ChargentOrders__Shipping_Name__c = entity1.Id,
                ChargentOrders__Billing_First_Name__c = 'Jordan',
                ChargentOrders__Billing_Last_Name__c = 'Unique Last Name 2 for order that should be still recurring',
                ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                ChargentOrders__Billing_Zip_Postal__c = '02467',
                ChargentOrders__Subtotal__c = i,
                ChargentOrders__Payment_Method__c = 'Credit Card',
                ChargentOrders__Account__c = accA.Id,
                Account_Bill__c = ab.Id,
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

            newOrders.add(newOrder);
        }

        insert newOrders;

        Test.stopTest();

        // this test is mainly ensuring that query limits aren't breaking, but we'll assert that everything is how it
        //  should be after

        List<ChargentOrders__ChargentOrder__c> ordersWithAccAEntity1AfterCreation =
        [SELECT Id, Account_Bill__r.Parent_Account__c,
            Entity_Name__c, ChargentOrders__Payment_Status__c, ChargentOrders__Gateway__c, Account_Bill__c
        FROM ChargentOrders__ChargentOrder__c
        WHERE Account_Bill__r.Parent_Account__c =: accA.Id
        AND Entity_Name__c =: entity1.Name
        AND ChargentOrders__Payment_Status__c = 'Recurring'];

        System.assertEquals(ordersWithAccAEntity1Before.size(), 1);
        System.assertEquals(ordersWithAccAEntity1AfterCreation.size(), 100);

        // add one more identical order
        ChargentOrders__ChargentOrder__c newOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Gateway__c = ordersWithAccAEntity1Before.get(0).ChargentOrders__Gateway__c,
            Entity__c = entity1.Id,
            ChargentOrders__Shipping_Name__c = entity1.Id,
            ChargentOrders__Billing_First_Name__c = 'Jordan',
            ChargentOrders__Billing_Last_Name__c = 'Unique Last Name 2 for order that should be still recurring',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 1,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Account__c = accA.Id,
            Account_Bill__c = ab.Id,
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

        insert newOrder;

        List<ChargentOrders__ChargentOrder__c> ordersWithAccAEntity1AfterFinalInsert =
        [SELECT Id, Account_Bill__r.Parent_Account__c,
            Entity_Name__c, ChargentOrders__Payment_Status__c, ChargentOrders__Gateway__c, Account_Bill__c
        FROM ChargentOrders__ChargentOrder__c
        WHERE Account_Bill__r.Parent_Account__c =: accA.Id
        AND Entity_Name__c =: entity1.Name
        AND ChargentOrders__Payment_Status__c = 'Recurring'];

        System.assertEquals(1, ordersWithAccAEntity1AfterFinalInsert.size());
    }

    @IsTest static void testChargeCarryoverBalanceNotTotalDue() {
        List<System_Bill__c> systemBills = [
            SELECT Id, Name, Bill_Number__c, Account_Bill__r.Bill_Number__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Parent_Account__r.Name = 'Account A'
        ];
        for (System_Bill__c systemBill : systemBills) {
            // There should only be the first bills, loaded from setup
            System.assertEquals(1, systemBill.Bill_Number__c);
            System.assertEquals(1, systemBill.Account_Bill__r.Bill_Number__c);
        }

        Test.startTest();
        List<Energy_Usage_Update__c> productionUpdateList = [
            SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c, YearDate__c, Credits_on_Bill_Period__c, MonthDate__c,
                Total_System_NMCs__c, Production__c, Generate_Bills__c, Total_System_NMCs_2_of_4__c, Total_System_NMCs_3_of_4__c,
                Production_kWh_2_of_4__c, Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c, Production_kWh_4_of_4__c,
                Net_Metering_Rate_Applied__c, Size_off_NMCs__c, Date__c, Billing_Period_Start_Date__c, Billing_Period_End_Date__c,
                Month_Number__c, Net_Metering_Rate_Applied_2_of_4__c, Net_Metering_Rate_Applied_3_of_4__c,
                Net_Metering_Rate_Applied_4_of_4__c
        FROM Energy_Usage_Update__c
        WHERE Name = 'sssB - March 2016'
        OR Name = 'sssA - March 2016'
        LIMIT 2];
        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(productionUpdateList);
        ee.runBills();

        systemBills = [
            SELECT Id, Name, Bill_Number__c, Total_Due__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Parent_Account__r.Name = 'Account A'
            AND Bill_Number__c = 2
        ];
        // Now there should be two bills, one for each system for March
        System.assertEquals(2, systemBills.size());
        List<Account_Bill__c> accountBills = [
            SELECT Id, Total_Due__c, Carry_Over_Balance__c
            FROM Account_Bill__c
            WHERE Parent_Account__r.Name = 'Account A'
            AND Bill_Number__c = 2
        ];
        System.assertEquals(1, accountBills.size());
        System.assertEquals(345.28, accountBills[0].Total_Due__c);
        System.assertEquals(345.28, accountBills[0].Carry_Over_Balance__c);

        // Simulate making a payment to pay off bills
        for (System_Bill__c systemBill : systemBills) {
            systemBill.Total_Payments_This_Month__c = systemBill.Total_Due__c;
        }
        update systemBills;

        // Now, the second bill should be paid.
        systemBills = [
            SELECT Id, Name, Bill_Number__c, Total_Due__c, Carry_Over_Balance__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Parent_Account__r.Name = 'Account A'
            AND Bill_Number__c = 2
        ];
        for (System_Bill__c systemBill : systemBills) {
            System.assertEquals(0, systemBill.Carry_Over_Balance__c);
        }
        // And the account bill should be paid as well
        accountBills = [
            SELECT Id, Total_Due__c, Carry_Over_Balance__c
            FROM Account_Bill__c
            WHERE Parent_Account__r.Name = 'Account A'
            AND Bill_Number__c = 2
        ];
        System.assertEquals(345.28, accountBills[0].Total_Due__c);
        System.assertEquals(0, accountBills[0].Carry_Over_Balance__c);

        List<ChargentOrders__ChargentOrder__c> chargentOrders = [
            SELECT Id, ChargentOrders__Charge_Amount__c, ChargentOrders__Subtotal__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Account_Bill__c = :accountBills[0].Id
        ];
        // There are no chargent orders on the latest bill
        System.assertEquals(0, chargentOrders.size());

        // After the chargent move runs, chargent orders should be set to 0 and in the future
        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        Database.executeBatch(batchToRun,50);
        Test.stopTest();

        chargentOrders = [
            SELECT Id, ChargentOrders__Charge_Amount__c, ChargentOrders__Subtotal__c, ChargentOrders__Payment_Start_Date__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Account_Bill__c = :accountBills[0].Id
        ];
        // There should now be two orders on the latest bill, with 0 charge amount, and a payment start in the future
        System.assertEquals(2, chargentOrders.size());
        for (ChargentOrders__ChargentOrder__c chargentOrder : chargentOrders) {
            System.assert(chargentOrder.ChargentOrders__Payment_Start_Date__c > Date.today());
            System.assertEquals(0, chargentOrder.ChargentOrders__Charge_Amount__c);
        }
    }
}