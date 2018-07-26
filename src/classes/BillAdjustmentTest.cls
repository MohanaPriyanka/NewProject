/**
 * Created by mstackhouse on 7/26/2018.
 * Description: 
 * Test: 
 */

@isTest
public with sharing class BillAdjustmentTest {
    @testSetup public static void testSetup(){
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

        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent = new Account(name = 'Account Parent',
            RecordTypeId = parentAccountRT);
        insert accountParent;
        Account accountParent2 = new Account(name = 'Account Parent',
            RecordTypeId = parentAccountRT);
        insert accountParent2;

        Contact contactA = new Contact( FirstName = 'Contact',
            LastName = 'A',
            AccountId = accountParent.Id);
        insert contactA;
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
        Util.insertSobjs(new list<User>{userRecord});

        ChargentBase__Gateway__c chGateway  =
            new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                ChargentBase__Merchant_ID__c = '235986',
                ChargentBase__Debug__c = True,
                ChargentBase__Active__c = TRUE);
        insert chGateway;


        Entity__c entity1 = new Entity__c (
            Name = 'Oxford Barrett St. P1',
            Send_Checks_Address__c = 'Fake Lockbox Address, P.O Box 12345, Phoenix Arizona 02114',
            Client_Account__c = clientAccount.Id,
            Gateway__c = chGateway.Id
        );
        insert entity1;

        Entity__c entity2 = new Entity__c (
            Name = 'Oxford Barrett St. P2',
            Send_Checks_Address__c = '200 Other Street, City MA 02114',
            Client_Account__c = clientAccount2.Id,
            Gateway__c = chGateway.Id
        );
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
                Billing_Method__c = 'NMC',
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
                Billing_Method__c = 'NMC',
                BWC_Project_Entity_Manual__c = entity2.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id
            );

        insert new List<Shared_Solar_System__c>{sss1, sss2};


        Account accountA = new Account(name = 'Account A',
            Parent_Account__c = accountParent.Id);
        Account accountB = new Account(name = 'Account B',
            Parent_Account__c = accountParent2.Id);
        insert new List<Account>{accountA, accountB};



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

        //Changed something (not sure if it was billing number fix) and it now applies this Bill adjustment to every system bill
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

        Schedule_Z__c scheduleZ2 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P2',
            Shared_Solar_System__c = sss2.Id,
            Status__c = 'Billing'
        );

        insert new List<Schedule_Z__c>{scheduleZ1, scheduleZ2};

        Energy_Usage_Update__c productionupdateA1 = new Energy_Usage_Update__c (
            Name = 'sssA - January 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.id,
            Production__c = 90000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateFeb,
            Total_System_NMCs__c = 16632,
            Date__c = myDateJan
        );

        Energy_Usage_Update__c productionupdateA2 = new Energy_Usage_Update__c (
            Name = 'sssA - February 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.id,
            Production__c = 120000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateMar,
            Total_System_NMCs__c = 22176,
            Date__c = myDateFeb
        );

        Energy_Usage_Update__c productionupdateA3 = new Energy_Usage_Update__c (
            Name = 'sssA - March 2016',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.id,
            Production__c = 140000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateApr,
            Total_System_NMCs__c = 25872,
            Date__c = myDateMar
        );

        Energy_Usage_Update__c productionupdateB1 = new Energy_Usage_Update__c (
            Name = 'sssB - January 2016',
            Shared_Solar_System__c = sss2.id,
            Schedule_Z__c = scheduleZ2.id,
            Production__c = 90000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateFeb,
            Total_System_NMCs__c = 16632,
            Date__c = myDateJan
        );

        Energy_Usage_Update__c productionupdateB2 = new Energy_Usage_Update__c (
            Name = 'sssB - February 2016',
            Shared_Solar_System__c = sss2.id,
            Schedule_Z__c = scheduleZ2.id,
            Production__c = 120000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = myDateMar,
            Total_System_NMCs__c = 22176,
            Date__c = myDateFeb
        );

        insert new List<Energy_Usage_Update__c>{
            productionupdateA1,
            productionupdateA2,
            productionupdateA3,
            productionupdateB1,
            productionupdateB2
        };

        productionupdateA1.Generate_Bills__c = TRUE;
        productionupdateA2.Generate_Bills__c = TRUE;
        update productionupdateA1;
        update productionupdateA2;

        OverpaymentApplication.applyOverpayments();
