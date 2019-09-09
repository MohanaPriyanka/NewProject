@isTest
public class MultipleMonthProductionUpdateTest {
    @testSetup public static void multipleMonthTest(){
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

        ChargentBase__Gateway__c chGateway  =
            new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                ChargentBase__Merchant_ID__c = '235986',
                ChargentBase__Available_Payment_Methods__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
                ChargentBase__Active__c = TRUE);
        insert chGateway;

        Account clientAccount = new Account(name = 'Test Client');

        insert new List<Account>{clientAccount};

        Entity__c entity1 = new Entity__c (
            Name = 'Oxford Barrett St. P1',
            Gateway__c = chGateway.Id,
            Client_Account__c = clientAccount.Id
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
                                       Client_Account__c = clientAccount.Id,
                                       BWC_Project_Entity_Manual__c = entity1.Id,
                                       Utility__c = eversource.Id,
                                       Maximum_Subscription_Assemblage__c = 25,
                                       Billing_Method__c = 'kWh');
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
        
        Account parentAccount = new Account(name = 'Jon Snow',
                                       RecordTypeId = parentAccountRT);

        insert new List<Account>{parentAccount};  

        Account propertyOne = new Account(name = 'Property A', 
                                      Parent_Account__c = parentAccount.Id);

        insert new List<Account>{propertyOne};  

        Utility_Account_Log__c ualogOne = 
            new Utility_Account_Log__c(Name = '00088888',
                                       Account__c = propertyOne.Id,
                                       Annual_Cost_of_Electricity__c = 12000,
                                       Name_on_Account__c = 'Prop A');

        Utility_Account_Log__c ualogTwo = 
            new Utility_Account_Log__c(Name = '000999999',
                                       Account__c = propertyOne.Id,
                                       Annual_Cost_of_Electricity__c = 4000,
                                       Name_on_Account__c = 'Prop B');

        insert new List<Utility_Account_Log__c>{ualogOne, ualogTwo};  

        Opportunity opportunityOne = 
            new Opportunity(Name = 'Building SSS1',
                            AccountId = propertyOne.Id,
                            Shared_Solar_System__c = sss1.Id,
                            StageName = 'Complete',
                            Product__c = normalCSProduct.Id,
                            CloseDate = System.today());

        insert new List<Opportunity>{opportunityOne};

        Utility_Account_Subscription__c uasOne = 
            new Utility_Account_Subscription__c(Name = '00088888',
                                                Utility_Account_Log__c = ualogOne.Id,
                                                Opportunity__c = opportunityOne.Id,
                                                Next_Schedule_Z_Status__c = 'Active Subscription',
                                                Calculated_Annual_Cost_of_Electricity__c = 12000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 12000);

        Utility_Account_Subscription__c uasTwo = 
            new Utility_Account_Subscription__c(Name = '000999999',
                                                Utility_Account_Log__c = ualogTwo.Id,
                                                Opportunity__c = opportunityOne.Id,
                                                Next_Schedule_Z_Status__c = 'Active Subscription',
                                                Calculated_Annual_Cost_of_Electricity__c = 4000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 4000);

        insert new List<Utility_Account_Subscription__c>{uasOne, uasTwo};

        uasOne.Customer_Subscription_KW_DC_STATIC__c = 20;
        uasTwo.Customer_Subscription_KW_DC_STATIC__c = 14;

        update new List<Utility_Account_Subscription__c>{uasOne, uasTwo};

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

        Energy_Usage_Update__c prodUpdateFourMonths = new Energy_Usage_Update__c (
                Name = 'sssA - January 2016',
                Shared_Solar_System__c = sss1.id,
                Schedule_Z__c = scheduleZ1.id,
                Billing_Period_End_Date__c = myDateFeb,
                Date__c = myDateJan, 
                Total_System_NMCs__c = 45000,
                Net_Metering_Rate_Applied__c = 0.1234,
                Production__c = 364667,
                Total_System_NMCs_2_of_4__c = 20000, 
                Net_Metering_Rate_Applied_2_of_4__c = 0.13,
                Production_kWh_2_of_4__c = 153846,
                Total_System_NMCs_3_of_4__c = 23000,
                Net_Metering_Rate_Applied_3_of_4__c = 0.11,
                Production_kWh_3_of_4__c = 209090,
                Total_System_NMCs_4_of_4__c = 575,
                Net_Metering_Rate_Applied_4_of_4__c = 0.10,
                Production_kWh_4_of_4__c = 5750);
        insert prodUpdateFourMonths;

