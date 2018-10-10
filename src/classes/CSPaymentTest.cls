@isTest
public class CSPaymentTest {
    private static Profile profileRecord = [SELECT Id FROM Profile WHERE Name = 'Community Solar Community User'];

    @testSetup public static void CSPaymentSetupTestData() {
        TestFactory.insertBWAddress();
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
        System_Properties__c sysProp = new System_Properties__c(Name = 'System', Disable_System_Bill_Trigger__c = true);
        insert sysProp;
        Test.loadData(System_Bill__c.SObjectType, 'TestCSSystemBill');
        Test.loadData(Utility_Account_Bill__c.SObjectType, 'TestCSUtilityAccountBill');
        Test.loadData(UASB__c.SObjectType, 'TestCSUASB');
        Test.loadData(ChargentOrders__ChargentOrder__c.SObjectType, 'TestCSChargentOrder');

        sysProp.Disable_System_Bill_Trigger__c = false;
        update sysProp;

        // Because there's no way to populate self lookups:
        // https://salesforce.stackexchange.com/questions/54527/test-loaddata-undocumented-but-useful-behavior-loading-relationships
        // We put the parent account's name in AccountNumber and use that to update the accounts.
        Map<String, Account> accountNameMap = new Map<String, Account>();
        List<Account> accounts = [SELECT Id, Name, AccountNumber FROM Account];
        for (Account acct : accounts) {
            accountNameMap.put(acct.Name, acct);
        }
        for (Account acct : accounts) {
            if (accountNameMap.get(acct.AccountNumber) != null) {
                acct.Parent_Account__c = accountNameMap.get(acct.AccountNumber).Id;
            }
        }
        update accounts;
        for (Account acct : accounts) {
            if (acct.Name == 'ADonut Shop Parent') {
                insertUser(acct, 'CSPaymentTest@bluewavesolar.com');
            } else if (acct.Name == 'Unrelated OtherAccount Parent') {
                insertUser(acct, 'CSPaymentTestB@bluewavesolar.com');
            } else if (acct.Name == 'PaymentTestParentAccountA') {
                insertUser(acct, 'PaymentTestParentAccountA@bluewavesolar.com');
            } else if (acct.Name == 'PaymentTestParentAccountC') {
                insertUser(acct, 'PaymentTestParentAccountC@bluewavesolar.com');
            }
        }

        List<Account_Bill__c> abs = [
            SELECT Id
            FROM Account_Bill__c
            WHERE Name LIKE '%Donut Shop%'
            OR Name LIKE '%Payment Test%'
            OR Name LIKE '%Account A%'
            OR Name LIKE '%Account B%'
        ];
        for (Account_Bill__c ab : abs) {
            ab.Published__c = true;
        }
        update abs;
    }

    // We get System.UnexpectedException: Salesforce System Error: 900955498-340097 (1185570226) (1185570226)
    // when trying to load users via Test.loadData
    private static void insertUser(Account account, String email) {
        Contact contact = new Contact(FirstName = 'First', LastName = account.Name, AccountId = account.Id);
        insert contact;
        User user = new User(
            FirstName = 'First',
            LastName = account.Name,
            Alias = ((String) account.Id).right(6),
            Email = email,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileRecord.Id,
            Country = 'United States',
            IsActive = true,
            ContactId = contact.Id,
            TimeZoneSidKey = 'Pacific/Tongatapu',
            Username = email);
        Util.insertSObj(user);
    }

