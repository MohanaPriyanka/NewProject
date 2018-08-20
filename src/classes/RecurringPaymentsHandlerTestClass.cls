@isTest
private class RecurringPaymentsHandlerTestClass{
    @testSetup public static void setupData() {
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
            WHERE Account_Bill__r.Parent_Account__r.id = : oldAccountC.Id
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
            ChargentOrders__Payment_Start_Date__c = system.today(),
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
            ChargentOrders__Payment_Start_Date__c = system.today(),
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

        ChargentBase__Gateway__c chGatewayA  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway A',
            ChargentBase__Merchant_ID__c = '235986',
            ChargentBase__Active__c = true);
        insert chGatewayA;

        Entity__c entityA = new Entity__c (
            Name = 'BarrettProjCo',
            Gateway__c = chGatewayA.Id
        );

        insert entityA;
        System.debug('4.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        Test.startTest();

        Shared_Solar_System__c sssA = [ SELECT Id
                                            FROM Shared_Solar_System__c
                                            WHERE name = 'Oxford Barrett St. P1'];



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
            WHERE Account_Bill__r.Parent_Account__r.id = : oldAccountC.Id
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
            ChargentOrders__Payment_Start_Date__c = system.today(),
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
}