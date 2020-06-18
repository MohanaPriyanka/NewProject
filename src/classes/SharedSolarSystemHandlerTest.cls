/**
 * Created by AlyssaCooper on 3/20/2019.
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
        RecordType clientRT = [SELECT Id FROM RecordType WHERE Name = 'Client Account' LIMIT 1];
        Account clientAccount = new Account(name = 'Test Client', RecordTypeId = clientRT.Id);
        insert clientAccount;

        Partner__c newPartner = new Partner__c(
            Name = 'Partner',
            Account__c = clientAccount.Id
        );
        insert newPartner;
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
            Customer_Subscription_Type__c = 'kWh',
            Sizing_Method__c = 'Rate Class Ratio',
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
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'SSS 1',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Stage__c = 'Onboarding',
            Client_Account__c = clientAccount.Id,
            Product__c = normalCSProduct.Id,
            Utility_NMC_Tariff__c = everbillNMC.Id,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 48,
            Total_System_Size_kW_AC__c = 80,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 100,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All'
        );
        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(Name = 'SSS 2',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Stage__c = 'Onboarding',
            Client_Account__c = clientAccount.Id,
            Product__c = normalCSProduct.Id,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 32,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '2',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All'
        );
        Shared_Solar_System__c sss3 = new Shared_Solar_System__c(Name = 'SSS 3',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Client_Account__c = clientAccount.Id,
            Product__c = normalCSProduct.Id,
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
            Maximum_Subscription_Capacity_kWDC__c = 25);
        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3};
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
        List<Shared_Solar_System__c> ngAndEversourceSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{
                    nationalGrid.Id, eversource.Id
                },
                new Set<String>{
                    'SEMA', 'NEMA'
                }
            );
        System.assertEquals(3, ngAndEversourceSharedSolarSystems.size());
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
        Opportunity opportunityone =
            new Opportunity(Name = 'Alyssa Testcase1 0000234',
                AccountId = propAcct1.Id,
                Shared_Solar_System__c = sss1.Id,
                Customer_Group__c = 'Residential',
                Partner_tag_lookup__c = newPartner.Id,
                StageName = 'Complete',
                NMC_Tariff__c = everbillNMC.Id,
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        Opportunity opportunitytwo =
            new Opportunity(Name = 'Alyssa Testcase2 0000236',
                AccountId = propAcct2.Id,
                Shared_Solar_System__c = sss2.Id,
                Customer_Group__c = 'Residential',
                Partner_tag_lookup__c = newPartner.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        Opportunity opportunitythree =
            new Opportunity(Name = 'Alyssa Testcase3 0000238',
                AccountId = propAcct3.Id,
                Shared_Solar_System__c = sss2.Id,
                Customer_Group__c = 'Residential',
                Partner_tag_lookup__c = newPartner.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        Opportunity opportunityFour =
            new Opportunity(Name = 'Alyssa Anchor 0000238',
                AccountId = propAcct3.Id,
                Shared_Solar_System__c = sss2.Id,
                Partner_tag_lookup__c = newPartner.Id,
                StageName = 'Complete',
                Customer_Group__c = 'Anchor',
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        insert new List<Opportunity>{opportunityone, opportunitytwo, opportunitythree, opportunityFour};
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
                Shared_Solar_System__c = sss2.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 8000
            );
        Utility_Account_Subscription__c uasThree =
            new Utility_Account_Subscription__c(Name = '0000238',
                Utility_Account_Log__c = ualog3.Id,
                Opportunity__c = opportunitythree.Id,
                Shared_Solar_System__c = sss2.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 300
            );
        Utility_Account_Subscription__c uasFour =
            new Utility_Account_Subscription__c(Name = '0000239',
                Utility_Account_Log__c = ualog3.Id,
                Opportunity__c = opportunityFour.Id,
                Shared_Solar_System__c = sss2.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 30000
            );
        insert new List<Utility_Account_Subscription__c>{uasOne, uasTwo, uasThree, uasFour};
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
    public static void addMoreTestRecords() {
        Shared_Solar_System__c sss2 = [
            SELECT Id, Product__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        Account accountParent = new Account(Name = 'Parent Account 1', Client_Brand_Key__c = 'BluewaveLogo');
        insert accountParent;
        Account propAcct1 = new Account(
            Name = 'Prop Account 1',
            Parent_Account__c = accountParent.Id);
        Account propAcct2 = new Account(
            Name = 'Prop Account 2',
            Parent_Account__c = accountParent.Id);
        Account propAcct3 = new Account(
            Name = 'Prop Account 3',
            Parent_Account__c = accountParent.Id);
        insert new List<Account>{propAcct1, propAcct2, propAcct3};
        Utility_Account_Log__c ualog1 = new Utility_Account_Log__c(
            Name = '1100234',
            Account__c = propAcct1.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Name one');
        Utility_Account_Log__c ualog2 = new Utility_Account_Log__c(
            Name = '1100236',
            Account__c = propAcct2.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Name two');
        Utility_Account_Log__c ualog3 = new Utility_Account_Log__c(
            Name = '1100238',
            Account__c = propAcct3.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Name three');
        insert new List<Utility_Account_Log__c>{ualog1, ualog2, ualog3};
        Opportunity opportunityone =
            new Opportunity(Name = 'Test1 0000234',
                AccountId = propAcct1.Id,
                Shared_Solar_System__c = sss2.Id,
                StageName = 'Cancelled',
                Product__c = sss2.Product__c,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        Opportunity opportunitytwo =
            new Opportunity(Name = 'Test2 0000236',
                AccountId = propAcct2.Id,
                Shared_Solar_System__c = sss2.Id,
                StageName = 'Expired',
                Product__c = sss2.Product__c,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        Opportunity opportunitythree =
            new Opportunity(Name = 'Test3 0000238',
                AccountId = propAcct3.Id,
                Shared_Solar_System__c = sss2.Id,
                StageName = 'QC in Process',
                Product__c = sss2.Product__c,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        Opportunity opportunityFour =
            new Opportunity(Name = 'Other 0000238',
                AccountId = propAcct3.Id,
                Shared_Solar_System__c = sss2.Id,
                StageName = 'Pending BW Signature',
                Product__c = sss2.Product__c,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        insert new List<Opportunity>{opportunityone, opportunitytwo, opportunitythree, opportunityFour};
        Utility_Account_Subscription__c uasOne =
            new Utility_Account_Subscription__c(Name = '1100234',
                Utility_Account_Log__c = ualog1.Id,
                Opportunity__c = opportunityone.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 4200,
                Calculated_Annual_Cost_of_Electricity__c = 4200,
                Subscribed_Annual_Cost_of_Electricity__c = 4200);
        Utility_Account_Subscription__c uasTwo =
            new Utility_Account_Subscription__c(Name = '1100236',
                Utility_Account_Log__c = ualog2.Id,
                Opportunity__c = opportunitytwo.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 8200,
                Calculated_Annual_Cost_of_Electricity__c = 8200,
                Subscribed_Annual_Cost_of_Electricity__c = 8200);
        Utility_Account_Subscription__c uasThree =
            new Utility_Account_Subscription__c(Name = '1100238',
                Utility_Account_Log__c = ualog3.Id,
                Opportunity__c = opportunitythree.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 320,
                Calculated_Annual_Cost_of_Electricity__c = 320,
                Subscribed_Annual_Cost_of_Electricity__c = 320);
        Utility_Account_Subscription__c uasFour =
            new Utility_Account_Subscription__c(Name = '1100239',
                Utility_Account_Log__c = ualog3.Id,
                Opportunity__c = opportunityFour.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 32000,
                Calculated_Annual_Cost_of_Electricity__c = 32000,
                Subscribed_Annual_Cost_of_Electricity__c = 32000);
        insert new List<Utility_Account_Subscription__c>{uasOne, uasTwo, uasThree, uasFour};
    }
    public static void createContractTestRecords(){
        Account account = [SELECT Id FROM Account LIMIT 1];
        RecordType clientRT = [SELECT Id FROM RecordType WHERE Name = 'Client Contract' LIMIT 1];

        Contract contractA = new Contract(
            Name = 'Client Contract A',
            AccountId = account.Id,
            RecordTypeId = clientRT.Id
        );
        insert contractA;

        Contract_Fee_Detail__c acq = new Contract_Fee_Detail__c(
            Contract__c = contractA.Id,
            Acquisition_Channels_BCS_Acquired__c = true,
            Acquisition_Channels_Non_BCS_Acquired__c = true,
            Acquisition_Cust_Group_Anchor__c = true,
            Acquisition_Cust_Group_Public_Offtake__c = true,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Cust_Group_Non_Residential__c = true,
            Acquisition_Sizing_Type_Downsizing__c = true,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Type_Acquisition__c = true,
            Acquisition_Type_Reacquisition__c = false,
            Fee__c = 0.10
        );
        Contract_Fee_Detail__c reacq = new Contract_Fee_Detail__c(
            Contract__c = contractA.Id,
            Acquisition_Channels_BCS_Acquired__c = true,
            Acquisition_Channels_Non_BCS_Acquired__c = true,
            Acquisition_Cust_Group_Anchor__c = true,
            Acquisition_Cust_Group_Public_Offtake__c = true,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Cust_Group_Non_Residential__c = true,
            Acquisition_Sizing_Type_Downsizing__c = true,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Type_Acquisition__c = false,
            Acquisition_Type_Reacquisition__c = true,
            Fee__c = 0.20
        );
        insert new List<Contract_Fee_Detail__c>{
            acq, reacq
        };

        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Client_Acquisition_Contract__c, Client_Management_Contract__c
            FROM Shared_Solar_System__c
        ];
        for (Shared_Solar_System__c sss : sssList){
            sss.Client_Acquisition_Contract__c = contractA.Id;
            sss.Client_Management_Contract__c = contractA.Id;
        }
        update sssList;
    }

    @IsTest
    public static void testApexContext() {
        Shared_Solar_System__c sss = [
            SELECT Id, Apex_Context__c, Stage__c, Estimated_COD_Date_Manual__c, Estimated_PTO_Date_MANUAL__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 1'
            LIMIT 1
        ];
        //Change SSS Stage to Acquisition so Validation Rule is active
        sss.Estimated_COD_Date_Manual__c = System.today();
        sss.Estimated_PTO_Date_MANUAL__c = System.today();
        sss.Stage__c = 'Acquisition';
        update sss;
        sss = [
            SELECT Id, Apex_Context__c, Total_System_Size_kWh_DC__c, Stage__c
            FROM Shared_Solar_System__c
            WHERE Id = :sss.Id
            LIMIT 1
        ];
        //Before setting Apex Context - should not be able to update system size due to Validation Rule
        sss.Total_System_Size_kWh_DC__c = 80;
        try {
            update sss;
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage(), 'Update of SSS should fail due to Validation Rule');
        }
        sss = [
            SELECT Id, Apex_Context__c, Total_System_Size_kWh_DC__c
            FROM Shared_Solar_System__c
            WHERE Id = :sss.Id
            LIMIT 1
        ];
        //Feature flag is used in validation rule
        FeatureService featureService = new FeatureService();
        Boolean featureOn = featureService.isEnabled('Subscription_Orders');
        if (featureOn) {
            System.assertEquals(48, sss.Total_System_Size_kWh_DC__c);
        } else {
            System.assertEquals(80, sss.Total_System_Size_kWh_DC__c);
        }
        //Set Apex_Context to true to bypass validation rule
        sss.Apex_Context__c = true;
        sss.Total_System_Size_kWh_DC__c = 80;
        update sss;
        sss = [
            SELECT Id, Apex_Context__c, Total_System_Size_kWh_DC__c
            FROM Shared_Solar_System__c
            WHERE Id = :sss.Id
            LIMIT 1
        ];
        //Apex Context is automatically set back to false after updating SSS
        System.assertEquals(false, sss.Apex_Context__c);
        System.assertEquals(80, sss.Total_System_Size_kWh_DC__c);
    }
    @IsTest
    public static void testSharedSolarSystemUpdate() {
        Test.startTest();
        List<Utility_Account_Subscription__c> uas = [SELECT Utility_Account_Log__c,
            Opportunity__c,
            Next_Schedule_Z_Status__c,
            Calculated_Annual_Cost_of_Electricity__c,
            Subscribed_Annual_Cost_of_Electricity__c,
            Customer_Subscription_KW_DC__c,
            Opportunity__r.Shared_Solar_System__c
        FROM Utility_Account_Subscription__c
        WHERE Name = '0000234'
        LIMIT  1];
        List<Shared_Solar_System__c> testSSS = [SELECT Name, Capacity_Committed_kW_DC__c
        FROM Shared_Solar_System__c
        WHERE Id =: uas[0].Opportunity__r.Shared_Solar_System__c];
        System.assertNotEquals(0, uas[0].Customer_Subscription_KW_DC__c);
        update testSSS;
        System.assertEquals(uas[0].Customer_Subscription_KW_DC__c, testSSS[0].Capacity_Committed_kW_DC__c);
        System.assertNotEquals(0, testSSS[0].Capacity_Committed_kW_DC__c);
        Test.stopTest();
    }
    @IsTest
    public static void testMultipleUASes() {
        Shared_Solar_System__c originalSSS = [
            SELECT Id, Capacity_Committed_kW_DC__c, Anchor_capacity_reserved__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        // 2 UASes:  6.1538 , 0.2308 = 6.3846
        // 1 Anchor: 23.0769
        // Subscription Orders use the rounded version of the subscription
        FeatureService featureService = new FeatureService();
        if (featureService.isEnabled('Subscription_Orders')) {
            System.assertEquals(6.384,originalSSS.Capacity_Committed_kW_DC__c);
            System.assertEquals(23.0784,originalSSS.Anchor_capacity_reserved__c);
        } else {
            System.assertEquals(6.3846,originalSSS.Capacity_Committed_kW_DC__c);
            System.assertEquals(23.0769,originalSSS.Anchor_capacity_reserved__c);
        }

        Utility_Account_Subscription__c selectedUAS = [
            SELECT Utility_Account_Log__c,
                Opportunity__c,
                Next_Schedule_Z_Status__c,
                Annual_kwh_subscription_future__c,
                Calculated_Annual_Cost_of_Electricity__c,
                Subscribed_Annual_Cost_of_Electricity__c,
                Customer_Subscription_KW_DC__c,
                Opportunity__r.Shared_Solar_System__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000236'
            LIMIT 1
        ];
        // Increase one subscription:
        if (featureService.isEnabled('Subscription_Orders')) {
            Subscription_Order__c resize = new Subscription_Order__c(
                Utility_Account_Subscription__c = selectedUAS.Id,
                New_Annual_kWh__c = 12000,
                Type__c = 'Resize',
                Approval_Status__c = 'Approved',
                Effective_Date__c = System.now()
            );
            insert resize;
        } else {
            selectedUAS.Annual_kwh_subscription_future__c = 12000;
            update selectedUAS;
        }
        Test.startTest();
        SharedSolarSystemHandler handler = new SharedSolarSystemHandler();
        handler.updateSSS();
        Test.stopTest();
        Shared_Solar_System__c sssUpdated = [
            SELECT Id, Capacity_Committed_kW_DC__c, Anchor_capacity_reserved__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];

        if (featureService.isEnabled('Subscription_Orders')) {
            System.assertEquals(9.4624,sssUpdated.Capacity_Committed_kW_DC__c);
            System.assertEquals(23.0784,sssUpdated.Anchor_capacity_reserved__c);
        } else {
            System.assertEquals(9.4616,sssUpdated.Capacity_Committed_kW_DC__c);
            System.assertEquals(23.0769,sssUpdated.Anchor_capacity_reserved__c);
        }
    }
    @IsTest
    public static void testDifferentStatuses() {
        addMoreTestRecords();
        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Customer_Subscription_KW_DC__c, Name, Opportunity__r.StageName, Next_Schedule_Z_Status__c,
                Future_Customer_Subscription_KWDC_Rollup__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Shared_Solar_System__r.Name = 'SSS 2'
            AND Opportunity__r.Customer_Group__c != 'Anchor'
            ORDER BY Name
        ];
        System.assertEquals(6,uasList.size());
        Integer countComplete = 0;
        Decimal sumComplete = 0;
        Integer countReserved = 0;
        Decimal sumReserved = 0;
        Integer countOther = 0;
        Decimal sumOther = 0;


        for (Utility_Account_Subscription__c uas : uasList){
            if (uas.Opportunity__r.StageName == 'Complete') {
                countComplete += 1;
                sumComplete += uas.Customer_Subscription_KW_DC__c;
            } else if (uas.Opportunity__r.StageName != 'Expired' && uas.Opportunity__r.StageName != 'Cancelled') {
                countReserved += 1;
                sumReserved += uas.Customer_Subscription_KW_DC__c;
            } else {
                countOther += 1;
                sumOther += uas.Customer_Subscription_KW_DC__c;
            }
        }

        FeatureService featureService = new FeatureService();
        if (featureService.isEnabled('Subscription_Orders')) {
            System.assertEquals(6.3840,sumComplete);
            System.assertEquals(24.8608,sumReserved);
            System.assertEquals(9.5392,sumOther);
            sumReserved = sumReserved.setScale(6);
        } else {
            System.assertEquals(6.3846,sumComplete);
            System.assertEquals(24.8616,sumReserved);
            System.assertEquals(9.5385,sumOther);
        }

        System.assertEquals(4, countComplete + countReserved);
        Test.startTest();
            SharedSolarSystemHandler handler = new SharedSolarSystemHandler();
            handler.updateSSS();
        Test.stopTest();
        Shared_Solar_System__c sssUpdated = [
            SELECT Id, Capacity_Committed_kW_DC__c, Anchor_capacity_reserved__c, Reserved_capacity_kW_DC__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(sumComplete,sssUpdated.Capacity_Committed_kW_DC__c);
        System.assertEquals(String.valueOf(sumReserved),sssUpdated.Reserved_capacity_kW_DC__c);
    }
    @IsTest
    public static void testStageUpdate(){
        List<Shared_Solar_System__c> testSSS = [
            SELECT Name, Capacity_Committed_kW_DC__c, Stage__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 1'
        ];
        String response = SharedSolarSystemHandler.updateStage(testSSS[0].Id,'Pending');
        System.assertEquals('Success',response);
        //Does not update because of validation rules
        String responseTwo = SharedSolarSystemHandler.updateStage(testSSS[0].Id,'Management');
        System.assertNotEquals('Success',responseTwo);
    }
    @IsTest
    public static void testReservedAnchorCapacity(){
        List<Shared_Solar_System__c> sssList = [
            SELECT Name, Capacity_Committed_kW_DC__c, Stage__c, Anchor_Capacity_Reserved__c
            FROM Shared_Solar_System__c
            ORDER BY Name
            LIMIT 2
        ];
        sssList[0].Reserved_Anchor_Capacity__c = 7;
        update sssList[0];
        List<Shared_Solar_System__c> checkSSS = [
            SELECT Name, Capacity_Committed_kW_DC__c, Stage__c, Anchor_Capacity_Reserved__c, Reserved_Anchor_Capacity__c,
                Capacity_Available_to_be_Reserved__c, Total_Capacity_Committed_Reserved__c, Total_System_Size_kWh_DC__c
            FROM Shared_Solar_System__c
            ORDER BY Name
            LIMIT 2
        ];
        //SSS1 does NOT have anchors but the Reserved Anchor Capacity field is populated
        //SSS2 does have anchors --> Anchor Capacity should be sum of anchor opps
        System.assertEquals(7, checkSSS[0].Reserved_Anchor_Capacity__c);
        System.assertEquals(7, checkSSS[0].Anchor_Capacity_Reserved__c);

        FeatureService featureService = new FeatureService();
        if (featureService.isEnabled('Subscription_Orders')) {
            System.assertEquals(23.0784, checkSSS[1].Anchor_Capacity_Reserved__c);
        } else {
            System.assertEquals(23.0769, checkSSS[1].Anchor_Capacity_Reserved__c);
        }

        checkSSS[0].Open__c = false;
        checkSSS[1].Open__c = false;
        update checkSSS;
        //Move the SSS1 into management --> Anchor Capacity should be 0
        //Move SSS2 into Management --> should be sum of anchor opps
        String response = SharedSolarSystemHandler.updateStage(checkSSS[0].Id,'Management');
        System.assertEquals('Success', response);
        String responseTwo = SharedSolarSystemHandler.updateStage(checkSSS[1].Id,'Management');
        System.assertEquals('Success', responseTwo);
        checkSSS = [
            SELECT Name, Capacity_Committed_kW_DC__c, Stage__c, Anchor_Capacity_Reserved__c
            FROM Shared_Solar_System__c
            ORDER BY Name
            LIMIT 2
        ];
        System.assertEquals('Management', checkSSS[0].Stage__c);
        System.assertEquals(0, checkSSS[0].Anchor_Capacity_Reserved__c);
        System.assertEquals('Management', checkSSS[1].Stage__c);

        if (featureService.isEnabled('Subscription_Orders')) {
            System.assertEquals(23.0784, checkSSS[1].Anchor_Capacity_Reserved__c);
        } else {
            System.assertEquals(23.0769, checkSSS[1].Anchor_Capacity_Reserved__c);
        }
    }
    @IsTest
    public static void testReacqStartDateChange(){
        createContractTestRecords();
        FeatureService featureService = new FeatureService();

        Date sevenDaysAgo = System.today().addDays(-7);
        Date threeDaysAgo = System.today().addDays(-3);

        List<Subscription_Order__c> beforeOrders = [
            SELECT Id, Contract_Fee_Detail__c, Approval_Status__c
            FROM Subscription_Order__c
        ];

        if (featureService.isEnabled('Subscription_Orders')) {
            System.assertEquals(4,beforeOrders.size());
            for (Subscription_Order__c order : beforeOrders){
                System.assertEquals(null,order.Contract_Fee_Detail__c);
            }
        }

        Test.startTest();
            List<Shared_Solar_System__c> sssList = [
                SELECT Name, Reacquisition_Start_Date__c, Client_Acquisition_Contract__c, Client_Management_Contract__c
                FROM Shared_Solar_System__c
                ORDER BY Name
                LIMIT 2
            ];
            System.debug(sssList);
            System.assertEquals(null,sssList[0].Reacquisition_Start_Date__c);
            System.assertEquals(null,sssList[1].Reacquisition_Start_Date__c);
            sssList[0].Reacquisition_Start_Date__c = sevenDaysAgo;
            sssList[1].Reacquisition_Start_Date__c = threeDaysAgo;
            update sssList;
        Test.stopTest();

        List<Shared_Solar_System__c> sssListTwo = [
            SELECT Name, Reacquisition_Start_Date__c, Client_Acquisition_Contract__c, Client_Management_Contract__c
            FROM Shared_Solar_System__c
            ORDER BY Name
            LIMIT 2
        ];
        System.debug(sssListTwo);

        List<Subscription_Order__c> afterOrders = [
            SELECT Id, Contract_Fee_Detail__c, Contract_Fee_Detail__r.Fee__c,
                Utility_Account_Subscription__r.Shared_Solar_System__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.Reacquisition_Start_Date__c
            FROM Subscription_Order__c
        ];


        if (featureService.isEnabled('Subscription_Orders')) {
            System.assertEquals(4,afterOrders.size());
            for (Subscription_Order__c order : afterOrders){
                // Reacq has $0.20 fee, acq has $0.10 fee
                System.assertEquals(0.20,order.Contract_Fee_Detail__r.Fee__c);
            }
        }
    }
}