    @isTest public static void testPayOffOne() {
        // assert Bills were inserted for each property account, for 2 billing periods:
        List<System_Bill__c> systemBillList = [
            SELECT Id, Account_Bill__r.Name, Total_Due__c,
                Account_Bill__r.Is_Most_Recent__c, Account_Bill__c
            FROM System_Bill__c
            WHERE Name LIKE '%Donut Shop%'
            ORDER BY Account_Bill__r.Name
        ];
        // Only production updates for SSS1 (4 UASes * 2 Production Updates)
        System.assertEquals(8, systemBillList.size());

        User userA = [  SELECT Id
                        FROM User
                        WHERE Username='CSPaymentTest@bluewavesolar.com'];

        System.runAs(userA) {
            Test.startTest();
            // Baseline: If you were to make a payment for all properties, there would be 4 payments
            List<ChargentOrders__ChargentOrder__c> initialOrderList = makePaymentInPortal('All');
            System.assertEquals(4, initialOrderList.size());

            for (ChargentOrders__ChargentOrder__c chOrder : initialOrderList) {
                System.assert(chOrder.ChargentOrders__Subtotal__c > 0);
            }
        }

        // Make a payment for only ONE property account:
        List<System_Bill__c> sbList = new List<System_Bill__c>();
        Account_Bill__c billToPay = systemBillList[2].Account_Bill__r;
        System.assertEquals('BDonut Shop February 2018', billToPay.Name);
        System.assertEquals(true, billToPay.Is_Most_Recent__c);
        sbList.add(systemBillList[2]);
        mockMakeASinglePayment(sbList);

        System.runAs(userA) {
            // Try again to make a payment for all property accounts, 4 orders, but one at $0
            List<ChargentOrders__ChargentOrder__c> secondOrderList = makePaymentInPortal('All');
            System.assertEquals(4,secondOrderList.size());

            for (ChargentOrders__ChargentOrder__c orderToCharge : secondOrderList) {
                if (orderToCharge.Account_Bill__c == billToPay.Id) {
                    System.assertEquals(0, orderToCharge.ChargentOrders__Subtotal__c);
                } else {
                    System.assert(orderToCharge.ChargentOrders__Subtotal__c > 0);
                }
            }

            String response1 = CreateOrderandPaymentRequest.chargeOrder(secondOrderList[0]);
            System.assertEquals('Approved', response1.right(8));
            String response2 = CreateOrderandPaymentRequest.chargeOrder(secondOrderList[1]);
            System.assertEquals('Approved', response2.right(8));
            String response3 = CreateOrderandPaymentRequest.chargeOrder(secondOrderList[2]);
            System.assertEquals('Approved', response3.right(8));

            Test.stopTest();
        }
    }

    @isTest public static void testPayOffAll(){
        // assert Bills were inserted for each property account, for 2 billing periods:
        List<System_Bill__c> systemBillList = [
            SELECT Id, Account_Bill__r.Name, Total_Due__c,
                Account_Bill__r.Is_Most_Recent__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Donut Shop%'
            ORDER BY Account_Bill__r.Name
        ];
        // Only production updates for SSS1 (4 UASes * 2 Production Updates)
        System.assertEquals(8, systemBillList.size());

        User userA = [  SELECT Id
                        FROM User
                        WHERE Username='CSPaymentTest@bluewavesolar.com'];

        System.runAs(userA) {
            Test.startTest();
            // Baseline: If you were to make a payment for all properties, there would be 4 payments
            List<String> paymentMethods = MyAccountController.getPaymentMethods('All');
            // There should only be one payment method for CSPaymentTest because those system bills point use a Gateway
            // that only accepts Bank Transfer
            System.assertEquals(1, paymentMethods.size());
            System.assert(paymentMethods.contains('ACH'));
            List<ChargentOrders__ChargentOrder__c> initialOrderList = makePaymentInPortal('All');
            System.assertEquals(4, initialOrderList.size());

            for (ChargentOrders__ChargentOrder__c chOrder : initialOrderList) {
                System.assert(chOrder.ChargentOrders__Subtotal__c > 0);
            }
        }

        // Make a payment for only ONE property account:
        List<System_Bill__c> sbList = new List<System_Bill__c>();
        System.assertEquals(true,systemBillList[0].Account_Bill__r.Is_Most_Recent__c);
        System.assertEquals(true,systemBillList[2].Account_Bill__r.Is_Most_Recent__c);
        System.assertEquals(true,systemBillList[4].Account_Bill__r.Is_Most_Recent__c);
        System.assertEquals(true,systemBillList[6].Account_Bill__r.Is_Most_Recent__c);
        sbList.add(systemBillList[0]);
        sbList.add(systemBillList[2]);
        sbList.add(systemBillList[4]);
        sbList.add(systemBillList[6]);
        mockMakeASinglePayment(sbList);

        System.runAs(userA) {
            // Try again to make a payment for all property accounts - we'll make 4 orders, but for $0
            List<ChargentOrders__ChargentOrder__c> secondOrderList = makePaymentInPortal('All');
            System.assertEquals(4, secondOrderList.size());

            for (ChargentOrders__ChargentOrder__c orderToCharge : secondOrderList) {
                System.assertEquals(0, orderToCharge.ChargentOrders__Subtotal__c);
            }

            Test.stopTest();
        }
    }

