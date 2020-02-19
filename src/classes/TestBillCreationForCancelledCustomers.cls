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

        Bill_Period__c bpA1 = new Bill_Period__c(
            Name = 'sssA - August 2016',
            Shared_Solar_System__c = sss1.Id,
            Bill_Date__c = oneMonthAgo
        );

        Bill_Period__c bpB1 = new Bill_Period__c(
            Name = 'sssB - August 2016',
            Shared_Solar_System__c = sss2.Id,
            Bill_Date__c = oneMonthAgo
        );


        insert new List<Bill_Period__c>{bpA1, bpB1};

        Production__c prodA1 = new Production__c(
            Name = 'sssA August Production',
            Shared_Solar_System__c = sss1.Id,
            Start_Date__c = todaysDate,
            End_Date__c = oneMonthInFuture,
            Production_kWh__c = 81869.00,
            Credits_Generated__c = 13483.66
        );

        Production__c prodB1 = new Production__c(
            Name = 'sssB July Production',
            Shared_Solar_System__c = sss2.Id,
            Start_Date__c = oneMonthAgo,
            End_Date__c = todaysDate,
            Production_kWh__c = 367918.00,
            Credits_Generated__c = 40983.43
        );

        Production__c prodB2 = new Production__c(
            Name = 'sssB August Production',
            Shared_Solar_System__c = sss2.Id,
            Start_Date__c = todaysDate,
            End_Date__c = oneMonthInFuture,
            Production_kWh__c = 153846,
            Credits_Generated__c = 20000
        );

        insert new List<Production__c>{prodA1, prodB1, prodB2};


        Transfer__c transferA1 = new Transfer__c(
            Name = 'Main Transfer - sssA August',
            Bill_Period__c = bpA1.Id,
            Date_of_Transfer__c = oneMonthInFuture,
            Shared_Solar_System__c = sss1.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = schZOne.Id,
            Attempted_Transfer__c = 13483.66,
            Attempted_kWh_Transfer__c = 81869,
            Transfer_Amount__c = 13483.66,
            Default_Credit_Value__c = 0.1848
        );

        Transfer__c transferB1 = new Transfer__c(
            Name = 'Main Transfer - sssB July',
            Bill_Period__c = bpB1.Id,
            Date_of_Transfer__c = oneMonthAgo,
            Shared_Solar_System__c = sss2.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = schZTwo.Id,
            Attempted_Transfer__c =  40983.43,
            Attempted_kWh_Transfer__c = 367918,
            Transfer_Amount__c = 40983.43,
            Default_Credit_Value__c = 0.13
        );


        Transfer__c transferB2 = new Transfer__c(
            Name = 'Main Transfer - sssB August',
            Bill_Period__c = bpB1.Id,
            Date_of_Transfer__c = oneMonthInFuture,
            Shared_Solar_System__c = sss2.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = schZTwo.Id,
            Attempted_Transfer__c =  20000,
            Attempted_kWh_Transfer__c = 153846,
            Transfer_Amount__c = 20000,
            Default_Credit_Value__c = 0.13
        );

        insert new List<Transfer__c>{transferA1, transferB1, transferB2};

        //If we have multiple months of Production for one Transfer, have to create parts in separate calls (in order)
        TransferPartService transferPartService = new TransferPartService();
        transferPartService.createPartsFromTransfer(new List<Transfer__c>{transferA1, transferB1});
        transferPartService.createPartsFromTransfer(new List<Transfer__c>{transferB2});

        List<Transfer_Part__c > parts = [SELECT Id, Name, Amount__c, Production__r.Name FROM Transfer_Part__c ];
        System.assertEquals(3, parts.size());

        TestBillCreationandPayment.runBillPeriod(new List<Id>{bpA1.Id, bpB1.Id});

        List<UASB__c> uasbList = [SELECT Utility_Account_Subscription__r.Name, Shared_Solar_System__c,
            Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
            Utility_Account_Subscription__r.Share_of_System__c,
            Production_Update__r.Name, Credits_on_Bill_Period__c,
            Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
            Net_Metering_Credits_Allocated__c, Discounted_Bill__c,
            Subscription_Production_kWh__c, System_Bill__r.Opportunity__r.Name
        FROM UASB__c];

        setBillsToPublished();
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

    public static void runSecondMonthBillPeriods() {
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

        Bill_Period__c bpB2 = new Bill_Period__c(
            Name = 'sssB - September 2016',
            Shared_Solar_System__c = sssList[0].Id,
            Bill_Date__c = todaysDate
        );

        Bill_Period__c bpA2 = new Bill_Period__c(
            Name = 'sssA - September 2016',
            Shared_Solar_System__c = sssList[1].Id,
            Bill_Date__c = todaysDate
        );

        insert new List<Bill_Period__c>{bpA2, bpB2};

        Production__c prodB3 = new Production__c(
            Name = 'sssB September Production',
            Shared_Solar_System__c = sssList[0].Id,
            Start_Date__c = oneMonthAgo,
            End_Date__c = todaysDate,
            Production_kWh__c = 73072.00,
            Credits_Generated__c = 12033.73
        );

        Production__c prodA2 = new Production__c(
            Name = 'sssA September Production',
            Shared_Solar_System__c = sssList[1].Id,
            Start_Date__c = oneMonthAgo,
            End_Date__c = todaysDate,
            Production_kWh__c = 73072.00,
            Credits_Generated__c = 12033.73
        );

        insert new List<Production__c>{prodB3, prodA2};

        Transfer__c transferB3 = new Transfer__c(
            Name = 'Main Transfer - sssB September',
            Bill_Period__c = bpB2.Id,
            Date_of_Transfer__c = todaysDate,
            Shared_Solar_System__c = sssList[0].Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = schZOne.Id,
            Attempted_Transfer__c =  12033.73,
            Attempted_kWh_Transfer__c = 73072,
            Transfer_Amount__c = 12033.73,
            Transfer_kWh__c = 73072,
            Default_Credit_Value__c = 0.13
        );

        Transfer__c transferA2 = new Transfer__c(
            Name = 'Main Transfer - sssA September',
            Bill_Period__c = bpA2.Id,
            Date_of_Transfer__c = todaysDate,
            Shared_Solar_System__c = sssList[1].Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = schZTwo.Id,
            Attempted_Transfer__c =  12033.73,
            Attempted_kWh_Transfer__c = 73072,
            Transfer_Amount__c =  12033.73,
            Default_Credit_Value__c = 0.13
        );

        insert new List<Transfer__c>{transferA2, transferB3};

        TransferPartService transferPartService = new TransferPartService();
        transferPartService.createPartsFromTransfer(new List<Transfer__c>{transferA2, transferB3});

        List<Transfer_Part__c > parts = [SELECT Id, Name, Amount__c, Production__r.Name FROM Transfer_Part__c ];
        System.assertEquals(5, parts.size());

        TestBillCreationandPayment.runBillPeriod(new List<Id>{bpB2.Id, bpA2.Id});
    }

    public static Map<String, List<UASB__c>> queryForBills() {
        Map<String, List<UASB__c>> uasbMap = new Map<String, List<UASB__c>>();

        for (UASB__c insertedUASB : [
            SELECT Id, CS_Billing_Log__c, Net_Metering_Credits_Allocated__c, Savings__c,
                Discounted_Bill__c, Opportunity__r.Name, Transfer__r.Date_of_Transfer__c, Date__c
            FROM UASB__c
            ORDER BY Date__c, Transfer__r.Date_of_Transfer__c]) {
                String billKey = insertedUASB.Opportunity__r.Name;
                if (uasbMap.containsKey(billKey)){
                    List<UASB__c> billList = uasbMap.get(billKey);
                    billList.add(insertedUASB);
                    uasbMap.put(billKey,billList);
                } else {
                    uasbMap.put(billKey,new List<UASB__c>{insertedUASB});
                }
        }
        return uasbMap;

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
    @IsTest
    public static void baseLineNoChange() {
        Map<String, List<UASB__c>> uasbMap = queryForBills();
        System.assertEquals(6,uasbMap.values().size()); // 6 Opportunities, 8 UASBs
        System.assertEquals(209.94,uasbMap.get('acA A_SSS1')[0].Discounted_Bill__c);
        System.assertEquals(83.74,uasbMap.get('acB B_SSS1')[0].Discounted_Bill__c);
        System.assertEquals(280.32,uasbMap.get('acB B_SSS2')[0].Discounted_Bill__c);
        System.assertEquals(136.80,uasbMap.get('acB B_SSS2')[1].Discounted_Bill__c);
        System.assertEquals(42.47,uasbMap.get('acC C_SSS1')[0].Discounted_Bill__c);
        System.assertEquals(509.01,uasbMap.get('acC C_SSS2')[0].Discounted_Bill__c);
        System.assertEquals(248.40,uasbMap.get('acC C_SSS2')[1].Discounted_Bill__c);
        System.assertEquals(192.95,uasbMap.get('acC C_B_SSS1')[0].Discounted_Bill__c);

        Test.startTest();
            runSecondMonthBillPeriods();
        Test.stopTest();

        Map<String, List<UASB__c>> uasbMapTwo = queryForBills();
        System.assertEquals(6,uasbMapTwo.values().size()); // 6 Opportunities, 6 new UASBs
        System.assertEquals(187.36,uasbMapTwo.get('acA A_SSS1')[1].Discounted_Bill__c);
        System.assertEquals(74.73,uasbMapTwo.get('acB B_SSS1')[1].Discounted_Bill__c);
        System.assertEquals(82.31,uasbMapTwo.get('acB B_SSS2')[2].Discounted_Bill__c);
        System.assertEquals(37.91,uasbMapTwo.get('acC C_SSS1')[1].Discounted_Bill__c);
        System.assertEquals(149.46,uasbMapTwo.get('acC C_SSS2')[2].Discounted_Bill__c);
        System.assertEquals(172.21,uasbMapTwo.get('acC C_B_SSS1')[1].Discounted_Bill__c);
    }
}