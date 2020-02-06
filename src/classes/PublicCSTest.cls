@IsTest
public class PublicCSTest {
    @TestSetup
    public static void csPublicTest(){
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 4
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 4
        );

        insert new List<Utility__c>{eversource, nationalGrid
        };

        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c (Name = 'Eversource SEMA Class 2', 
                                                                       Utility__c = 'Eversource', 
                                                                       Class__c = 'Class 2',
                                                                       Value_of_Net_Metering_Credit__c = 0.1848,
                                                                       Current_Billing_Rate__c = TRUE);

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c (Name = 'Eversource SEMA Class 2', 
                                                                       Utility__c = 'Eversource', 
                                                                       Class__c = 'Class 2',
                                                                       Value_of_Net_Metering_Credit__c = 0.1848,
                                                                       Sizing_Rate__c = TRUE);

        insert new List<Utility_NMC_Tariff__c>{everbillNMC, eversizeNMC};
        
        Load_U__c everLZU = new Load_U__c (Name = '02633', 
                                           LZ__c = 'SEMA',
                                           Town__c= 'Medfield');
        insert new List<Load_U__c>{everLZU};
        
        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU.Id,
            Utility__c = eversource.Id
        );
        insert junction;
        TestFactory.insertBWAddress();
        TestFactory.setCSBillSettings();

        ChargentBase__Gateway__c chGateway  = new ChargentBase__Gateway__c(
            Name = 'Chargent Gateway',
            ChargentBase__Merchant_ID__c = '235986',
            ChargentBase__Available_Payment_Methods__c = 'eCheck',
            ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
            ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
            ChargentBase__Active__c = TRUE
        );
        insert chGateway;

        Entity__c entity1 = new Entity__c (
            Name = 'Oxford Barrett St. P1',
            Gateway__c = chGateway.Id
        );
        insert entity1;
        
        Shared_Solar_System__c sss1 = 
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                       Service_Territory__c = 'SEMA',
                                       Open__c = true,
                                       Reserved_Capacity_kW_DC__c = '0',
                                       Capacity_Committed_kW_DC__c = 0,
                                       Total_System_Size_kWh_DC__c = 1445.86,
                                       Total_System_Size_kW_AC__c  = 996,
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '1',
                                       Utility_NMC_Tariff__c = eversizeNMC.Id,
                                       Expected_Yield_kWh_kW__c = 1300,
                                       Assemblage_Count__c = 1,
                                       Sales_Partners__c = 'All',
                                       BWC_Project_Entity_Manual__c = entity1.Id,
                                       Maximum_Subscription_Assemblage__c = 25,
                                       Billing_Method__c = 'NMC',
                                       Utility__c = eversource.Id
            );
        insert new List<Shared_Solar_System__c>{sss1};


        Id parentAccountRT = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

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
                                                  Days_In_Bill_Period__c = 30,
                                                  Monthly_Late_Fee__c = 1);

        Product2 publicCSProduct = new Product2(  Name = 'BlueWave Public Offtake CS',
                                                  Family = 'Community Solar',
                                                  Product_Type__c = 'Community Solar',
                                                  State__c = 'MA',
                                                  ProductCode = 'CS - Bluewave - Public CS - 20%',
                                                  IsActive = True,
                                                  Lender_of_Record__c = 'BlueWave', 
                                                  NMC_Discount__c = 20,
                                                  Annual_kWh_Maximum__c = 63000,
                                                  NM_Rate_Floor__c = 0.09,
                                                  Days_In_Bill_Period__c = 30,
                                                  Monthly_Late_Fee__c = 0.8333);
        insert new List<Product2>{normalCSProduct, publicCSProduct};
        
        Account parentPublicCS = new Account(name = 'Town of Townville',
                                       RecordTypeId = parentAccountRT);

        insert new List<Account>{parentPublicCS};  

         Account propertyPublicCS = new Account(name = 'School District A', 
                                      Parent_Account__c = parentPublicCS.Id);

        insert new List<Account>{propertyPublicCS};  

        Utility_Account_Log__c ualogPublic = 
            new Utility_Account_Log__c(Name = '00088888',
                                       Account__c = propertyPublicCS.Id,
                                       Annual_Cost_of_Electricity__c = 120000,
                                       Name_on_Account__c = 'School A');

        insert new List<Utility_Account_Log__c>{ualogPublic};  

        Opportunity opportunityPublic = 
            new Opportunity(Name = 'School DistrictA',
                            AccountId = propertyPublicCS.Id,
                            Shared_Solar_System__c = sss1.Id,
                            StageName = 'Complete',
                            Product__c = publicCSProduct.Id,
                            CloseDate = System.today());
        insert new List<Opportunity>{opportunityPublic};

        Utility_Account_Subscription__c uasPublic = 
            new Utility_Account_Subscription__c(Name = '00088888',
                                                Utility_Account_Log__c = ualogPublic.Id,
                                                Opportunity__c = opportunityPublic.Id,
                                                Next_Schedule_Z_Status__c = 'Active Subscription',
                                                Calculated_Annual_Cost_of_Electricity__c = 12000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 12000);

        insert new List<Utility_Account_Subscription__c>{uasPublic};

        uasPublic.Customer_Subscription_KW_DC_STATIC__c = 20;
        update new List<Utility_Account_Subscription__c>{uasPublic};

        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Status__c = 'Billing'
        );

        insert scheduleZ1;

        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);

        Bill_Period__c bpA1 = new Bill_Period__c(
            Name = 'sssA - January 2016',
            Shared_Solar_System__c = sss1.Id,
            Bill_Date__c = myDateJan
        );

        Bill_Period__c bpA2 = new Bill_Period__c(
            Name = 'sssA - February 2016',
            Shared_Solar_System__c = sss1.Id,
            Bill_Date__c = myDateFeb
        );

        insert new List<Bill_Period__c>{bpA1, bpA2};

        Production__c prodA1 = new Production__c(
            Name = 'sssA January Production',
            Shared_Solar_System__c = sss1.Id,
            Start_Date__c = myDateJan,
            End_Date__c = myDateFeb - 1,
            Production_kWh__c = 400000,
            Credits_Generated__c = 45000
        );

        Production__c prodA2 = new Production__c(
            Name = 'sssA February Production',
            Shared_Solar_System__c = sss1.Id,
            Start_Date__c = myDateFeb,
            End_Date__c = myDateMar - 1,
            Production_kWh__c = 60000,
            Credits_Generated__c = 3000
        );

        insert new List<Production__c>{prodA1, prodA2};

        // Effective NMC Rate of $0.11
        Transfer__c transferA1 = new Transfer__c(
            Name = 'Main Transfer - sssA January',
            Bill_Period__c = bpA1.Id,
            Date_of_Transfer__c = myDateJan,
            Shared_Solar_System__c = sss1.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Attempted_Transfer__c = 45000,
            Attempted_kWh_Transfer__c = 400000,
            Transfer_Amount__c = 45000,
            Default_Credit_Value__c = 0.1125
        );

        // Effective NMC Rate of $0.05
        Transfer__c transferA2 = new Transfer__c(
            Name = 'Main Transfer - sssA February',
            Bill_Period__c = bpA2.Id,
            Date_of_Transfer__c = myDateFeb,
            Shared_Solar_System__c = sss1.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Attempted_Transfer__c = 3000,
            Attempted_kWh_Transfer__c = 60000,
            Transfer_Amount__c = 3000,
            Default_Credit_Value__c = 0.05
        );
        insert new List<Transfer__c>{transferA1, transferA2};

        System.debug('1.Number of Queries used in this apex code so far: ' + Limits.getQueries());

        TransferPartService transferPartService = new TransferPartService();
        transferPartService.createPartsFromTransfer(new List<Transfer__c>{transferA1, transferA2});
        Test.startTest();
        System.debug('2.Number of Queries used in this apex code so far: ' + Limits.getQueries());

        TestBillCreationandPayment.runBillPeriod(new List<Id>{bpA1.Id});
        //63
        System.debug('3.Number of Queries used in this apex code so far: ' + Limits.getQueries());

        TestBillCreationandPayment.setBillsToPublished();
        //68
        System.debug('4.Number of Queries used in this apex code so far: ' + Limits.getQueries());

        TestBillCreationandPayment.runBillPeriod(new List<Id>{bpA2.Id});
        System.debug('5.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        Test.stopTest();
    }

    @IsTest
    public static void testBillCreation() {
        System.debug('Are we even getting to the testBill Creation method? '  );
        List<System_Bill__c> systemBillList = SystemBillsSelector.selectAllSystemBills();

        List<UASB__c> uablist =
            [SELECT Id, Name, Bill_Date__c, System_Bill__r.Bill_Number__c, Above_NM_Rate_Floor__c, 
            Due_Date__c, Billing_Period_End_Date__c, NM_Rate_Floor__c,
            Subscription_Production_kWh__c, Utility_Account_Subscription__c, Bill_Value__c
            FROM UASB__c
            ORDER BY Bill_Date__c ];

        List<Utility_Account_Log__c> ualList = CreateUALController.getUALs(systemBillList[0].Property_Account_ID__c);
        System.assertEquals(ualList.size(), 1);

        // First Bill has 20% Discount, does not hit NM Rate Floor
        System.assertEquals(true, uablist[0].Above_NM_Rate_Floor__c);
        System.assertEquals(622.49, systembillList[0].Net_Metering_Credits_Allocated__c);
        Decimal firstBillAmount = (622.49*0.80).setScale(2);
        System.assertEquals(firstBillAmount,systembillList[0].Due_This_Month__c);
        System.assertEquals(firstBillAmount,systemBillList[0].Total_Due__c);
        
        // Second Bill Should Hit the NM Rate Floor
        System.assertEquals(false, uablist[1].Above_NM_Rate_Floor__c);
        System.assertEquals(41.50,systembillList[1].Net_Metering_Credits_Allocated__c);
        System.assertEquals(829.98,systembillList[1].Production_kWH__c);
        Decimal secondBillAmount = (829.98*0.09).setScale(2);
        System.assertEquals(secondBillAmount,systembillList[1].Due_This_Month__c);

        // Waiving Late Fees:
        System.assertEquals(0, systemBillList[1].Late_Fees__c);
        Decimal totalDueSecondMonth =  firstBillAmount + secondBillAmount;
        System.assertEquals(totalDueSecondMonth, systemBillList[1].Total_Due__c);

        // Late Fees should be 10% Annually, not 12% 
        // Decimal calcLateFees = (firstBillAmount * 0.008333).setScale(2);
        // System.assertEquals(calcLateFees,systemBillList[1].Late_Fees__c);
        // Decimal totalDueSecondMonth = calcLateFees + firstBillAmount + secondBillAmount;
        // System.assertEquals(totalDueSecondMonth,systemBillList[1].Total_Due__c);
    }
}