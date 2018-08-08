@isTest
public class CSPaymentTest {
    @testSetup public static void CSPaymentSetupTestData() {
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c national_grid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{
            eversource, national_grid
        };

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c(Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = TRUE);

        Utility_NMC_Tariff__c ngridsizeNMC = new Utility_NMC_Tariff__c(Name = 'National Grid WCMA Class 2',
            Utility__c = 'National Grid',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = TRUE);

        insert new List<Utility_NMC_Tariff__c>{
            eversizeNMC, ngridsizeNMC
        };

        Load_U__c everLZU = new Load_U__c(Name = '02633',
            Load_zone__c = 'SEMA Eversource',
            LZ__c = 'SEMA',
            Utility__C = 'Eversource',
            Town__c = 'Medfield');

        Load_U__c ngridLZU = new Load_U__c(Name = '01570',
            Load_zone__c = 'WCMA National Grid',
            LZ__c = 'WCMA',
            Utility__C = 'National Grid',
            Town__c = 'Westtown');

        insert new List<Load_U__c>{
            everLZU, ngridLZU
        };
        insert new BW_Address__c(Name = 'BlueWave', Address_Line_One__c = '137 Newbury Street', Address_Line_Two__c = 'Boston, MA 02114');

        Account clientAccount = new Account(name = 'Client Account',
            Client_Brand_Key__c = 'AmpBlack');
        insert clientAccount;

        Account clientAccount2 = new Account(name = 'Client Account 2',
            Client_Brand_Key__c = 'AmpBlack');
        insert clientAccount2;

        Entity__c entity1 = new Entity__c(Name = 'Oxford Barrett St. P1',
            Send_Checks_Address__c = 'Fake Lockbox Address, P.O Box 12345, Phoenix Arizona 02114',
            Client_Account__c = clientAccount.Id);
        insert entity1;

        Entity__c entity2 = new Entity__c(Name = 'Oxford Barrett St. P2',
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
                Total_System_Size_kW_AC__c = 996,
                System_Utility__c = 'Eversource',
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '1',
                Billing_Method__c = 'NMC',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Sales_Partners__c = 'All',
                BWC_Project_Entity_Manual__c = entity1.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id
            );

        Product2 normalCSProduct = new Product2(Name = 'BlueWave Community Solar',
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

        Shared_Solar_System__c sss2 =
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                Service_Territory__c = 'SEMA',
                Service_Territories__c = 'SEMA',
                Open__c = true,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c = 996,
                System_Utility__c = 'Eversource',
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '2',
                Billing_Method__c = 'NMC',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Sales_Partners__c = 'All',
                BWC_Project_Entity_Manual__c = entity2.Id,
                Product__c = normalCSProduct.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id
            );

        insert new List<Shared_Solar_System__c>{
            sss1, sss2
        };

        ChargentBase__Gateway__c chGateway =
            new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                ChargentBase__Merchant_ID__c = '235986',
                Shared_Solar_System__c = sss1.id,
                ChargentBase__Debug__c = True,
                Entity__c = entity1.Id,
                ChargentBase__Active__c = TRUE);
        insert chGateway;

        // 4 Properties Under the Same Parent, 1 Alone:
        String firstName1 = 'ADonut';
        String firstName2 = 'BDonut';
        String firstName3 = 'CDonut';
        String firstName4 = 'DDonut';
        String firstName5 = 'Unrelated';

        String lastName1 = 'Shop';
        String lastName2 = 'Shop';
        String lastName3 = 'Shop';
        String lastName4 = 'Shop';
        String lastName5 = 'OtherAccount';

        String accountName1 = firstName1 + ' ' + lastname1;
        String accountName2 = firstName2 + ' ' + lastname2;
        String accountName3 = firstName3 + ' ' + lastname3;
        String accountName4 = firstName4 + ' ' + lastname4;
        String accountName5 = firstName5 + ' ' + lastname5;