        Energy_Usage_Update__c prodUpdateTwoMonths = new Energy_Usage_Update__c (
                Name = 'sssA - February 2016',
                Shared_Solar_System__c = sss1.id,
                Schedule_Z__c = scheduleZ1.id,
                Billing_Period_End_Date__c = myDateMar,
                Date__c = myDateFeb,
                Total_System_NMCs__c = 13000,
                Net_Metering_Rate_Applied__c = 0.1619,
                Production__c = 80296,
                Total_System_NMCs_2_of_4__c = 45000, 
                Net_Metering_Rate_Applied_2_of_4__c = 0.1234,
                Production_kWh_2_of_4__c = 364667);
        insert prodUpdateTwoMonths;

        Energy_Usage_Update__c prodUpdateSizeoffKwh = new Energy_Usage_Update__c (
                Name = 'sssA - March 2016',
                Shared_Solar_System__c = sss1.id,
                Schedule_Z__c = scheduleZ1.id,
                Billing_Period_End_Date__c = myDateMar,
                Date__c = myDateMar,
                Total_System_NMCs__c = 13000,
                Net_Metering_Rate_Applied__c = 0.1619,
                Production__c = 80296);
        insert prodUpdateSizeoffKwh;

        System.assertEquals( 8, (PreviewProductionUpdateResults.getUASes(prodUpdateFourMonths.Id, true, scheduleZ1.Id)).size());
        System.assertEquals( 4, (PreviewProductionUpdateResults.getUASes(prodUpdateTwoMonths.Id, true, scheduleZ1.Id)).size());