//        APXT_BPM__Conductor__c congaRecord = new APXT_BPM__Conductor__c (
//            APXT_BPM__Title__c = 'Conga Record');
//        insert congaRecord;
//        congaRecord.Apply_Overpay_Adjust__c = true;
//        update congaRecord;
    }

    @isTest public static void testAdjustments() {
        List<Account_Bill__c> accountbilllist = [
            SELECT Id, Name, Bill_Number__c, Property_Account_ID__c
            FROM Account_Bill__c
        ];

        for (Account_Bill__c abill : accountbilllist) {
            abill.Published__c = True;
        }
        update accountbilllist;

        Entity__c entity = [
            SELECT Id, Gateway__c
            FROM Entity__c
            WHERE Name = 'Oxford Barrett St. P1'
        ];

        Test.startTest();

        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToUpdate = new List<ChargentOrders__Transaction__c>();
        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToNotUpdate = new List<ChargentOrders__Transaction__c>();
        for (Account_Bill__c accountbill : accountbilllist) {
            if(accountbill.Bill_Number__c == 2) {
                ChargentOrders__ChargentOrder__c orderA =
                    new ChargentOrders__ChargentOrder__c(
                        Entity__c = entity.Id,
                        ChargentOrders__Gateway__c = entity.Gateway__c,
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
                        ChargentOrders__Gateway_ID__c = entity.Gateway__c,
                        ChargentOrders__Gateway__c = entity.Gateway__c,
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
                        ChargentOrders__Gateway_ID__c = entity.Gateway__c,
                        ChargentOrders__Gateway__c = entity.Gateway__c,
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

        Test.stopTest();

        Account accountA = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Account A'
        ];

        List<Account> acctList = new List<Account>{accountA};

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
    }

    @isTest public static void testAdjustments2() {
        List<Account_Bill__c> accountbilllist = [
            SELECT Id, Name, Bill_Number__c, Property_Account_ID__c,
                (SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
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
                FROM System_Bills__r
                ORDER BY Bill_Number__c)
            FROM Account_Bill__c
        ];

        for (Account_Bill__c abill : accountbilllist) {
            abill.Published__c = True;
        }
        update accountbilllist;

        Entity__c entity = [
            SELECT Id, Gateway__c
            FROM Entity__c
            WHERE Name = 'Oxford Barrett St. P1'
        ];
        Test.startTest();

        Account_Bill__c accountbill2;

        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToUpdate = new List<ChargentOrders__Transaction__c>();
        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToNotUpdate = new List<ChargentOrders__Transaction__c>();
        for (Account_Bill__c accountbill : accountbilllist) {
            if(accountbill.Bill_Number__c == 2) {
                accountbill2 = accountbill;
                ChargentOrders__ChargentOrder__c orderA =
                    new ChargentOrders__ChargentOrder__c(
                        Entity__c = entity.Id,
                        ChargentOrders__Gateway__c = entity.Gateway__c,
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
                        ChargentOrders__Gateway_ID__c = entity.Gateway__c,
                        ChargentOrders__Gateway__c = entity.Gateway__c,
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
                        ChargentOrders__Gateway_ID__c = entity.Gateway__c,
                        ChargentOrders__Gateway__c = entity.Gateway__c,
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

        List<System_Bill__c> updatedsystemBillListOne = accountbill2.System_Bills__r;

        for (System_Bill__c editBill : updatedsystemBillListOne) {
            if (editBill.Bill_Number__c == 2) {
                editBill.Waive_Late_Fees__c = True;
            }
        }
        update updatedsystemBillListOne;

        Energy_Usage_Update__c prodUpdate = [SELECT Id, Name, Generate_Bills__c FROM Energy_Usage_Update__c WHERE Name = 'sssA - March 2016'];
        prodUpdate.Generate_Bills__c = True;
        update prodUpdate;

//        APXT_BPM__Conductor__c congaRecord = new APXT_BPM__Conductor__c (
//            APXT_BPM__Title__c = 'Conga Record');
//        insert congaRecord;
//        congaRecord.Apply_Overpay_Adjust__c = true;
//        update congaRecord;
        Test.stopTest();
        OverpaymentApplication.applyOverpayments();

        List<Adjustment_Application__c> secondAdjustApp =   [
            SELECT Id, Name, Bill_Adjustment__c, System_Bill__c,
                Overpayment_Amount__c, Adjustment_Amount__c,
                Bill_Adjustment__r.Overpayment__c
            FROM Adjustment_Application__c
            WHERE Bill_Adjustment__r.Overpayment__c = true
        ];
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

    @isTest public static void updateCheckAddress() {
        List<Account_Bill__c> accountbilllist = [
            SELECT Id, Name, Bill_Number__c, Property_Account_ID__c,
            (SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c,
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
            FROM System_Bills__r
            ORDER BY Bill_Number__c)
            FROM Account_Bill__c
        ];

        for (Account_Bill__c abill : accountbilllist) {
            abill.Published__c = True;
        }
        update accountbilllist;

        Test.startTest();

        Entity__c entity = [
            SELECT Id, Gateway__c
            FROM Entity__c
            WHERE Name = 'Oxford Barrett St. P1'
        ];

        Account_Bill__c accountbill2;

        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToUpdate = new List<ChargentOrders__Transaction__c>();
        List<ChargentOrders__Transaction__c> chargentOrdersTransactionsToNotUpdate = new List<ChargentOrders__Transaction__c>();
        for (Account_Bill__c accountbill : accountbilllist) {
            if(accountbill.Bill_Number__c == 2) {
                accountbill2 = accountbill;
                ChargentOrders__ChargentOrder__c orderA =
                    new ChargentOrders__ChargentOrder__c(
                        Entity__c = entity.Id,
                        ChargentOrders__Gateway__c = entity.Gateway__c,
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
                        ChargentOrders__Gateway_ID__c = entity.Gateway__c,
                        ChargentOrders__Gateway__c = entity.Gateway__c,
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
                        ChargentOrders__Gateway_ID__c = entity.Gateway__c,
                        ChargentOrders__Gateway__c = entity.Gateway__c,
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

        List<System_Bill__c> updatedsystemBillListOne = accountbill2.System_Bills__r;

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
        Test.stopTest();
        Account propertyAccount = [
            SELECT Id, Name, Directions_To_Write_Paper_Check__c,
                Send_Checks_Address__c, Client_Brand_Key__c
            FROM Account
            WHERE Id = : propertyAccountId
        ];

        System.assertNotEquals(oldCheckAddressField, propertyAccount.Directions_To_Write_Paper_Check__c);
        System.assert(propertyAccount.Directions_To_Write_Paper_Check__c.contains('Oxford Barrett St. P1'));
        System.assertEquals('Fake Lockbox Address, P.O Box 12345, Phoenix Arizona 02114', propertyAccount.Send_Checks_Address__c);
        System.assertEquals('AmpBlack', propertyAccount.Client_Brand_Key__c);
    }
}