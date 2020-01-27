@IsTest
public class CSPaymentTest {
    private static Profile profileRecord = [SELECT Id FROM Profile WHERE Name = 'Community Solar Community User'];

    @testSetup public static void csPaymentSetupTestData() {
        Util.disableAllTriggers();

        TestFactory.insertBWAddress();
        Test.loadData(Utility__c.SObjectType, 'TestCSUtility');
        Test.loadData(Utility_NMC_Tariff__c.SObjectType, 'TestCSUtilityNMCTariff');
        Test.loadData(Load_U__c.SObjectType, 'TestCSLoadU');
        Test.loadData(ChargentBase__Gateway__c.SObjectType, 'TestCSGateway');
        Test.loadData(Contact.SObjectType, 'TestCSContact');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Test.loadData(Entity__c.SObjectType, 'TestCSEntity');
        Test.loadData(Shared_Solar_System__c.SObjectType, 'TestCSSharedSolarSystem');
        Test.loadData(Utility_Account_Log__c.SObjectType, 'TestCSUtilityAccountLog');
        Test.startTest();
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Test.loadData(Utility_Account_Subscription__c.SObjectType, 'TestCSUtilityAccountSubscription');
        Test.loadData(Schedule_Z__c.SObjectType, 'TestCSScheduleZ');
        Test.loadData(Schedule_Z_Subscription__c.SObjectType, 'TestCSScheduleZSubscription');
        Test.loadData(Bill_Period__c.SObjectType, 'TestCSBillPeriod');
        Test.loadData(Production__c.SObjectType, 'TestCSProduction');
        Test.loadData(Transfer__c.SObjectType, 'TestCSTransfer');
        Test.loadData(Account_Bill__c.SObjectType, 'TestCSAccountBill');
        Test.loadData(System_Bill__c.SObjectType, 'TestCSSystemBill');
        Test.loadData(Utility_Account_Bill__c.SObjectType, 'TestCSUtilityAccountBill');
        Test.stopTest();
        Test.loadData(UASB__c.SObjectType, 'TestCSUASB');
        Test.loadData(ChargentOrders__ChargentOrder__c.SObjectType, 'TestCSChargentOrder');
        TestFactory.setCSBillSettings();

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
        Util.printCPULimit('1');
        Util.enableAllTriggers();

        List<Account_Bill__c> abs = [
            SELECT Id, Name, Bill_Number__c
            FROM Account_Bill__c
            WHERE Name LIKE '%Donut Shop%'
            OR Name LIKE '%Payment Test%'
            OR Name LIKE '%Account A%'
            OR Name LIKE '%Account B%'
            OR Name LIKE '%Pizza Shop%'
        ];
        for (Account_Bill__c ab : abs) {
            if (!ab.Name.contains('Pizza Shop') || ab.Bill_Number__c != 2) {
                ab.Published__c = true;
            }
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

    @IsTest
    public static void testReverseMultiplePayments() {
        Test.startTest();
        // assert Bills were inserted for each property account, for 2 billing periods:
        List<Account_Bill__c> abs = [
            SELECT Id, Name, Bill_Number__c
            FROM Account_Bill__c
            WHERE Name LIKE '%Bike Shop%'
            AND Published__c = false
        ];
        for (Account_Bill__c ab : abs) {
            ab.Published__c = true;
        }
        update abs;

        List<System_Bill__c> systemBillList = [
            SELECT Id, Account_Bill__r.Name, Total_Due__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Account_Bill__r.Is_Most_Recent__c, Account_Bill__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
                Account_Bill__r.Carry_Over_Balance__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Bike Shop%'
            AND Account_Bill__r.Is_Most_Recent__c = TRUE
            ORDER BY Account_Bill__r.Name
        ];

        // Only production updates for SSS1 (4 UASes * 2 Production Updates)
        System.assertEquals(2, systemBillList.size());
        System.assertEquals(systemBillList[1].Account_Bill__c, systemBillList[0].Account_Bill__c);
        Id sb1Entity = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        Id sb2Entity = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        System.assertNotEquals(sb1Entity, sb2Entity);

        ChargentOrders__ChargentOrder__c orderA = new ChargentOrders__ChargentOrder__c(
            Entity__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = systemBillList[0].Total_Due__c + 2, // 258.96
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillList[0].Account_Bill__c,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111'
        );

        ChargentOrders__ChargentOrder__c orderB = new ChargentOrders__ChargentOrder__c(
            Entity__c = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = systemBillList[1].Total_Due__c + 2, // 606.24
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillList[1].Account_Bill__c,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111'
        );
        insert new List<ChargentOrders__ChargentOrder__c>{orderA, orderB};

        ChargentOrders__Transaction__c transB = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderB.id,
            ChargentOrders__Amount__c = systemBillList[1].Total_Due__c + 2, // 606.24
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            ChargentOrders__Gateway__c = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            Distributed_Among_System_Bills__c = false,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment'
        );

        ChargentOrders__Transaction__c transA = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderA.id,
            ChargentOrders__Amount__c = systemBillList[0].Total_Due__c + 2,// 258.96
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            ChargentOrders__Gateway__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            Distributed_Among_System_Bills__c = false,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment'
        );

        insert new List<ChargentOrders__Transaction__c>{transA, transB};

        transA.Distributed_Among_System_Bills__c = true;
        transB.Distributed_Among_System_Bills__c = true;
        update new List<ChargentOrders__Transaction__c>{transA, transB};

        List<System_Bill__c> updatedsystemBillListOne = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c,
                Account_Bill__r.Overpayment_Amount_Rollup__c, Account_Bill__r.Bill_Number__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Bike Shop%'
            ORDER BY Account_Bill__r.Bill_Number__c, Bill_Number__c
        ];

