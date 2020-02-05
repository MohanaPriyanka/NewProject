/**
 * Created by JordanPentaleri on 1/30/2020.
 */

@IsTest
public with sharing class ClientBrandingServiceTest {
    @TestSetup
    public static void testSetup() {
        // Because we rely on Aggregate Results, this test is difficult to mock:
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
        Account clientAccount1 = new Account(
            Name = 'AmpRed Client',
            Client_Brand_Key__c = 'AmpRed'
        );
        Account clientAccount2 = new Account(
            Name = 'AmpBlack Client',
            Client_Brand_Key__c = 'AmpBlack'
        );
        Account clientAccount3 = new Account(
            Name = 'BluewaveLogo Client',
            Client_Brand_Key__c = 'BluewaveLogo'
        );
        insert new List<Account>{clientAccount1, clientAccount2, clientAccount3};

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
            Client_Account__c = clientAccount1.Id,
            Gateway__c = chGateway.Id);
        insert entity1;

        Entity__c entity2 = new Entity__c(
            Name = 'Project B Main St',
            Client_Account__c = clientAccount2.Id,
            Gateway__c = chGateway.Id);
        insert entity2;

        Shared_Solar_System__c sss1 =
            new Shared_Solar_System__c(Name = 'Project A Oak Road',
                Service_Territory__c = 'SEMA',
                Open__c = true,
                Client_Account__c = clientAccount1.Id,
                Client_Brand_Key__c = 'AmpBlack',
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
                Client_Account__c = clientAccount2.Id,
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

        String firstName1 = 'acA';
        String firstName2 = 'acB';
        String firstName3 = 'acC';

        String lastName1 = 'A';
        String lastName2 = 'B';
        String lastName3 = 'C';

        String accountName1 = firstName1 + ' ' + lastname1;
        String accountName2 = firstName2 + ' ' + lastname2;
        String accountName3 = firstName3 + ' ' + lastname3;

        Account accountParent1 = new Account(
            Name = accountName1,
            Client_Brand_Key__c = 'AmpBlack'
        );
        Account accountParent2 = new Account(
            Name = accountName2,
            Client_Brand_Key__c = 'BlueWaveLogo'
        );

        insert new List<Account>{
            accountParent1, accountParent2
        };

        Account propAccount1 = new Account(
            name = accountName1,
            Client_Brand_Key__c = 'BluewaveLogo',
            Parent_Account__c = accountParent1.Id
        );
        Account propAccount2 = new Account(
            name = accountName2,
            Client_Brand_Key__c = 'BluewaveLogo',
            Parent_Account__c = accountParent1.Id
        );
        Account propAccount3 = new Account(
            name = accountName3,
            Client_Brand_Key__c = 'AmpBlack',
            Parent_Account__c = accountParent2.Id
        );

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
    }

    @IsTest
    private static void testGetBrandKeysByAccount() {
        Set<Id> parentAcctIds = new Set<Id>();
        List<Account> propertyAccounts = [
            SELECT Id, Name, Parent_Account__c
            FROM Account
            WHERE Parent_Account__c != null
            ORDER BY Name
        ];
        for (Account acct : propertyAccounts){
            parentAcctIds.add(acct.Parent_Account__c);
        }
        System.assertEquals(2,parentAcctIds.size());
        System.assertEquals(3,propertyAccounts.size());

        UASSelector uasSelector = new UASSelector();
        List<AggregateResult> uasSummary = uasSelector.getBrandKeySummary(parentAcctIds);
        System.assertEquals(5,uasSummary.size());

        ClientBrandingService brandingService = new ClientBrandingService();

        // Even though an entity is set to AmpRed, the SSS override field makes it AmpBlack:
        Map<Id, Account> acctMap = brandingService.getPropertyAccountBrandKey(uasSummary);
        System.assertEquals('AmpBlack', acctMap.get(propertyAccounts[0].Id).Client_Brand_Key__c);
        System.assertEquals('AmpBlack', acctMap.get(propertyAccounts[1].Id).Client_Brand_Key__c);
        System.assertEquals('AmpBlack', acctMap.get(propertyAccounts[2].Id).Client_Brand_Key__c);

        Map<Id, Account> newAcctMap = brandingService.getParentAccountBrandKey(acctMap);
        System.assertEquals('AmpBlack', newAcctMap.get(propertyAccounts[0].Id).Client_Brand_Key__c);
        System.assertEquals('AmpBlack', newAcctMap.get(propertyAccounts[1].Id).Client_Brand_Key__c);
        System.assertEquals('AmpBlack', newAcctMap.get(propertyAccounts[2].Id).Client_Brand_Key__c);
        System.assertEquals('AmpBlack', newAcctMap.get(propertyAccounts[0].Parent_Account__c).Client_Brand_Key__c);
        System.assertEquals('AmpBlack', newAcctMap.get(propertyAccounts[2].Parent_Account__c).Client_Brand_Key__c);

        List<Account> acctsToUpdate = brandingService.checkForDifferences(newAcctMap);
        // 2 of the 5 accounts already have Client_Brand_Key = AmpBlack
        System.assertEquals(3, acctsToUpdate.size());
    }

    @IsTest
    private static void testHandleEvent() {
        List<Shared_Solar_System__c> sss = [
            SELECT Id, Client_Brand_Key__c
            FROM Shared_Solar_System__c
            WHERE Client_Brand_Key__c = 'AmpBlack'
        ];
        // Want to test opp update, not SSS one:
        Util.disableTrigger('Disable_SharedSolarSystemTrigger__c');
        sss[0].Client_Brand_Key__c = null;
        update sss[0];

        List<Account> oldPropertyAccounts = [
            SELECT Id, Name, Parent_Account__c, Client_Brand_Key__c
            FROM Account
            WHERE Parent_Account__c != null
            ORDER BY Name
        ];
        System.assertEquals(3,oldPropertyAccounts.size());
        System.assertEquals('BluewaveLogo',oldPropertyAccounts[0].Client_Brand_Key__c);
        System.assertEquals('BluewaveLogo',oldPropertyAccounts[1].Client_Brand_Key__c);
        System.assertEquals('AmpBlack',oldPropertyAccounts[2].Client_Brand_Key__c);

        List<Subscription_Change_Event__e> eventList = new List<Subscription_Change_Event__e>();
        for (Account acct : oldPropertyAccounts){
            Subscription_Change_Event__e eventOne = new Subscription_Change_Event__e(
                Property_Account_Id__c = acct.Id
            );
            eventList.add(eventOne);
        }
        Test.startTest();
        EventBus.publish(eventList);
        Test.stopTest();

        List<Account> updatedPropertyAccounts = [
            SELECT Id, Name, Parent_Account__c, Client_Brand_Key__c
            FROM Account
            WHERE Parent_Account__c != null
            ORDER BY Name
        ];
        System.assertEquals('AmpRed',updatedPropertyAccounts[0].Client_Brand_Key__c);
        System.assertEquals('BluewaveLogo',updatedPropertyAccounts[1].Client_Brand_Key__c);
        System.assertEquals('BluewaveLogo',updatedPropertyAccounts[2].Client_Brand_Key__c);

        List<Account> updatedParentAccounts = [
            SELECT Id, Name, Parent_Account__c, Client_Brand_Key__c
            FROM Account
            WHERE Id = : updatedPropertyAccounts[0].Parent_Account__c
            OR Id = : updatedPropertyAccounts[1].Parent_Account__c
            OR Id = : updatedPropertyAccounts[2].Parent_Account__c
            ORDER BY Name
        ];
        System.assertEquals(2,updatedParentAccounts.size());
        System.assertEquals('BluewaveLogo',updatedParentAccounts[0].Client_Brand_Key__c);
        System.assertEquals('BluewaveLogo',updatedParentAccounts[1].Client_Brand_Key__c);
    }

    @IsTest
    private static void testOpportunityTrigger() {
        Shared_Solar_System__c sss1 = [
            SELECT Id, Client_Brand_Key__c, BWC_Project_Entity_Manual__r.Client_Account__r.Client_Brand_Key__c
            FROM Shared_Solar_System__c
            WHERE Name = 'Project A Oak Road'
            LIMIT 1
        ];
        // Want to test opp update, not SSS one:
        Util.disableTrigger('Disable_SharedSolarSystemTrigger__c');
        sss1.Client_Brand_Key__c = null;
        update sss1;
        System.assertEquals('AmpRed',sss1.BWC_Project_Entity_Manual__r.Client_Account__r.Client_Brand_Key__c);

        Shared_Solar_System__c sss2 = [
            SELECT Id, Client_Brand_Key__c, BWC_Project_Entity_Manual__r.Client_Account__r.Client_Brand_Key__c
            FROM Shared_Solar_System__c
            WHERE Name = 'Project B Main St'
            LIMIT 1
        ];
        System.assertEquals('AmpBlack',sss2.BWC_Project_Entity_Manual__r.Client_Account__r.Client_Brand_Key__c);
        List<Id> oppIdList = new List<Id>();
        List<Opportunity> opportunities = [
            SELECT Id, Account.Client_Brand_Key__c
            FROM Opportunity
            WHERE Shared_Solar_System__c = : sss1.Id
            ORDER BY Name
        ];
        System.assertEquals(4,opportunities.size());
        System.assertEquals('BluewaveLogo',opportunities[0].Account.Client_Brand_Key__c);
        System.assertEquals('BluewaveLogo',opportunities[1].Account.Client_Brand_Key__c);
        System.assertEquals('AmpBlack',opportunities[2].Account.Client_Brand_Key__c);
        System.assertEquals('AmpBlack',opportunities[3].Account.Client_Brand_Key__c);

        for (Opportunity opptny : opportunities){
            opptny.Shared_Solar_System__c = sss2.Id;
            oppIdList.add(opptny.Id);
        }

        Test.startTest();
            update opportunities;
        Test.stopTest();

        List<Opportunity> updatedOpps = [
            SELECT Id, Account.Client_Brand_Key__c
            FROM Opportunity
            WHERE Id IN : oppIdList
            ORDER BY Name
        ];
        System.assertEquals(4,updatedOpps.size());
        System.assertEquals('AmpBlack',updatedOpps[0].Account.Client_Brand_Key__c);
        System.assertEquals('AmpBlack',updatedOpps[1].Account.Client_Brand_Key__c);
        System.assertEquals('AmpBlack',updatedOpps[2].Account.Client_Brand_Key__c);
        System.assertEquals('AmpBlack',updatedOpps[3].Account.Client_Brand_Key__c);
    }

    @IsTest
    private static void testSSSTrigger() {
        List<Account> oldPropertyAccounts = [
            SELECT Id, Name, Parent_Account__c, Client_Brand_Key__c
            FROM Account
            WHERE Parent_Account__c != null
            ORDER BY Name
        ];
        System.assertEquals('BluewaveLogo',oldPropertyAccounts[0].Client_Brand_Key__c);
        System.assertEquals('BluewaveLogo',oldPropertyAccounts[1].Client_Brand_Key__c);
        System.assertEquals('AmpBlack',oldPropertyAccounts[2].Client_Brand_Key__c);

        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Client_Brand_Key__c
            FROM Shared_Solar_System__c
        ];
        for (Shared_Solar_System__c sss : sssList){
            sss.Client_Brand_Key__c = 'AmpRed';
        }

        Test.startTest();
            update sssList;
        Test.stopTest();

        List<Account> updatedPropertyAccounts = [
            SELECT Id, Name, Parent_Account__c, Client_Brand_Key__c
            FROM Account
            WHERE Parent_Account__c != null
            ORDER BY Name
        ];
        System.assertEquals('AmpRed',updatedPropertyAccounts[0].Client_Brand_Key__c);
        System.assertEquals('AmpRed',updatedPropertyAccounts[1].Client_Brand_Key__c);
        System.assertEquals('AmpRed',updatedPropertyAccounts[2].Client_Brand_Key__c);
    }
}