        TestBillCreationandPayment.runProductionUpdate(new List<Id>{prodUpdateFourMonths.Id});
        TestBillCreationandPayment.setBillsToPublished();
        TestBillCreationandPayment.runProductionUpdate(new List<Id>{prodUpdateTwoMonths.Id});
        Test.stopTest();
    }

    @isTest public static void testBillCreation() {
        List<UASB__c> uasblist =
            [SELECT Id, Name, Date__c, System_Bill__r.Bill_Number__c, Above_NM_Rate_Floor__c,
                Due_Date__c, Total_System_NMCs__c, NM_Rate_Floor__c, NMC_Rate__c, System_Bill__c,
                Total_System_Production_kWh__c, Utility_Account_Subscription__c, Bill_Value__c, Schedule_Z_Subscription__c
            FROM UASB__c
            ORDER BY Date__c, NMC_Rate__c];

        Date firstBillDate = Date.newInstance(2016, 1, 1);
        Date secondBillDate = Date.newInstance(2016, 2, 2);

        System.assertEquals(12, uasblist.size());

        System.assertEquals(firstBillDate, uasblist[0].Date__c);
        System.assertEquals(firstBillDate, uasblist[7].Date__c);
        System.assertEquals(secondBillDate, uasblist[8].Date__c);
        System.assertEquals(secondBillDate, uasblist[11].Date__c);

        // ensure that Schedule Z Subscription lookup field is being populated
        for (UASB__c uasb : uasblist) {
            System.assert(uasb.Schedule_Z_Subscription__c != null);
        }

        System.assertEquals(0.10, uasblist[0].NMC_Rate__c);
        System.assertEquals(575, uasblist[1].Total_System_NMCs__c);
        System.assertEquals(0.11, uasblist[2].NMC_Rate__c);
        System.assertEquals(23000, uasblist[3].Total_System_NMCs__c);
        System.assertEquals(0.1234, uasblist[4].NMC_Rate__c);
        System.assertEquals(364667, uasblist[5].Total_System_Production_kWh__c);
        System.assertEquals(uasblist[7].System_Bill__c, uasblist[6].System_Bill__c);
        System.assertNotEquals(uasblist[7].System_Bill__c, uasblist[8].System_Bill__c);
        System.assertEquals(uasblist[8].System_Bill__c, uasblist[11].System_Bill__c);
        System.assertEquals(0.1234, uasblist[9].NMC_Rate__c);
        System.assertEquals(0.1619, uasblist[10].NMC_Rate__c);
    }

    @isTest public static void testSizeOffkWH() {
        Test.startTest();
        Energy_Usage_Update__c prodUpdateSizeoffKwh = [SELECT Id, Name, Schedule_Z__c
                                                      FROM Energy_Usage_Update__c
                                                      WHERE Name = 'sssA - March 2016'];

        List<UASB__c> previewedUASBs = PreviewProductionUpdateResults.getUASes(prodUpdateSizeoffKwh.Id, true, prodUpdateSizeoffKwh.Schedule_Z__c);

        System.assertEquals( 2, previewedUASBs.size());

        TestBillCreationandPayment.runProductionUpdate(new List<Id>{prodUpdateSizeoffKwh.Id});

        Test.stopTest();

        UASB__c generatedBill = 
            [SELECT Id, Name, Utility_Account_Subscription__r.Name,
            Credits_Allocated__c, Share_of_System__c, Subscription_Production_kWh_Static__c
            FROM UASB__c
            WHERE Utility_Account_Subscription__r.Name = : previewedUASBs[1].PreGen_Utility_Acct__c 
            AND Production_Update__c = : prodUpdateSizeoffKwh.Id];

        System.assertEquals(126.10, generatedBill.Credits_Allocated__c);
        System.assertEquals(126.10, previewedUASBs[1].PreGen_NMCs_Allocated__c);

        System.assertEquals(0.97, generatedBill.Share_of_System__c);
        System.assertEquals(0.97, previewedUASBs[1].PreGen_System_Share__c);

        System.assertEquals(778.87, generatedBill.Subscription_Production_kWh_Static__c);
        System.assertEquals(778.87, previewedUASBs[1].PreGen_Subscription_Production__c);
    }

    @isTest public static void testMNRounding() {
        Test.startTest();
        Energy_Usage_Update__c prodUpdateSizeoffKwh = [SELECT Id, Name, Schedule_Z__c, Production__c
                                                        FROM Energy_Usage_Update__c
                                                        WHERE Name = 'sssA - March 2016'];

        prodUpdateSizeoffKwh.Production__c = 159817;
        prodUpdateSizeoffKwh.Net_Metering_Rate_Applied__c = 0.15539;
        update prodUpdateSizeoffKwh;

        Schedule_Z_Subscription__c szs = [SELECT Id, Name, Customer_Subscription_kW_DC__c,
                                            Number_of_Decimal_Places__c
                                            FROM Schedule_Z_Subscription__c
                                            WHERE Customer_Subscription_kW_DC__c = 14];

        szs.Customer_Subscription_kW_DC__c = 6.988;
        szs.Number_of_Decimal_Places__c = 4;
        update szs;

        TestBillCreationandPayment.runProductionUpdate(new List<Id>{prodUpdateSizeoffKwh.Id});

        Test.stopTest();

        UASB__c generatedBill =
        [SELECT Id, Name, Utility_Account_Subscription__r.Name,
            Credits_Allocated__c, Share_of_System__c, Subscription_Production_kWh_Static__c
        FROM UASB__c
        WHERE Schedule_Z_Subscription__r.Name = : szs.Name
        AND Production_Update__r.Id = : prodUpdateSizeoffKwh.Id];

        // 0.15539 (nmc Rate) & 159817 (total system kWh) & 0.4833 (share of system) should = $120.03 NOT $120.02
        System.assertEquals(120.03, generatedBill.Credits_Allocated__c);
        System.assertNotEquals(120.02, generatedBill.Credits_Allocated__c);
        System.assertEquals(0.4833, generatedBill.Share_of_System__c);
        System.assertEquals(772.40, generatedBill.Subscription_Production_kWh_Static__c);
    }

    @isTest public static void testRoundingMethodSwitch() {
        Test.startTest();
        Energy_Usage_Update__c prodUpdate = [
            SELECT Id, Name, Schedule_Z__c, Production__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssA - March 2016'];

        Utility__c nGrid = [
            SELECT Id, Credits_Allocated_Rounding_Method__c
            FROM Utility__c
            WHERE Name = 'Eversource'];

        Shared_Solar_System__c sss1 = [
            SELECT Id, Billing_Method__c
            FROM Shared_Solar_System__c];

        Schedule_Z_Subscription__c szs = [
            SELECT Id, Name, Customer_Subscription_kW_DC__c,
            Number_of_Decimal_Places__c
            FROM Schedule_Z_Subscription__c
            WHERE Customer_Subscription_kW_DC__c = 14];

        szs.Customer_Subscription_kW_DC__c = 25.59;
        szs.Number_of_Decimal_Places__c = 2;
        update szs;

        prodUpdate.Total_System_NMCs__c = 28319.04;
        update prodUpdate;

        nGrid.Credits_Allocated_Rounding_Method__c = 'DOWN';
        update nGrid;

        sss1.Billing_Method__c = 'NMC';
        update sss1;

        TestBillCreationandPayment.runProductionUpdate(new List<Id>{prodUpdate.Id});
        Test.stopTest();

        UASB__c generatedBill =
        [SELECT Id, Name, Utility_Account_Subscription__r.Name,
            Credits_Allocated__c, Share_of_System__c, Subscription_Production_kWh_Static__c
        FROM UASB__c
        WHERE Schedule_Z_Subscription__r.Name = : szs.Name
        AND Production_Update__r.Id = : prodUpdate.Id];

        // Matches real data: (1.77% share with $28,319.04 NMCs = 501.247, round down to 501.24)
        System.assertEquals(501.24, generatedBill.Credits_Allocated__c);
        System.assertNotEquals(501.25, generatedBill.Credits_Allocated__c);
        System.assertEquals(1.77, generatedBill.Share_of_System__c);
    }
}