        Id parentAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent1 = new Account(name = accountName1, RecordTypeId = parentAccountRT);
        Account accountParent2 = new Account(name = accountName5, RecordTypeId = parentAccountRT);

        insert new List<Account>{
            accountParent1, accountParent2
        };

        Contact contact1 = new Contact(FirstName = firstName1, LastName = lastname1, AccountId = accountParent1.Id);
        Contact contact2 = new Contact(FirstName = firstName2, LastName = lastname2, AccountId = accountParent1.Id);
        Contact contact3 = new Contact(FirstName = firstName3, LastName = lastname3, AccountId = accountParent1.Id);
        Contact contact4 = new Contact(FirstName = firstName4, LastName = lastname4, AccountId = accountParent1.Id);
        Contact contact5 = new Contact(FirstName = firstName5, LastName = lastname5, AccountId = accountParent2.Id);

        insert new List<Contact>{
            contact1, contact2, contact3, contact4, contact5
        };

        Account propAccount1 = new Account(name = accountName1, Parent_Account__c = accountParent1.Id, Send_Bills_Contact__c = contact1.Id);
        Account propAccount2 = new Account(name = accountName2, Parent_Account__c = accountParent1.Id, Send_Bills_Contact__c = contact1.Id);
        Account propAccount3 = new Account(name = accountName3, Parent_Account__c = accountParent1.Id, Send_Bills_Contact__c = contact1.Id);
        Account propAccount4 = new Account(name = accountName4, Parent_Account__c = accountParent1.Id, Send_Bills_Contact__c = contact1.Id);
        Account propAccount5 = new Account(name = accountName5, Parent_Account__c = accountParent2.Id, Send_Bills_Contact__c = contact3.Id);

        insert new List<Account>{
            propAccount1, propAccount2, propAccount3, propAccount4, propAccount5
        };

        Utility_Account_Log__c ualog1 = new Utility_Account_Log__c(Name = '0000234', Account__c = propAccount1.Id, Annual_Cost_of_Electricity__c = 10000, Name_on_Account__c = accountName1);
        Utility_Account_Log__c ualog2 = new Utility_Account_Log__c(Name = '0000235', Account__c = propAccount2.Id, Annual_Cost_of_Electricity__c = 10000, Name_on_Account__c = accountName2);
        Utility_Account_Log__c ualog3 = new Utility_Account_Log__c(Name = '0000236', Account__c = propAccount3.Id, Annual_Cost_of_Electricity__c = 10000, Name_on_Account__c = accountName3);
        Utility_Account_Log__c ualog4 = new Utility_Account_Log__c(Name = '0000237', Account__c = propAccount4.Id, Annual_Cost_of_Electricity__c = 10000, Name_on_Account__c = accountName4);
        Utility_Account_Log__c ualog5 = new Utility_Account_Log__c(Name = '0000238', Account__c = propAccount5.Id, Annual_Cost_of_Electricity__c = 10000, Name_on_Account__c = accountName5);

        insert new List<Utility_Account_Log__c>{
            ualog1, ualog2, ualog3, ualog4, ualog5
        };

        Opportunity opportunity1 = new Opportunity(Name = accountName1, AccountId = propAccount1.Id, Shared_Solar_System__c = sss1.Id, StageName = 'Complete', Product__c = sss1.Product__r.Id, CloseDate = System.today());
        Opportunity opportunity2 = new Opportunity(Name = accountName2, AccountId = propAccount2.Id, Shared_Solar_System__c = sss1.Id, StageName = 'Complete', Product__c = sss1.Product__r.Id, CloseDate = System.today());
        Opportunity opportunity3 = new Opportunity(Name = accountName3, AccountId = propAccount3.Id, Shared_Solar_System__c = sss1.Id, StageName = 'Complete', Product__c = sss1.Product__r.Id, CloseDate = System.today());
        Opportunity opportunity4 = new Opportunity(Name = accountName4, AccountId = propAccount4.Id, Shared_Solar_System__c = sss1.Id, StageName = 'Complete', Product__c = sss1.Product__r.Id, CloseDate = System.today());
        Opportunity opportunity5 = new Opportunity(Name = accountName5, AccountId = propAccount5.Id, Shared_Solar_System__c = sss1.Id, StageName = 'Complete', Product__c = sss1.Product__r.Id, CloseDate = System.today());

