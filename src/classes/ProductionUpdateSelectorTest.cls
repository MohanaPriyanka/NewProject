@isTest
public class ProductionUpdateSelectorTest {
    @testSetup public static void setupTestData() {
        TestFactory.insertBWAddress();
        TestFactory.setCSBillSettings();

        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );
        insert new List<Utility__c>{
            eversource
        };

        Load_U__c everLZU = new Load_U__c(Name = '02633',
            LZ__c = 'SEMA',
            Town__c = 'Medfield');
        insert new List<Load_U__c>{
            everLZU
        };

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU.Id,
            Utility__c = eversource.Id
        );
        insert new List<ZipCode_Utility_Junction__c>{
            junction
        };

        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c(Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Current_Billing_Rate__c = TRUE);
        insert new List<Utility_NMC_Tariff__c>{
            everbillNMC
        };

        Product2 normalCSProduct = new Product2(Name = 'BlueWave Community Solar',
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

        Entity__c entity1 = new Entity__c(Name = 'Project A Oak Road');
        insert entity1;

        Shared_Solar_System__c sss1 =
            new Shared_Solar_System__c(Name = 'Project A Oak Road',
                Service_Territory__c = 'SEMA',
                Open__c = true,
                Client_Account__c = clientAccount.Id,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c = 996,
                System_Utility__c = 'Eversource',
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
                System_Utility__c = 'Eversource',
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '2',
                Utility_NMC_Tariff__c = everbillNMC.Id,
                Billing_Method__c = 'NMC',
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Product__c = normalCSProduct.Id,
                Sales_Partners__c = 'All',
                BWC_Project_Entity_Manual__c = entity1.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id);

        Shared_Solar_System__c sss3 =
            new Shared_Solar_System__c(Name = 'Project C Other St',
                Service_Territory__c = 'SEMA',
                Open__c = true,
                Client_Account__c = clientAccount.Id,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1245.86,
                Total_System_Size_kW_AC__c = 996,
                System_Utility__c = 'Eversource',
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '2',
                Utility_NMC_Tariff__c = everbillNMC.Id,
                Billing_Method__c = 'NMC',
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Product__c = normalCSProduct.Id,
                Sales_Partners__c = 'All',
                BWC_Project_Entity_Manual__c = entity1.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id);
        insert new List<Shared_Solar_System__c>{
            sss1, sss2, sss3
        };

        String firstName1 = 'Ashley';
        String firstName2 = 'Steven ';
        String firstName3 = 'Marie';
        String firstName4 = 'Justin ';
        String firstName5 = 'Russell';
        String firstName6 = 'Joshua';
        String firstName7 = 'Donna';
        String firstName8 = 'Keith';
        String firstName9 = 'Mark';
        String firstName10 = 'Albert';

        String lastName1 = 'Smith';
        String lastName2 = 'Ward';
        String lastName3 = 'Mitchell';
        String lastName4 = 'Jenkins';
        String lastName5 = 'Butler';
        String lastName6 = 'Phillips';
        String lastName7 = 'Simmons';
        String lastName8 = 'Morgan';
        String lastName9 = 'Allen';
        String lastName10 = 'Price';

        String accountName1 = firstName1 + ' ' + lastname1;
        String accountName2 = firstName2 + ' ' + lastname2;
        String accountName3 = firstName3 + ' ' + lastname3;
        String accountName4 = firstName4 + ' ' + lastname4;
        String accountName5 = firstName5 + ' ' + lastname5;
        String accountName6 = firstName6 + ' ' + lastname6;
        String accountName7 = firstName7 + ' ' + lastname7;
        String accountName8 = firstName8 + ' ' + lastname8;
        String accountName9 = firstName9 + ' ' + lastname9;
        String accountName10 = firstName10 + ' ' + lastname10;

        Account accountParent1 = new Account(
            Name = accountName1);
        Account accountParent2 = new Account(
            Name = accountName2);
        Account accountParent3 = new Account(
            Name = accountName3);
        Account accountParent4 = new Account(
            Name = accountName4);
        Account accountParent5 = new Account(
            Name = accountName5);

        insert new List<Account>{
            accountParent1, accountParent2, accountParent3, accountParent4, accountParent5
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
        Contact contact4 = new Contact(
            FirstName = firstName4,
            LastName = lastname4,
            AccountId = accountParent4.Id);
        Contact contact5 = new Contact(
            FirstName = firstName5,
            LastName = lastname5,
            AccountId = accountParent5.Id);

        insert new List<Contact>{
            contact1, contact2, contact3, contact4, contact5
        };

        Account propAccount1 = new Account(name = accountName1,
            Parent_Account__c = accountParent1.Id,
            Send_Bills_Contact__c = contact1.Id);
        Account propAccount2 = new Account(name = accountName2,
            Parent_Account__c = accountParent2.Id,
            Send_Bills_Contact__c = contact2.Id);
        Account propAccount3 = new Account(name = accountName3,
            Parent_Account__c = accountParent3.Id,
            Send_Bills_Contact__c = contact3.Id);
        Account propAccount4 = new Account(name = accountName4,
            Parent_Account__c = accountParent4.Id,
            Send_Bills_Contact__c = contact4.Id);
        Account propAccount5 = new Account(name = accountName5,
            Parent_Account__c = accountParent5.Id,
            Send_Bills_Contact__c = contact5.Id);

        insert new List<Account>{
            propAccount1, propAccount2, propAccount3, propAccount4, propAccount5
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
            Name = '0000237',
            Account__c = propAccount4.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = accountName4);
        Utility_Account_Log__c ualog5 = new Utility_Account_Log__c(
            Name = '0000238',
            Account__c = propAccount5.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = accountName5);
        Utility_Account_Log__c ualog9 = new Utility_Account_Log__c(
            Name = '0000242',
            Account__c = propAccount1.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = accountName9);
        Utility_Account_Log__c ualog10 = new Utility_Account_Log__c(
            Name = '0000243',
            Account__c = propAccount4.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = accountName10);

        insert new List<Utility_Account_Log__c>{
            ualog1, ualog2, ualog3, ualog4, ualog5, ualog9, ualog10
        };

        Opportunity opportunity1 = new Opportunity(
            Name = accountName1,
            AccountId = propAccount1.Id,
            Shared_Solar_System__c = sss1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity2 = new Opportunity(
            Name = accountName2,
            AccountId = propAccount2.Id,
            Shared_Solar_System__c = sss1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity3 = new Opportunity(
            Name = accountName3,
            AccountId = propAccount3.Id,
            Shared_Solar_System__c = sss1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity4 = new Opportunity(
            Name = accountName4,
            AccountId = propAccount4.Id,
            Shared_Solar_System__c = sss1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity5 = new Opportunity(
            Name = accountName5,
            AccountId = propAccount5.Id,
            Shared_Solar_System__c = sss2.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity6 = new Opportunity(
            Name = accountName6,
            AccountId = propAccount1.Id,
            Shared_Solar_System__c = sss2.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity7 = new Opportunity(
            Name = accountName7,
            AccountId = propAccount2.Id,
            Shared_Solar_System__c = sss2.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity8 = new Opportunity(
            Name = accountName8,
            AccountId = propAccount3.Id,
            Shared_Solar_System__c = sss3.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity9 = new Opportunity(
            Name = accountName9,
            AccountId = propAccount4.Id,
            Shared_Solar_System__c = sss3.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());
        Opportunity opportunity10 = new Opportunity(
            Name = accountName10,
            AccountId = propAccount5.Id,
            Shared_Solar_System__c = sss3.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today());

        insert new List<Opportunity>{
            opportunity1, opportunity2, opportunity3, opportunity4, opportunity5,
            opportunity6, opportunity7, opportunity8, opportunity9, opportunity10
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
            Name = '0000236',
            Utility_Account_Log__c = ualog3.Id,
            Opportunity__c = opportunity3.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 20);
        Utility_Account_Subscription__c uas4 = new Utility_Account_Subscription__c(
            Name = '0000237',
            Utility_Account_Log__c = ualog4.Id,
            Opportunity__c = opportunity4.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 19);
        Utility_Account_Subscription__c uas5 = new Utility_Account_Subscription__c(
            Name = '0000238',
            Utility_Account_Log__c = ualog5.Id,
            Opportunity__c = opportunity5.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 17);
        Utility_Account_Subscription__c uas6 = new Utility_Account_Subscription__c(
            Name = '00002341',
            Utility_Account_Log__c = ualog1.Id,
            Opportunity__c = opportunity6.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 14);
        Utility_Account_Subscription__c uas7 = new Utility_Account_Subscription__c(
            Name = '00002351',
            Utility_Account_Log__c = ualog2.Id,
            Opportunity__c = opportunity7.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 11);
        Utility_Account_Subscription__c uas8 = new Utility_Account_Subscription__c(
            Name = '00002361',
            Utility_Account_Log__c = ualog3.Id,
            Opportunity__c = opportunity8.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 5);
        Utility_Account_Subscription__c uas9 = new Utility_Account_Subscription__c(
            Name = '0000242',
            Utility_Account_Log__c = ualog9.Id,
            Opportunity__c = opportunity9.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 24);
        Utility_Account_Subscription__c uas10 = new Utility_Account_Subscription__c(
            Name = '0000243',
            Utility_Account_Log__c = ualog10.Id,
            Opportunity__c = opportunity10.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = 23);

        insert new List<Utility_Account_Subscription__c>{
            uas1, uas2, uas3, uas4, uas5, uas6, uas7, uas8, uas9, uas10
        };

        Date thisMonth = Date.today();
        Date lastMonth = thisMonth.addMonths(-1);
        Date nextMonth = thisMonth.addMonths(1);

        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Status__c = 'Billing'
        );

        Schedule_Z__c scheduleZ2 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P2',
            Shared_Solar_System__c = sss2.Id,
            Status__c = 'Billing'
        );

        Schedule_Z__c scheduleZ3 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P2',
            Shared_Solar_System__c = sss3.Id,
            Status__c = 'Billing'
        );

        insert new List<Schedule_Z__c>{
            scheduleZ1, scheduleZ2, scheduleZ3
        };

        Energy_Usage_Update__c productionupdateA1 = new Energy_Usage_Update__c(
            Name = 'sssA - This Month',
            Shared_Solar_System__c = sss1.id,
            Schedule_Z__c = scheduleZ1.id,
            Production__c = 90000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = lastMonth,
            Total_System_NMCs__c = 16632,
            Bill_Status__c = 'Ready to Generate',
            Date__c = thisMonth
        );

        Energy_Usage_Update__c productionupdateA2 = new Energy_Usage_Update__c(
            Name = 'sssB - This Month',
            Shared_Solar_System__c = sss2.id,
            Schedule_Z__c = scheduleZ2.id,
            Production__c = 120000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = lastMonth,
            Total_System_NMCs__c = 22176,
            Bill_Status__c = 'Ready to Generate',
            Date__c = thisMonth
        );

        Energy_Usage_Update__c productionupdateA3 = new Energy_Usage_Update__c(
            Name = 'sssC - This Month',
            Shared_Solar_System__c = sss3.id,
            Schedule_Z__c = scheduleZ3.id,
            Production__c = 140000,
            Net_Metering_Rate_Applied__c = 0.1848,
            Billing_Period_End_Date__c = lastMonth,
            Total_System_NMCs__c = 25872,
            Bill_Status__c = 'Ready to Generate',
            Date__c = thisMonth
        );

        Energy_Usage_Update__c productionupdateA4 = new Energy_Usage_Update__c(
            Name = 'sssC - This Month',
            Shared_Solar_System__c = sss3.id,
            Schedule_Z__c = scheduleZ3.id,
            Production__c = 142300,
            Net_Metering_Rate_Applied__c = 0.1548,
            Billing_Period_End_Date__c = thisMonth,
            Total_System_NMCs__c = 25872,
            Bill_Status__c = 'Ready to Generate',
            Date__c = nextMonth
        );

        insert new List<Energy_Usage_Update__c>{
            productionupdateA1, productionupdateA2, productionupdateA3, productionupdateA4
        };
    }

    @isTest public static void testQueryProdUpdate() {
        Date todaysDate = Date.today();

        List<Energy_Usage_Update__c> prodList;
        prodList = ProductionUpdateSelector.getProductionUpdatesByMonth(todaysDate.month(),String.valueOf(todaysDate.year()));

        System.assertEquals(3,prodList.size());

        List<Energy_Usage_Update__c> prodListById;
        prodListById = ProductionUpdateSelector.getAllProductionUpdatesById(new List<Id> {prodList[0].Id, prodList[1].Id});
        System.assertEquals(2,prodListById.size());
    }

    @isTest public static void testSSSWithoutProdUpdates() {
        List<Shared_Solar_System__c> sssList;
        sssList = SharedSolarSystemsSelector.getAllSSSWithProdUpdatesNotInList(null);

        System.assertEquals(3,sssList.size());
    }
}