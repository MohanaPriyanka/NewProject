/*************************************************************************************
 * Created By: peteryao on 2019-03-03  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ClientReportingServiceTest {
    @TestSetup
    public static void testSetup() {
        Test.startTest();
        Test.loadData(Utility__c.SObjectType, 'TestCSUtility');
        Test.loadData(Utility_NMC_Tariff__c.SObjectType, 'TestCSUtilityNMCTariff');
        Test.loadData(Load_U__c.SObjectType, 'TestCSLoadU');
        Test.loadData(ChargentBase__Gateway__c.SObjectType, 'TestCSGateway');
        Test.loadData(Contact.SObjectType, 'TestCSContact');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Test.loadData(Entity__c.SObjectType, 'TestCSEntity');
        Test.loadData(Shared_Solar_System__c.SObjectType, 'TestCSSharedSolarSystem');
        Test.loadData(Utility_Account_Log__c.SObjectType, 'TestCSUtilityAccountLog');
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Test.stopTest();
        Test.loadData(Utility_Account_Subscription__c.SObjectType, 'TestCSUtilityAccountSubscription');
        Test.loadData(Schedule_Z__c.SObjectType, 'TestCSScheduleZ');
        Test.loadData(Schedule_Z_Subscription__c.SObjectType, 'TestCSScheduleZSubscription');
        Test.loadData(Bill_Period__c.SObjectType, 'TestCSBillPeriod');
        Test.loadData(Production__c.SObjectType, 'TestCSProduction');
        Test.loadData(Transfer__c.SObjectType, 'TestCSTransfer');

    }

    @IsTest
    public static void testSystemBillClientOwnerStamp() {
        Util.enableTrigger('Disable_EnergyUsageUpdateTrigger__c');

        Bill_Period__c billPeriod = [
            SELECT Id, Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c
            FROM Bill_Period__c
            WHERE Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c != NULL
            AND Name = 'sssA - March 2016'
            LIMIT 1
        ];

        TestBillCreationandPayment.runBillPeriod(new List<Id>{billPeriod.Id});

        List<System_Bill__c> systemBills = [
            SELECT Id, Client__c
            FROM System_Bill__c
        ];
        for (System_Bill__c systemBill : systemBills) {
            System.assertNotEquals(null, systemBill.Client__c);
            System.assertEquals(
                billPeriod.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c,
                systemBill.Client__c
            );
        }
    }

    @IsTest
    public static void testAdjustmentClientOwnerStamp() {
        Util.enableTrigger('Disable_EnergyUsageUpdateTrigger__c');
        Utility_Account_Subscription__c uas = [
            SELECT Id, Opportunity__r.Shared_Solar_System__c,
                Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000239'
        ];

        Bill_Adjustment__c adjustment = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment',
            Utility_Account_Subscription__c = uas.Id,
            Adjustment_Type__c = 'Production',
            Adjustment_Amount__c = 24,
            Credits_Allocated__c = 24,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Client Owner Test'
        );
        insert adjustment;

        Bill_Period__c billPeriod = [
            SELECT Id, Shared_Solar_System__c
            FROM Bill_Period__c
            WHERE Name = 'sssA - March 2016'
        ];

        Transfer__c transfer = [
            SELECT Id, Name, Shared_Solar_System__c, Allocation_Schedule__c, Attempted_Transfer__c, Bill_Period__c,
                Bill_Period__r.Bill_Date__c, Default_Credit_Value__c, Bills_Generated__c, Total_kWh_Transferred__c,
                Total_Transferred__c, Transfer_Amount__c, Transfer_kWh__c, Transfer_Type__c, Date_of_Transfer__c
            FROM Transfer__c
            WHERE Bill_Period__c = :billPeriod.Id
            LIMIT 1
        ];
        TransferPartService transferPartService = new TransferPartService();
        transferPartService.createPartsFromTransfer(new List<Transfer__c>{transfer});

        System.assertEquals(uas.Opportunity__r.Shared_Solar_System__c, billPeriod.Shared_Solar_System__c);
        TestBillCreationandPayment.runBillPeriod(new List<Id>{billPeriod.Id});

        Bill_Adjustment__c billAdjustment = [
            SELECT Id, UASB__r.System_Bill__r.Shared_Solar_System__c, Client__c, UASB__c
            FROM Bill_Adjustment__c
            WHERE Id = :adjustment.Id
        ];

        System.assertEquals(
            uas.Opportunity__r.Shared_Solar_System__c,
            billAdjustment.UASB__r.System_Bill__r.Shared_Solar_System__c
        );
        System.assertNotEquals(null, billAdjustment.Client__c);
        System.assertEquals(
            uas.Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c,
            billAdjustment.Client__c
        );
    }

    @IsTest
    public static void testTransactionClientOwner() {
        List<Entity__c> entities = [
            SELECT Id, Client_Account__c
            FROM Entity__c
            WHERE Client_Account__c != NULL
        ];
        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            Entity__c = entities[0].Id,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 50,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111'
        );
        insert order;
        ChargentOrders__Transaction__c trx = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = order.Id,
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment'
        );
        insert trx;
        List<ChargentOrders__Transaction__c> transactions = [
            SELECT Id, Client__c
            FROM ChargentOrders__Transaction__c
            WHERE Id = :trx.Id
        ];
        System.assertNotEquals(null, transactions[0].Client__c);
        System.assertEquals(entities[0].Client_Account__c, transactions[0].Client__c);
    }

    @isTest
    public static void testClientHealthScore(){
        Account acct = [SELECT Id FROM Account LIMIT 1];

        Client_Health_Report__c perfectScore = new Client_Health_Report__c(
            Client_Account__c = acct.Id,
            Customers_Beginning_Balance__c  = 1200,
            Customers_Invoiced__c = 1200,
            Customers_Payments__c = 2400,
            Clients_Beginning_Balance__c  = 1200,
            Clients_Invoiced__c = 1200,
            Clients_Payments__c = 2400,
            NPS__c = 10,
            BlueWave_Rating__c = 10,
            Open_Cases__c = 0,
            Management_Projects_Utilization__c = 100
        );
        Client_Health_Report__c emptyData = new Client_Health_Report__c(
            Client_Account__c = acct.Id,
            BlueWave_Rating__c = 6,
            Open_Cases__c = 10
        );
        Client_Health_Report__c badScore = new Client_Health_Report__c(
            Client_Account__c = acct.Id,
            Customers_Beginning_Balance__c  = 1200,
            Customers_Invoiced__c = 1000,
            Customers_Payments__c = 100,
            Clients_Beginning_Balance__c  = 1200,
            Clients_Invoiced__c = 1000,
            Clients_Payments__c = 100,
            NPS__c = 5,
            BlueWave_Rating__c = 4,
            Open_Cases__c = 18,
            Management_Projects_Utilization__c = 90
        );

        insert new List<Client_Health_Report__c>{perfectScore, emptyData, badScore};

        perfectScore.Recalculate_Health_Score__c = true;
        emptyData.Recalculate_Health_Score__c = true;
        badScore.Recalculate_Health_Score__c = true;

        update new List<Client_Health_Report__c>{perfectScore, emptyData, badScore};

        List<Client_Health_Report__c> reportList = [
            SELECT Id, Name, Customer_DSO__c,
                Client_DSO__c,
                Client_Account__c,
                Client_Health_Score__c,
                Customers_Beginning_Balance__c,
                Customers_Invoiced__c,
                Customers_Payments__c,
                Clients_Beginning_Balance__c,
                Clients_Invoiced__c,
                Clients_Payments__c,
                NPS__c,
                BlueWave_Rating__c,
                Open_Cases__c,
                Management_Projects_Utilization__c
            FROM Client_Health_Report__c
            ORDER BY BlueWave_Rating__c DESC
        ];

        System.assertEquals(10, reportList[0].Client_Health_Score__c);
        System.assertEquals(6.38, reportList[1].Client_Health_Score__c);
        System.assertEquals(5.34, reportList[2].Client_Health_Score__c);
    }

    @IsTest
    public static void testClientUAS() {
        Utility_Account_Log__c ual = [SELECT Id FROM Utility_Account_Log__c LIMIT 1];

        Opportunity opp = [SELECT Id, Name, Shared_Solar_System__c, Shared_Solar_System__r.Name FROM Opportunity LIMIT 1];

        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = '123456',
            Utility_Account_Log__c = ual.Id,
            Opportunity__c = opp.Id,
            Subscribed_Annual_Cost_of_Electricity__c = 300,
            Annual_kwh_subscription_future__c = 7000

        );
        insert uas;

        Test.startTest();

        Client_Utility_Account_Subscription__c clientUAS = [
            SELECT Id, Customer__c, Annual_Cost_of_Electricity_Future__c, Annual_kWh_Subscription_Future__c, Shared_Solar_System__c
            FROM Client_Utility_Account_Subscription__c
            WHERE Utility_Account_Subscription__c = :uas.Id
            LIMIT 1
        ];


        System.assertEquals(opp.Name, clientUAS.Customer__c);
        System.assertEquals(300, clientUAS.Annual_Cost_of_Electricity_Future__c);
        System.assertEquals(7000, clientUAS.Annual_kWh_Subscription_Future__c);
        System.assertEquals(opp.Shared_Solar_System__c, clientUAS.Shared_Solar_System__c);


        //Test an update to parent UAS
        uas.Subscribed_Annual_Cost_of_Electricity__c = 500;
        update uas;

        Client_Utility_Account_Subscription__c clientUASUpdate = [
            SELECT Id, Annual_Cost_of_Electricity_Future__c, Annual_kWh_Subscription_Future__c, Shared_Solar_System__c
            FROM Client_Utility_Account_Subscription__c
            WHERE Utility_Account_Subscription__c = :uas.Id
            LIMIT 1
        ];


        System.assertEquals(500, clientUASUpdate.Annual_Cost_of_Electricity_Future__c);

        //Test update of Opp's SSS
        Shared_Solar_System__c sss2 = [
            SELECT Id, Name
            FROM Shared_Solar_System__c
            WHERE Id != :opp.Shared_Solar_System__c
            LIMIT 1
        ];

        opp.Shared_Solar_System__c = sss2.Id;
        update opp;


        Utility_Account_Subscription__c uasUpdate = [
            SELECT Id, Shared_Solar_System_Name__c
            FROM Utility_Account_Subscription__c
            WHERE Id = :uas.Id
            LIMIT 1
        ];

        Client_Utility_Account_Subscription__c clientUASUpdate2 = [
            SELECT Id, Annual_Cost_of_Electricity_Future__c, Annual_kWh_Subscription_Future__c, Shared_Solar_System__c
            FROM Client_Utility_Account_Subscription__c
            WHERE Utility_Account_Subscription__c = :uas.Id
            LIMIT 1
        ];

        System.assertEquals(sss2.Name, uasUpdate.Shared_Solar_System_Name__c);
        System.assertEquals(sss2.Id, clientUASUpdate2.Shared_Solar_System__c);

        //Test deletion of parent UAS
        delete uas;

        List<Client_Utility_Account_Subscription__c> clientUASDelete = [
            SELECT Id, Annual_Cost_of_Electricity_Future__c, Annual_kWh_Subscription_Future__c, Shared_Solar_System__c
            FROM Client_Utility_Account_Subscription__c
            WHERE Utility_Account_Subscription__c = :uas.Id
            LIMIT 1
        ];


        System.assertEquals(0, clientUASDelete.size());

        Test.stopTest();

    }

    @IsTest
    public static void testClientALSS() {
        Utility_Account_Log__c ual = [SELECT Id FROM Utility_Account_Log__c LIMIT 1];

        Opportunity opp = [SELECT Id, Shared_Solar_System__c FROM Opportunity LIMIT 1];

        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = '123456',
            Utility_Account_Log__c = ual.Id,
            Opportunity__c = opp.Id,
            Subscribed_Annual_Cost_of_Electricity__c = 300,
            Annual_kwh_subscription_future__c = 7000

        );
        insert uas;

        Client_Utility_Account_Subscription__c clientUAS = [
            SELECT Id
            FROM Client_Utility_Account_Subscription__c
            WHERE Utility_Account_Subscription__c = :uas.Id
            LIMIT 1
        ];

        Schedule_Z__c sz = [SELECT Id FROM Schedule_Z__c LIMIT 1];

        Schedule_Z_Subscription__c alss = new Schedule_Z_Subscription__c(
            Schedule_Z__c = sz.Id,
            Utility_Account_Subscription__c = uas.Id,
            Number_of_Decimal_Places__c = 4,
            Customer_Subscription_kW_DC__c = 5,
            System_Size_kW_DC__c = 100
        );

        insert alss;

        Test.startTest();

        Client_Allocation_Schedule_Subscription__c clientALSS= [
            SELECT Id, Client_Utility_Account_Subscription__c, Customer_Subscription_kW_DC__c, Allocation_Schedule__c
            FROM Client_Allocation_Schedule_Subscription__c
            WHERE Allocation_Schedule_Subscription__c = :alss.Id
        ];

        System.assertEquals(sz.Id, clientALSS.Allocation_Schedule__c );
        System.assertEquals(clientUAS.Id, clientAlSS.Client_Utility_Account_Subscription__c);
        System.assertEquals(alss.Customer_Subscription_kW_DC__c, clientALSS.Customer_Subscription_kW_DC__c);

        //Test update of parent ALSS
        alss.Customer_Subscription_kW_DC__c = 7;
        update alss;

        Client_Allocation_Schedule_Subscription__c clientALSSUpdate = [
            SELECT Id, Client_Utility_Account_Subscription__c, Customer_Subscription_kW_DC__c, Allocation_Schedule__c
            FROM Client_Allocation_Schedule_Subscription__c
            WHERE Allocation_Schedule_Subscription__c = :alss.Id
        ];

        System.assertEquals(7, clientALSSUpdate.Customer_Subscription_kW_DC__c);

        //Test delete of parent ALSS
        delete alss;

        List<Client_Allocation_Schedule_Subscription__c> clientALSSDelete = [
            SELECT Id, Client_Utility_Account_Subscription__c, Customer_Subscription_kW_DC__c, Allocation_Schedule__c
            FROM Client_Allocation_Schedule_Subscription__c
            WHERE Allocation_Schedule_Subscription__c = :alss.Id
        ];

        System.assertEquals(0, clientALSSDelete.size());

        Test.stopTest();
    }

}