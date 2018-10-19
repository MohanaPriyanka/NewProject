/**
 * Created by WParker on 8/1/2018.
 */

@IsTest
private class PaymentCaseTest {

    @TestSetup public static void setupData() {

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
        Test.loadData(ChargentOrders__ChargentOrder__c.SObjectType, 'TestCSChargentOrder');
        Test.loadData(ChargentOrders__Transaction__c.SObjectType, 'TestCSTransaction');
        Test.loadData(Case.SObjectType, 'TestCSCase');


        // Altering next transaction dates

        // Change all orders not designed for this class to have valid next transaction dates
        List<ChargentOrders__ChargentOrder__c> otherOrders = [
            SELECT Id, ChargentOrders__Next_Transaction_Date__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE NOT ChargentOrders__Billing_Last_Name__c LIKE '%CaseCreation%'
        ];

        for (ChargentOrders__ChargentOrder__c order : otherOrders) {
            order.ChargentOrders__Next_Transaction_Date__c = order.ChargentOrders__Next_Transaction_Date__c.addMonths(1);
        }

        update otherOrders;

        // Set an error-causing next transaction date
        ChargentOrders__ChargentOrder__c orderWithBadNextTransDate = [
            SELECT Id, ChargentOrders__Billing_Last_Name__c, ChargentOrders__Next_Transaction_Date__c, ChargentOrders__Charge_Date__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Billing_Last_Name__c = 'CaseCreationNextTrans'
            LIMIT 1
        ];

        orderWithBadNextTransDate.ChargentOrders__Next_Transaction_Date__c = System.today();
        orderWithBadNextTransDate.ChargentOrders__Charge_Date__c = String.valueOf(Date.today().day());

        update orderWithBadNextTransDate;

    }

    @IsTest
    static void testWithMassiveAmountsOfRecords() {
        PaymentCaseCreator caseCreator = new PaymentCaseCreator();

        List<Account> accounts = new List<Account>();
        List<ChargentOrders__ChargentOrder__c> orders = new List<ChargentOrders__ChargentOrder__c>();
        List<Account> clientAccounts = new List<Account>();
        List<ChargentBase__Gateway__c> gateways = new List<ChargentBase__Gateway__c>();
        List<Entity__c> entities = new List<Entity__c>();
        List<ChargentOrders__Transaction__c> transactions = new List<ChargentOrders__Transaction__c>();

        for (Integer i = 0; i < 90; i++) {


            Account accountA = new Account(Name = 'Account A',
                RecordTypeId = '012j00000010Ha3',
                Recurring_Billing__c = true);

            accounts.add(accountA);

            // Payment Status Case should be made for this
            ChargentOrders__ChargentOrder__c orderPaymentStatusError = new ChargentOrders__ChargentOrder__c(
                ChargentOrders__Account__c = accountA.Id,
                ChargentOrders__Billing_First_Name__c = 'Sarah',
                ChargentOrders__Billing_Last_Name__c = 'Renfro',
                ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                ChargentOrders__Billing_Zip_Postal__c = '02467',
                ChargentOrders__Subtotal__c = 603.92,
                ChargentOrders__Payment_Method__c = 'Credit Card',
                ChargentOrders__Card_Type__c = 'Visa',
                ChargentOrders__Card_Number__c = '411111111111',
                ChargentOrders__Card_Security_Code__c = '999',
                ChargentOrders__Card_Expiration_Month__c = '02',
                ChargentOrders__Card_Expiration_Year__c = '2018',
                ChargentOrders__Card_Last_4__c = '1111',
                ChargentOrders__Payment_Status__c = 'Error',
                ChargentOrders__Payment_Frequency__c = 'Monthly',
                ChargentOrders__Payment_Start_Date__c = System.today(),
                ChargentOrders__Charge_Date__c = '30',
                ChargentOrders__Next_Transaction_Date__c = Date.today().addDays(1)
            );

            orders.add(orderPaymentStatusError);

            Account clientAccount = new Account(Name = 'Client Account',
                Client_Brand_Key__c = 'AmpBlack');

            clientAccounts.add(clientAccount);

            ChargentBase__Gateway__c chGateway =
                new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                    ChargentBase__Merchant_ID__c = '235986',
                    ChargentBase__Debug__c = true,
                    ChargentBase__Active__c = true);

            gateways.add(chGateway);

            Entity__c entity1 = new Entity__c(
                Name = 'Oxford Barrett St. P1',
                Send_Checks_Address__c = 'Fake Lockbox Address, P.O Box 12345, Phoenix Arizona 02114',
                Client_Account__c = clientAccount.Id,
                Gateway__c = chGateway.Id
            );

            entities.add(entity1);


        }