        insert new List<Opportunity>{
            opportunity1, opportunity2, opportunity3, opportunity4, opportunity5
        };

        Utility_Account_Subscription__c uas1 = new Utility_Account_Subscription__c(Name = '0000234', Utility_Account_Log__c = ualog1.Id, Opportunity__c = opportunity1.Id, Next_Schedule_Z_Status__c = 'Active Subscription', Calculated_Annual_Cost_of_Electricity__c = 1400, Subscribed_Annual_Cost_of_Electricity__c = 1400, Customer_Subscription_KW_DC_STATIC__c = 25);
        Utility_Account_Subscription__c uas2 = new Utility_Account_Subscription__c(Name = '0000235', Utility_Account_Log__c = ualog2.Id, Opportunity__c = opportunity2.Id, Next_Schedule_Z_Status__c = 'Active Subscription', Calculated_Annual_Cost_of_Electricity__c = 1400, Subscribed_Annual_Cost_of_Electricity__c = 1400, Customer_Subscription_KW_DC_STATIC__c = 10);
        Utility_Account_Subscription__c uas3 = new Utility_Account_Subscription__c(Name = '0000236', Utility_Account_Log__c = ualog3.Id, Opportunity__c = opportunity3.Id, Next_Schedule_Z_Status__c = 'Active Subscription', Calculated_Annual_Cost_of_Electricity__c = 1400, Subscribed_Annual_Cost_of_Electricity__c = 1400, Customer_Subscription_KW_DC_STATIC__c = 20);
        Utility_Account_Subscription__c uas4 = new Utility_Account_Subscription__c(Name = '0000237', Utility_Account_Log__c = ualog4.Id, Opportunity__c = opportunity4.Id, Next_Schedule_Z_Status__c = 'Active Subscription', Calculated_Annual_Cost_of_Electricity__c = 1400, Subscribed_Annual_Cost_of_Electricity__c = 1400, Customer_Subscription_KW_DC_STATIC__c = 19);
        Utility_Account_Subscription__c uas5 = new Utility_Account_Subscription__c(Name = '0000238', Utility_Account_Log__c = ualog5.Id, Opportunity__c = opportunity5.Id, Next_Schedule_Z_Status__c = 'Active Subscription', Calculated_Annual_Cost_of_Electricity__c = 1400, Subscribed_Annual_Cost_of_Electricity__c = 1400, Customer_Subscription_KW_DC_STATIC__c = 17);

        insert new List<Utility_Account_Subscription__c>{
            uas1, uas2, uas3, uas4, uas5
        };

        Profile profileRecord = [SELECT Id FROM Profile WHERE Name = 'Community Solar Community User'];

        User userRecord = new User(
            FirstName = 'Jordan',
            Lastname = 'CSPaymentTest',
            Alias = 'CSpyTt',
            Email = 'jpentaleri@bluewavesolar.com',
            Emailencodingkey = 'UTF-8',
            Languagelocalekey = 'en_US',
            Localesidkey = 'en_US',
            Profileid = profileRecord.Id,
            Country = 'United States',
            IsActive = true,
            ContactId = contact1.Id,
            Timezonesidkey = 'America/Los_Angeles',
            Username = 'CSPaymentTest@bluewavesolar.com');

        Util.insertSobj(userRecord);

