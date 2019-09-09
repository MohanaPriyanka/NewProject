@isTest
public class ProductEscalationTest {
    @testSetup public static void testSetupBillRecords() {
        Test.startTest();
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 6
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 6
        );

        insert new List<Utility__c>{eversource, nationalGrid};

        Load_U__c everLZU = new Load_U__c(
            Name = '02633',
            LZ__c = 'SEMA',
            Town__c = 'Medfield');

        Load_U__c ngridLZU = new Load_U__c(
            Name = '01570',
            LZ__c = 'WCMA',
            Town__c = 'Westtown');

        insert new List<Load_U__c>{
            everLZU, ngridLZU
        };

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU.Id,
            Utility__c = eversource.Id
        );
        ZipCode_Utility_Junction__c junctionTwo = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = ngridLZU.Id,
            Utility__c = nationalGrid.Id
        );
        insert new List<ZipCode_Utility_Junction__c>{junction, junctionTwo};

        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c(
            Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Current_Billing_Rate__c = TRUE);

        Utility_NMC_Tariff__c ngridbillNMC = new Utility_NMC_Tariff__c(
            Name = 'National Grid WCMA Class 2 Billing Rate',
            Utility__c = 'National Grid',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Current_Billing_Rate__c = TRUE);

        Utility_NMC_Tariff__c ngridsizeNMC = new Utility_NMC_Tariff__c(
            Name = 'National Grid WCMA Class 2 Sizing Rate',
            Utility__c = 'National Grid',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = TRUE);

        insert new List<Utility_NMC_Tariff__c>{
            everbillNMC, ngridsizeNMC, ngridbillNMC
        };

        Product2 normalCSProduct = new Product2(
            Name = 'Test ProductEscalationTest',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            Solar_Electricity_Rate__c = 0.14,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Pricing_Structure__c = 'Use Solar Electric Rate',
            Monthly_Late_Fee__c = 1);
        insert new List<Product2>{
            normalCSProduct
        };

        Account clientAccount = new Account(name = 'Test Client');
        insert clientAccount;

        Contact clientContact = new Contact(AccountId = clientAccount.Id, FirstName = 'Test', LastName = 'Client');
        insert clientContact;

        ChargentBase__Gateway__c chGateway =
            new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                ChargentBase__Merchant_ID__c = '235986',
                ChargentBase__Debug__c = True,
                ChargentBase__Available_Payment_Methods__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
                ChargentBase__Active__c = TRUE);
        insert chGateway;

        Entity__c entity1 = new Entity__c(
            Name = 'Project A Oak Road',
            Client_Account__c = clientAccount.Id,
            Gateway__c = chGateway.Id);
        insert entity1;

        Entity__c entity2 = new Entity__c(
            Name = 'Project B Main St',
            Client_Account__c = clientAccount.Id,
            Gateway__c = chGateway.Id);
        insert entity2;

        Shared_Solar_System__c sss1 =
            new Shared_Solar_System__c(Name = 'Project A Oak Road',
                Service_Territory__c = 'SEMA',
                Open__c = true,
                Client_Account__c = clientAccount.Id,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c = 996,
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '1',
                Billing_Method__c = 'NMC',
                Utility_NMC_Tariff__c = everbillNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Product__c = normalCSProduct.Id,
                Sales_Partners__c = 'All',
                BWC_Project_Entity_Manual__c = entity1.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id);

        Shared_Solar_System__c sss2 =
            new Shared_Solar_System__c(Name = 'Project B Main St',
                Service_Territory__c = 'SEMA',
                Open__c = true,
                Client_Account__c = clientAccount.Id,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c = 996,
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '2',
                Utility_NMC_Tariff__c = everbillNMC.Id,
                Billing_Method__c = 'NMC',
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Product__c = normalCSProduct.Id,
                Sales_Partners__c = 'All',
                BWC_Project_Entity_Manual__c = entity2.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id);

        insert new List<Shared_Solar_System__c>{sss1, sss2};

        TestFactory.insertBWAddress();
        TestFactory.setCSBillSettings();

        String firstName1 = 'acA';
        String firstName2 = 'acB';
        String firstName3 = 'acC';

        String lastName1 = 'A';
        String lastName2 = 'B';
        String lastName3 = 'C';

        String accountName1 = firstName1 + ' ' + lastname1;
        String accountName2 = firstName2 + ' ' + lastname2;
        String accountName3 = firstName3 + ' ' + lastname3;

        Account accountParent1 = new Account(Name = accountName1);
        Account accountParent2 = new Account(Name = accountName2);
        Account accountParent3 = new Account(Name = accountName3);

        insert new List<Account>{
            accountParent1, accountParent2, accountParent3
        };

        Contact contact1 = new Contact(
            FirstName = firstName1,
            LastName = lastname1,
            AccountId = accountParent1.Id);
        Contact contact2 = new Contact(
            FirstName = firstName2,
            LastName = lastname2,
            AccountId = accountParent2.Id);
        Contact contact3 = new Contact(
            FirstName = firstName3,
            LastName = lastname3,
            AccountId = accountParent3.Id);

        insert new List<Contact>{
            contact1, contact2, contact3
        };

        Account propAccount1 = new Account(
            name = accountName1,
            Parent_Account__c = accountParent1.Id,
            Send_Bills_Contact__c = contact1.Id);
        Account propAccount2 = new Account(
            name = accountName2,
            Parent_Account__c = accountParent2.Id,
            Send_Bills_Contact__c = contact2.Id);
        Account propAccount3 = new Account(
            name = accountName3,
            Parent_Account__c = accountParent3.Id,
            Send_Bills_Contact__c = contact3.Id);

        insert new List<Account>{
            propAccount1, propAccount2, propAccount3
        };

        Utility_Account_Log__c ualog1 = new Utility_Account_Log__c(
            Name = '0000234',
            Account__c = propAccount1.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = accountName1);
        Utility_Account_Log__c ualog2 = new Utility_Account_Log__c(
            Name = '0000235',
            Account__c = propAccount2.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = accountName2);
        Utility_Account_Log__c ualog3 = new Utility_Account_Log__c(
            Name = '0000236',
            Account__c = propAccount3.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = accountName3);
        Utility_Account_Log__c ualog4 = new Utility_Account_Log__c(
            Name = '0000243',
            Account__c = propAccount3.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = accountName3);

        insert new List<Utility_Account_Log__c>{
            ualog1, ualog2, ualog3, ualog4
        };

        Opportunity opportunity1 = new Opportunity(
            Name = accountName1 + '_SSS1',
            AccountId = propAccount1.Id,
            Shared_Solar_System__c = sss1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity2 = new Opportunity(
            Name = accountName2 + '_SSS1',
            AccountId = propAccount2.Id,
            Shared_Solar_System__c = sss1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity3 = new Opportunity(
            Name = accountName2 + '_SSS2',
            AccountId = propAccount2.Id,
            Shared_Solar_System__c = sss2.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity4 = new Opportunity(
            Name = accountName3 + '_SSS1',
            AccountId = propAccount3.Id,
            Shared_Solar_System__c = sss1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity5 = new Opportunity(
            Name = accountName3 + '_SSS2',
            AccountId = propAccount3.Id,
            Shared_Solar_System__c = sss2.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity6 = new Opportunity(
            Name = accountName3 + '_B_SSS1',
            AccountId = propAccount3.Id,
            Shared_Solar_System__c = sss1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());

        insert new List<Opportunity>{
            opportunity1, opportunity2, opportunity3, opportunity4, opportunity5, opportunity6
        };

        Utility_Account_Subscription__c uas1 = new Utility_Account_Subscription__c(
            Name = '0000234',
            Utility_Account_Log__c = ualog1.Id,
            Opportunity__c = opportunity1.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 10);
        Utility_Account_Subscription__c uas2 = new Utility_Account_Subscription__c(
            Name = '0000235',
            Utility_Account_Log__c = ualog2.Id,
            Opportunity__c = opportunity2.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 10);
        Utility_Account_Subscription__c uas3 = new Utility_Account_Subscription__c(
            Name = '0000235',
            Utility_Account_Log__c = ualog2.Id,
            Opportunity__c = opportunity3.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 10);
        Utility_Account_Subscription__c uas4 = new Utility_Account_Subscription__c(
            Name = '0000236',
            Utility_Account_Log__c = ualog3.Id,
            Opportunity__c = opportunity4.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 10);
        Utility_Account_Subscription__c uas5 = new Utility_Account_Subscription__c(
            Name = '0000236',
            Utility_Account_Log__c = ualog3.Id,
            Opportunity__c = opportunity5.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 10);
        Utility_Account_Subscription__c uas6 = new Utility_Account_Subscription__c(
            Name = '0000243',
            Utility_Account_Log__c = ualog4.Id,
            Opportunity__c = opportunity6.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 10);

        insert new List<Utility_Account_Subscription__c>{
            uas1, uas2, uas3, uas4, uas5, uas6
        };

        Schedule_Z__c schZOne = new Schedule_Z__c(
            Name = '18-0515 Project A Oak Rd',
            Shared_Solar_System__c = sss1.Id,
            Status__c = 'Billing'
        );

        Schedule_Z__c schZTwo = new Schedule_Z__c(
            Name = '18-0515 Project B Main St',
            Shared_Solar_System__c = sss2.Id,
            Status__c = 'Billing'
        );

        insert new List<Schedule_Z__c>{schZOne, schZTwo};
        Date todaysDate = Date.today();
        Date oneMonthAgo = todaysDate.addMonths(-1);
        Date oneMonthInFuture = todaysDate.addMonths(1);

        Energy_Usage_Update__c firstProdUpdateSSS1 = new Energy_Usage_Update__c (
            Name = 'sssA - August 2016',
            Shared_Solar_System__c = sss1.Id,
            Production__c = 81869.00,
            Due_Date__c = todaysDate,
            Net_Metering_Rate_Applied__c = 0.13,
            Billing_Period_Start_Date__c = oneMonthInFuture,
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 13483.66,
            Date__c = oneMonthAgo,
            Schedule_Z__c = schZOne.Id
        );

        insert firstProdUpdateSSS1;

        Energy_Usage_Update__c firstProdUpdateSSS2 = new Energy_Usage_Update__c (
            Name = 'sssB - August 2016',
            Shared_Solar_System__c = sss2.Id,
            Production__c = 367918.00,
            Due_Date__c = todaysDate,
            Net_Metering_Rate_Applied__c = 0.13,
            Billing_Period_Start_Date__c = oneMonthInFuture,
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 40983.43,
            Total_System_NMCs_2_of_4__c = 20000,
            Net_Metering_Rate_Applied_2_of_4__c = 0.13,
            Production_kWh_2_of_4__c = 153846,
            Date__c = oneMonthAgo,
            Schedule_Z__c = schZTwo.Id
        );

        insert firstProdUpdateSSS2;
        Test.stopTest();
    }

    public static void setEscalator(Product_Escalation_Schedule__c schedule) {
        List<Opportunity> oppList = [
            SELECT Id, Product_Escalation_Schedule__c
            FROM Opportunity
        ];

        for (Opportunity opp : oppList){
            opp.Product_Escalation_Schedule__c = schedule.Id;
        }

        update oppList;
    }

    public static void insertOldProductionUpdates() {
        Date todaysDate = Date.today();

        List<Schedule_Z__c> schZList = [
            SELECT Id, Name, Shared_Solar_System__c, Shared_Solar_System__r.Id
            FROM Schedule_Z__c
            WHERE Name = '18-0515 Project A Oak Rd' OR Name = '18-0515 Project B Main St'
            ORDER BY Shared_Solar_System__r.Name
        ];

        Energy_Usage_Update__c prodUpdateA1 = new Energy_Usage_Update__c (
            Name = 'sssA - August 2016',
            Shared_Solar_System__c = schZList[0].Shared_Solar_System__r.Id,
            Production__c = 81869.00,
            Due_Date__c = todaysDate,
            Net_Metering_Rate_Applied__c = 0.13,
            Billing_Period_Start_Date__c = todaysDate.addMonths(-4),
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 13483.66,
            Date__c = todaysDate.addMonths(-4),
            Schedule_Z__c = schZList[0].Id,
            Generate_Bills__c = true
        );

        Energy_Usage_Update__c prodUpdateB1 = new Energy_Usage_Update__c (
            Name = 'sssB - August 2016',
            Shared_Solar_System__c = schZList[1].Shared_Solar_System__r.Id,
            Production__c = 367918.00,
            Due_Date__c = todaysDate,
            Net_Metering_Rate_Applied__c = 0.13,
            Billing_Period_Start_Date__c = todaysDate.addMonths(-4),
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 40983.43,
            Total_System_NMCs_2_of_4__c = 20000,
            Net_Metering_Rate_Applied_2_of_4__c = 0.13,
            Production_kWh_2_of_4__c = 153846,
            Date__c = todaysDate.addMonths(-4),
            Schedule_Z__c = schZList[1].Id,
            Generate_Bills__c = true
        );

        Energy_Usage_Update__c prodUpdateA2 = new Energy_Usage_Update__c (
            Name = 'sssA - August 2016',
            Shared_Solar_System__c = schZList[0].Shared_Solar_System__r.Id,
            Production__c = 81869.00,
            Due_Date__c = todaysDate,
            Net_Metering_Rate_Applied__c = 0.13,
            Billing_Period_Start_Date__c = todaysDate.addMonths(-3),
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 13483.66,
            Date__c =  todaysDate.addMonths(-3),
            Schedule_Z__c = schZList[0].Id,
            Generate_Bills__c = true
        );

        Energy_Usage_Update__c prodUpdateB2 = new Energy_Usage_Update__c (
            Name = 'sssB - August 2016',
            Shared_Solar_System__c = schZList[1].Shared_Solar_System__r.Id,
            Production__c = 367918.00,
            Due_Date__c = todaysDate,
            Net_Metering_Rate_Applied__c = 0.13,
            Billing_Period_Start_Date__c = todaysDate.addMonths(-3),
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 40983.43,
            Total_System_NMCs_2_of_4__c = 20000,
            Net_Metering_Rate_Applied_2_of_4__c = 0.13,
            Production_kWh_2_of_4__c = 153846,
            Date__c = todaysDate.addMonths(-3),
            Schedule_Z__c = schZList[1].Id,
            Generate_Bills__c = true
        );

        Energy_Usage_Update__c prodUpdateA3 = new Energy_Usage_Update__c (
            Name = 'sssA - August 2016',
            Shared_Solar_System__c = schZList[0].Shared_Solar_System__r.Id,
            Production__c = 81869.00,
            Due_Date__c = todaysDate,
            Net_Metering_Rate_Applied__c = 0.13,
            Billing_Period_Start_Date__c = todaysDate.addMonths(-2),
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 13483.66,
            Date__c = todaysDate.addMonths(-2),
            Schedule_Z__c = schZList[0].Id,
            Generate_Bills__c = true
        );

        Energy_Usage_Update__c prodUpdateB3 = new Energy_Usage_Update__c (
            Name = 'sssB - August 2016',
            Shared_Solar_System__c = schZList[1].Shared_Solar_System__r.Id,
            Production__c = 367918.00,
            Due_Date__c = todaysDate,
            Net_Metering_Rate_Applied__c = 0.13,
            Billing_Period_Start_Date__c = todaysDate.addMonths(-2),
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 40983.43,
            Total_System_NMCs_2_of_4__c = 20000,
            Net_Metering_Rate_Applied_2_of_4__c = 0.13,
            Production_kWh_2_of_4__c = 153846,
            Date__c = todaysDate.addMonths(-2),
            Schedule_Z__c = schZList[1].Id,
            Generate_Bills__c = true
        );

        insert new List<Energy_Usage_Update__c> {
            prodUpdateA1, prodUpdateB1, prodUpdateA2, prodUpdateB2, prodUpdateA3, prodUpdateB3
        };
    }

    public static void switchProductToPercentDiscount(){
        Product2 productToUpdate = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test ProductEscalationTest'
            LIMIT 1
        ];

        productToUpdate.NMC_Discount__c = 10;
        productToUpdate.Pricing_Structure__c = 'Fixed % Discount';
        update productToUpdate;
    }

    public static void runOneMonthsBills() {
        Date todaysDate = Date.today();
        Date oneMonthAgo = todaysDate.addMonths(-1);

        List<Energy_Usage_Update__c> trigProdUp;
        trigProdUp = ProductionUpdateSelector.getProductionUpdatesByMonth(oneMonthAgo.Month(), String.valueOf(oneMonthAgo.Year()));
        EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(trigProdUp);
        ee.runBills();
        TestBillCreationandPayment.setBillsToPublished();
    }

    @IsTest public static void percentDiscountNoEscalator() {
        switchProductToPercentDiscount();
        insertOldProductionUpdates();
        runOneMonthsBills();
        Map<String, System_Bill__c> sbMap = TestBillCreationForCancelledCustomers.queryForBills();

        /* All UASes are 10 kW for consistency:
            ~(sss1) NMCs = 93.26 Discount = 10% Bill = 83.93
            ~(sss2 ) NMCs = 283.45 Discount = 10% Bill = 255.11
            ~(sss2 2nd transfer) NMCs = 138.33 Discount = 10% Bill = 124.49
        */

        System.assertEquals(6,sbMap.values().size());
        System.assertEquals(83.93,sbMap.get('acA A_SSS1_1').Due_This_Month__c);
        System.assertEquals(83.93,sbMap.get('acB B_SSS1_1').Due_This_Month__c);
        System.assertEquals(379.61,sbMap.get('acB B_SSS2_1').Due_This_Month__c);
        System.assertEquals(83.93,sbMap.get('acC C_SSS1_1').Due_This_Month__c);
        System.assertEquals(379.61,sbMap.get('acC C_SSS2_1').Due_This_Month__c);
        System.assertEquals(83.93,sbMap.get('acC C_B_SSS1_1').Due_This_Month__c);
    }

    @IsTest public static void percentDiscountWithEscalator() {
        switchProductToPercentDiscount();
        insertOldProductionUpdates();

        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Name, Count_of_Transfers__c
            FROM Shared_Solar_System__c
        ];

        System.assertEquals(2, sssList.size());
        System.assertEquals(3, sssList[0].Count_of_Transfers__c);
        System.assertEquals(6, sssList[1].Count_of_Transfers__c);

        Product_Escalation_Schedule__c newSchedule = new Product_Escalation_Schedule__c (
            Name = 'Product Escalator: 100% Discount First 4 Transfers'
        );
        insert newSchedule;

        Product_Escalator__c escalatorOne = new Product_Escalator__c (
            Product_Escalation_Schedule__c = newSchedule.Id,
            Starting_Credit_Transfer__c = 1,
            New_NMC_Discount__c = 100
        );
        Product_Escalator__c escalatorTwo = new Product_Escalator__c (
            Product_Escalation_Schedule__c = newSchedule.Id,
            Starting_Credit_Transfer__c = 5,
            New_NMC_Discount__c = 10
        );
        insert new List<Product_Escalator__c>{escalatorOne, escalatorTwo};

        setEscalator(newSchedule);

        Test.startTest();
        runOneMonthsBills();
        Test.stopTest();

        /* All UASes are 10 kW for consistency:
            ~(sss1) NMCs = 93.26 Discount = 10% Bill = 83.93 (transfer #4)
            ~(sss2 ) NMCs = 283.45 Discount = 10% Bill = 255.11 (transfer #7)
            ~(sss2 2nd transfer) NMCs = 138.33 Discount = 10% Bill = 124.50 (transfer #8)
        */

        for (UASB__c uasb : [
            SELECT Utility_Account_Subscription__r.Name, Shared_Solar_System__c,
                Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
                Utility_Account_Subscription__r.Share_of_System__c,
                Production_Update__r.Name, Credits_on_Bill_Period__c,
                Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
                Net_Metering_Credits_Allocated__c, Discounted_Bill__c,
                Subscription_Production_kWh__c, System_Bill__r.Opportunity__r.Name,
                Shared_Solar_System__r.Name, Solar_Electricity_Rate__c,
                Solar_Share_Rate_Bill_Value__c, Subscription_Production_kWh_Static__c,
                NMC_Discount__c, Bill_Value__c
            FROM UASB__c]){
            if (uasb.Shared_Solar_System__r.Name == 'Project A Oak Road'){
                System.assertEquals(100, uasb.NMC_Discount__c);
                System.assertEquals(0, uasb.Bill_Value__c);
                System.assertEquals(566.23, uasb.Subscription_Production_kWh_Static__c);
            } else if ( uasb.Shared_Solar_System__r.Name == 'Project B Main St'
                && uasb.Subscription_Production_kWh_Static__c == 1064.05){
                System.assertEquals(10, uasb.NMC_Discount__c);
                System.assertEquals(124.50, uasb.Bill_Value__c);
                System.assertEquals(1064.05, uasb.Subscription_Production_kWh_Static__c);
            } else if ( uasb.Shared_Solar_System__r.Name == 'Project B Main St'
                && uasb.Subscription_Production_kWh_Static__c != 1064.05){
                System.assertEquals(10, uasb.NMC_Discount__c);
                System.assertEquals(255.11, uasb.Bill_Value__c);
                System.assertEquals(2544.63, uasb.Subscription_Production_kWh_Static__c);
            } else {
                // Do not expect to hit this:
                System.assert(false);
            }
        }

        Map<String, System_Bill__c> sbMap = TestBillCreationForCancelledCustomers.queryForBills();

        System.assertEquals(6,sbMap.values().size());
        System.assertEquals(0,sbMap.get('acA A_SSS1_1').Due_This_Month__c);
        System.assertEquals(0,sbMap.get('acB B_SSS1_1').Due_This_Month__c);
        System.assertEquals(379.61,sbMap.get('acB B_SSS2_1').Due_This_Month__c);
        System.assertEquals(0,sbMap.get('acC C_SSS1_1').Due_This_Month__c);
        System.assertEquals(379.61,sbMap.get('acC C_SSS2_1').Due_This_Month__c);
        System.assertEquals(0,sbMap.get('acC C_B_SSS1_1').Due_This_Month__c);
    }

    @IsTest public static void solarElectricRateNoEscalator() {
        insertOldProductionUpdates();
        runOneMonthsBills();
        Map<String, System_Bill__c> sbMap = TestBillCreationForCancelledCustomers.queryForBills();

        /* All UASes are 10 kW for consistency:
            (sss1) Kwh = 566.23, SEE = 0.14, Bill = 79.27
            (sss2 ) Kwh = 1064.05, SEE = 0.14, Bill = 148.97
            (sss2 2nd transfer) Kwh = 2544.63, SEE = 0.14, Bill = 356.25
        */

        System.assertEquals(6,sbMap.values().size());
        System.assertEquals(79.27,sbMap.get('acA A_SSS1_1').Due_This_Month__c);
        System.assertEquals(79.27,sbMap.get('acB B_SSS1_1').Due_This_Month__c);
        System.assertEquals(505.22,sbMap.get('acB B_SSS2_1').Due_This_Month__c);
        System.assertEquals(79.27,sbMap.get('acC C_SSS1_1').Due_This_Month__c);
        System.assertEquals(505.22,sbMap.get('acC C_SSS2_1').Due_This_Month__c);
        System.assertEquals(79.27,sbMap.get('acC C_B_SSS1_1').Due_This_Month__c);
    }

    @IsTest public static void solarElectricRateWithEscalator() {
        insertOldProductionUpdates();

        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Name, Count_of_Transfers__c
            FROM Shared_Solar_System__c
        ];

        System.assertEquals(2, sssList.size());
        System.assertEquals(3, sssList[0].Count_of_Transfers__c);
        System.assertEquals(6, sssList[1].Count_of_Transfers__c);

        Product_Escalation_Schedule__c newSchedule = ProductService.createEscalationSchedule(0.03, 0.14, 20, 2);

        System.assertEquals(4,newSchedule.Product_Escalators__r[2].Starting_Credit_Transfer__c);
        System.assertEquals(6,newSchedule.Product_Escalators__r[3].Starting_Credit_Transfer__c);
        System.assertEquals(8,newSchedule.Product_Escalators__r[4].Starting_Credit_Transfer__c);
        System.assertEquals(0.1485,newSchedule.Product_Escalators__r[2].New_Solar_Electricity_Rate__c);
        System.assertEquals(0.1530,newSchedule.Product_Escalators__r[3].New_Solar_Electricity_Rate__c);
        System.assertEquals(0.1576,newSchedule.Product_Escalators__r[4].New_Solar_Electricity_Rate__c);

        setEscalator(newSchedule);

        Test.startTest();
        runOneMonthsBills();
        Test.stopTest();

        /* All UASes are 10 kW for consistency:
            (sss1) Kwh = 566.23, SEE = 0.1485, Bill = 84.09 (transfer #4)
            (sss2) Kwh = 2544.63, SEE = 0.1576, Bill = 356.25 (transfer #7)
            (sss2 2nd transfer) Kwh = 1064.05, SEE = 0.1530, Bill = 167.69 (transfer #8)
        */

        for (UASB__c uasb : [
            SELECT Utility_Account_Subscription__r.Name, Shared_Solar_System__c,
                Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
                Utility_Account_Subscription__r.Share_of_System__c,
                Production_Update__r.Name, Credits_on_Bill_Period__c,
                Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
                Net_Metering_Credits_Allocated__c, Discounted_Bill__c,
                Subscription_Production_kWh__c, System_Bill__r.Opportunity__r.Name,
                Shared_Solar_System__r.Name, Solar_Electricity_Rate__c,
                Solar_Share_Rate_Bill_Value__c, Subscription_Production_kWh_Static__c
            FROM UASB__c]){
                if (uasb.Shared_Solar_System__r.Name == 'Project A Oak Road'){
                    System.assertEquals(0.1485, uasb.Solar_Electricity_Rate__c);
                    System.assertEquals(84.09, uasb.Solar_Share_Rate_Bill_Value__c);
                    System.assertEquals(566.23, uasb.Subscription_Production_kWh_Static__c);
                } else if ( uasb.Shared_Solar_System__r.Name == 'Project B Main St'
                            && uasb.Subscription_Production_kWh_Static__c == 1064.05){
                    System.assertEquals(0.1576, uasb.Solar_Electricity_Rate__c);
                    System.assertEquals(167.69, uasb.Solar_Share_Rate_Bill_Value__c);
                    System.assertEquals(1064.05, uasb.Subscription_Production_kWh_Static__c);
                } else if ( uasb.Shared_Solar_System__r.Name == 'Project B Main St'
                            && uasb.Subscription_Production_kWh_Static__c != 1064.05){
                    System.assertEquals(0.1530, uasb.Solar_Electricity_Rate__c);
                    System.assertEquals(389.33, uasb.Solar_Share_Rate_Bill_Value__c);
                    System.assertEquals(2544.63, uasb.Subscription_Production_kWh_Static__c);
                } else {
                    // Do not expect to hit this:
                    System.assert(false);
                }
        }

        Map<String, System_Bill__c> sbMap = TestBillCreationForCancelledCustomers.queryForBills();

        System.assertEquals(6,sbMap.values().size());
        System.assertEquals(84.09,sbMap.get('acA A_SSS1_1').Due_This_Month__c);
        System.assertEquals(84.09,sbMap.get('acB B_SSS1_1').Due_This_Month__c);
        System.assertEquals(557.02,sbMap.get('acB B_SSS2_1').Due_This_Month__c);
        System.assertEquals(84.09,sbMap.get('acC C_SSS1_1').Due_This_Month__c);
        System.assertEquals(557.02,sbMap.get('acC C_SSS2_1').Due_This_Month__c);
        System.assertEquals(84.09,sbMap.get('acC C_B_SSS1_1').Due_This_Month__c);
    }
}