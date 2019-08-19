@IsTest
private class RecurringPaymentsHandlerTestClass {
    @TestSetup public static void setupData() {
        CSPaymentTest.CSPaymentSetupTestData();
    }

    @IsTest static void scheduleJob(){
        Test.startTest();

        // Test scheduling of batch:
        Datetime dt = Datetime.now().addMinutes(0);
        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        String CRON_EXP = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
        System.schedule('RecurringPaymentsHandlerTest', CRON_EXP, batchToRun);

        Test.stopTest();
    }

    @IsTest static void testBatchExecution() {
        Test.startTest();
        List<Energy_Usage_Update__c> productionUpdateList = [
            SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c,
                YearDate__c, Credits_on_Bill_Period__c,
                MonthDate__c, Total_System_NMCs__c, Production__c,
                Generate_Bills__c, Total_System_NMCs_2_of_4__c,
                Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c,
                Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c,
                Production_kWh_4_of_4__c, Net_Metering_Rate_Applied__c,
                Billing_Method__c, Date__c, Billing_Period_Start_Date__c,
                Billing_Period_End_Date__c, Month_Number__c,
                Net_Metering_Rate_Applied_2_of_4__c,
                Net_Metering_Rate_Applied_3_of_4__c,
                Net_Metering_Rate_Applied_4_of_4__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssB - March 2016'
            OR Name = 'sssA - March 2016'
            LIMIT 1
        ];
        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(productionUpdateList);
        Database.executeBatch(ee, 50);
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
            Billing_Method__c, Date__c, Billing_Period_Start_Date__c,
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

        RecurringPaymentsHandler rph = simulateBatchRecurringHandler();
        Test.stopTest();

        List<ChargentOrders__ChargentOrder__c> nonCaseCreationOrders = [
              SELECT Id,
                     Entity_Name__c,
                     ChargentOrders__Payment_Status__c,
                     ChargentOrders__Charge_Date__c,
                     Reason_for_Recurring_Stop__c,
                     Account_Bill__r.Bill_Number__c,
                     Account_Bill__r.Name,
                     Account_Bill__r.Parent_Account__r.Name,
                     ChargentOrders__Charge_Amount__c,
                     Account_Bill__r.Parent_Account__r.Recurring_Billing__c,
                     ChargentOrders__Billing_Last_Name__c
              FROM ChargentOrders__ChargentOrder__c
              WHERE (NOT ChargentOrders__Billing_Last_Name__c LIKE '%CaseCreation%')
              AND (NOT ChargentOrders__Billing_Last_Name__c LIKE '%AutoEmailer%')
        ];

        // Seven non-CaseCreation Chargent Orders:
        // 4 that should be stopped (three with charge date of 15 and 1 without charge date) because 0 SBs
        // 3 that should have been moved to the newer bill

        // 5 CaseCreation orders (excluding 2 in error):
        // 5 that should be stopped
        System.assertEquals(7, nonCaseCreationOrders.size());
        System.assertEquals(9, rph.ordersStopped);
        System.assertEquals(3, rph.ordersMovedOrSet);
        System.assertEquals(0, rph.ordersCloned);

        for (ChargentOrders__ChargentOrder__c cho : nonCaseCreationOrders) {
            if (cho.ChargentOrders__Charge_Date__c == '15') {
                System.assertEquals(0, cho.ChargentOrders__Charge_Amount__c);
                System.assertEquals('Stopped', cho.ChargentOrders__Payment_Status__c);
                System.assertNotEquals(null, cho.Reason_for_Recurring_Stop__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '30') {
                System.assertEquals('Account A', cho.Account_Bill__r.Parent_Account__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '27') {
                System.assertEquals('Account A', cho.Account_Bill__r.Parent_Account__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '25') {
                System.assertEquals('Account B', cho.Account_Bill__r.Parent_Account__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            }
        }
    }

    @IsTest static void cloneOrderCorrectly() {
        Test.startTest();
        Util.disableTrigger('Disable_Client_Objects_Trigger__c');
        List<Energy_Usage_Update__c> productionUpdateList = [SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c,
            YearDate__c, Credits_on_Bill_Period__c,
            MonthDate__c, Total_System_NMCs__c, Production__c,
            Generate_Bills__c, Total_System_NMCs_2_of_4__c,
            Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c,
            Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c,
            Production_kWh_4_of_4__c, Net_Metering_Rate_Applied__c,
            Billing_Method__c, Date__c, Billing_Period_Start_Date__c,
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
        AND (NOT ChargentOrders__Billing_Last_Name__c LIKE '%CaseCreation%')
        AND (NOT ChargentOrders__Billing_Last_Name__c LIKE '%AutoEmailer%')
        LIMIT 1];
        delete orderToDelete;

        List<ChargentOrders__ChargentOrder__c> originalOrderCount = [
            SELECT Id, ChargentOrders__Billing_Last_Name__c, ChargentOrders__Charge_Date__c, ChargentOrders__Gateway__r.Name
            FROM ChargentOrders__ChargentOrder__c
            WHERE (NOT ChargentOrders__Billing_Last_Name__c LIKE '%CaseCreation%')
            AND (NOT ChargentOrders__Billing_Last_Name__c LIKE '%AutoEmailer%')
        ];
        System.assertEquals(6,originalOrderCount.size());

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

        RecurringPaymentsHandler rph = simulateBatchRecurringHandler();
        Test.stopTest();

        List<ChargentOrders__ChargentOrder__c> orderlist = [
              SELECT Id,
                     ChargentOrders__Payment_Status__c,
                     ChargentOrders__Charge_Date__c,
                     Reason_for_Recurring_Stop__c,
                     Account_Bill__r.Bill_Number__c,
                     Account_Bill__r.Name,
                     Account_Bill__r.Parent_Account__r.Name,
                     ChargentOrders__Charge_Amount__c,
                     Account_Bill__r.Parent_Account__r.Recurring_Billing__c
              FROM ChargentOrders__ChargentOrder__c
              WHERE (NOT ChargentOrders__Billing_Last_Name__c LIKE '%CaseCreation%')
              AND (NOT ChargentOrders__Billing_Last_Name__c LIKE '%AutoEmailer%')
        ];


        // Six Original Chargent Orders:
        // 3 that should be marked as stopped (all charge date of 15) because 0 SBs
        // 2 that should have been moved to the newer bill
        // 1 that should have been cloned
        System.assertEquals(7,orderlist.size());
        System.assertEquals(1, rph.ordersCloned);

        for (ChargentOrders__ChargentOrder__c cho : orderlist) {
            if (cho.ChargentOrders__Charge_Date__c == '15') {
                System.assertEquals(0, cho.ChargentOrders__Charge_Amount__c);
                System.assertEquals('Stopped', cho.ChargentOrders__Payment_Status__c);
                System.assertNotEquals(null, cho.Reason_for_Recurring_Stop__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '30') {
                System.assertEquals('Account A', cho.Account_Bill__r.Parent_Account__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
                System.assertEquals('Cloned Order', cho.Comments__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '27') {
                System.assertEquals('Account A', cho.Account_Bill__r.Parent_Account__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '25') {
                System.assertEquals('Account B', cho.Account_Bill__r.Parent_Account__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            }
        }
        Util.enableTrigger('Disable_Client_Objects_Trigger__c');
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

    @IsTest static void doNotUpdateParentAccountIfOneRecurringOrderOnAccountBills() {
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

    @IsTest static void doNotUpdateParentAccountIfOneRecurringOrderOnAccount() {
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
            ChargentOrders__Account__c = oldAccountC.Id,
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
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Start_Date__c = System.today(),
            ChargentOrders__Charge_Date__c = '15');

        ChargentOrders__ChargentOrder__c recurringPayment2  = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c = oldAccountC.Id,
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
        Util.disableTrigger('Disable_Client_Objects_Trigger__c');
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
            ChargentBase__Available_Payment_Methods__c = 'eCheck',
            ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
            ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
            ChargentBase__Active__c = true
        );
        insert chGatewayA;

        Entity__c entityA = new Entity__c (Name = 'BarrettProjCo', Gateway__c = chGatewayA.Id);

        insert entityA;

        Shared_Solar_System__c sssA = [
            SELECT Id, BWC_Project_Entity_Manual__c, BWC_Project_Entity_Manual__r.Gateway__c
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
        ];

        Opportunity opportunityA = new Opportunity(
            Name = 'OppA',
            AccountId = propAccountA.Id,
            Shared_Solar_System__c = sssA.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Non-Residential',
            Product_Line__c = 'Community Solar',
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


        opportunityA.CC_Card_Type__c = 'Visa';
        opportunityA.CC_Account_Number__c = '411111111111';
        opportunityA.CC_CVV__c = '999';
        opportunityA.CC_CardHolder_Name__c = 'Renfro';
        opportunityA.CC_Expiration_Month__c = '02';
        opportunityA.CC_Expiration_Year__c = '2018';

        update opportunityA;

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
            SELECT Id, Name
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
                Billing_Method__c, Date__c, Billing_Period_Start_Date__c,
                Billing_Period_End_Date__c, Month_Number__c,
                Net_Metering_Rate_Applied_2_of_4__c,
                Net_Metering_Rate_Applied_3_of_4__c,
                Net_Metering_Rate_Applied_4_of_4__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - March 2016'
        ];
        Test.startTest();
        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(productionUpdateList);
        ee.runBills();
        TestBillCreationandPayment.setBillsToPublished();

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

        simulateBatchRecurringHandler();
        Test.stopTest();

        //Check to see if Chargent Order's Account Name is null and Account Bill is = to AB
        ChargentOrders__ChargentOrder__c checkCO = [
            SELECT Id, Account_Bill__c, ChargentOrders__Account__c,
                Entity_Name__c, Entity__c, ChargentOrders__Gateway__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Billing_Last_Name__c = 'Renfro'
        ];

        Account_Bill__c checkAB = [
            SELECT Id, Property_Account_Name__c, Parent_Account__c,
                (SELECT Id, Shared_Solar_System__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c FROM System_Bills__r)
            FROM Account_Bill__c
            WHERE Parent_Account__c = :propAccountA.Id
        ];

        //Check if CO and AB were created
        System.assertNotEquals(null, checkCO.Account_Bill__c);
        System.assertEquals(null, checkCO.ChargentOrders__Account__c);
        System.assertEquals(checkCO.Account_Bill__c, checkAB.Id);

        //Confirm system bill shared solar system is sssA and make sure ChargentOrder entity matches
        System.assertEquals(sssA.Id, checkAB.System_Bills__r[0].Shared_Solar_System__c);
        System.assertEquals(sssA.BWC_Project_Entity_Manual__c, checkCO.Entity__c);
        System.assertEquals(sssA.BWC_Project_Entity_Manual__r.Gateway__c, checkCO.ChargentOrders__Gateway__c);
        Util.enableTrigger('Disable_Client_Objects_Trigger__c');
    }

    @IsTest static void moveChargentOrderFromPropertyAcctToFirstAcctBillFromWaitlist() {
        //Tests the moving of the Chargent Order from the Property Account to the first Account Bill
        Util.disableTrigger('Disable_Client_Objects_Trigger__c');

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
            ChargentBase__Available_Payment_Methods__c = 'eCheck',
            ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
            ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
            ChargentBase__Active__c = true
        );
        insert chGatewayA;

        Entity__c entityA = new Entity__c (Name = 'BarrettProjCo', Gateway__c = chGatewayA.Id);

        insert entityA;

        Shared_Solar_System__c sssA = [
            SELECT Id, BWC_Project_Entity_Manual__c, BWC_Project_Entity_Manual__r.Gateway__c
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
        ];
        Shared_Solar_System__c sssWaitlist = [
            SELECT Id, BWC_Project_Entity_Manual__c, BWC_Project_Entity_Manual__r.Gateway__c
            FROM Shared_Solar_System__c
            WHERE Name = 'Waitlist'
        ];

        Opportunity opportunityA = new Opportunity(
            Name = 'OppA',
            AccountId = propAccountA.Id,
            Shared_Solar_System__c = sssWaitlist.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Non-Residential',
            Product_Line__c = 'Community Solar',
            CloseDate = System.today());

        insert opportunityA;

        opportunityA.CC_Card_Type__c = 'Visa';
        opportunityA.CC_Account_Number__c = '411111111111';
        opportunityA.CC_CVV__c = '999';
        opportunityA.CC_CardHolder_Name__c = 'Renfro';
        opportunityA.CC_Expiration_Month__c = '02';
        opportunityA.CC_Expiration_Year__c = '2018';

        update opportunityA;

        opportunityA.Shared_Solar_System__c = sssA.Id;

        update opportunityA;

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

        Test.startTest();

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
            SELECT Id, Name
            FROM Account_Bill__c
            WHERE Parent_Account__c = :propAccountA.Id
        ];
        System.assertEquals(0, acctBills.size());

        List<Energy_Usage_Update__c> productionUpdateList = [
            SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c,
                YearDate__c, Credits_on_Bill_Period__c,
                MonthDate__c, Total_System_NMCs__c, Production__c,
                Generate_Bills__c, Total_System_NMCs_2_of_4__c,
                Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c,
                Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c,
                Production_kWh_4_of_4__c, Net_Metering_Rate_Applied__c,
                Billing_Method__c, Date__c, Billing_Period_Start_Date__c,
                Billing_Period_End_Date__c, Month_Number__c,
                Net_Metering_Rate_Applied_2_of_4__c,
                Net_Metering_Rate_Applied_3_of_4__c,
                Net_Metering_Rate_Applied_4_of_4__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - March 2016'
        ];

        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(productionUpdateList);
        ee.runBills();
        TestBillCreationandPayment.setBillsToPublished();

        List<Account_Bill__c> acctBillsList = [
            SELECT Id, Name
            FROM Account_Bill__c
            WHERE Parent_Account__c = :propAccountA.Id
        ];
        System.assertEquals(1, acctBillsList.size() );

        simulateBatchRecurringHandler();
        Test.stopTest();

        //Check to see if Chargent Order's Account Name is null and Account Bill is = to AB
        ChargentOrders__ChargentOrder__c checkCO = [
            SELECT Id, Account_Bill__c, ChargentOrders__Account__c,
                Entity_Name__c, Entity__c, ChargentOrders__Gateway__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Billing_Last_Name__c = 'Renfro'
        ];

        Account_Bill__c checkAB = [
            SELECT Id, Property_Account_Name__c, Parent_Account__c,
            (SELECT Id, Shared_Solar_System__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c FROM System_Bills__r)
            FROM Account_Bill__c
            WHERE Parent_Account__c = :propAccountA.Id
        ];

        //Check if CO and AB were created
        System.assertNotEquals(null, checkCO.Account_Bill__c);
        System.assertEquals(null, checkCO.ChargentOrders__Account__c);
        System.assertEquals(checkCO.Account_Bill__c, checkAB.Id);

        //Confirm system bill shared solar system is sssA and make sure ChargentOrder entity matches
        System.assertEquals(sssA.Id, checkAB.System_Bills__r[0].Shared_Solar_System__c);
        System.assertEquals(sssA.BWC_Project_Entity_Manual__c, checkCO.Entity__c);
        System.assertEquals(sssA.BWC_Project_Entity_Manual__r.Gateway__c, checkCO.ChargentOrders__Gateway__c);

        Util.enableTrigger('Disable_Client_Objects_Trigger__c');
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
        Account accountA, accountB;
        List<Account> parentAccounts = [SELECT Id, Name FROM Account];
        for (Account account : parentAccounts) {
            if (account.Name == 'Account A') {
                accountA = account;
            } else if (account.Name == 'Account B') {
                accountB = account;
            }
        }
        List<System_Bill__c> systemBills = [
            SELECT Id, Total_Due__c, Property_Account__r.Name, Shared_Solar_System__r.Name
            FROM System_Bill__c
            WHERE (Property_Account__c = :accountA.Id
            OR Property_Account__c = :accountB.Id)
            AND Bill_Number__c = 1
        ];
        // Pay off the first bill
        CSPaymentTest.mockMakeASinglePayment(systemBills);

        Test.startTest();
        List<Energy_Usage_Update__c> prodUpdates = [
            SELECT Id, Name
            FROM Energy_Usage_Update__c
            WHERE Name IN ('sssA - March 2016', 'sssB - March 2016')
        ];
        List<Id> prodUpdateIdList = new List<Id>();
        for (Energy_Usage_Update__c prodUpdate : prodUpdates) {
            // Generate $0 bills for one system
            if (prodUpdate.Name == 'sssA - March 2016') {
                prodUpdate.Production__c = 0;
                prodUpdate.Total_System_NMCs__c = 0;
            }
            prodUpdateIdList.add(prodUpdate.Id);
        }
        update prodUpdates;
        TestBillCreationandPayment.runProductionUpdate(prodUpdateIdList);
        TestBillCreationandPayment.setBillsToPublished();

        List<Account_Bill__c> accountBills = [
            SELECT Id
            FROM Account_Bill__c
            WHERE Parent_Account__c = :accountA.Id
            OR Parent_Account__c = :accountB.Id
        ];
        // Should be four Account Bills, two for Feb that were loaded, and two for Mar just generated
        System.assertEquals(4, accountBills.size());
        systemBills = [
            SELECT Id, Total_Due__c, Property_Account__r.Name, Shared_Solar_System__r.Name
            FROM System_Bill__c
            WHERE (Property_Account__c = :accountA.Id
            OR Property_Account__c = :accountB.Id)
            AND Bill_Number__c = 2
        ];
        // Should be three new System Bills, two for Account A and one for Account B.
        // One SB for Account A should be $0, the other is zeroed out below:
        System.assertEquals(3, systemBills.size());
        for (System_Bill__c systemBill : systemBills) {
            if (systemBill.Property_Account__r.Name == 'Account A' && systemBill.Total_Due__c != 0) {
                // Set Total Due = $0
                systemBill.Total_Payments_This_Month__c = systemBill.Total_Due__c;
                systemBill.Payments_Net_Previous_Balances__c = systemBill.Total_Due__c;
                update systemBill;
            } else if (systemBill.Property_Account__r.Name == 'Account B') {
                System.assertEquals(321.33, systemBill.Total_Due__c);
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
        Map<Id, Date> paymentStartDateMap = new Map<Id, Date>();
        for (ChargentOrders__ChargentOrder__c chargentOrder : chargentOrders) {
            System.assert(chargentOrder.ChargentOrders__Charge_Amount__c > 0);
            System.assert(chargentOrder.ChargentOrders__Payment_Start_Date__c < System.today());
            paymentStartDateMap.put(chargentOrder.Id, chargentOrder.ChargentOrders__Payment_Start_Date__c);
        }

        simulateBatchRecurringHandler();
        Test.stopTest();

        chargentOrders = [
            SELECT Id, ChargentOrders__Payment_Start_Date__c, ChargentOrders__Charge_Amount__c,
                ChargentOrders__Charge_Date__c, Account_Bill__c, Opportunity__r.Account.Name
            FROM ChargentOrders__ChargentOrder__c
            WHERE Opportunity__r.AccountId = :accountA.Id
            OR Opportunity__r.AccountId = :accountB.Id
        ];
        // Two Chargent Orders for Account A should be 0 and have a Payment Start Date of the next month's charge date
        // if running on the charge date, but two months out if running before the charge date.
        for (ChargentOrders__ChargentOrder__c chargentOrder : chargentOrders) {
            if (chargentOrder.Opportunity__r.Account.Name == 'Account A') {
                Date expectedChargeDate =
                    RecurringPaymentsHandler.newPaymentStartDate(
                        Date.today(),
                        Integer.valueOf(chargentOrder.ChargentOrders__Charge_Date__c),
                        paymentStartDateMap.get(chargentOrder.Id)
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

    @IsTest static void testNegativeDollarCharges() {
        Account accountA, accountB;
        List<Account> parentAccounts = [SELECT Id, Name FROM Account];
        for (Account account : parentAccounts) {
            if (account.Name == 'Account A') {
                accountA = account;
            } else if (account.Name == 'Account B') {
                accountB = account;
            }
        }
        List<System_Bill__c> systemBills = [
            SELECT Id, Total_Due__c, Property_Account__r.Name, Shared_Solar_System__r.Name, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c
            FROM System_Bill__c
            WHERE (Property_Account__c = :accountA.Id
            OR Property_Account__c = :accountB.Id)
            AND Bill_Number__c = 1
        ];
        // Pay off the first bill
        CSPaymentTest.mockMakeASinglePayment(systemBills);

        for (System_Bill__c systemBill : systemBills) {
            if (systemBill.Property_Account__c == accountA.Id) {
                // we want to mock an extra payment for this bill, so the resulting bill has a negative balance
                systemBill.Total_Payments_This_Month__c += 1000;
                systemBill.Payments_Net_Previous_Balances__c += 1000;
                update systemBill;
            }
        }

        Test.startTest();
        List<Energy_Usage_Update__c> prodUpdates = [
            SELECT Id, Name
            FROM Energy_Usage_Update__c
            WHERE Name IN ('sssA - March 2016', 'sssB - March 2016')
        ];
        List<Id> prodUpdateIdList = new List<Id>();

        for (Energy_Usage_Update__c prodUpdate : prodUpdates) {
            // Generate $0 bills for one system
            if (prodUpdate.Name == 'sssA - March 2016') {
                prodUpdate.Production__c = 0;
                prodUpdate.Total_System_NMCs__c = 0;
            }
            prodUpdateIdList.add(prodUpdate.Id);
        }
        update prodUpdates;

        TestBillCreationandPayment.runProductionUpdate(prodUpdateIdList);
        TestBillCreationandPayment.setBillsToPublished();

        List<Account_Bill__c> accountBills = [
            SELECT Id
            FROM Account_Bill__c
            WHERE Parent_Account__c = :accountA.Id
            OR Parent_Account__c = :accountB.Id
        ];
        // Should be four Account Bills, two for Feb that were loaded, and two for Mar just generated
        System.assertEquals(4, accountBills.size());
        systemBills = [
            SELECT Id, Total_Due__c, Property_Account__r.Name, Shared_Solar_System__r.Name, Carry_Over_Balance__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c, Due_This_Month__c
            FROM System_Bill__c
            WHERE (Property_Account__c = :accountA.Id
            OR Property_Account__c = :accountB.Id)
            AND Bill_Number__c = 2
        ];
        // Should be three new System Bills, two for Account A and one for Account B.
        // One for Account A should be $0, the other is zeroed out below:
        System.assertEquals(3, systemBills.size());
        for (System_Bill__c systemBill : systemBills) {
            if (systemBill.Property_Account__r.Name == 'Account A'
                && systemBill.Shared_Solar_System__r.Name == 'Oxford Barrett St. P1') {
                System.assertEquals(-1000, systemBill.Total_Due__c);
            } else if (systemBill.Property_Account__r.Name == 'Account A' ){
                System.assertEquals(-678.67, systemBill.Total_Due__c);
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
        Map<Id, Date> paymentStartDateMap = new Map<Id, Date>();
        for (ChargentOrders__ChargentOrder__c chargentOrder : chargentOrders) {
            System.assert(chargentOrder.ChargentOrders__Charge_Amount__c > 0);
            System.assert(chargentOrder.ChargentOrders__Payment_Start_Date__c < System.today());
            paymentStartDateMap.put(chargentOrder.Id, chargentOrder.ChargentOrders__Payment_Start_Date__c);
        }

        simulateBatchRecurringHandler();
        Test.stopTest();

        chargentOrders = [
            SELECT Id, ChargentOrders__Payment_Start_Date__c, ChargentOrders__Charge_Amount__c,
                ChargentOrders__Charge_Date__c, Account_Bill__c, Opportunity__r.Account.Name,
                Opportunity__r.Shared_Solar_System__r.Name
            FROM ChargentOrders__ChargentOrder__c
            WHERE Opportunity__r.AccountId = :accountA.Id
            OR Opportunity__r.AccountId = :accountB.Id
        ];
        // Two Chargent Orders for Account A should be 0 and have a Payment Start Date of the next month's charge date
        // if running on the charge date, but two months out if running before the charge date.
        for (ChargentOrders__ChargentOrder__c chargentOrder : chargentOrders) {
            if (chargentOrder.Opportunity__r.Account.Name == 'Account A'
                && chargentOrder.Opportunity__r.Shared_Solar_System__r.Name == 'Oxford Barrett St. P1') {
                Date expectedChargeDate =
                    RecurringPaymentsHandler.newPaymentStartDate(
                        Date.today(),
                        Integer.valueOf(chargentOrder.ChargentOrders__Charge_Date__c),
                        paymentStartDateMap.get(chargentOrder.Id)
                    );
                System.assertEquals(-1000, chargentOrder.ChargentOrders__Charge_Amount__c);
                System.assertEquals(expectedChargeDate, chargentOrder.ChargentOrders__Payment_Start_Date__c);
            } else if (chargentOrder.Opportunity__r.Account.Name == 'Account A'){
                Date expectedChargeDate =
                    RecurringPaymentsHandler.newPaymentStartDate(
                        Date.today(),
                        Integer.valueOf(chargentOrder.ChargentOrders__Charge_Date__c),
                        paymentStartDateMap.get(chargentOrder.Id)
                    );
                System.assertEquals(-678.67, chargentOrder.ChargentOrders__Charge_Amount__c);
                System.assertEquals(expectedChargeDate, chargentOrder.ChargentOrders__Payment_Start_Date__c);
            } else if (chargentOrder.Opportunity__r.Account.Name == 'Account B') {
                System.assertEquals(321.33, chargentOrder.ChargentOrders__Charge_Amount__c);
                System.assert(chargentOrder.ChargentOrders__Payment_Start_Date__c < System.today());
            } else {
                System.assertEquals('Account A or B', chargentOrder.Opportunity__r.Account.Name);
            }
        }
    }

    // If we get a $0 chargent order, the chargent move pushes the payment start date out so we don't get an error when
    // doing the autopay charge. If we run the move before the charge date, we might push the date out by two months.
    @IsTest static void testNextPaymentStartDate() {
        Date chargentMoveDate;
        chargentMoveDate = Date.newInstance(2018, 9, 1);
        System.assertEquals(
            Date.newInstance(2018, 10, 1),
            RecurringPaymentsHandler.newPaymentStartDate(chargentMoveDate, 1, Date.newInstance(2017, 9, 1)),
            'Expected Payment Start Date of 10/1 since existing start is in the past and we\'re running on the charge date'
        );
        chargentMoveDate = Date.newInstance(2018, 9, 1);
        System.assertEquals(
            Date.newInstance(2018, 10, 1),
            RecurringPaymentsHandler.newPaymentStartDate(chargentMoveDate, 1, Date.newInstance(2018, 9, 1)),
            'Expected Payment Start Date to move to 10/1 since we don\'t want to charge 0 on autopay date of 9/1'
        );
        chargentMoveDate = Date.newInstance(2018, 9, 1);
        System.assertEquals(
            Date.newInstance(2018, 10, 1),
            RecurringPaymentsHandler.newPaymentStartDate(chargentMoveDate, 1, Date.newInstance(2018, 10, 1)),
            'Expected Payment Start Date to stay at 10/1, since we\'re not going to charge $0 on 9/1'
        );
        chargentMoveDate = Date.newInstance(2018, 8, 31);
        System.assertEquals(
            Date.newInstance(2018, 10, 15),
            RecurringPaymentsHandler.newPaymentStartDate(chargentMoveDate, 15, Date.newInstance(2017, 9, 1)),
            'Expected Payment Start Date of 10/15 since existing start is in the past and we\'re running before the charge date'
        );
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

        // Assert that if a new order is created that is NOT recurring, the old order is not closed
        // Account is set through the Account__c field in this one, rather than through the account bill
        ChargentOrders__ChargentOrder__c newOrderWithSameEntity1AndAccNotRecurring  = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Gateway__c = ordersWithAccAEntity1Before.get(0).ChargentOrders__Gateway__c,
            Entity__c = entity1.Id,
            ChargentOrders__Shipping_Name__c = entity1.Id,
            ChargentOrders__Billing_First_Name__c = 'Jordan',
            ChargentOrders__Billing_Last_Name__c = 'Pent',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 603.92,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = ab.Id,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Payment_Status__c = '',
            ChargentOrders__Payment_Frequency__c = 'Once',
            ChargentOrders__Payment_Start_Date__c = system.today(),
            ChargentOrders__Charge_Date__c = '30');

        insert newOrderWithSameEntity1AndAccNotRecurring;

        List<ChargentOrders__ChargentOrder__c> ordersWithAccAEntity1AfterNonRecurring =
        [SELECT Id, Account_Bill__r.Parent_Account__c,
            Entity_Name__c, ChargentOrders__Payment_Status__c, ChargentOrders__Billing_Last_Name__c
        FROM ChargentOrders__ChargentOrder__c
        WHERE Account_Bill__r.Parent_Account__c =: accA.Id
        AND Entity_Name__c =: entity1.Name
        AND ChargentOrders__Payment_Status__c = 'Recurring'];

        System.assertEquals(ordersWithAccAEntity1AfterNonRecurring.size(), 1); // There is now ONLY 1 recurring order with this entity+account
        System.assertEquals(ordersWithAccAEntity1AfterNonRecurring.get(0).ChargentOrders__Billing_Last_Name__c,
            'Unique Last Name 1 for order that should be still recurring'); // The one that's still recurring is the order just inserted
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

    // This test reproduces a bug where Chargent Orders would be moved from the account to the first account bill upon
    // making any change to the first account bill, EVEN IF there was already a second account bill.
    // This happened to Jyoti Enterprises in July/Aug 2018. A paper check was logged in August to pay off the July Bill,
    // and when the balanced changed on the July bill and AccountBillTrigger(/AccountBillHandler) was run, Chargent
    // Order 4105 was moved from the Account to July and set to recurring, and the August bill had already been created.
    static testMethod void  testOnlyUnsetIsFirstBillIfNoSubsequent() {

        // Get the account
        Account accountWithOrder = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Account E'
        ];

        // Get the list of orders currently on that account
        List<ChargentOrders__ChargentOrder__c> ordersOnAccount = [
            SELECT Id, Property_Account__r.Id, Property_Account_ID__c, Entity__c, Account_Bill__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Property_Account__r.Id =: accountWithOrder.Id
        ];

        // Get the first bill. There are TWO bills on the account.
        Account_Bill__c firstAccountBill = [
            SELECT Id, Parent_Account__c, Name,
            (SELECT Id FROM Chargent_Orders__r)
            FROM Account_Bill__c
            WHERE Parent_Account__c =: accountWithOrder.Id
            AND Name = 'First Account Bill'
        ];

        // Get the first bill. There are TWO bills on the account.
        List<Account_Bill__c> billsOnAccount = [
            SELECT Id, Parent_Account__c, Name,
            (SELECT Id FROM Chargent_Orders__r)
            FROM Account_Bill__c
            WHERE Parent_Account__c =: accountWithOrder.Id
        ];

        // Show that there is an order on the account, and no order on the first bill.
        System.assertEquals(ordersOnAccount.size(), 1);
        System.assertEquals(firstAccountBill.Chargent_Orders__r.size(), 0);

        // Assert that there are two bills for this account
        System.assertEquals(billsOnAccount.size(), 2);

        // make any change to the first account bill, so that AccountBillHandler runs
        firstAccountBill.Name = 'making any change';
        update firstAccountBill;

        // Run updateRecurringOrders, which also contained the bug, to ensure that it does not cause the order to move
        //  to the first account bill
        RecurringPaymentsHandler handler = new RecurringPaymentsHandler();
        handler.updateRecurringOrders(ordersOnAccount);

        List<ChargentOrders__ChargentOrder__c> ordersOnAccountAfter = [
            SELECT Id, Property_Account__r.Id
            FROM ChargentOrders__ChargentOrder__c
            WHERE Property_Account__r.Id =: accountWithOrder.Id
        ];

        Account_Bill__c firstAccountBillAfter = [
            SELECT Id, Parent_Account__c, Name,
            (SELECT Id FROM Chargent_Orders__r)
            FROM Account_Bill__c
            WHERE Parent_Account__c =: accountWithOrder.Id
            AND Name = 'making any change'
        ];


        // Assert that there is still one order on the account, and none on the first bill (i.e. nothing has changed)
        System.assertEquals(ordersOnAccountAfter.size(), 1);
        System.assertEquals(firstAccountBillAfter.Chargent_Orders__r.size(), 0);
    }

    @IsTest static void testChargeCarryoverBalanceNotTotalDue() {
        List<System_Bill__c> systemBills = [
            SELECT Id, Name, Bill_Number__c, Account_Bill__r.Bill_Number__c, Total_Due__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Parent_Account__r.Name = 'Account A'
        ];
        for (System_Bill__c systemBill : systemBills) {
            // There should only be the first bills, loaded from setup
            System.assertEquals(1, systemBill.Bill_Number__c);
            System.assertEquals(1, systemBill.Account_Bill__r.Bill_Number__c);
        }
        TestBillCreationandPayment.setBillsToPublished();

        // Pay off the bills to start with $0 carryover balance
        CSPaymentTest.mockMakeASinglePayment(systemBills);

        Test.startTest();
        List<Energy_Usage_Update__c> productionUpdateList = [
            SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c, YearDate__c, Credits_on_Bill_Period__c, MonthDate__c,
                Total_System_NMCs__c, Production__c, Generate_Bills__c, Total_System_NMCs_2_of_4__c, Total_System_NMCs_3_of_4__c,
                Production_kWh_2_of_4__c, Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c, Production_kWh_4_of_4__c,
                Net_Metering_Rate_Applied__c, Billing_Method__c, Date__c, Billing_Period_Start_Date__c, Billing_Period_End_Date__c,
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
            SELECT Id, Total_Due__c, Due_This_Month__c, Carry_Over_Balance__c, Adjustments__c
            FROM Account_Bill__c
            WHERE Parent_Account__r.Name = 'Account A'
            AND Bill_Number__c = 2
        ];
        System.assertEquals(1, accountBills.size());
        System.assertEquals(666.61, accountBills[0].Due_This_Month__c);
        System.assertEquals(666.61, accountBills[0].Carry_Over_Balance__c);

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
        System.assertEquals(666.61, accountBills[0].Total_Due__c);
        System.assertEquals(0, accountBills[0].Carry_Over_Balance__c);

        List<ChargentOrders__ChargentOrder__c> chargentOrders = [
            SELECT Id, ChargentOrders__Charge_Amount__c, ChargentOrders__Subtotal__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Account_Bill__c = :accountBills[0].Id
        ];
        // There are no chargent orders on the latest bill
        System.assertEquals(0, chargentOrders.size());

        // After the chargent move runs, chargent orders should be set to 0 and in the future
        simulateBatchRecurringHandler();
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

    // Tests for handling recurring Chargent Orders if they're on the last account bill
    @IsTest public static void testOrdersOnActiveLastBill() {
        User user = [
            SELECT Id, Contact.AccountId
            FROM User
            WHERE Username='PaymentTestParentAccountC@bluewavesolar.com'
        ];

        List<System_Bill__c> firstSystemBills = [
            SELECT Id, Total_Due__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Parent_Account__r.Name = 'PaymentTestPropertyD'
        ];
        System.assertEquals(2, firstSystemBills.size());
        // Since Test.loadData doesn't import dynamic dates, we'll update these system bills to be due tomorrow.
        Date today = Date.today();
        for (System_Bill__c systemBill : firstSystemBills) {
            systemBill.Date__c = Date.newInstance(today.year(), today.month(), today.day() + 1);
        }
        update firstSystemBills;

        List<Account_Bill__c> accountBills = [
            SELECT Id, Total_Due__c, Carry_Over_Balance__c, Published__c, Due_Date_SB__c
            FROM Account_Bill__c
            WHERE Parent_Account__r.Name = 'PaymentTestPropertyD'
        ];
        // Should be one account bill, but not due yet.
        System.assertEquals(1, accountBills.size());
        Account_Bill__c accountBill = accountBills[0];
        System.assert(accountBill.Due_Date_SB__c > Date.today());
        List<ChargentOrders__ChargentOrder__c> autopayOrders;

        System.runAs(user) {
            List<AggregateResult> aggregateSystemBills = MyAccountController.getSystemBills('All');
            System.assertEquals(2, aggregateSystemBills.size());

            // Sign up for autopay
            autopayOrders = CSPaymentTest.makePaymentInPortal('All', true);
            // Should be two autopay orders sitting on the account bill
            System.assertEquals(2, autopayOrders.size());
            for (ChargentOrders__ChargentOrder__c order : autopayOrders) {
                System.assertEquals('Recurring', order.ChargentOrders__Payment_Status__c);
                System.assertEquals(accountBill.Id, order.Account_Bill__c);
                System.assertEquals(null, order.Reason_for_Recurring_Stop__c);
                System.assertEquals(today.addDays(1), order.ChargentOrders__Payment_Start_Date__c);
                System.assert(
                    order.ChargentOrders__Subtotal__c == firstSystemBills[0].total_Due__c ||
                        order.ChargentOrders__Subtotal__c == firstSystemBills[1].total_Due__c,
                    'Wrong charge amount: ' + order.ChargentOrders__Subtotal__c);
            }
        }
        // Make a partial payment by paying half of each bill
        for (System_Bill__c systemBill : firstSystemBills) {
            systemBill.Total_Payments_This_Month__c = systemBill.Total_Due__c/2;
            systemBill.Payments_Net_Previous_Balances__c = systemBill.Total_Due__c/2;
        }
        update firstSystemBills;
        firstSystemBills = [
            SELECT Id, Total_Due__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Parent_Account__r.Name = 'PaymentTestPropertyD'
        ];

        Test.startTest();
        // After the chargent move runs, there should still be two recurring orders on the account bill
        simulateBatchRecurringHandler();
        Test.stopTest();

        List<ChargentOrders__ChargentOrder__c> chargentOrders = [
            SELECT Id, Account_Bill__c, ChargentOrders__Payment_Status__c, Reason_for_Recurring_Stop__c,
                ChargentOrders__Payment_Start_Date__c, ChargentOrders__Subtotal__c, ChargentOrders__Charge_Amount__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id = :autopayOrders
        ];

        // Should still have 2 orders
        System.assertEquals(2, chargentOrders.size());
        for (ChargentOrders__ChargentOrder__c order : chargentOrders) {
            // And they should still be recurring
            System.assertEquals(null, order.Reason_for_Recurring_Stop__c);
            System.assertEquals('Recurring', order.ChargentOrders__Payment_Status__c);
            System.assertEquals(accountBill.Id, order.Account_Bill__c);
            System.assertEquals(today.addDays(1), order.ChargentOrders__Payment_Start_Date__c);
            System.assert(
                order.ChargentOrders__Charge_Amount__c == ((Decimal) firstSystemBills[0].Total_Due__c/2).setScale(2, RoundingMode.HALF_UP) ||
                    order.ChargentOrders__Charge_Amount__c == ((Decimal) firstSystemBills[1].Total_Due__c/2).setScale(2, RoundingMode.HALF_UP),
                'Wrong charge amount: ' + order.ChargentOrders__Charge_Amount__c);
        }
    }

    // Tests for handling recurring Chargent Orders if they're on the last account bill and paid the bill off. In that
    // case, they should stay as recurring, but get pushed out
    @IsTest public static void testOrdersOnPaidLastBill() {
        User user = [
            SELECT Id, Contact.AccountId
            FROM User
            WHERE Username='PaymentTestParentAccountC@bluewavesolar.com'
        ];

        List<System_Bill__c> firstSystemBills = [
            SELECT Id, Total_Due__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Parent_Account__r.Name = 'PaymentTestPropertyD'
        ];
        System.assertEquals(2, firstSystemBills.size());
        // Since Test.loadData doesn't import dynamic dates, we'll update these system bills to be due tomorrow.
        Date today = Date.today();
        for (System_Bill__c systemBill : firstSystemBills) {
            systemBill.Date__c = Date.newInstance(today.year(), today.month(), today.day() + 1);
        }
        update firstSystemBills;

        List<Account_Bill__c> accountBills = [
            SELECT Id, Total_Due__c, Carry_Over_Balance__c, Published__c, Due_Date_SB__c
            FROM Account_Bill__c
            WHERE Parent_Account__r.Name = 'PaymentTestPropertyD'
        ];
        // Should be one account bill, but not due yet.
        System.assertEquals(1, accountBills.size());
        Account_Bill__c accountBill = accountBills[0];
        System.assert(accountBill.Due_Date_SB__c > Date.today());
        List<ChargentOrders__ChargentOrder__c> autopayOrders;

        System.runAs(user) {
            List<AggregateResult> aggregateSystemBills = MyAccountController.getSystemBills('All');
            System.assertEquals(2, aggregateSystemBills.size());

            // Sign up for autopay and pay off the account bill
            autopayOrders = CSPaymentTest.makePaymentInPortal('All', true);
        }

        CSPaymentTest.mockMakeASinglePayment(firstSystemBills);
        // Should be two autopay orders sitting on the account bill
        System.assertEquals(2, autopayOrders.size());
        for (ChargentOrders__ChargentOrder__c order : autopayOrders) {
            System.assertEquals('Recurring', order.ChargentOrders__Payment_Status__c);
            System.assertEquals(accountBill.Id, order.Account_Bill__c);
            System.assertEquals(null, order.Reason_for_Recurring_Stop__c);
            System.assertEquals(today.addDays(1), order.ChargentOrders__Payment_Start_Date__c);
            System.assert(order.ChargentOrders__Subtotal__c == 345.28 || order.ChargentOrders__Subtotal__c == 321.33,
                'Wrong charge amount: ' + order.ChargentOrders__Subtotal__c);
        }

        Test.startTest();
        // After the chargent move runs, there should still be two recurring orders on the account bill
        simulateBatchRecurringHandler();
        Test.stopTest();

        List<ChargentOrders__ChargentOrder__c> chargentOrders = [
            SELECT Id, Account_Bill__c, ChargentOrders__Payment_Status__c, Reason_for_Recurring_Stop__c,
                ChargentOrders__Payment_Start_Date__c, ChargentOrders__Subtotal__c, ChargentOrders__Charge_Date__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id = :autopayOrders
        ];

        // Should still have 2 orders
        System.assertEquals(2, chargentOrders.size());
        for (ChargentOrders__ChargentOrder__c order : chargentOrders) {
            // And they should still be recurring, but to start sometime in the future
            System.assertEquals(null, order.Reason_for_Recurring_Stop__c);
            System.assertEquals('Recurring', order.ChargentOrders__Payment_Status__c);
            System.assertEquals(accountBill.Id, order.Account_Bill__c);
            System.assert(order.ChargentOrders__Payment_Start_Date__c > Date.today());
        }
    }

    // Tests for handling recurring Chargent Orders if they're on an account bill that doesn't have a subsequent bill
    // (e.g. if their subscription is stopped)
    @IsTest public static void testOrdersOnOldLastBill() {
        User user = [
            SELECT Id, Contact.AccountId
            FROM User
            WHERE Username='PaymentTestParentAccountC@bluewavesolar.com'
        ];

        List<System_Bill__c> firstSystemBills = [
            SELECT Id, Total_Due__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Parent_Account__r.Name = 'PaymentTestPropertyD'
        ];
        System.assertEquals(2, firstSystemBills.size());
        Date today = Date.today();

        List<Account_Bill__c> accountBills = [
            SELECT Id, Total_Due__c, Carry_Over_Balance__c, Published__c, Due_Date_SB__c
            FROM Account_Bill__c
            WHERE Parent_Account__r.Name = 'PaymentTestPropertyD'
        ];
        // Should be one account bill, but not due yet.
        System.assertEquals(1, accountBills.size());
        Account_Bill__c accountBill = accountBills[0];
        System.assert(accountBill.Due_Date_SB__c < Date.today());
        List<ChargentOrders__ChargentOrder__c> autopayOrders;

        System.runAs(user) {
            List<AggregateResult> aggregateSystemBills = MyAccountController.getSystemBills('All');
            System.assertEquals(2, aggregateSystemBills.size());

            // Sign up for autopay, and make a partial payment
            autopayOrders = CSPaymentTest.makePaymentInPortal('All', true);
            // Should be two autopay orders sitting on the account bill
            System.assertEquals(2, autopayOrders.size());
            for (ChargentOrders__ChargentOrder__c order : autopayOrders) {
                System.assertEquals('Recurring', order.ChargentOrders__Payment_Status__c);
                System.assertEquals(accountBill.Id, order.Account_Bill__c);
                System.assertEquals(null, order.Reason_for_Recurring_Stop__c);
                System.assertEquals(today.addDays(1), order.ChargentOrders__Payment_Start_Date__c);
                System.assert(order.ChargentOrders__Subtotal__c == 345.28 || order.ChargentOrders__Subtotal__c == 321.33,
                    'Wrong charge amount: ' + order.ChargentOrders__Subtotal__c);
            }
        }

        Test.startTest();
        // After the chargent move runs, there should still be two recurring orders on the account bill
        simulateBatchRecurringHandler();
        Test.stopTest();

        List<ChargentOrders__ChargentOrder__c> chargentOrders = [
            SELECT Id, Account_Bill__c, ChargentOrders__Payment_Status__c, Reason_for_Recurring_Stop__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id = :autopayOrders
        ];
        // Should still have 2 orders
        System.assertEquals(2, chargentOrders.size());
        for (ChargentOrders__ChargentOrder__c order : chargentOrders) {
            // But they should be stopped because there's no other account bill
            System.assert(order.Reason_for_Recurring_Stop__c.contains('No Account Bill found for Bill Number and Property Account Id'));
            System.assertEquals('Stopped', order.ChargentOrders__Payment_Status__c);
            System.assertEquals(accountBill.Id, order.Account_Bill__c);
        }
    }

    @IsTest static void testNoAutopayScheduleSet() {
        List<Energy_Usage_Update__c> productionUpdateList = [
            SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c,
                YearDate__c, Credits_on_Bill_Period__c,
                MonthDate__c, Total_System_NMCs__c, Production__c,
                Generate_Bills__c, Total_System_NMCs_2_of_4__c,
                Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c,
                Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c,
                Production_kWh_4_of_4__c, Net_Metering_Rate_Applied__c,
                Billing_Method__c, Date__c, Billing_Period_Start_Date__c,
                Billing_Period_End_Date__c, Month_Number__c,
                Net_Metering_Rate_Applied_2_of_4__c,
                Net_Metering_Rate_Applied_3_of_4__c,
                Net_Metering_Rate_Applied_4_of_4__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssB - March 2016'
            OR Name = 'sssA - March 2016'
            LIMIT 2
        ];
        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(productionUpdateList);
        ee.runBills();
        TestBillCreationandPayment.setBillsToPublished();

        // Save the chargent orders before recurring payment handler runs
        List<ChargentOrders__ChargentOrder__c> orderListBeforeRPH = [
            SELECT Id,
                Entity_Name__c,
                ChargentOrders__Payment_Status__c,
                ChargentOrders__Charge_Date__c,
                Reason_for_Recurring_Stop__c,
                Account_Bill__r.Bill_Number__c,
                Account_Bill__r.Name,
                ChargentOrders__Charge_Amount__c,
                Account_Bill__r.Parent_Account__r.Recurring_Billing__c,
                ChargentOrders__Billing_Last_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE (NOT ChargentOrders__Billing_Last_Name__c LIKE '%CaseCreation%')
            AND (NOT ChargentOrders__Billing_Last_Name__c LIKE '%AutoEmailer%')
        ];
        Map<Id, ChargentOrders__ChargentOrder__c> beforeRPHOrderMap =
            new Map<Id, ChargentOrders__ChargentOrder__c>(orderListBeforeRPH);

        Test.startTest();
        Date today = Date.newInstance(2018, 12, 31);
        List<Autopay_Schedule__c> autopaySchedules = [
            SELECT Id
            FROM Autopay_Schedule__c
            WHERE Run_Date__c = :today
        ];
        // There shouldn't be a schedule for 12/31, so the RPH shouldn't run
        System.assertEquals(0, autopaySchedules.size());
        RecurringPaymentsHandler rph = new RecurringPaymentsHandler();
        rph.checkAutopaySchedule(null, today);
        Test.stopTest();

        List<ChargentOrders__ChargentOrder__c> orderListAfterRPH = [
            SELECT Id,
                Entity_Name__c,
                ChargentOrders__Payment_Status__c,
                ChargentOrders__Charge_Date__c,
                Reason_for_Recurring_Stop__c,
                Account_Bill__r.Bill_Number__c,
                Account_Bill__r.Name,
                ChargentOrders__Charge_Amount__c,
                Account_Bill__r.Parent_Account__r.Recurring_Billing__c,
                ChargentOrders__Billing_Last_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE (NOT ChargentOrders__Billing_Last_Name__c LIKE '%CaseCreation%')
            AND (NOT ChargentOrders__Billing_Last_Name__c LIKE '%AutoEmailer%')
        ];
        // None of the orders should have changed because RPH shouldn't have run
        for (ChargentOrders__ChargentOrder__c order : orderListAfterRPH) {
            System.assertEquals(order, beforeRPHOrderMap.get(order.Id));
        }
    }

    @IsTest static void testAutopayScheduleForToday() {
        List<Energy_Usage_Update__c> productionUpdateList = [
            SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c,
                YearDate__c, Credits_on_Bill_Period__c,
                MonthDate__c, Total_System_NMCs__c, Production__c,
                Generate_Bills__c, Total_System_NMCs_2_of_4__c,
                Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c,
                Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c,
                Production_kWh_4_of_4__c, Net_Metering_Rate_Applied__c,
                Billing_Method__c, Date__c, Billing_Period_Start_Date__c,
                Billing_Period_End_Date__c, Month_Number__c,
                Net_Metering_Rate_Applied_2_of_4__c,
                Net_Metering_Rate_Applied_3_of_4__c,
                Net_Metering_Rate_Applied_4_of_4__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssB - March 2016'
            OR Name = 'sssA - March 2016'
            LIMIT 2
        ];
        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(productionUpdateList);
        ee.runBills();
        TestBillCreationandPayment.setBillsToPublished();

        // Save the chargent orders before recurring payment handler runs
        List<ChargentOrders__ChargentOrder__c> orderListBeforeRPH = [
            SELECT Id,
                Entity_Name__c,
                ChargentOrders__Payment_Status__c,
                ChargentOrders__Charge_Date__c,
                Reason_for_Recurring_Stop__c,
                Account_Bill__r.Bill_Number__c,
                Account_Bill__r.Name,
                ChargentOrders__Charge_Amount__c,
                Account_Bill__r.Parent_Account__r.Recurring_Billing__c,
                ChargentOrders__Billing_Last_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE (NOT ChargentOrders__Billing_Last_Name__c LIKE '%CaseCreation%')
            AND (NOT ChargentOrders__Billing_Last_Name__c LIKE '%AutoEmailer%')
        ];

        Test.startTest();
        Date today = Date.newInstance(2018, 12, 31);
        Autopay_Schedule__c aps = new Autopay_Schedule__c(Run_Date__c = today);
        insert aps;
        List<Autopay_Schedule__c> autopaySchedules = [
            SELECT Id
            FROM Autopay_Schedule__c
            WHERE Run_Date__c = :today
        ];
        System.assertEquals(1, autopaySchedules.size());
        RecurringPaymentsHandler rph = new RecurringPaymentsHandler();
        rph.checkAutopaySchedule(null, today);
        Test.stopTest();

        List<ChargentOrders__ChargentOrder__c> orderListAfterRPH = [
            SELECT Id,
                Entity_Name__c,
                ChargentOrders__Payment_Status__c,
                ChargentOrders__Charge_Date__c,
                Reason_for_Recurring_Stop__c,
                Account_Bill__r.Bill_Number__c,
                Account_Bill__r.Name,
                ChargentOrders__Charge_Amount__c,
                Account_Bill__r.Parent_Account__r.Recurring_Billing__c,
                Account_Bill__r.Parent_Account__r.Name,
                ChargentOrders__Billing_Last_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE (NOT ChargentOrders__Billing_Last_Name__c LIKE '%CaseCreation%')
            AND (NOT ChargentOrders__Billing_Last_Name__c LIKE '%AutoEmailer%')
        ];

        // Seven non-CaseCreation Chargent Orders:
        // 4 that should be stopped (three with charge date of 15 and 1 without charge date) because 0 SBs
        // 3 that should have been moved to the newer bill
        System.assertEquals(7, orderListAfterRPH.size());

        for (ChargentOrders__ChargentOrder__c cho : orderListAfterRPH) {
            if (cho.ChargentOrders__Charge_Date__c == '15') {
                System.assertEquals(0, cho.ChargentOrders__Charge_Amount__c);
                System.assertEquals('Stopped', cho.ChargentOrders__Payment_Status__c);
                System.assertNotEquals(null, cho.Reason_for_Recurring_Stop__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '30') {
                System.assertEquals('Account A', cho.Account_Bill__r.Parent_Account__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '27') {
                System.assertEquals('Account A', cho.Account_Bill__r.Parent_Account__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            } else if (cho.ChargentOrders__Charge_Date__c == '25') {
                System.assertEquals('Account B', cho.Account_Bill__r.Parent_Account__r.Name);
                System.assertEquals('Recurring', cho.ChargentOrders__Payment_Status__c);
                System.assertEquals(2, cho.Account_Bill__r.Bill_Number__c);
            }
        }
    }

    @IsTest public static void testOrdersOnNewBill() {
        // If a chargent order is on Bill Number 1, and it's the only bill it shouldn't be stopped
        List<Account_Bill__c> accountBills = [
            SELECT Id, Bill_Number__c, Due_Date_SB__c,
            (SELECT Id FROM Chargent_Orders__r WHERE ChargentOrders__Payment_Status__c = 'Recurring'),
            (SELECT Id, Date__c FROM System_Bills__r)
            FROM Account_Bill__c
            WHERE Parent_Account__r.Name = 'Account A'
        ];
        // There should be just one Account Bill for Account A with a two Chargent Orders (for different entities)
        System.assertEquals(1, accountBills.size());
        System.assertEquals(1, accountBills[0].Bill_Number__c);
        System.assertEquals(2, accountBills[0].Chargent_Orders__r.size());
        for (System_Bill__c systemBill : accountBills[0].System_Bills__r) {
            systemBill.Date__c = Date.today();
        }
        update accountBills[0].System_Bills__r;
        accountBills = [
            SELECT Id, Bill_Number__c, Due_Date_SB__c,
            (SELECT Id FROM Chargent_Orders__r WHERE ChargentOrders__Payment_Status__c = 'Recurring'),
            (SELECT Id, Date__c FROM System_Bills__r)
            FROM Account_Bill__c
            WHERE Parent_Account__r.Name = 'Account A'
        ];
        System.assert(accountBills[0].Due_Date_SB__c > Date.today(), 'Account Bill shouldn\'t be due yet');

        Test.startTest();
        simulateBatchRecurringHandler();
        Test.stopTest();
        accountBills = [
            SELECT Id, Bill_Number__c,
            (SELECT Id FROM Chargent_Orders__r WHERE ChargentOrders__Payment_Status__c = 'Recurring')
            FROM Account_Bill__c
            WHERE Parent_Account__r.Name = 'Account A'
        ];
        // There should be just one Account Bill for Account A with a two Chargent Orders (for different entities)
        System.assertEquals(1, accountBills.size());
        System.assertEquals(1, accountBills[0].Bill_Number__c);
        System.assertEquals(2, accountBills[0].Chargent_Orders__r.size());
    }

    private static RecurringPaymentsHandler simulateBatchRecurringHandler() {
        RecurringPaymentsHandler batchToRun = new RecurringPaymentsHandler();
        List<ChargentOrders__ChargentOrder__c> orders = [
            SELECT Id, Name, ChargentOrders__Payment_Status__c,
                ChargentOrders__Charge_Amount__c, Account_Bill__c, ChargentOrders__Account__r.Max_Account_Bill_Number__c,
                Account_Bill__r.Bill_Number__c, Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Account_Bill__r.Due_Date_SB__c, Property_Account_ID__c, Reason_for_Recurring_Stop__c, Comments__c,
                ChargentOrders__Payment_Method__c, ChargentOrders__Bank_Name__c, ChargentOrders__Bank_Routing_Number__c,
                ChargentOrders__Bank_Account_Type__c, ChargentOrders__Bank_Account_Number__c, ChargentOrders__Bank_Account_Name__c,
                ChargentOrders__Billing_Email__c, ChargentOrders__Card_Type__c, ChargentOrders__Card_Number__c,
                ChargentOrders__Card_Expiration_Month__c, ChargentOrders__Card_Expiration_Year__c,
                ChargentOrders__Billing_Address__c, ChargentOrders__Billing_City__c, ChargentOrders__Billing_State__c,
                ChargentOrders__Billing_Zip_Postal__c, ChargentOrders__Billing_First_Name__c, ChargentOrders__Billing_Last_Name__c,
                ChargentOrders__Payment_Frequency__c, ChargentOrders__Payment_Stop__c, ChargentOrders__Charge_Date__c,
                ChargentOrders__Payment_Start_Date__c, ChargentOrders__Shipping_Name__c, Entity__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            ORDER BY CreatedDate
        ];
        List<ChargentOrders__ChargentOrder__c> orders1 = new List<ChargentOrders__ChargentOrder__c>();
        List<ChargentOrders__ChargentOrder__c> orders2 = new List<ChargentOrders__ChargentOrder__c>();
        for (ChargentOrders__ChargentOrder__c order : orders) {
            if (orders1.size() > orders2.size()) {
                orders2.add(order);
            } else {
                orders1.add(order);
            }
        }
        batchToRun.updateRecurringOrders(orders1);
        batchToRun.updateRecurringOrders(orders2);
        return batchToRun;
    }
}