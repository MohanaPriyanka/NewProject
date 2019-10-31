@isTest
public class TestBillCreationForCancelledCustomers {
    @testSetup public static void testSetupBillRecords() {
        Test.startTest();
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
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
            Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
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
            Customer_Subscription_KW_DC_STATIC__c = 25);
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
            Customer_Subscription_KW_DC_STATIC__c = 11);
        Utility_Account_Subscription__c uas4 = new Utility_Account_Subscription__c(
            Name = '0000236',
            Utility_Account_Log__c = ualog3.Id,
            Opportunity__c = opportunity4.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 5);
        Utility_Account_Subscription__c uas5 = new Utility_Account_Subscription__c(
            Name = '0000236',
            Utility_Account_Log__c = ualog3.Id,
            Opportunity__c = opportunity5.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 20);
        Utility_Account_Subscription__c uas6 = new Utility_Account_Subscription__c(
            Name = '0000243',
            Utility_Account_Log__c = ualog4.Id,
            Opportunity__c = opportunity6.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 23);

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

        TestBillCreationandPayment.runProductionUpdate(new List<Id>{firstProdUpdateSSS1.Id, firstProdUpdateSSS2.Id});
        setBillsToPublished();
        CustomerCommunicationHandlerTest.mockZuoraFields();
        Test.stopTest();
    }

    public static void setBillsToPublished() {
        List <Account_Bill__c> listAccountBills = [
            SELECT Id, Published__c
            FROM Account_Bill__c
            WHERE Published__c = FALSE
        ];
        for (Account_Bill__c acctBill : listAccountBills) {
            acctBill.Published__c = True;
        }
        update listAccountBills;
    }

    public static void setCollectionsWindow (Integer monthsToGenerate){
        System_Properties__c propertyAlreadyInserted = [Select Id FROM System_Properties__c];
        delete propertyAlreadyInserted;

        System_Properties__c property = new System_Properties__c(
            Name = 'System',
            Days_Generate_Bills_for_Cancelled__c = monthsToGenerate,
            Minimum_Balance_Bills_for_Cancelled__c = 0);
        insert property;
    }

    public static void setOppToCancelled(List<String> oppIds) {
        List<Opportunity> listOpps = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id IN : oppIds
        ];
        for (Opportunity opp : listOpps) {
            opp.StageName = 'Cancelled';
        }
        update listOpps;
    }

    public static void runSecondMonthProductionUpdates() {
        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id
            FROM Shared_Solar_System__c
            ORDER BY Name DESC];

        Schedule_Z__c schZOne = new Schedule_Z__c(
            Name = '18-0515 Project A Oak Rd',
            Shared_Solar_System__c = sssList[0].Id,
            Status__c = 'Billing'
        );

        Schedule_Z__c schZTwo = new Schedule_Z__c(
            Name = '18-0515 Project B Main St',
            Shared_Solar_System__c = sssList[1].Id,
            Status__c = 'Billing'
        );

        insert new List<Schedule_Z__c>{schZOne, schZTwo};

        Date todaysDate = Date.today();
        Date oneMonthAgo = todaysDate.addMonths(-1);
        Date oneMonthInFuture = todaysDate.addMonths(1);

        Energy_Usage_Update__c secondProdUpdateSSS1 = new Energy_Usage_Update__c (
            Name = 'sssB - September 2016',
            Shared_Solar_System__c = sssList[0].Id,
            Production__c = 73072.00,
            Due_Date__c = oneMonthInFuture,
            Billing_Period_Start_Date__c = oneMonthAgo,
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 12033.73,
            Date__c = todaysDate,
            Schedule_Z__c =  schZOne.Id
        );
        insert secondProdUpdateSSS1;

        Energy_Usage_Update__c secondProdUpdateSSS2 = new Energy_Usage_Update__c (
            Name = 'sssA - September 2016',
            Shared_Solar_System__c = sssList[1].Id,
            Production__c = 73072.00,
            Due_Date__c = oneMonthInFuture,
            Billing_Period_Start_Date__c = oneMonthAgo,
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 12033.73,
            Date__c = todaysDate,
            Schedule_Z__c =  schZTwo.Id
        );

        insert secondProdUpdateSSS2;

        TestBillCreationandPayment.runProductionUpdate(new List<Id>{secondProdUpdateSSS1.Id, secondProdUpdateSSS2.Id});
    }

    public static void makePayment(String oppName, Integer billNumber){
        // Mocks making a payment because consumes too many SOQL queries to insert Order & Transaction

        System_Bill__c sbToPay = [
            SELECT Id, Name,
                Total_Due__c, Total_Payments_This_Month__c,
                Carry_Over_Balance__c
            FROM System_Bill__c
            WHERE Opportunity__r.Name = : oppName
            AND Bill_Number__c = : billNumber
            LIMIT 1];

        sbToPay.Total_Payments_This_Month__c = sbToPay.Carry_Over_Balance__c;
        sbToPay.Payments_Net_Previous_Balances__c = sbToPay.Carry_Over_Balance__c;

        update sbToPay;
    }

    public static Map<String, System_Bill__c> queryForBills() {
        Map<String, System_Bill__c> sbMap = new Map<String, System_Bill__c>();

        for (System_Bill__c insertedSB : [
            SELECT Id, Name, Bill_Number__c, Opportunity__r.Name, Total_Payments_This_Month__c,
                Due_This_Month__c, Total_Due__c, Carry_Over_Balance__c, Balance_Net_Late_Payments__c, (
                SELECT Id, CS_Billing_Log__c, Net_Metering_Credits_Allocated__c, Savings__c
                FROM Utility_Account_Subscription_Bills__r
            )
            FROM System_Bill__c
            ORDER BY Opportunity__r.Name, Bill_Number__c]) {
            sbMap.put(insertedSB.Opportunity__r.Name + '_' + insertedSB.Bill_Number__c,insertedSB);
        }
        return sbMap;

        /* Expected key values:
            acAA has 1 UAL, 1 UAS (just SSS1)
            AccountBB has 1 UAL, 2 UAS (SSS1/SSS2)
            AccountCC has 2 UAL, 3 UAS (SSS1/SSS2 & SSS1)

            'acA A_SSS1_(Bill Number)
            'acB B_SSS1_(Bill Number)'
            'acB B_SSS2_(Bill Number)'
            'acC C_SSS2_(Bill Number)'
            'acC C_SSS2_(Bill Number)'
            'acC C_B_SSS2_(Bill Number)'
        */
    }

    // BASELINE: Run the same schedule z for 2 months
    @IsTest public static void baseLineNoChange() {

        Map<String, System_Bill__c> sbMap = queryForBills();

        List<UASB__c> uasbList = [SELECT Utility_Account_Subscription__r.Name, Shared_Solar_System__c,
            Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
            Utility_Account_Subscription__r.Share_of_System__c,
            Production_Update__r.Name, Credits_on_Bill_Period__c,
            Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
            Net_Metering_Credits_Allocated__c, Discounted_Bill__c,
            Subscription_Production_kWh__c, System_Bill__r.Opportunity__r.Name
        FROM UASB__c];

        System.assertEquals(6,sbMap.values().size());
        System.assertEquals(209.94,sbMap.get('acA A_SSS1_1').Due_This_Month__c);
        System.assertEquals(83.74,sbMap.get('acB B_SSS1_1').Due_This_Month__c);
        System.assertEquals(417.12,sbMap.get('acB B_SSS2_1').Due_This_Month__c);
        System.assertEquals(42.47,sbMap.get('acC C_SSS1_1').Due_This_Month__c);
        System.assertEquals(757.41,sbMap.get('acC C_SSS2_1').Due_This_Month__c);
        System.assertEquals(192.95,sbMap.get('acC C_B_SSS1_1').Due_This_Month__c);

        Test.startTest();
        runSecondMonthProductionUpdates();
        Test.stopTest();

        Map<String, System_Bill__c> sbMapTwo = queryForBills();
        System.assertEquals(12,sbMapTwo.values().size());
        System.assertEquals(397.30,sbMapTwo.get('acA A_SSS1_2').Total_Due__c); // DTM:187.36 + PMOB:209.94 = TD:397.30
        System.assertEquals(158.47,sbMapTwo.get('acB B_SSS1_2').Total_Due__c); // DTM:74.73 + PMOB:83.74 = TD:158.47
        System.assertEquals(499.43,sbMapTwo.get('acB B_SSS2_2').Total_Due__c); // DTM:82.31 + PMOB:417.12 = TD:499.43
        System.assertEquals(80.38,sbMapTwo.get('acC C_SSS1_2').Total_Due__c); // DTM:37.91 + PMOB:42.47 = TD:80.38
        System.assertEquals(906.87,sbMapTwo.get('acC C_SSS2_2').Total_Due__c); // DTM:149.46 + PMOB:757.41 = TD:906.87
        System.assertEquals(365.16,sbMapTwo.get('acC C_B_SSS1_2').Total_Due__c); // DTM:172.21 + PMOB:192.95 = TD:365.16
    }

    @IsTest public static void removalOutstandingBalance() {
        // 1 customer on 1 project is taken off schedule z
        // Should still have a system bill made because outstanding balance is > 0

        Test.startTest();

        Utility_Account_Subscription__c uasToDeactivate = [
            SELECT Id, Name, Opportunity__r.Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Name = 'acA A_SSS1'
            LIMIT 1];

        uasToDeactivate.Next_Schedule_Z_Status__c = 'Inactive Subscription';
        update uasToDeactivate;
        setOppToCancelled(new List<String>{uasToDeactivate.Opportunity__r.Id});
        runSecondMonthProductionUpdates();

        Test.stopTest();

        Map<String, System_Bill__c> sbMapTwo = queryForBills();
        System.assertEquals(12,sbMapTwo.values().size());
        System.assertEquals(0,sbMapTwo.get('acA A_SSS1_2').Due_This_Month__c);
        System.assertEquals(209.94,sbMapTwo.get('acA A_SSS1_2').Total_Due__c); // DTM:0 + PMOB:209.94 = TD:209.94
        System.assertEquals(158.47,sbMapTwo.get('acB B_SSS1_2').Total_Due__c); // DTM:74.73 + PMOB:83.74 = TD:158.47
        System.assertEquals(499.43,sbMapTwo.get('acB B_SSS2_2').Total_Due__c); // DTM:82.31 + PMOB:417.12 = TD:499.43
        System.assertEquals(80.38,sbMapTwo.get('acC C_SSS1_2').Total_Due__c); // DTM:37.91 + PMOB:42.47 = TD:80.38
        System.assertEquals(906.87,sbMapTwo.get('acC C_SSS2_2').Total_Due__c); // DTM:149.46 + PMOB:757.41 = TD:906.87
        System.assertEquals(365.16,sbMapTwo.get('acC C_B_SSS1_2').Total_Due__c); // DTM:172.21 + PMOB:192.95 = TD:365.16
    }

    @IsTest public static void removalZeroOutstandingBalance() {
        // 1 customer on 1 project is taken off schedule z
        // Should NOT have a system bill made because balance is paid off

        makePayment('acA A_SSS1', 1);

        Test.startTest();

        Utility_Account_Subscription__c uasToDeactivate = [
            SELECT Id, Name, Opportunity__r.Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Name = 'acA A_SSS1'
            LIMIT 1];

        uasToDeactivate.Next_Schedule_Z_Status__c = 'Inactive Subscription';
        update uasToDeactivate;
        setOppToCancelled(new List<String>{uasToDeactivate.Opportunity__r.Id});
        runSecondMonthProductionUpdates();

        Test.stopTest();

        Map<String, System_Bill__c> sbMapTwo = queryForBills();
        System.assertEquals(11,sbMapTwo.values().size());
        System.assertEquals(209.94,sbMapTwo.get('acA A_SSS1_1').Total_Due__c);
        System.assertEquals(209.94,sbMapTwo.get('acA A_SSS1_1').Total_Payments_This_Month__c);
        System.assertEquals(0,sbMapTwo.get('acA A_SSS1_1').Carry_Over_Balance__c);
        System.assertEquals(false,sbMapTwo.containsKey('acA A_SSS1_2'));
        System.assertEquals(158.47,sbMapTwo.get('acB B_SSS1_2').Total_Due__c); // DTM:74.73 + PMOB:83.74 = TD:158.47
        System.assertEquals(499.43,sbMapTwo.get('acB B_SSS2_2').Total_Due__c); // DTM:82.31 + PMOB:417.12 = TD:499.43
        System.assertEquals(80.38,sbMapTwo.get('acC C_SSS1_2').Total_Due__c); // DTM:37.91 + PMOB:42.47 = TD:80.38
        System.assertEquals(906.87,sbMapTwo.get('acC C_SSS2_2').Total_Due__c); // DTM:149.46 + PMOB:757.41 = TD:906.87
        System.assertEquals(365.16,sbMapTwo.get('acC C_B_SSS1_2').Total_Due__c); // DTM:172.21 + PMOB:192.95 = TD:365.16
    }

    @IsTest public static void removalOutstandingBalanceCrossSubscribed() {
        // 1 customer on 2 project is taken off both schedule zs
        // Should still have a system bill made because outstanding balance is > 0

        Test.startTest();
        List<Utility_Account_Subscription__c> uasList = new List<Utility_Account_Subscription__c>();
        for (Utility_Account_Subscription__c uasToDeactivate : [
            SELECT Id, Name, Opportunity__r.Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Name = 'acB B_SSS1'
            OR Opportunity__r.Name = 'acB B_SSS2'
            LIMIT 2
        ]) {
            uasToDeactivate.Next_Schedule_Z_Status__c = 'Inactive Subscription';
            uasList.add(uasToDeactivate);
        }
        update uasList;
        setOppToCancelled(new List<String>{uasList[0].Opportunity__r.Id, uasList[1].Opportunity__r.Id});
        runSecondMonthProductionUpdates();
        Test.stopTest();

        Map<String, System_Bill__c> sbMapTwo = queryForBills();
        System.assertEquals(12,sbMapTwo.values().size());
        System.assertEquals(397.30,sbMapTwo.get('acA A_SSS1_2').Total_Due__c); // DTM:187.36 + PMOB:209.94 = TD:397.30
        System.assertEquals(83.74,sbMapTwo.get('acB B_SSS1_2').Total_Due__c); // DTM:0 + PMOB:83.74 = TD:83.74
        checkUASBAndUABAssertions(sbMapTwo.get('acB B_SSS1_2'));
        System.assertEquals(417.12,sbMapTwo.get('acB B_SSS2_2').Total_Due__c); // DTM:0 + PMOB:417.12 = TD:417.12
        checkUASBAndUABAssertions(sbMapTwo.get('acB B_SSS2_2'));
        System.assertEquals(80.38,sbMapTwo.get('acC C_SSS1_2').Total_Due__c); // DTM:37.91 + PMOB:42.47 = TD:80.38
        System.assertEquals(906.87,sbMapTwo.get('acC C_SSS2_2').Total_Due__c); // DTM:149.46 + PMOB:757.41 = TD:906.87
        System.assertEquals(365.16,sbMapTwo.get('acC C_B_SSS1_2').Total_Due__c); // DTM:172.21 + PMOB:192.95 = TD:365.16
    }

    private static void checkUASBAndUABAssertions(System_Bill__c sb) {
        System.assertEquals(1, sb.Utility_Account_Subscription_Bills__r.size());
        System.assertEquals(0, sb.Utility_Account_Subscription_Bills__r[0].Net_Metering_Credits_Allocated__c);
        System.assertEquals(0, sb.Utility_Account_Subscription_Bills__r[0].Savings__c);
        System.assertNotEquals(null, sb.Utility_Account_Subscription_Bills__r[0].CS_Billing_Log__c);
    }

    @IsTest public static void removalZeroOutstandingBalanceCrossSubscribed() {
        // 1 customer on 2 project is taken off both schedule zs
        // but has only paid off 1 of 2 so should have 1 system bill

        makePayment('acB B_SSS1', 1);

        Test.startTest();
        List<Utility_Account_Subscription__c> uasList = new List<Utility_Account_Subscription__c>();
        for (Utility_Account_Subscription__c uasToDeactivate : [
            SELECT Id, Name, Opportunity__r.Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Name = 'acB B_SSS1'
            OR Opportunity__r.Name = 'acB B_SSS2'
            LIMIT 2
        ]) {
            uasToDeactivate.Next_Schedule_Z_Status__c = 'Inactive Subscription';
            uasList.add(uasToDeactivate);
        }
        update uasList;
        setOppToCancelled(new List<String>{uasList[0].Opportunity__r.Id, uasList[1].Opportunity__r.Id});
        runSecondMonthProductionUpdates();
        Test.stopTest();

        Map<String, System_Bill__c> sbMapTwo = queryForBills();
        System.assertEquals(11,sbMapTwo.values().size());
        System.assertEquals(83.74,sbMapTwo.get('acB B_SSS1_1').Total_Payments_This_Month__c);
        System.assertEquals(0,sbMapTwo.get('acB B_SSS1_1').Carry_Over_Balance__c);
        System.assertEquals(397.30,sbMapTwo.get('acA A_SSS1_2').Total_Due__c); // DTM:187.36 + PMOB:209.94 = TD:397.30
        System.assertEquals(false,sbMapTwo.containsKey('acB B_SSS1_2'));
        System.assertEquals(417.12,sbMapTwo.get('acB B_SSS2_2').Total_Due__c); // DTM:0 + PMOB:417.12 = TD:417.12
        System.assertEquals(80.38,sbMapTwo.get('acC C_SSS1_2').Total_Due__c); // DTM:37.91 + PMOB:42.47 = TD:80.38
        System.assertEquals(906.87,sbMapTwo.get('acC C_SSS2_2').Total_Due__c); // DTM:149.46 + PMOB:757.41 = TD:906.87
        System.assertEquals(365.16,sbMapTwo.get('acC C_B_SSS1_2').Total_Due__c); // DTM:172.21 + PMOB:192.95 = TD:365.16
    }

    @IsTest public static void changePeriodOfMonths(){
        // 1 customer on 2 project is taken off both schedule zs
        // Should have a system bill made because outstanding balance is > 0
        // BUT month window is set to 0, so that prevents it

        setCollectionsWindow(0);

        Test.startTest();

        Utility_Account_Subscription__c uasToDeactivate = [
            SELECT Id, Name, Opportunity__r.Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Name = 'acA A_SSS1'
            LIMIT 1];

        uasToDeactivate.Next_Schedule_Z_Status__c = 'Inactive Subscription';
        update uasToDeactivate;
        setOppToCancelled(new List<String>{uasToDeactivate.Opportunity__r.Id, uasToDeactivate.Opportunity__r.Id});
        runSecondMonthProductionUpdates();

        Test.stopTest();

        Map<String, System_Bill__c> sbMapTwo = queryForBills();
        System.assertEquals(11,sbMapTwo.values().size());
        System.assertEquals(209.94,sbMapTwo.get('acA A_SSS1_1').Total_Due__c);
        System.assertEquals(false,sbMapTwo.containsKey('acA A_SSS1_2'));
        System.assertEquals(158.47,sbMapTwo.get('acB B_SSS1_2').Total_Due__c); // DTM:74.73 + PMOB:83.74 = TD:158.47
        System.assertEquals(499.43,sbMapTwo.get('acB B_SSS2_2').Total_Due__c); // DTM:82.31 + PMOB:417.12 = TD:499.43
        System.assertEquals(80.38,sbMapTwo.get('acC C_SSS1_2').Total_Due__c); // DTM:37.91 + PMOB:42.47 = TD:80.38
        System.assertEquals(906.87,sbMapTwo.get('acC C_SSS2_2').Total_Due__c); // DTM:149.46 + PMOB:757.41 = TD:906.87
        System.assertEquals(365.16,sbMapTwo.get('acC C_B_SSS1_2').Total_Due__c); // DTM:172.21 + PMOB:192.95 = TD:365.16
    }

    @IsTest public static void testPreviewBillsPaidOffCustomer() {
        // 1 customer on 2 project is taken off both schedule zs
        // but has only paid off 1 of 2 so should have 1 system bill

        makePayment('acB B_SSS1', 1);

        Test.startTest();
        List<Utility_Account_Subscription__c> uasList = new List<Utility_Account_Subscription__c>();
        for (Utility_Account_Subscription__c uasToDeactivate : [
            SELECT Id, Name, Opportunity__r.Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Name = 'acB B_SSS1'
            OR Opportunity__r.Name = 'acB B_SSS2'
            LIMIT 2
        ]) {
            uasToDeactivate.Next_Schedule_Z_Status__c = 'Inactive Subscription';
            uasList.add(uasToDeactivate);
        }
        update uasList;
        setOppToCancelled(new List<String>{uasList[0].Opportunity__r.Id, uasList[1].Opportunity__r.Id});
        runSecondMonthProductionUpdates();

        Energy_Usage_Update__c sss1Prod = [
            SELECT Id, Schedule_Z__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - September 2016'];

        List<UASB__c> normalBillsListA = PreviewProductionUpdateResults.getUASes(sss1Prod.Id, true, sss1Prod.Schedule_Z__c);

        List<Id> uasIdsA = new List<Id>();
        for (UASB__c bill : normalBillsListA){
            uasIdsA.add(bill.Utility_Account_Subscription__c);
        }
        Test.stopTest();

        List<UASB__c> cancelledBillListA = PreviewProductionUpdateResults.getCancelledBills(sss1Prod.Id, uasIdsA);
        System.assertEquals(3, normalBillsListA.size());
        System.assertEquals(0, cancelledBillListA.size());

        Map<String, System_Bill__c> sbMapTwo = queryForBills();
        System.assertEquals(11,sbMapTwo.values().size());
        System.assertEquals(83.74,sbMapTwo.get('acB B_SSS1_1').Total_Payments_This_Month__c);
        System.assertEquals(0,sbMapTwo.get('acB B_SSS1_1').Carry_Over_Balance__c);

        System.assertEquals(false,sbMapTwo.containsKey('acB B_SSS1_2'));
        System.assertEquals(397.30,sbMapTwo.get('acA A_SSS1_2').Total_Due__c); // DTM:187.36 + PMOB:209.94 = TD:397.30
        System.assertEquals(417.12,sbMapTwo.get('acB B_SSS2_2').Total_Due__c); // DTM:0 + PMOB:417.12 = TD:417.12
        System.assertEquals(80.38,sbMapTwo.get('acC C_SSS1_2').Total_Due__c); // DTM:37.91 + PMOB:42.47 = TD:80.38
        System.assertEquals(906.87,sbMapTwo.get('acC C_SSS2_2').Total_Due__c); // DTM:149.46 + PMOB:757.41 = TD:906.87
        System.assertEquals(365.16,sbMapTwo.get('acC C_B_SSS1_2').Total_Due__c); // DTM:172.21 + PMOB:192.95 = TD:365.16
    }

    @IsTest public static void testPreviewBillsNotPaidOff() {
        // 1 customer on 2 project is taken off both schedule zs
        // but has only paid off 1 of 2 so should have 1 system bill

        makePayment('acB B_SSS1', 1);

        Test.startTest();
        List<Utility_Account_Subscription__c> uasList = new List<Utility_Account_Subscription__c>();
        for (Utility_Account_Subscription__c uasToDeactivate : [
            SELECT Id, Name, Opportunity__r.Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Name = 'acB B_SSS1'
            OR Opportunity__r.Name = 'acB B_SSS2'
            LIMIT 2
        ]) {
            uasToDeactivate.Next_Schedule_Z_Status__c = 'Inactive Subscription';
            uasList.add(uasToDeactivate);
        }
        update uasList;
        setOppToCancelled(new List<String>{uasList[0].Opportunity__r.Id, uasList[1].Opportunity__r.Id});
        runSecondMonthProductionUpdates();

        Energy_Usage_Update__c sss2Prod = [
            SELECT Id, Schedule_Z__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssB - September 2016'];

        List<UASB__c> normalBillsListB = PreviewProductionUpdateResults.getUASes(sss2Prod.Id, true, sss2Prod.Schedule_Z__c);

        List<Id> uasIdsB = new List<Id>();
        for (UASB__c bill : normalBillsListB){
            uasIdsB.add(bill.Utility_Account_Subscription__c);
        }

        List<UASB__c> cancelledBillListB = PreviewProductionUpdateResults.getCancelledBills(sss2Prod.Id, uasIdsB);
        System.assertEquals(1, normalBillsListB.size());
        System.assertEquals(1, cancelledBillListB.size());
        Test.stopTest();

        Map<String, System_Bill__c> sbMapTwo = queryForBills();
        System.assertEquals(11,sbMapTwo.values().size());
        System.assertEquals(83.74,sbMapTwo.get('acB B_SSS1_1').Total_Payments_This_Month__c);
        System.assertEquals(0,sbMapTwo.get('acB B_SSS1_1').Carry_Over_Balance__c);

        System.assertEquals(false,sbMapTwo.containsKey('acB B_SSS1_2'));
        System.assertEquals(397.30,sbMapTwo.get('acA A_SSS1_2').Total_Due__c); // DTM:187.36 + PMOB:209.94 = TD:397.30
        System.assertEquals(417.12,sbMapTwo.get('acB B_SSS2_2').Total_Due__c); // DTM:0 + PMOB:417.12 = TD:417.12
        System.assertEquals(80.38,sbMapTwo.get('acC C_SSS1_2').Total_Due__c); // DTM:37.91 + PMOB:42.47 = TD:80.38
        System.assertEquals(906.87,sbMapTwo.get('acC C_SSS2_2').Total_Due__c); // DTM:149.46 + PMOB:757.41 = TD:906.87
        System.assertEquals(365.16,sbMapTwo.get('acC C_B_SSS1_2').Total_Due__c); // DTM:172.21 + PMOB:192.95 = TD:365.16
    }
}