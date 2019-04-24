/**
 * Created by AlyssaCooper on 3/20/2019.
 * note to self: look at customercommunicationhandlertest and utilityaccountlogtriggerhandlertest
 */
@IsTest
public with sharing class SharedSolarSystemHandlerTest {
    @TestSetup
    public static void setupData() {
        Test.startTest();
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );
        Utility__c noSSS = new Utility__c(
            Name = 'No SSS Utility',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{
            eversource, nationalGrid, noSSS
        };
        Entity__c entity1 = new Entity__c(Name = 'Oxford Barrett St. P1');
        insert entity1;

        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c(Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Current_Billing_Rate__c = TRUE);

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c(Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = TRUE);

        insert new List<Utility_NMC_Tariff__c>{
            everbillNMC, eversizeNMC
        };

        Load_U__c everLZU = new Load_U__c(Name = '02633',
            LZ__c = 'SEMA',
            Town__c = 'Medfield');
        insert everLZU;

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU.Id,
            Utility__c = eversource.Id
        );
        insert junction;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);

        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '2',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);

        Shared_Solar_System__c sss3 = new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '3',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);

        Shared_Solar_System__c sss4 = new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = nationalGrid.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '2',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);

        insert new List<Shared_Solar_System__c>{
            sss1, sss2, sss3, sss4
        };

        List<Shared_Solar_System__c> noSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{
                    noSSS.Id
                },
                new Set<String>{
                    'No Load Zone'
                }
            );

        System.assertEquals(0, noSharedSolarSystems.size());

        noSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{
                    eversource.Id
                },
                new Set<String>{
                    'No Load Zone'
                }
            );

        System.assertEquals(0, noSharedSolarSystems.size());

        noSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>(),
                new Set<String>()
            );

        System.assertEquals(0, noSharedSolarSystems.size());

        noSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{
                    noSSS.Id
                },
                new Set<String>{
                    'SEMA'
                }
            );

        System.assertEquals(0, noSharedSolarSystems.size());

        List<Shared_Solar_System__c> eversourceSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{
                    eversource.Id
                },
                new Set<String>{
                    'SEMA', 'NEMA'
                }
            );

        System.assertEquals(3, eversourceSharedSolarSystems.size());

        List<Shared_Solar_System__c> nationalGridSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{
                    nationalGrid.Id
                },
                new Set<String>{
                    'SEMA', 'NEMA'
                }
            );

        System.assertEquals(1, nationalGridSharedSolarSystems.size());

        List<Shared_Solar_System__c> ngAndEversourceSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{
                    nationalGrid.Id, eversource.Id
                },
                new Set<String>{
                    'SEMA', 'NEMA'
                }
            );

        System.assertEquals(4, ngAndEversourceSharedSolarSystems.size());

        Account accountParent1 = new Account(Name = 'Parent Account 1', Client_Brand_Key__c = 'BluewaveLogo');
        Account accountParent2 = new Account(Name = 'Parent Account 2', Client_Brand_Key__c = 'AmpRed');
        Account accountParent3 = new Account(Name = 'Parent Account 3', Client_Brand_Key__c = 'BluewaveLogo');
        insert new List<Account>{accountParent1, accountParent2, accountParent3};

        Contact contactA = new Contact( FirstName = 'Contact A',
            LastName = 'Last',
            Account = accountParent1,
            Email = 'acooper@bluewavesolar.com');
        Contact contactB = new Contact( FirstName = 'Contact B',
            LastName = 'Last',
            Account = accountParent2,
            Email = 'acooper@bluewavesolar.com');
        Contact contactC = new Contact( FirstName = 'Contact C',
            LastName = 'Last',
            Account = accountParent3,
            Email = 'acooper@bluewavesolar.com');

        insert new List<Contact>{contactA, contactB, contactC};

        Account propAcct1 = new Account( Name = 'Prop Account 1',
            Parent_Account__c = accountParent1.Id,
            Send_Bills_Contact__c = contactA.Id,
            RecordTypeId = '012j00000010HeQ',
            Client_Brand_Key__c = 'BluewaveLogo');
        Account propAcct2 = new Account( Name = 'Prop Account 2',
            Parent_Account__c = accountParent2.Id,
            Send_Bills_Contact__c = contactB.Id,
            RecordTypeId = '012j00000010HeQ',
            Client_Brand_Key__c = 'AmpRed');
        Account propAcct3 = new Account( Name = 'Prop Account 3',
            Parent_Account__c = accountParent3.Id,
            Send_Bills_Contact__c = contactC.Id,
            RecordTypeId = '012j00000010HeQ',
            Client_Brand_Key__c = 'BluewaveLogo');

        insert new List<Account>{propAcct1, propAcct2, propAcct3};

        Utility_Account_Log__c ualog1 = new Utility_Account_Log__c(
            Name = '0000234',
            Account__c = propAcct1.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Name one');

        Utility_Account_Log__c ualog2 = new Utility_Account_Log__c(
            Name = '0000236',
            Account__c = propAcct2.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Name two');

        Utility_Account_Log__c ualog3 = new Utility_Account_Log__c(
            Name = '0000238',
            Account__c = propAcct3.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Name three');

        insert new List<Utility_Account_Log__c>{ualog1, ualog2, ualog3};

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
            Days_in_Bill_Period__c = 20,
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
            Days_in_Bill_Period__c = 20,
            Monthly_Late_Fee__c = 0.8333);
        insert new List<Product2>{normalCSProduct, publicCSProduct};

        Opportunity opportunityone =
            new Opportunity(Name = 'Alyssa Testcase1 0000234',
                AccountId = propAcct1.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());

        Opportunity opportunitytwo =
            new Opportunity(Name = 'Alyssa Testcase2 0000236',
                AccountId = propAcct2.Id,
                Shared_Solar_System__c = sss2.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());

        Opportunity opportunitythree =
            new Opportunity(Name = 'Alyssa Testcase3 0000238',
                AccountId = propAcct3.Id,
                Shared_Solar_System__c = sss3.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        insert new List<Opportunity>{opportunityone, opportunitytwo, opportunitythree};

        Utility_Account_Subscription__c uasOne =
            new Utility_Account_Subscription__c(Name = '0000234',
                Utility_Account_Log__c = ualog1.Id,
                Opportunity__c = opportunityone.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 4000,
                Calculated_Annual_Cost_of_Electricity__c = 4000,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);
        Utility_Account_Subscription__c uasTwo =
            new Utility_Account_Subscription__c(Name = '0000236',
                Utility_Account_Log__c = ualog2.Id,
                Opportunity__c = opportunitytwo.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 8000,
                Calculated_Annual_Cost_of_Electricity__c = 8000,
                Subscribed_Annual_Cost_of_Electricity__c = 8000);
        Utility_Account_Subscription__c uasThree =
            new Utility_Account_Subscription__c(Name = '0000238',
                Utility_Account_Log__c = ualog3.Id,
                Opportunity__c = opportunitythree.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 300,
                Calculated_Annual_Cost_of_Electricity__c = 300,
                Subscribed_Annual_Cost_of_Electricity__c = 300);

        insert new List<Utility_Account_Subscription__c>{uasOne, uasTwo, uasThree};
        uasOne.Customer_Subscription_KW_DC_STATIC__c = 0;
        uasTwo.Customer_Subscription_KW_DC_STATIC__c = 10;
        uasThree.Customer_Subscription_KW_DC_STATIC__c = 10;
        update new List<Utility_Account_Subscription__c>{uasOne, uasTwo, uasThree};

        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2018,1,1),
            Status__c = 'Billing'
        );

        Schedule_Z__c scheduleZ2 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P2',
            Shared_Solar_System__c = sss2.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2018,1,1),
            Status__c = 'Billing'
        );

        Schedule_Z__c scheduleZ3 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P3',
            Shared_Solar_System__c = sss3.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2018,1,1),
            Status__c = 'Billing'
        );

        insert new List<Schedule_Z__c>{scheduleZ1, scheduleZ2, scheduleZ3};
        Test.stopTest();
    }

    @IsTest
    public static void testSharedSolarSystemUpdateWithUAS() {
        Test.startTest();
        List<Shared_Solar_System__c> testSSS = [SELECT Name, Capacity_Committed_kW_DC__c, Total_Capacity_Committed_Reserved__c
        FROM Shared_Solar_System__c WHERE Name = 'Oxford Barrett St. P1'];
        System.assertNotEquals(5, testSSS[0].Capacity_Committed_kW_DC__c);
        System.assertEquals(0, testSSS[0].Capacity_Committed_kW_DC__c);
        List<Utility_Account_Subscription__c> uas = [SELECT Utility_Account_Log__c,
            Opportunity__c,
            Next_Schedule_Z_Status__c,
            Calculated_Annual_Cost_of_Electricity__c,
            Subscribed_Annual_Cost_of_Electricity__c,
            Customer_Subscription_KW_DC_STATIC__c
            FROM Utility_Account_Subscription__c
            WHERE Customer_Subscription_KW_DC_Static__c = 0];

        uas[0].Customer_Subscription_KW_DC_Static__c = 5;
        update uas;
        System.assertEquals(5, uas[0].Customer_Subscription_KW_DC_STATIC__c);

        update testSSS;
        List<Shared_Solar_System__c> updatedSSS = [SELECT Name, Capacity_Committed_kW_DC__c, Total_Capacity_Committed_Reserved__c
        FROM Shared_Solar_System__c WHERE Name = 'Oxford Barrett St. P1'];
        System.assertEquals(5, updatedSSS[0].Capacity_Committed_kW_DC__c);
        Test.stopTest();
    }

    @IsTest
    public static void testSharedSolarSystemDoesntUpdate() {
        List<Shared_Solar_System__c> testSSS = [SELECT Name, Capacity_Committed_kW_DC__c, Total_Capacity_Committed_Reserved__c
        FROM Shared_Solar_System__c WHERE Name = 'Oxford Barrett St. P1'];
        System.assertEquals(0, testSSS[0].Capacity_Committed_kW_DC__c);

        List<Utility_Account_Subscription__c> uas = [SELECT Utility_Account_Log__c,
            Opportunity__c,
            Next_Schedule_Z_Status__c,
            Calculated_Annual_Cost_of_Electricity__c,
            Subscribed_Annual_Cost_of_Electricity__c,
            Customer_Subscription_KW_DC_STATIC__c
        FROM Utility_Account_Subscription__c
        WHERE Customer_Subscription_KW_DC_Static__c = 0];

        uas[0].Customer_Subscription_KW_DC_Static__c = 20;
        update uas;
        System.assertEquals(20, uas[0].Customer_Subscription_KW_DC_STATIC__c);

        Test.startTest();
        SharedSolarSystemHandler sh1 = new SharedSolarSystemHandler();
        String sch = '0 0 1 * * ?';
        System.schedule('Test Shared Solar System Update', sch, sh1);
        Test.stopTest();

        List<Shared_Solar_System__c> updatedSSS = [SELECT Name, Capacity_Committed_kW_DC__c, Total_Capacity_Committed_Reserved__c
        FROM Shared_Solar_System__c WHERE Name = 'Oxford Barrett St. P1'];
        System.assertEquals(20, updatedSSS[0].Capacity_Committed_kW_DC__c);

    }
}