        List<Overpayment__c> bill2Adjustments = [
            SELECT Id, Overpayment_Amount__c
            FROM Overpayment__c
            WHERE Account_Bill__c = : systemBillList[0].Account_Bill__c
        ];
        System.assertEquals(1, updatedsystemBillListOne[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListOne[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Total_Due__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListOne[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Payments_This_Month__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Carry_Over_Balance__c);

        System.assertEquals(2, updatedsystemBillListOne[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Carry_Over_Balance__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Payments_This_Month__c);

        System.assertEquals(2, bill2Adjustments.size());
        System.assertEquals(2, bill2Adjustments[0].Overpayment_Amount__c);
        System.assertEquals(2, bill2Adjustments[1].Overpayment_Amount__c);

        List<Id> transactions = new List<Id>{transA.Id, transB.Id};
        ReturnedTransactionController.unrollPayments(transactions);
        Test.stopTest();

        List<ChargentOrders__Transaction__c> updatedTransactions = [
            SELECT Id, ChargentOrders__Response_Status__c
            FROM ChargentOrders__Transaction__c
            WHERE Id IN : transactions
            ORDER BY ChargentOrders__Amount__c ASC
        ];

        System.assertEquals('Returned', updatedTransactions[0].ChargentOrders__Response_Status__c);
        System.assertEquals('Returned', updatedTransactions[1].ChargentOrders__Response_Status__c);

        List<System_Bill__c> updatedsystemBillListAfterReversal = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c, Account_Bill__r.Bill_Number__c,
                Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c, Account_Bill__r.Overpayment_Amount_Rollup__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Bike Shop%'
            ORDER BY Account_Bill__r.Bill_Number__c, Bill_Number__c
        ];

        System.debug(updatedsystemBillListAfterReversal);

        List<Overpayment__c> bill2AdjustmentsAfterReversal = [
            SELECT Id, Overpayment_Amount__c
            FROM Overpayment__c
            WHERE Account_Bill__c = : systemBillList[0].Account_Bill__c
        ];

        System.assertEquals(1, updatedsystemBillListAfterReversal[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListAfterReversal[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Carry_Over_Balance__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListAfterReversal[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[1].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Total_Payments_This_Month__c);

        System.assertEquals(2, updatedsystemBillListAfterReversal[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListAfterReversal[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Late_Payments__c);
        System.assertEquals(604.24, updatedsystemBillListAfterReversal[2].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Total_Payments_This_Month__c);

        System.assertEquals(2, bill2AdjustmentsAfterReversal.size());
        System.debug(bill2AdjustmentsAfterReversal);
        System.assertEquals(0, bill2AdjustmentsAfterReversal[0].Overpayment_Amount__c);
        System.assertEquals(0, bill2AdjustmentsAfterReversal[1].Overpayment_Amount__c);
    }

    @IsTest
    public static void testReversePaperCheck() {
        Test.startTest();
        // assert Bills were inserted for each property account, for 2 billing periods:
        List<Account_Bill__c> abs = [
            SELECT Id, Name, Bill_Number__c, Parent_Account__c
            FROM Account_Bill__c
            WHERE Name LIKE '%Bike Shop%'
            AND Published__c = false
        ];
        for (Account_Bill__c ab : abs) {
            ab.Published__c = true;
        }
        update abs;

        List<System_Bill__c> systemBillList = [
            SELECT Id, Account_Bill__r.Name, Total_Due__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Account_Bill__r.Is_Most_Recent__c, Account_Bill__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
                Account_Bill__r.Carry_Over_Balance__c, Account_Bill__r.Parent_Account__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Bike Shop%'
            AND Account_Bill__r.Is_Most_Recent__c = TRUE
            ORDER BY Account_Bill__r.Name
        ];

        // Only production updates for SSS1 (4 UASes * 2 Production Updates)
        System.assertEquals(2, systemBillList.size());
        System.assertEquals(systemBillList[1].Account_Bill__c, systemBillList[0].Account_Bill__c);
        Id sb1Entity = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        Id sb2Entity = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        System.assertNotEquals(sb1Entity, sb2Entity);
        Decimal amountDueToEntity1 = systemBillList[0].Total_Due__c + 2; // 258.96
        Decimal amountDueToEntity2 = systemBillList[1].Total_Due__c + 2; // 606.24

        Paper_Check__c paperCheck = new Paper_Check__c(
            Name = 'paper check',
            Account__c = systemBillList[0].Account_Bill__r.Parent_Account__c,
            Applied_to_Account__c = 'Yes',
            Check_Number__c = '1',
            Amount__c = amountDueToEntity1 + amountDueToEntity2
        );

        insert paperCheck;

        ChargentOrders__ChargentOrder__c orderA = new ChargentOrders__ChargentOrder__c(
            Paper_Check__c = paperCheck.Id,
            Entity__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = amountDueToEntity1, // 258.96
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillList[0].Account_Bill__c,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111'
        );

        ChargentOrders__ChargentOrder__c orderB = new ChargentOrders__ChargentOrder__c(
            Paper_Check__c = paperCheck.Id,
            Entity__c = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = amountDueToEntity2, // 606.24
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillList[1].Account_Bill__c,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111'
        );
        insert new List<ChargentOrders__ChargentOrder__c>{orderA, orderB};

        ChargentOrders__Transaction__c transB = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderB.id,
            ChargentOrders__Amount__c = amountDueToEntity2, // 606.24
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            ChargentOrders__Gateway__c = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            Distributed_Among_System_Bills__c = false,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment'
        );

        ChargentOrders__Transaction__c transA = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderA.id,
            ChargentOrders__Amount__c = amountDueToEntity1,// 258.96
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            ChargentOrders__Gateway__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            Distributed_Among_System_Bills__c = false,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment'
        );

        insert new List<ChargentOrders__Transaction__c>{transA, transB};

        transA.Distributed_Among_System_Bills__c = true;
        transB.Distributed_Among_System_Bills__c = true;
        update new List<ChargentOrders__Transaction__c>{transA, transB};

        List<System_Bill__c> updatedsystemBillListOne = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c,
                Account_Bill__r.Overpayment_Amount_Rollup__c, Account_Bill__r.Bill_Number__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Bike Shop%'
            ORDER BY Account_Bill__r.Bill_Number__c, Bill_Number__c
        ];

        List<Overpayment__c> bill2Adjustments = [
            SELECT Id, Overpayment_Amount__c
            FROM Overpayment__c
            WHERE Account_Bill__c = : systemBillList[0].Account_Bill__c
        ];
        System.assertEquals(1, updatedsystemBillListOne[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListOne[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Total_Due__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListOne[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Payments_This_Month__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Carry_Over_Balance__c);

        System.assertEquals(2, updatedsystemBillListOne[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Carry_Over_Balance__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Payments_This_Month__c);

        System.assertEquals(2, bill2Adjustments.size());
        System.assertEquals(2, bill2Adjustments[0].Overpayment_Amount__c);
        System.assertEquals(2, bill2Adjustments[1].Overpayment_Amount__c);

        List<Id> transactions = new List<Id>{transA.Id, transB.Id};
        ReturnedTransactionController.unrollPaperChecks(new List<Id>{paperCheck.Id});
        Test.stopTest();

        List<ChargentOrders__Transaction__c> updatedTransactions = [
            SELECT Id, ChargentOrders__Response_Status__c
            FROM ChargentOrders__Transaction__c
            WHERE ChargentOrders__Order__r.Paper_Check__c = : paperCheck.Id
            ORDER BY ChargentOrders__Amount__c ASC
        ];

        System.assertEquals(4, updatedTransactions.size());
        System.assertEquals('Returned', updatedTransactions[0].ChargentOrders__Response_Status__c);
        System.assertEquals('Returned', updatedTransactions[1].ChargentOrders__Response_Status__c);
        System.assertEquals('Returned', updatedTransactions[2].ChargentOrders__Response_Status__c);
        System.assertEquals('Returned', updatedTransactions[3].ChargentOrders__Response_Status__c);


        List<System_Bill__c> updatedsystemBillListAfterReversal = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c, Account_Bill__r.Bill_Number__c,
                Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c, Account_Bill__r.Overpayment_Amount_Rollup__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Bike Shop%'
            ORDER BY Account_Bill__r.Bill_Number__c, Bill_Number__c
        ];

        System.debug(updatedsystemBillListAfterReversal);

        List<Overpayment__c> bill2AdjustmentsAfterReversal = [
            SELECT Id, Overpayment_Amount__c
            FROM Overpayment__c
            WHERE Account_Bill__c = : systemBillList[0].Account_Bill__c
        ];

        System.assertEquals(1, updatedsystemBillListAfterReversal[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListAfterReversal[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Carry_Over_Balance__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListAfterReversal[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[1].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Total_Payments_This_Month__c);

        System.assertEquals(2, updatedsystemBillListAfterReversal[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListAfterReversal[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Late_Payments__c);
        System.assertEquals(604.24, updatedsystemBillListAfterReversal[2].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Total_Payments_This_Month__c);


        System.assertEquals(2, bill2AdjustmentsAfterReversal.size());
        System.debug(bill2AdjustmentsAfterReversal);
        System.assertEquals(0, bill2AdjustmentsAfterReversal[0].Overpayment_Amount__c);
        System.assertEquals(0, bill2AdjustmentsAfterReversal[1].Overpayment_Amount__c);
    }

    @IsTest
    public static void testReversePaperCheckMonthAfter() {
        Test.startTest();
        // assert Bills were inserted for each property account, for 2 billing periods:
        List<Account_Bill__c> abs = [
            SELECT Id, Name, Bill_Number__c, Parent_Account__c
            FROM Account_Bill__c
            WHERE Name LIKE '%Bike Shop%'
            AND Published__c = false
        ];
        for (Account_Bill__c ab : abs) {
            ab.Published__c = true;
        }
        update abs;

        List<System_Bill__c> systemBillList = [
            SELECT Id, Account_Bill__r.Name, Total_Due__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Account_Bill__r.Is_Most_Recent__c, Account_Bill__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
                Account_Bill__r.Carry_Over_Balance__c, Account_Bill__r.Parent_Account__c, Date__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Bike Shop%'
            AND Account_Bill__r.Is_Most_Recent__c = TRUE
            ORDER BY Account_Bill__r.Name
        ];

        // Only production updates for SSS1 (4 UASes * 2 Production Updates)
        System.assertEquals(2, systemBillList.size());
        System.assertEquals(systemBillList[1].Account_Bill__c, systemBillList[0].Account_Bill__c);
        Id sb1Entity = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        Id sb2Entity = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        System.assertNotEquals(sb1Entity, sb2Entity);
        Decimal amountDueToEntity1 = systemBillList[0].Total_Due__c + 2; // 258.96
        Decimal amountDueToEntity2 = systemBillList[1].Total_Due__c + 2; // 606.24

        Paper_Check__c paperCheck = new Paper_Check__c(
            Name = 'paper check',
            Account__c = systemBillList[0].Account_Bill__r.Parent_Account__c,
            Applied_to_Account__c = 'Yes',
            Check_Number__c = '1',
            Amount__c = amountDueToEntity1 + amountDueToEntity2
        );

        insert paperCheck;

        ChargentOrders__ChargentOrder__c orderA = new ChargentOrders__ChargentOrder__c(
            Paper_Check__c = paperCheck.Id,
            Entity__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = amountDueToEntity1, // 258.96
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillList[0].Account_Bill__c,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111'
        );

        ChargentOrders__ChargentOrder__c orderB = new ChargentOrders__ChargentOrder__c(
            Paper_Check__c = paperCheck.Id,
            Entity__c = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = amountDueToEntity2, // 606.24
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillList[1].Account_Bill__c,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111'
        );
        insert new List<ChargentOrders__ChargentOrder__c>{orderA, orderB};

        ChargentOrders__Transaction__c transB = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderB.id,
            ChargentOrders__Amount__c = amountDueToEntity2, // 606.24
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            ChargentOrders__Gateway__c = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            Distributed_Among_System_Bills__c = false,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment',
            CreatedDate = systemBillList[0].Date__c.addDays(-2) // need transaction to be before bills were generated
        );

        ChargentOrders__Transaction__c transA = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderA.id,
            ChargentOrders__Amount__c = amountDueToEntity1,// 258.96
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            ChargentOrders__Gateway__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            Distributed_Among_System_Bills__c = false,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment',
            CreatedDate = systemBillList[0].Date__c.addDays(-2) // need transaction to be before bills were generated
        );

        insert new List<ChargentOrders__Transaction__c>{transA, transB};

        transA.Distributed_Among_System_Bills__c = true;
        transB.Distributed_Among_System_Bills__c = true;
        update new List<ChargentOrders__Transaction__c>{transA, transB};

        List<System_Bill__c> updatedsystemBillListOne = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c,
                Account_Bill__r.Overpayment_Amount_Rollup__c, Account_Bill__r.Bill_Number__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Bike Shop%'
            ORDER BY Account_Bill__r.Bill_Number__c, Bill_Number__c
        ];

        List<Overpayment__c> bill2Adjustments = [
            SELECT Id, Overpayment_Amount__c
            FROM Overpayment__c
            WHERE Account_Bill__c = : systemBillList[0].Account_Bill__c
        ];
        System.assertEquals(1, updatedsystemBillListOne[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListOne[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Total_Due__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListOne[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Payments_This_Month__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Carry_Over_Balance__c);

        System.assertEquals(2, updatedsystemBillListOne[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Carry_Over_Balance__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Payments_This_Month__c);

        System.assertEquals(2, bill2Adjustments.size());
        System.assertEquals(2, bill2Adjustments[0].Overpayment_Amount__c);
        System.assertEquals(2, bill2Adjustments[1].Overpayment_Amount__c);

        List<Id> transactions = new List<Id>{transA.Id, transB.Id};
        ReturnedTransactionController.unrollPaperChecks(new List<Id>{paperCheck.Id});
        Test.stopTest();

        List<ChargentOrders__Transaction__c> updatedTransactions = [
            SELECT Id, ChargentOrders__Response_Status__c
            FROM ChargentOrders__Transaction__c
            WHERE ChargentOrders__Order__r.Paper_Check__c = : paperCheck.Id
            ORDER BY ChargentOrders__Amount__c ASC
        ];

        System.assertEquals(4, updatedTransactions.size());
        System.assertEquals('Returned', updatedTransactions[0].ChargentOrders__Response_Status__c);
        System.assertEquals('Returned', updatedTransactions[1].ChargentOrders__Response_Status__c);
        System.assertEquals('Returned', updatedTransactions[2].ChargentOrders__Response_Status__c);
        System.assertEquals('Returned', updatedTransactions[3].ChargentOrders__Response_Status__c);


        List<System_Bill__c> updatedsystemBillListAfterReversal = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c, Account_Bill__r.Bill_Number__c,
                Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c, Account_Bill__r.Overpayment_Amount_Rollup__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Bike Shop%'
            ORDER BY Account_Bill__r.Bill_Number__c, Bill_Number__c
        ];

        System.debug(updatedsystemBillListAfterReversal);

        List<Overpayment__c> overpaymentsAfterReversal = [
            SELECT Id, Overpayment_Amount__c
            FROM Overpayment__c
            WHERE Account_Bill__c = : systemBillList[0].Account_Bill__c
        ];

        List<Bill_Adjustment__c> bill2AdjustmentsAfterReversal = [
            SELECT Id, Adjustment_Amount__c, Utility_Account_Subscription__c, Account_Bill__c, Name
            FROM Bill_Adjustment__c
            WHERE Name LIKE '%Returned Payment%'
            ORDER BY Adjustment_Amount__c ASC
        ];

        System.assertEquals(1, updatedsystemBillListOne[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListOne[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Total_Due__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListOne[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Payments_This_Month__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Carry_Over_Balance__c);

        System.assertEquals(2, updatedsystemBillListOne[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Carry_Over_Balance__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Payments_This_Month__c);

        System.assertEquals(2, bill2AdjustmentsAfterReversal.size());
        System.assertEquals(260.96, bill2AdjustmentsAfterReversal[0].Adjustment_Amount__c);
        System.assertNotEquals(null, bill2AdjustmentsAfterReversal[0].Utility_Account_Subscription__c);
        System.assertEquals(null, bill2AdjustmentsAfterReversal[0].Account_Bill__c);

        System.assertEquals(606.24, bill2AdjustmentsAfterReversal[1].Adjustment_Amount__c);
        System.assertNotEquals(null, bill2AdjustmentsAfterReversal[1].Utility_Account_Subscription__c);
        System.assertEquals(null, bill2AdjustmentsAfterReversal[1].Account_Bill__c);

        System.assertEquals(2, overpaymentsAfterReversal.size());
        System.debug(overpaymentsAfterReversal);
        System.assertEquals(2, overpaymentsAfterReversal[0].Overpayment_Amount__c);
        System.assertEquals(2, overpaymentsAfterReversal[1].Overpayment_Amount__c);
    }

    @IsTest
    public static void testReverseMultiplePaymentsSameSystemBill() {
        Test.startTest();
        // assert Bills were inserted for each property account, for 2 billing periods:
        List<Account_Bill__c> abs = [
            SELECT Id, Name, Bill_Number__c
            FROM Account_Bill__c
            WHERE Name LIKE '%Pizza Shop%'
            AND Published__c = false
        ];
        for (Account_Bill__c ab : abs) {
            ab.Published__c = true;
        }
        update abs;

        List<System_Bill__c> systemBillList = [
            SELECT Id, Account_Bill__r.Name, Total_Due__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Account_Bill__r.Is_Most_Recent__c, Account_Bill__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
                Account_Bill__r.Carry_Over_Balance__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Pizza Shop%'
            AND Account_Bill__r.Is_Most_Recent__c = TRUE
            ORDER BY Account_Bill__r.Name
        ];

        // Only production updates for SSS1 (4 UASes * 2 Production Updates)
        System.assertEquals(2, systemBillList.size());
        System.assertEquals(systemBillList[1].Account_Bill__c, systemBillList[0].Account_Bill__c);
        Id sb1Entity = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        Id sb2Entity = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        System.assertEquals(sb1Entity, sb2Entity);

        ChargentOrders__ChargentOrder__c orderA = new ChargentOrders__ChargentOrder__c(
            Entity__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = systemBillList[0].Total_Due__c + 2, // 258.96
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillList[0].Account_Bill__c,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111'
        );

        ChargentOrders__ChargentOrder__c orderB = new ChargentOrders__ChargentOrder__c(
            Entity__c = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = systemBillList[1].Total_Due__c + 2, // 606.24
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillList[1].Account_Bill__c,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111'
        );
        insert new List<ChargentOrders__ChargentOrder__c>{orderA, orderB};

        ChargentOrders__Transaction__c transB = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderB.id,
            ChargentOrders__Amount__c = systemBillList[1].Total_Due__c + 2, // 606.24
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            ChargentOrders__Gateway__c = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            Distributed_Among_System_Bills__c = false,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment'
        );

        ChargentOrders__Transaction__c transA = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderA.id,
            ChargentOrders__Amount__c = systemBillList[0].Total_Due__c + 2,// 258.96
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            ChargentOrders__Gateway__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            Distributed_Among_System_Bills__c = false,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment'
        );

        // need to perform separately for SystemBillPaymentRollUpHandler
        insert transA;
        insert transB;

        transA.Distributed_Among_System_Bills__c = true;
        transB.Distributed_Among_System_Bills__c = true;

        // need to perform separately for SystemBillPaymentRollUpHandler
        update transA;
        update transB;

        List<System_Bill__c> updatedsystemBillListOne = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c,
                Account_Bill__r.Overpayment_Amount_Rollup__c, Account_Bill__r.Bill_Number__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Pizza Shop%'
            ORDER BY Account_Bill__r.Bill_Number__c, Bill_Number__c
        ];

        List<Overpayment__c> bill2Adjustments = [
            SELECT Id, Overpayment_Amount__c
            FROM Overpayment__c
            WHERE Account_Bill__c = : systemBillList[0].Account_Bill__c
        ];
        System.assertEquals(1, updatedsystemBillListOne[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListOne[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Total_Due__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListOne[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Payments_This_Month__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Carry_Over_Balance__c);

        System.assertEquals(2, updatedsystemBillListOne[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Carry_Over_Balance__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Payments_This_Month__c);

        System.assertEquals(1, bill2Adjustments.size());
        System.assertEquals(4, bill2Adjustments[0].Overpayment_Amount__c);

        List<Id> transactions = new List<Id>{transA.Id, transB.Id};
        ReturnedTransactionController.unrollPayments(transactions);
        Test.stopTest();

        List<ChargentOrders__Transaction__c> updatedTransactions = [
            SELECT Id, ChargentOrders__Response_Status__c
            FROM ChargentOrders__Transaction__c
            WHERE Id IN : transactions
            ORDER BY ChargentOrders__Amount__c ASC
        ];

        System.assertEquals('Returned', updatedTransactions[0].ChargentOrders__Response_Status__c);
        System.assertEquals('Returned', updatedTransactions[1].ChargentOrders__Response_Status__c);

        List<System_Bill__c> updatedsystemBillListAfterReversal = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c, Account_Bill__r.Bill_Number__c,
                Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c, Account_Bill__r.Overpayment_Amount_Rollup__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Pizza Shop%'
            ORDER BY Account_Bill__r.Bill_Number__c, Bill_Number__c
        ];

        List<Overpayment__c> bill2AdjustmentsAfterReversal = [
            SELECT Id, Overpayment_Amount__c
            FROM Overpayment__c
            WHERE Account_Bill__c = : systemBillList[0].Account_Bill__c
        ];

        System.assertEquals(1, bill2AdjustmentsAfterReversal.size());
        System.assertEquals(0, bill2AdjustmentsAfterReversal[0].Overpayment_Amount__c);

        System.assertEquals(1, updatedsystemBillListAfterReversal[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListAfterReversal[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Carry_Over_Balance__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListAfterReversal[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[1].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Total_Payments_This_Month__c);

        System.assertEquals(2, updatedsystemBillListAfterReversal[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListAfterReversal[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Late_Payments__c);
        System.assertEquals(604.24, updatedsystemBillListAfterReversal[2].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Total_Payments_This_Month__c);
    }

    @isTest public static void testReversePaymentMultipleSystemBills() {
        Test.startTest();
        // assert Bills were inserted for each property account, for 2 billing periods:
        List<Account_Bill__c> abs = [
            SELECT Id, Name, Bill_Number__c
            FROM Account_Bill__c
            WHERE Name LIKE '%Pizza Shop%'
            AND Published__c = false
        ];
        for (Account_Bill__c ab : abs) {
            ab.Published__c = true;
        }
        update abs;

        List<System_Bill__c> systemBillList = [
            SELECT Id, Account_Bill__r.Name, Total_Due__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Account_Bill__r.Is_Most_Recent__c, Account_Bill__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
                Account_Bill__r.Carry_Over_Balance__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Pizza Shop%'
            AND Account_Bill__r.Is_Most_Recent__c = TRUE
            ORDER BY Account_Bill__r.Name
        ];

        // Only production updates for SSS1 (4 UASes * 2 Production Updates)
        System.assertEquals(2, systemBillList.size());
        System.assertEquals(systemBillList[1].Account_Bill__c, systemBillList[0].Account_Bill__c);
        Id sb1Entity = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        Id sb2Entity = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        System.assertEquals(sb1Entity, sb2Entity);

        Decimal totalPayment = systemBillList[0].Account_Bill__r.Carry_Over_Balance__c + 2; //$2 overpayment

        ChargentOrders__ChargentOrder__c orderA = new ChargentOrders__ChargentOrder__c(
            Entity__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = totalPayment,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillList[0].Account_Bill__c,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111'
        );
        insert orderA;

        ChargentOrders__Transaction__c transA = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderA.id,
            ChargentOrders__Amount__c = totalPayment - 50,
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            ChargentOrders__Gateway__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            Distributed_Among_System_Bills__c = false,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment'
        );

        ChargentOrders__Transaction__c transB = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderA.id,
            ChargentOrders__Amount__c = 50,
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            ChargentOrders__Gateway__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            Distributed_Among_System_Bills__c = false,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment'
        );

        insert transA;
        insert transB;

        transA.Distributed_Among_System_Bills__c = true;
        transB.Distributed_Among_System_Bills__c = true;
        update transA;
        update transB;

        List<System_Bill__c> updatedsystemBillListOne = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c,
                Account_Bill__r.Overpayment_Amount_Rollup__c, Account_Bill__r.Bill_Number__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Pizza Shop%'
            ORDER BY Account_Bill__r.Bill_Number__c, Bill_Number__c
        ];

        List<Overpayment__c> bill2Adjustments = [
            SELECT Id, Overpayment_Amount__c
            FROM Overpayment__c
            WHERE Account_Bill__c = : systemBillList[0].Account_Bill__c
        ];
        System.assertEquals(1, updatedsystemBillListOne[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListOne[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Total_Due__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListOne[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Payments_This_Month__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Carry_Over_Balance__c);

        System.assertEquals(2, updatedsystemBillListOne[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Carry_Over_Balance__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Payments_This_Month__c);

        System.assertEquals(1, bill2Adjustments.size());
        System.assertEquals(2, bill2Adjustments[0].Overpayment_Amount__c);

        ReturnedTransactionController.unrollPayments(new List<Id>{transA.Id});
        Test.stopTest();

        ChargentOrders__Transaction__c updatedTransA = [
            SELECT Id, ChargentOrders__Response_Status__c
            FROM ChargentOrders__Transaction__c
            WHERE Id = : transA.Id
        ];

        System.assertEquals('Returned', updatedTransA.ChargentOrders__Response_Status__c);
        System.assertEquals(transA.Id, updatedTransA.Id);


        List<System_Bill__c> updatedsystemBillListAfterReversal = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c, Account_Bill__r.Bill_Number__c,
                Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c, Account_Bill__r.Overpayment_Amount_Rollup__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Pizza Shop%'
            ORDER BY Account_Bill__r.Bill_Number__c, Bill_Number__c
        ];

        List<Overpayment__c> bill2AdjustmentsAfterReversal = [
            SELECT Id, Overpayment_Amount__c
            FROM Overpayment__c
            WHERE Account_Bill__c = : systemBillList[0].Account_Bill__c
        ];

        System.assertEquals(1, bill2AdjustmentsAfterReversal.size());
        System.assertEquals(0, bill2AdjustmentsAfterReversal[0].Overpayment_Amount__c);
        System.assertEquals(updatedsystemBillListAfterReversal[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                            updatedsystemBillListAfterReversal[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__c);
        System.assertEquals(updatedsystemBillListAfterReversal[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                            updatedsystemBillListAfterReversal[2].Shared_Solar_System__r.BWC_Project_Entity_Manual__c);


        System.assertEquals(1, updatedsystemBillListAfterReversal[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListAfterReversal[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Total_Due__c);
        System.assertEquals(50, updatedsystemBillListAfterReversal[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Carry_Over_Balance__c);
        System.assertEquals(208.96, updatedsystemBillListAfterReversal[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListAfterReversal[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Total_Payments_This_Month__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[1].Carry_Over_Balance__c);

        System.assertEquals(2, updatedsystemBillListAfterReversal[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListAfterReversal[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Late_Payments__c);
        System.assertEquals(554.24, updatedsystemBillListAfterReversal[2].Carry_Over_Balance__c);
        System.assertEquals(50, updatedsystemBillListAfterReversal[2].Total_Payments_This_Month__c);

        System.assertEquals(1, bill2AdjustmentsAfterReversal.size());
        System.assertEquals(0, bill2AdjustmentsAfterReversal[0].Overpayment_Amount__c);

        try {
            ReturnedTransactionController.unrollPayments(new List<Id>{updatedTransA.Id});
        } catch (Util.BWException e) {
            System.assertEquals('Transaction cannot be marked for return.', e.getMessage());
        }

        // show that all assertions stay the same if transaction is already marked as 'Returned'
        updatedsystemBillListAfterReversal = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c, Account_Bill__r.Bill_Number__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c, Account_Bill__r.Overpayment_Amount_Rollup__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Pizza Shop%'
            ORDER BY Account_Bill__r.Bill_Number__c
        ];

        bill2AdjustmentsAfterReversal = [
            SELECT Id, Overpayment_Amount__c
            FROM Overpayment__c
            WHERE Account_Bill__c = : systemBillList[0].Account_Bill__c
        ];

        System.assertEquals(1, updatedsystemBillListAfterReversal[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListAfterReversal[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Total_Due__c);
        System.assertEquals(50, updatedsystemBillListAfterReversal[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Carry_Over_Balance__c);
        System.assertEquals(208.96, updatedsystemBillListAfterReversal[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListAfterReversal[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Total_Payments_This_Month__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[1].Carry_Over_Balance__c);

        System.assertEquals(2, updatedsystemBillListAfterReversal[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListAfterReversal[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Late_Payments__c);
        System.assertEquals(554.24, updatedsystemBillListAfterReversal[2].Carry_Over_Balance__c);
        System.assertEquals(50, updatedsystemBillListAfterReversal[2].Total_Payments_This_Month__c);

        System.assertEquals(1, bill2AdjustmentsAfterReversal.size());
        System.assertEquals(0, bill2AdjustmentsAfterReversal[0].Overpayment_Amount__c);
    }

    @isTest public static void testReversePaymentMonthAfter() {
        Test.startTest();
        List<Account_Bill__c> abs = [
            SELECT Id, Name, Bill_Number__c
            FROM Account_Bill__c
            WHERE Name LIKE '%Pizza Shop%'
            AND Published__c = false
        ];
        for (Account_Bill__c ab : abs) {
            ab.Published__c = true;
        }
        update abs;

        List<System_Bill__c> systemBillList = [
            SELECT Id, Account_Bill__r.Name, Total_Due__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Account_Bill__r.Is_Most_Recent__c, Account_Bill__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
                Account_Bill__r.Carry_Over_Balance__c, Date__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Pizza Shop%'
            AND Account_Bill__r.Is_Most_Recent__c = TRUE
            ORDER BY Account_Bill__r.Name
        ];

        // Only production updates for SSS1 (4 UASes * 2 Production Updates)
        System.assertEquals(2, systemBillList.size());
        System.assertEquals(systemBillList[1].Account_Bill__c, systemBillList[0].Account_Bill__c);
        Id sb1Entity = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        Id sb2Entity = systemBillList[1].Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        System.assertEquals(sb1Entity, sb2Entity);

        Decimal totalPayment = systemBillList[0].Account_Bill__r.Carry_Over_Balance__c + 2; //$2 overpayment

        ChargentOrders__ChargentOrder__c orderA = new ChargentOrders__ChargentOrder__c(
            Entity__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = totalPayment,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = systemBillList[0].Account_Bill__c,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111'
        );
        insert orderA;

        ChargentOrders__Transaction__c transA = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderA.id,
            ChargentOrders__Amount__c = totalPayment - 50,
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            ChargentOrders__Gateway__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            Distributed_Among_System_Bills__c = false,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment',
            CreatedDate = systemBillList[0].Date__c.addDays(-2) // need transaction to be before bills were generated
        );

        ChargentOrders__Transaction__c transB = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderA.id,
            ChargentOrders__Amount__c = 50,
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            ChargentOrders__Gateway__c = systemBillList[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
            Distributed_Among_System_Bills__c = false,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment',
            CreatedDate = systemBillList[0].Date__c.addDays(-2) // need transaction to be before bills were generated
        );

        insert transA;
        insert transB;

        transA.Distributed_Among_System_Bills__c = true;
        transB.Distributed_Among_System_Bills__c = true;
        update transA;
        update transB;
        Test.stopTest();

        List<System_Bill__c> updatedsystemBillListOne = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c,
                Account_Bill__r.Overpayment_Amount_Rollup__c, Account_Bill__r.Bill_Number__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Pizza Shop%'
            ORDER BY AcCount_Bill__r.Bill_Number__c, Bill_Number__c
        ];

        List<Overpayment__c> bill2Adjustments = [
            SELECT Id, Overpayment_Amount__c
            FROM Overpayment__c
            WHERE Account_Bill__c = : systemBillList[0].Account_Bill__c
        ];

        System.assertEquals(1, updatedsystemBillListOne[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListOne[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Total_Due__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[0].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListOne[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[1].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListOne[1].Total_Payments_This_Month__c);
        System.assertEquals(0, updatedsystemBillListOne[1].Carry_Over_Balance__c);

        System.assertEquals(2, updatedsystemBillListOne[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListOne[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListOne[2].Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListOne[2].Carry_Over_Balance__c);
        System.assertEquals(604.24, updatedsystemBillListOne[2].Total_Payments_This_Month__c);

        System.assertEquals(2, updatedsystemBillListOne[1].Account_Bill__r.Overpayment_Amount_Rollup__c );
        System.assertEquals(1, bill2Adjustments.size());
        System.assertEquals(2, bill2Adjustments[0].Overpayment_Amount__c);

        ReturnedTransactionController.unrollPayments(new List<Id>{transA.Id});

        ChargentOrders__Transaction__c updatedTransA = [
            SELECT Id, ChargentOrders__Response_Status__c
            FROM ChargentOrders__Transaction__c
            WHERE Id = : transA.Id
        ];

        System.assertEquals('Returned', updatedTransA.ChargentOrders__Response_Status__c);
        System.assertEquals(transA.Id, updatedTransA.Id);

        List<System_Bill__c> updatedsystemBillListAfterReversal = [
            SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
                Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c,
                Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c,
                Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c,
                Payments_Net_Previous_Balances__c,
                Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
                Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c,
                Adjustments__c, Bill_Date__c,
                Waive_Late_Fees__c, Previous_Overpayment__c, Balance_Adjustment__c,
                Adjustments_UASB__c, Carry_Over_Balance__c, Account_Bill__r.Bill_Number__c,
                Billing_Period_End_Date__c, Billing_Period_Start_Date__c, Account_Bill__r.Overpayment_Amount_Rollup__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Name LIKE '%Pizza Shop%'
            ORDER BY Account_Bill__r.Bill_Number__c
        ];

        List<Bill_Adjustment__c> bill2AdjustmentsAfterReversal = [
            SELECT Id, Adjustment_Amount__c, Utility_Account_Subscription__c, Account_Bill__c, Name
            FROM Bill_Adjustment__c
            WHERE Name LIKE '%Returned Payment%'
            ORDER BY Adjustment_Amount__c ASC
        ];

        // Bills should not be reversed if the bill it was applied to is not the most recent
        System.assertEquals(1, updatedsystemBillListAfterReversal[0].Bill_Number__c);
        System.assertEquals(1, updatedsystemBillListAfterReversal[0].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Total_Due__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[0].Carry_Over_Balance__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[0].Balance_Net_Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[0].Total_Payments_This_Month__c);

        System.assertEquals(1, updatedsystemBillListAfterReversal[1].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[1].Account_Bill__r.Bill_Number__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[1].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Late_Payments__c);
        System.assertEquals(258.96, updatedsystemBillListAfterReversal[1].Total_Payments_This_Month__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[1].Carry_Over_Balance__c);

        System.assertEquals(2, updatedsystemBillListAfterReversal[2].Bill_Number__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[2].Account_Bill__r.Bill_Number__c);
        System.assertEquals(604.24, updatedsystemBillListAfterReversal[2].Total_Due__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Late_Fees__c );
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Late_Payments__c);
        System.assertEquals(0, updatedsystemBillListAfterReversal[2].Carry_Over_Balance__c);
        System.assertEquals(604.24, updatedsystemBillListAfterReversal[2].Total_Payments_This_Month__c);
        System.assertEquals(2, updatedsystemBillListAfterReversal[1].Account_Bill__r.Overpayment_Amount_Rollup__c );

        System.assertEquals(815.20, bill2AdjustmentsAfterReversal[0].Adjustment_Amount__c);
        System.assertNotEquals(null, bill2AdjustmentsAfterReversal[0].Utility_Account_Subscription__c);
        System.assertEquals(null, bill2AdjustmentsAfterReversal[0].Account_Bill__c);

        try {
            ReturnedTransactionController.unrollPayments(new List<Id>{updatedTransA.Id});
        } catch (Util.BWException e) {
            System.assertEquals('Transaction cannot be marked for return.', e.getMessage());
        }

        bill2AdjustmentsAfterReversal = [
            SELECT Id, Adjustment_Amount__c, Utility_Account_Subscription__c, Account_Bill__c, Name
            FROM Bill_Adjustment__c
            WHERE Name LIKE '%Returned Payment%'
            ORDER BY Adjustment_Amount__c ASC
        ];

        // show that a second adjustment doesn't get created if the transaction is already marked as 'Returned'
        System.assertEquals(1, bill2AdjustmentsAfterReversal.size());

    }
}