    @IsTest public static void testPayOffFailed() {
        // assert Bills were inserted for each property account, for 2 billing periods:
        List<System_Bill__c> systemBillList = [
            SELECT Id, Account_Bill__r.Name, Total_Due__c,
                Account_Bill__r.Is_Most_Recent__c
            FROM System_Bill__c
            WHERE Name LIKE '%Donut Shop%'
            ORDER BY Account_Bill__r.Name
        ];
        System.assertEquals(8, systemBillList.size());

        User userA = [SELECT Id FROM User WHERE Username='CSPaymentTest@bluewavesolar.com'];

        Test.startTest();
        // Make a payment for only ONE property account:
        List<System_Bill__c> sbList = new List<System_Bill__c>();
        System.assertEquals('BDonut Shop February 2018',systemBillList[2].Account_Bill__r.Name);
        System.assertEquals(true,systemBillList[2].Account_Bill__r.Is_Most_Recent__c);
        sbList.add(systemBillList[2]);
        mockMakeASinglePayment(sbList);

        System.runAs(userA) {
            // Try again to make a payment for all property accounts, now this list should be 3 not 4:
            List<ChargentOrders__ChargentOrder__c> secondOrderList = makePaymentInPortal('All');
            CreateOrderandPaymentRequest.testResult =
                CreateOrderandPaymentRequest.ChargentTestResult.CHARGENT_TEST_RESULT_TIMEOUT;
            String response1 = CreateOrderandPaymentRequest.chargeOrder(secondOrderList[0]);
            System.assertEquals('trying again.', response1.right(13));
        }
        Test.stopTest();
    }

    public static List<System_Bill__c> mockMakeASinglePayment(List<System_Bill__c> systemBills) {
        for (System_Bill__c systemBill : systemBills) {
            systemBill.Total_Payments_This_Month__c = systemBill.Total_Due__c;
            systemBill.Payments_Net_Previous_Balances__c = systemBill.Total_Due__c;
        }
        update systemBills;

        return systemBills;
    }

    public static List<ChargentOrders__ChargentOrder__c> makePaymentInPortal(String propertyAccountId) {
        return makePaymentInPortal(propertyAccountId, false);
    }

    public static List<ChargentOrders__ChargentOrder__c> makePaymentInPortal(String propertyAccountId, Boolean autopay) {
        List<AggregateResult> aggResult = MyAccountController.getSystemBills(propertyAccountId);
        ChargentOrders__ChargentOrder__c orderB = getPaymentInput();
        List<ChargentOrders__ChargentOrder__c> choList = CreateOrderandPaymentRequest.setChargeAmountAndInsert(aggResult, orderB, autopay);

        return choList;
    }