        Date myDateJan = Date.newInstance(2018, 1, 1);
        Date myDateFeb = Date.newInstance(2018, 2, 2);
        Date myDateMar = Date.newInstance(2018, 3, 3);

        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Status__c = 'Billing'
        );

        insert scheduleZ1;

        Energy_Usage_Update__c productionupdateA1 = new Energy_Usage_Update__c(
            Name = 'sssA - January 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.id,
            Production__c = 90000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateFeb,
            Total_System_NMCs__c = 16632,
            Date__c = myDateJan
        );

        Energy_Usage_Update__c productionupdateA2 = new Energy_Usage_Update__c(
            Name = 'sssA - February 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.id,
            Production__c = 120000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateMar,
            Total_System_NMCs__c = 22176,
            Date__c = myDateFeb
        );

        insert productionupdateA1;
        productionupdateA1.Generate_Bills__c = TRUE;
        update productionupdateA1;
        setBillsToPublished();

        insert productionupdateA2;
        productionupdateA2.Generate_Bills__c = TRUE;
        update productionupdateA2;
        setBillsToPublished();
    }

    @isTest public static void testPayOffOne(){
        // assert Bills were inserted for each property account, for 2 billing periods:
        List<System_Bill__c> systemBillList = [ SELECT Id, Account_Bill__r.Name, Total_Due__c,
                                                    Account_Bill__r.Is_Most_Recent__c
                                                FROM System_Bill__c
                                                ORDER BY Account_Bill__r.Name];
        System.assertEquals(10, systemBillList.size());

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
        System.assertEquals('BDonut Shop February 2018',systemBillList[2].Account_Bill__r.Name);
        System.assertEquals(true,systemBillList[2].Account_Bill__r.Is_Most_Recent__c);
        sbList.add(systemBillList[2]);
        mockMakeASinglePayment(sbList);

        System.runAs(userA) {
            // Try again to make a payment for all property accounts, now this list should be 3 not 4:
            List<ChargentOrders__ChargentOrder__c> secondOrderList = makePaymentInPortal('All');
            System.assertEquals(3,secondOrderList.size());

            for (ChargentOrders__ChargentOrder__c orderToCharge : secondOrderList) {
                System.assert(orderToCharge.ChargentOrders__Subtotal__c > 0);
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
        List<System_Bill__c> systemBillList = [ SELECT Id, Account_Bill__r.Name, Total_Due__c,
                                                    Account_Bill__r.Is_Most_Recent__c
                                                FROM System_Bill__c
                                                ORDER BY Account_Bill__r.Name];

        System.assertEquals(10, systemBillList.size());

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
            // Try again to make a payment for all property accounts, now this list should be 3 not 4:
            List<ChargentOrders__ChargentOrder__c> secondOrderList = makePaymentInPortal('All');
            System.assertEquals(0,secondOrderList.size());

            Test.stopTest();
        }
    }

    static void setBillsToPublished() {
        List <Account_Bill__c> listaccountBills = [ SELECT Id, Published__c
                                                    FROM Account_Bill__c
                                                    WHERE Published__c = False];
        for (Account_Bill__c acctBill : listaccountBills) {
            acctBill.Published__c = True;
        }
        update listaccountBills;
    }

    static List<System_Bill__c> mockMakeASinglePayment(List<System_Bill__c> systemBills) {
        for (System_Bill__c systemBill : systemBills) {
            systemBill.Total_Payments_This_Month__c = systemBill.Total_Due__c;
            systemBill.Payments_Net_Previous_Balances__c = systemBill.Total_Due__c;
        }
        update systemBills;

        return systemBills;
    }

    static List<ChargentOrders__ChargentOrder__c> makePaymentInPortal(String propertyAccountId) {
        List<AggregateResult> aggResult = MyAccountController.getSystemBills(propertyAccountId);
        ChargentOrders__ChargentOrder__c orderB = getPaymentInput();
        List<ChargentOrders__ChargentOrder__c> choList = CreateOrderandPaymentRequest.setChargeAmountAndInsert(aggResult, orderB, false);

        return choList;
    }

    static ChargentOrders__ChargentOrder__c getPaymentInput() {
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
 }