        // insert everything
        insert orders;
        insert accounts;
        insert clientAccounts;
        insert gateways;
        insert entities;

        for (Integer i = 0; i < 90; i++) {

            ChargentOrders__Transaction__c trans1 = new ChargentOrders__Transaction__c(CreatedDate = Date.today(),
                ChargentOrders__Order__c = orders.get(i).Id,
                ChargentOrders__Gateway__c = entities[i].Gateway__c,
                ChargentOrders__Gateway_ID__c = entities[i].Gateway__c,
                Distributed_Among_System_Bills__c = false,
                ChargentOrders__Response_Message__c = 'OK',
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Payment_Method__c = 'Credit Card',
                Activity_Type__c = 'Payment',
                ChargentOrders__Amount__c = 50,
                ChargentOrders__Response_Status__c = 'Approved');

            transactions.add(trans1);
        }

        insert transactions;

        // Actually test the data
        Test.startTest();

        caseCreator.fetchOrdersAndRun();

        Test.stopTest();


        List<Case> casesThatWereJustMade =
        [SELECT Id, AccountId, Chargent_Order__c, Subject, Status
        FROM Case
        WHERE Subject LIKE '%Automatic Payment Error%'
        AND Status != 'Closed'];

        System.assertEquals(casesThatWereJustMade.size(), 95);
    }

    @IsTest
    static void testFetchCorrectChargentOrdersFromToday() {
        PaymentCaseCreator caseCreator = new PaymentCaseCreator();

        List<ChargentOrders__ChargentOrder__c> orders = caseCreator.getAllRelevantOrders();

        System.assertEquals(orders.size(), 8);
    }

    @IsTest
    static void testFetchOrdersAndRunEverything() {
        PaymentCaseCreator caseCreator = new PaymentCaseCreator();


        Test.startTest();
        caseCreator.fetchOrdersAndRun();
        Test.stopTest();

        Case caseThatShouldBeClosedAfter =
        [SELECT Id, AccountId, Chargent_Order__c, Subject, Status
        FROM Case
        WHERE Subject LIKE '%Should be Closed%'];

        List<Case> casesThatWereJustMade =
        [SELECT Id, AccountId, Chargent_Order__c, Subject, Status
        FROM Case
        WHERE Subject LIKE '%Automatic Payment Error%'
        AND Status != 'Closed'];

        List<Case> psCases =
        [SELECT Id, AccountId, Chargent_Order__c, Subject, Status
        FROM Case
        WHERE Subject LIKE '%[Transaction Failed]%'
        AND Status != 'Closed'];

        List<Case> internalCases =
        [SELECT Id, AccountId, Chargent_Order__c, Subject, Status
        FROM Case
        WHERE Subject LIKE '%Product Team%'
        AND Status != 'Closed'];


        // Ensure correct case was closed
        System.assertEquals(caseThatShouldBeClosedAfter.Status, 'Closed');


        // Ensure correct cases were made
        System.assertEquals(casesThatWereJustMade.size(), 5);
        System.assertEquals(psCases.size(), 2); // The order with a transaction response of 'error' also becomes a PS
        System.assertEquals(internalCases.size(), 3);
    }

    @IsTest
    static void testCloseCases() {
        PaymentCaseCreator caseCreator = new PaymentCaseCreator();

        ChargentOrders__ChargentOrder__c order1 =
            [SELECT Id, Property_Account_ID__c, ChargentOrders__Account__c,
                ChargentOrders__Payment_Status__c, ChargentOrders__Next_Transaction_Date__c, Account_Bill__c,
                ChargentOrders__Account__r.Id, Property_Account__r.Id, Entity__c, ChargentOrders__Billing_Last_Name__c,
            (SELECT Id, Status, Chargent_Order__c FROM Cases__r WHERE Status != 'Closed')
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Billing_Last_Name__c = 'CaseCreationPentaleri'
            LIMIT 1].get(0);

        caseCreator.closeAndOpenNecessaryCases(new List<ChargentOrders__ChargentOrder__c>{order1});

        Case caseThatShouldBeClosedAfter =
        [SELECT Id, AccountId, Chargent_Order__c, Subject, Status
        FROM Case
        WHERE Subject LIKE '%Should be Closed%'];

        System.assertEquals(caseThatShouldBeClosedAfter.Status, 'Closed');
    }

    @IsTest
    static void testCaseCreation() {

        PaymentCaseCreator caseCreator = new PaymentCaseCreator();

        ChargentOrders__ChargentOrder__c order1 =
            [SELECT Id, Property_Account_ID__c, ChargentOrders__Account__c, Account_Bill__r.Parent_Account__r.Send_Bills_Contact__r.Id
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Billing_Last_Name__c = 'Pentaleri'
            LIMIT 1].get(0);

        Test.startTest();
        insert caseCreator.createCaseForOrder(order1,
            PaymentCaseCreator.OrderCaseType.PaymentStatusError);
        insert caseCreator.createCaseForOrder(order1,
            PaymentCaseCreator.OrderCaseType.InvalidNextTransDate);
        insert caseCreator.createCaseForOrder(order1,
            PaymentCaseCreator.OrderCaseType.AccountBillError);

        Test.stopTest();

        Case PSCase =
        [SELECT AccountId, Product_Line__c, Category__c, Chargent_Order__c, Description, Subject, Case_Type__c
        FROM Case
        WHERE Chargent_Order__c =: order1.Id
        AND Subject LIKE '%Transaction Failed%'
        AND (NOT Subject  LIKE '%Should be Closed%')
        LIMIT 1];

        List<Case> internalCases =
        [SELECT AccountId, Product_Line__c, Category__c, Chargent_Order__c, Description, Subject
        FROM Case
        WHERE Chargent_Order__c =: order1.Id
        AND Subject LIKE '%Send to Product Team%'];


        // Ensure a Case was created for the chargent order
        System.assertEquals(PSCase.Chargent_Order__c, order1.Id);

        // Ensure the type of the case is correctly being set to BlueWave (important because it defaults to customer
        //      which falsely implies that the case originated because of customer contact
        System.assertEquals(PSCase.Case_Type__c, 'BlueWave');

        // Ensure each Case was created with the error-specific description
        System.assertEquals(PaymentCaseCreator.paymentStatusErrorDescription, PSCase.Description);
        System.assertEquals(2, internalCases.size());
    }

    @IsTest
    static void testCloseCaseWhenOrderIsNotQueriedFor() {
        ChargentOrders__ChargentOrder__c orderWithTransResponseError = [
            SELECT Id, ChargentOrders__Billing_Last_Name__c, ChargentOrders__Account__c,
                Account_Bill__r.Parent_Account__r.Send_Bills_Contact__r.Id
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Billing_Last_Name__c = 'CaseCreationTransResponse'
        ];

        // Create Case for order
        PaymentCaseCreator pcc = new PaymentCaseCreator();
        insert pcc.createCaseForOrder(orderWithTransResponseError, PaymentCaseCreator.OrderCaseType.PaymentStatusError);

        // set the order's payment status to complete, saying there should no longer be a case, and check
        //  that the case will be closed correctly

        orderWithTransResponseError.ChargentOrders__Payment_Status__c = 'Complete';
        update orderWithTransResponseError;

        List<Case> casesForTransRespOrderBefore = [
            SELECT Id, Chargent_Order__c, Status
            FROM Case
            WHERE Status != 'Closed'
            AND Chargent_Order__c =: orderWithTransResponseError.Id
        ];

        System.assertEquals(1, casesForTransRespOrderBefore.size());

        // Pass no orders into the method
        pcc.closeAndOpenNecessaryCases(new List<ChargentOrders__ChargentOrder__c>());

        List<Case> casesForTransRespOrderAfter = [
            SELECT Id, Chargent_Order__c, Status
            FROM Case
            WHERE Status != 'Closed'
            AND Chargent_Order__c =: orderWithTransResponseError.Id
        ];

        // Case should be closed and therefore this query should retrieve nothing
        System.assertEquals(0, casesForTransRespOrderAfter.size());
    }
}