/*************************************************************************************
 * Created By: peteryao on 2019-03-03
 * Description:
 * Test:
 *************************************************************************************/
@IsTest
public with sharing class ClientReportingServiceTest {
    @TestSetup
    public static void testSetup() {
        useMocks();
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
        Test.loadData(Partner__c.SObjectType,'TestRLPartner');
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Test.loadData(Utility_Account_Subscription__c.SObjectType, 'TestCSUtilityAccountSubscription');
        Test.stopTest();
        Test.loadData(Schedule_Z__c.SObjectType, 'TestCSScheduleZ');
        Test.loadData(Schedule_Z_Subscription__c.SObjectType, 'TestCSScheduleZSubscription');
        Test.loadData(Bill_Period__c.SObjectType, 'TestCSBillPeriod');
        Test.loadData(Production__c.SObjectType, 'TestCSProduction');
        Test.loadData(Transfer__c.SObjectType, 'TestCSTransfer');
    }
    @IsTest
    public static void testAdjustmentClientOwnerStamp() {
        Utility_Account_Subscription__c uas = [
            SELECT Id, Opportunity__r.Shared_Solar_System__c, Opportunity__r.AccountId,
                Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c, Externally_Serviced__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000239'
        ];
        Bill_Period__c billPeriod = [
            SELECT Id, Shared_Solar_System__c, Bill_Date__c, Bill_Status__c
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
        Bill_Adjustment__c adjustment = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment',
            Utility_Account_Subscription__c = uas.Id,
            Account__c = uas.Opportunity__r.AccountId,
            Adjustment_Type__c = 'Production',
            Adjustment_Amount__c = 24,
            Credits_Allocated__c = 24,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Client Owner Test',
            Transfer__c = transfer.Id
        );
        insert adjustment;
        TransferPartService transferPartService = new TransferPartService();
        transferPartService.createPartsFromTransfer(new List<Transfer__c>{transfer});
        System.assertEquals(uas.Opportunity__r.Shared_Solar_System__c, billPeriod.Shared_Solar_System__c);
        BillGenerationServiceTest.generateBills(new List<Id>{billPeriod.Id});
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
        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Opportunity__r.AccountId
            FROM Utility_Account_Subscription__c
        ];

        UASB__c billOne = new UASB__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Zuora_Id__c = 'bbb1230005',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        UASB__c billTwo = new UASB__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Zuora_Id__c = 'bbb1230001',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        UASB__c billThree = new UASB__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Zuora_Id__c = 'bbb1230001',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        insert new List<UASB__c>{billOne, billTwo, billThree};

        List<UASB__c> uasbs = [
            SELECT Id, Client__c,
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c
            FROM UASB__c
        ];
        System.assert(uasbs.size() > 0);

        for (UASB__c uasb : uasbs) {
            System.assertNotEquals(null, uasb.Client__c);
            System.assertEquals(
                uasb.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c,
                uasb.Client__c
            );
        }
    }
    @IsTest
    public static void testClientStampsProductionAndBillRecords(){
        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Name, Client_Account__r.Name
            FROM Shared_Solar_System__c
            WHERE (Name = 'Oxford Barrett St. P1' OR Name = 'Oxford Barrett St. P3')
            ORDER BY Name
        ];
        System.assert(sssList[0].Client_Account__c != sssList[1].Client_Account__c);

        Production__c prodP1 = new Production__c(
            Shared_Solar_System__c = sssList[0].Id,
            Name = 'Production'
        );
        Production__c prodP3 = new Production__c(
            Shared_Solar_System__c = sssList[1].Id,
            Name = 'Production'
        );
        Bill_Period__c billPeriodP1 = new Bill_Period__c(
            Shared_Solar_System__c = sssList[0].Id,
            Name = 'BillPer'
        );
        Bill_Period__c billPeriodP3 = new Bill_Period__c(
            Shared_Solar_System__c = sssList[1].Id,
            Name = 'BillPer'
        );
        Transfer__c transferP1 = new Transfer__c(
            Shared_Solar_System__c = sssList[0].Id,
            Attempted_Transfer__c = 100,
            Attempted_kWh_Transfer__c = 100,
            Transfer_Amount__c = 100,
            Date_of_Transfer__c = Date.newInstance(2019, 6, 4),
            Name = 'TRF'
        );
        Transfer__c transferP3 = new Transfer__c(
            Shared_Solar_System__c = sssList[1].Id,
            Attempted_Transfer__c = 100,
            Attempted_kWh_Transfer__c = 100,
            Transfer_Amount__c = 100,
            Date_of_Transfer__c = Date.newInstance(2019, 6, 4),
            Name = 'TRF'
        );

        insert new List<Production__c>{prodP1,prodP3};
        insert new List<Bill_Period__c>{billPeriodP1,billPeriodP3};
        insert new List<Transfer__c>{transferP1,transferP3};

        List<Production__c> prodList = [
            SELECT Id, Client_Account__c
            FROM Production__c
            WHERE (Id = : prodP1.Id OR Id = : prodP3.Id)
            ORDER BY Shared_Solar_System__r.Name
        ];
        List<Bill_Period__c> bpList = [
            SELECT Id, Client_Account__c
            FROM Bill_Period__c
            WHERE (Id = : billPeriodP1.Id OR Id = : billPeriodP3.Id)
            ORDER BY Shared_Solar_System__r.Name
        ];
        List<Transfer__c> trfList = [
            SELECT Id, Client_Account__c
            FROM Transfer__c
            WHERE (Id = : transferP1.Id OR Id = : transferP3.Id)
            ORDER BY Shared_Solar_System__r.Name
        ];

        System.assertEquals(sssList[0].Client_Account__c,prodList[0].Client_Account__c);
        System.assertEquals(sssList[1].Client_Account__c,prodList[1].Client_Account__c);
        System.assertEquals(sssList[0].Client_Account__c,bpList[0].Client_Account__c);
        System.assertEquals(sssList[1].Client_Account__c,bpList[1].Client_Account__c);
        System.assertEquals(sssList[0].Client_Account__c,trfList[0].Client_Account__c);
        System.assertEquals(sssList[1].Client_Account__c,trfList[1].Client_Account__c);
    }
    @IsTest
    public static void testExternallyServicedAdjustment() {
        Transfer__c transfer = [
            SELECT Id, Name, Shared_Solar_System__c, Allocation_Schedule__c, Attempted_Transfer__c, Bill_Period__c,
                Bill_Period__r.Bill_Date__c, Default_Credit_Value__c, Bills_Generated__c, Total_kWh_Transferred__c,
                Total_Transferred__c, Transfer_Amount__c, Transfer_kWh__c, Transfer_Type__c, Date_of_Transfer__c
            FROM Transfer__c
            WHERE Bill_Period__r.Name = 'sssA - March 2016'
            LIMIT 1
        ];
        Utility_Account_Subscription__c uas = [
            SELECT Id, Opportunity__r.Shared_Solar_System__c, Opportunity__r.AccountId,
                Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000239'
        ];
        Opportunity opp = [
            SELECT Id, Customer_Group__c
            FROM Opportunity
            WHERE Id = :uas.Opportunity__c
            LIMIT 1
        ];
        Shared_Solar_System__c sss = [
            SELECT Id, Billing_Anchors__c
            FROM Shared_Solar_System__c
            WHERE Id = :uas.Opportunity__r.Shared_Solar_System__c
            LIMIT 1
        ];
        sss.Billing_Anchors__c = 'RadianGen';
        update sss;
        opp.Customer_Group__c = 'Anchor';
        update opp;
        Bill_Adjustment__c adjustment = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment',
            Utility_Account_Subscription__c = uas.Id,
            Account__c = uas.Opportunity__r.AccountId,
            Transfer__c = transfer.Id,
            Adjustment_Type__c = 'Production',
            Adjustment_Amount__c = 24,
            Credits_Allocated__c = 24,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Client Owner Test'
        );
        insert adjustment;
        Bill_Adjustment__c billAdjustment = [
            SELECT Id, Externally_Serviced__c
            FROM Bill_Adjustment__c
            WHERE Id = :adjustment.Id
        ];
        System.assertEquals(true, billAdjustment.Externally_Serviced__c);
    }
    @IsTest
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
            Accounting_Score__c = 10,
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
            Accounting_Score__c = 8,
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
            SELECT Id, Name,
                Accounting_Score__c,
                Customer_DSO__c,
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
        System.assertEquals(5.16, reportList[2].Client_Health_Score__c);
    }
    @IsTest
    public static void testClientUAS() {
        Utility_Account_Log__c ual = [SELECT Id FROM Utility_Account_Log__c LIMIT 1];
        Opportunity opp = [SELECT Id, Name, Shared_Solar_System__c, Shared_Solar_System__r.Name, NMC_Tariff__c
        FROM Opportunity LIMIT 1];
        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = '123456',
            Utility_Account_Log__c = ual.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Sizing_Method__c = opp.NMC_Tariff__c,
            Opportunity__c = opp.Id,
            Subscribed_Annual_Cost_of_Electricity__c = 300,
            calculated_annual_cost_of_electricity__c = 300);
        insert uas;
        Test.startTest();
        List<Client_Utility_Account_Subscription__c> clientUAS = ClientReportObjectSelector.getClientUASesByUASIds(new Set<Id>{uas.Id});
        System.assertEquals(opp.Name, clientUAS[0].Customer__c);
        System.assertEquals(300, clientUAS[0].Annual_Cost_of_Electricity_Future__c);
        System.assertEquals(opp.Shared_Solar_System__c, clientUAS[0].Shared_Solar_System__c);
        //Test an update to parent UAS
        FeatureService featureService = new FeatureService();
        if (featureService.isEnabled('Subscription_Orders')) {
            //SUBSCRIPTION ORDER FEATURE ON
            Subscription_Order__c soResize = new Subscription_Order__c(
                Utility_Account_Subscription__c = uas.Id,
                Type__c = 'Resize',
                New_Annual_Cost__c = 500,
                Approval_Status__c = 'Approved',
                Effective_Date__c = System.now()
            );
            insert soResize;
        } else {
            //SUBSCRIPTION ORDER FEATURE OFF
            uas.Subscribed_Annual_Cost_of_Electricity__c = 500;
            update uas;
        }
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
        Test.stopTest();
        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Shared_Solar_System_Name__c, Shared_Solar_System__r.Name, Next_Schedule_Z_Status__c, Subscription_Comment_c__c
            FROM Utility_Account_Subscription__c
            WHERE Name = :uas.Name
        ];
        Set<Id> uasIds = new Set<Id>();
        for (Utility_Account_Subscription__c uasUpdate : uasList) {
            uasIds.add(uasUpdate.Id);
        }
        List<Client_Utility_Account_Subscription__c> clientUASUpdate2 = ClientReportObjectSelector.getClientUASesByUASIds(uasIds);
        for (Client_Utility_Account_Subscription__c cuas : clientUASUpdate2) {
            System.assertEquals(cuas.Utility_Account_Subscription__r.Shared_Solar_System_Name__c, cuas.Shared_Solar_System__r.Name);
            if (cuas.Utility_Account_Subscription__r.Next_Schedule_Z_Status__c == 'Active Subscription') {
                System.assertEquals(sss2.Id, cuas.Shared_Solar_System__c);
                System.assertEquals(500, clientUASUpdate[0].Annual_Cost_of_Electricity_Future__c);
            } else {
                //When Subscription Order Feature flag is ON, original UAS is marked as "Inactive" and zeroed out
                System.assertNotEquals(sss2.Id, cuas.Shared_Solar_System__c);
                System.assertEquals(0, cuas.Annual_Cost_of_Electricity_Future__c);
            }
        }
        //Test deletion of parent UAS
        delete uas;
        List<Client_Utility_Account_Subscription__c> clientUASDelete = ClientReportObjectSelector.getClientUASesByUASIds(new Set<Id>{uas.Id});
        System.assertEquals(0, clientUASDelete.size());
    }

    @IsTest
    public static void testClientUASOppChange() {
        Utility_Account_Log__c ual = [SELECT Id FROM Utility_Account_Log__c LIMIT 1];
        List<Opportunity> opps = [SELECT Id, Name, Shared_Solar_System__c, Shared_Solar_System__r.Name, NMC_Tariff__c
        FROM Opportunity LIMIT 2];
        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = '123456',
            Utility_Account_Log__c = ual.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Sizing_Method__c = opps[0].NMC_Tariff__c,
            Opportunity__c = opps[0].Id,
            Subscribed_Annual_Cost_of_Electricity__c = 300,
            calculated_annual_cost_of_electricity__c = 300);
        insert uas;
        Test.startTest();
        List<Client_Utility_Account_Subscription__c> clientUAS = ClientReportObjectSelector.getClientUASesByUASIds(new Set<Id>{uas.Id});
        System.assertEquals(opps[0].Name, clientUAS[0].Customer__c);
        System.assertEquals(300, clientUAS[0].Annual_Cost_of_Electricity_Future__c);
        System.assertEquals(opps[0].Shared_Solar_System__c, clientUAS[0].Shared_Solar_System__c);

        Shared_Solar_System__c sss2 = [
            SELECT Id, Name
            FROM Shared_Solar_System__c
            WHERE Id != :opps[1].Shared_Solar_System__c
            LIMIT 1
        ];
        opps[1].Shared_Solar_System__c = sss2.Id;
        update opps[1];

        //Test update of UASes Opportunity
        uas.Opportunity__c = opps[1].Id;
        update uas;
        Test.stopTest();
        List<Client_Utility_Account_Subscription__c> clientUASUpdate = ClientReportObjectSelector.getClientUASesByUASIds(new Set<Id>{uas.Id});
        System.assertEquals(sss2.Id, clientUASUpdate[0].Shared_Solar_System__c);
    }
    @IsTest
    public static void testClientALSS() {
        Utility_Account_Log__c ual = [SELECT Id FROM Utility_Account_Log__c LIMIT 1];
        Opportunity opp = [SELECT Id, Shared_Solar_System__c, NMC_Tariff__c FROM Opportunity LIMIT 1];
        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = '123456',
            Utility_Account_Log__c = ual.Id,
            Opportunity__c = opp.Id,
            Sizing_Method__c = opp.NMC_Tariff__c,
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

    private static void useMocks() {
        UtilityAccountSubscriptionHandler.partnerCommissionHandler = (PartnerCommissionHandler) Test.createStub(PartnerCommissionHandler.class, new PartnerCommissionHandlerTest.MockPartnerCommissionHandler());
    }
}