    public static ChargentOrders__ChargentOrder__c getPaymentInput() {
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
                ChargentOrders__Billing_Zip_Postal__c = '',
                ChargentOrders__Billing_First_Name__c = '',
                ChargentOrders__Billing_Last_Name__c = '');
        return paymentInfoACH;
    }

    @IsTest static void testPaymentMethodConversion() {
        List<String> gatewayPaymentMethods = new List<String>{'eCheck;Bank Transfer', 'Credit Card;eCheck'};
        List<String> paymentMethods = MyAccountController.convertPaymentMethods(gatewayPaymentMethods);
        // Should one have one accepted method, since ACH is the only common method
        System.assertEquals(1, paymentMethods.size());
        System.assert(paymentMethods.contains('ACH'));

        gatewayPaymentMethods = new List<String>{'Bank Transfer', 'eCheck'};
        paymentMethods = MyAccountController.convertPaymentMethods(gatewayPaymentMethods);
        System.assertEquals(1, paymentMethods.size());
        System.assert(paymentMethods.contains('ACH'));

        gatewayPaymentMethods = new List<String>{'Bank Transfer;Credit Card', 'eCheck;Credit Card'};
        paymentMethods = MyAccountController.convertPaymentMethods(gatewayPaymentMethods);
        System.assertEquals(2, paymentMethods.size());
        System.assert(paymentMethods.contains('ACH'));
        System.assert(paymentMethods.contains('Credit Card'));

        gatewayPaymentMethods = new List<String>();
        paymentMethods = MyAccountController.convertPaymentMethods(gatewayPaymentMethods);
        System.assertEquals(0, paymentMethods.size());

        gatewayPaymentMethods = new List<String>{'New Method'};
        Boolean caughtException = false;
        try {
            paymentMethods = MyAccountController.convertPaymentMethods(gatewayPaymentMethods);
        } catch (AuraHandledException ahe) {
            caughtException = true;
        }
        System.assert(caughtException);
    }

    @IsTest public static void testPaymentForNoSystemBill() {
        User userB = [
            SELECT Id, Contact.AccountId
            FROM User
            WHERE Username='CSPaymentTestB@bluewavesolar.com'
        ];
        List<System_Bill__c> bills = [
            SELECT Id
            FROM System_Bill__c
            WHERE Property_Account__r.Parent_Account__c = :userB.Contact.AccountId
        ];
        // Shouldn't have any System Bills because Production Updates haven't been made
        System.assertEquals(0, bills.size());
        List<Opportunity> opps = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Account.Parent_Account__c = :userB.Contact.AccountId
        ];
        // But there should be an opportunity from which we can get the Gateway and accepted payment methods
        System.assertEquals(1, opps.size());

        System.runAs(userB) {
            List<String> paymentMethods = MyAccountController.getPaymentMethods('All');
            // There should only be one payment method for CSPaymentTest because those system bills point use a Gateway
            // that only accepts Bank Transfer
            System.assertEquals(1, paymentMethods.size());
            System.assert(paymentMethods.contains('Credit Card'));
        }
    }

    @IsTest public static void testAutopayWithNoBalance() {
        User user = [
            SELECT Id, Contact.AccountId
            FROM User
            WHERE Username='PaymentTestParentAccountA@bluewavesolar.com'
        ];
        List<Opportunity> opps = [
            SELECT Id, Name, AccountId, Account.Parent_Account__c
            FROM Opportunity
            WHERE Account.Parent_Account__c =: user.Contact.AccountId
        ];
        // Should be three opportunities, one hasn't had bills generated yet.
        System.assertEquals(3, opps.size());

        System.runAs(user) {
            List<AggregateResult> aggregateSystemBills = MyAccountController.getSystemBills('All');
            // Should have two bills, both $0
            System.assertEquals(2, aggregateSystemBills.size());
            System.assertEquals(0, aggregateSystemBills[0].get('ChargentOrders__Subtotal__c'));

            List<ChargentOrders__ChargentOrder__c> autopayOrders = makePaymentInPortal('All', true);
            // Should be two autopay orders (three, when we create the autopay order for the opp that hasn't been billed yet)
            System.assertEquals(2, autopayOrders.size());
            for (ChargentOrders__ChargentOrder__c order : autopayOrders) {
                if (order.Account_Bill__c != null) {
                    // If there's already an account bill and we're adding recurring, they're ready for billing and
                    // we set the payment status to Recurring
                    System.assertEquals('Recurring', order.ChargentOrders__Payment_Status__c);
                } else {
                    // If billing hasn't started, we wait for the Chargent Move to to set the payment status to Recurring
                    System.assertEquals(null, order.ChargentOrders__Payment_Status__c);
                }
            }

            // If the customer tries to make a one-time payment, but doesn't have a balance,
            // we'll make orders but not charge them
            autopayOrders = makePaymentInPortal('All', false);
            System.assertEquals(2, autopayOrders.size());
        }
    }
 }