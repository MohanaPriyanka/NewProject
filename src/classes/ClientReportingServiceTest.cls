/*************************************************************************************
 * Created By: peteryao on 2019-03-03
 * Description:
 * Test:
 *************************************************************************************/
@IsTest
public with sharing class ClientReportingServiceTest {
    @TestSetup
    public static void testSetup() {
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
        Test.loadData(Utility_Account_Subscription__c.SObjectType, 'TestCSUtilityAccountSubscription');
        Test.loadData(Schedule_Z__c.SObjectType, 'TestCSScheduleZ');
        Test.loadData(Schedule_Z_Subscription__c.SObjectType, 'TestCSScheduleZSubscription');
        Test.loadData(Energy_Usage_Update__c.SObjectType, 'TestCSProdUpdate');
    }

    @IsTest
    public static void testAdjustmentClientOwnerStamp() {
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

        Bill_Adjustment__c billAdjustment = [
            SELECT Id, Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c, Client__c
            FROM Bill_Adjustment__c
            WHERE Id = :adjustment.Id
        ];
        System.assertEquals(
            uas.Opportunity__r.Shared_Solar_System__c,
            billAdjustment.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c
        );
        System.assertNotEquals(null, billAdjustment.Client__c);
        System.assertEquals(
            uas.Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c,
            billAdjustment.Client__c
        );

        Utility_Account_Subscription__c uasTwo = [
            SELECT Id, Opportunity__r.Shared_Solar_System__c,
                Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000244'
        ];

        adjustment.Utility_Account_Subscription__c = uasTwo.Id;
        update adjustment;

        Bill_Adjustment__c updatedBillAdjustment = [
            SELECT Id, Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c, Client__c
            FROM Bill_Adjustment__c
            WHERE Id = :adjustment.Id
        ];
        System.assertEquals(
            uasTwo.Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c,
            updatedBillAdjustment.Client__c
        );
    }

    @IsTest
    public static void testUASBClientOwnerStamp() {
        Util.enableTrigger('Disable_EnergyUsageUpdateTrigger__c');
        Energy_Usage_Update__c energyUsageUpdate = [
            SELECT Id, Generate_Bills__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c
            FROM Energy_Usage_Update__c
            WHERE Generate_Bills__c = FALSE
            AND Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c != NULL
            LIMIT 1
        ];
        List<Energy_Usage_Update__c> trigProdUp = ProductionUpdateSelector.getAllProductionUpdatesById(new List<Id>{energyUsageUpdate.Id});
        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(trigProdUp);
        ee.runBills();

        List<UASB__c> uasbs = [
            SELECT Id, Client__c
            FROM UASB__c
        ];
        System.assert(uasbs.size() > 0);
        for (UASB__c uasb : uasbs) {
            System.assertNotEquals(null, uasb.Client__c);
            System.assertEquals(
                energyUsageUpdate.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c,
                uasb.Client__c
            );
        }
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

        List<Client_Utility_Account_Subscription__c> clientUAS = ClientReportObjectSelector.getClientUASesByUASIds(new Set<Id>{uas.Id});

        System.assertEquals(opp.Name, clientUAS[0].Customer__c);
        System.assertEquals(300, clientUAS[0].Annual_Cost_of_Electricity_Future__c);
        System.assertEquals(7000, clientUAS[0].Annual_kWh_Subscription_Future__c);
        System.assertEquals(opp.Shared_Solar_System__c, clientUAS[0].Shared_Solar_System__c);


        //Test an update to parent UAS
        uas.Subscribed_Annual_Cost_of_Electricity__c = 500;
        update uas;

        List<Client_Utility_Account_Subscription__c> clientUASUpdate = ClientReportObjectSelector.getClientUASesByUASIds(new Set<Id>{uas.Id});

        System.assertEquals(500, clientUASUpdate[0].Annual_Cost_of_Electricity_Future__c);

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

        List<Client_Utility_Account_Subscription__c> clientUASUpdate2 = ClientReportObjectSelector.getClientUASesByUASIds(new Set<Id>{uas.Id});

        System.assertEquals(sss2.Name, uasUpdate.Shared_Solar_System_Name__c);
        System.assertEquals(sss2.Id, clientUASUpdate2[0].Shared_Solar_System__c);

        System.assertEquals(500, clientUASUpdate[0].Annual_Cost_of_Electricity_Future__c);

        //Test deletion of parent UAS
        delete uas;

        List<Client_Utility_Account_Subscription__c> clientUASDelete = ClientReportObjectSelector.getClientUASesByUASIds(new Set<Id>{uas.Id});

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

        List<Client_Utility_Account_Subscription__c> clientUAS = ClientReportObjectSelector.getClientUASesByUASIds(new Set<Id>{uas.Id});

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

        List<Client_Allocation_Schedule_Subscription__c> clientALSS = ClientReportObjectSelector.getClientALSSBySZSIds(new Set<Id>{alss.Id});

        System.assertEquals(sz.Id, clientALSS[0].Allocation_Schedule__c );
        System.assertEquals(clientUAS[0].Id, clientAlSS[0].Client_Utility_Account_Subscription__c);
        System.assertEquals(alss.Customer_Subscription_kW_DC__c, clientALSS[0].Customer_Subscription_kW_DC__c);

        //Test update of parent ALSS
        alss.Customer_Subscription_kW_DC__c = 7;
        update alss;

        List<Client_Allocation_Schedule_Subscription__c> clientALSSUpdate = ClientReportObjectSelector.getClientALSSBySZSIds(new Set<Id>{alss.Id});

        System.assertEquals(7, clientALSSUpdate[0].Customer_Subscription_kW_DC__c);

        //Test delete of parent ALSS
        delete alss;

        List<Client_Allocation_Schedule_Subscription__c> clientALSSDelete = ClientReportObjectSelector.getClientALSSBySZSIds(new Set<Id>{alss.Id});

        System.assertEquals(0, clientALSSDelete.size());

        Test.stopTest();
    }

}