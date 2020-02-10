/**
 * Created by mstackhouse on 12/17/2018.
 * Description: 
 * Test: 
 */

@IsTest
public with sharing class CSUtilityAccountSubscriptionFactoryTest {
    @TestSetup
    public static void testSetup() {
        Utility_NMC_Tariff__c nmcRate =  new Utility_NMC_Tariff__c(
            Value_of_Net_Metering_Credit__c = .1848,
            Name = 'Nation Grid WCMA Class 2 - S/F 2016',
            Sizing_Rate__c = true,
            Date__c = Date.today()
        );
        insert nmcRate;

        Product2 csProduct = new Product2( Name = 'Community Solar - SREC 16-01',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            Monthly_Late_Fee__c = 1);
        insert csProduct;


        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Eversource P1',
            Service_Territories__c = 'WCMA; SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            System_Utility__c = 'Eversource',
            Credit_Score_Requirement__c = 700,
            Assignment_Order__c = '1',
            Utility_NMC_Tariff__c = nmcRate.Id,
            Product__c = csProduct.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Assemblage__c = 25,
            Sales_Partners__c = 'All'
        );

        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(
            Name = 'Eversource P2',
            Service_Territories__c = 'WCMA; SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            System_Utility__c = 'Eversource',
            Credit_Score_Requirement__c = 700,
            Assignment_Order__c = '1',
            Utility_NMC_Tariff__c = nmcRate.Id,
            Product__c = csProduct.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Assemblage__c = 25,
            Sales_Partners__c = 'All'
        );

        insert new List<Shared_Solar_System__c>{sss1, sss2};
    }

    @IsTest
    public static void testCanGeneratedSubscriptionsByCostForMultipleOpportunitiesAndUALs() {
        useMocks(false);
        Product2 csProduct = new Product2( Name = 'Community Solar - SREC 16-01',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            Monthly_Late_Fee__c = 1);
        insert csProduct;

        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Testcase',
            Email = 'test@test.com',
            Electricity_Provider__c = 'Eversource',
            Utility_1__c = 'Eversource',
            Load_Zone__c = 'WCMA',
            Company = 'Test',
            Status = 'Qualified',
            Product_line__c = 'Community Solar',
            Product__c = csProduct.Id,
            Custom_ID__c = 'partner',
            System_Assignment__c = 'Automatic - Assignment Order'
        );
        insert lead;

        List<Utility_Account_Log__c> uals = new List<Utility_Account_Log__c>();
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Annual_Cost_of_Electricity__c = 15000,
            Lead__c = lead.Id,
            Name_on_Account__c = 'Joey Chan',
            Name = 'Account 1'
        );
        uals.add(ual);

        Utility_Account_Log__c ual2 = new Utility_Account_Log__c(
            Annual_Cost_of_Electricity__c = 15000,
            Lead__c = lead.Id,
            Name_on_Account__c = 'Joey Chan',
            Name = 'Account 2'
        );
        uals.add(ual2);

        insert uals;

        uals = [
            SELECT Id, Annual_Cost_of_Electricity__c, Lead__r.Product__r.Customer_Subscription_Type__c, Name,
                Name_on_Account__c
            FROM Utility_Account_Log__c
            WHERE Id IN :uals
        ];

        Integer counter = 1;
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems();

        // 2 shared solar systems => 2 opps
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            opportunities.add(new Opportunity(
                Name = 'Opp ' + counter,
                Shared_Solar_System__c = sss.Id
            ));
            ++counter;

            setMaximumSubscriptionCost(sss, ual.Annual_Cost_of_Electricity__c / 2);
        }
        update sharedSolarSystems;
        sharedSolarSystems = getSharedSolarSystems();

        System.assertEquals(2, opportunities.size());


        List<Utility_Account_Subscription__c> generatedUASes;
        generatedUASes = CSUtilityAccountSubscriptionFactory.generateSubscriptions(uals, sharedSolarSystems, opportunities);

        // 2 opps & 2 uals each = 4 subscriptions
        System.assertEquals(4, generatedUASes.size());
    }

    @IsTest
    public static void testCanGeneratedSubscriptionsBykWhForMultipleOpportunitiesAndUALs() {
        useMocks(true);
        Product2 csProduct = new Product2( Name = 'Community Solar - SREC 16-01',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SMART - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Customer_Subscription_Type__c = 'kWh',
            Monthly_Late_Fee__c = 1);
        insert csProduct;

        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Testcase',
            Email = 'test@test.com',
            Electricity_Provider__c = 'Eversource',
            Utility_1__c = 'Eversource',
            Load_Zone__c = 'WCMA',
            Company = 'Test',
            Status = 'Qualified',
            Product_line__c = 'Community Solar',
            Product__c = csProduct.Id,
            Custom_ID__c = 'partner',
            System_Assignment__c = 'Automatic - Assignment Order'
        );
        insert lead;


        List<Utility_Account_Log__c> uals = new List<Utility_Account_Log__c>();
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Annual_kWh__c = 5000,
            Proposed_kWh__c = 15000,
            Lead__c = lead.Id,
            Name_on_Account__c = 'Joey Chan',
            Name = 'Account 1'
        );
        uals.add(ual);

        Utility_Account_Log__c ual2 = new Utility_Account_Log__c(
            Annual_kWh__c = 5000,
            Proposed_kWh__c = 15000,
            Lead__c = lead.Id,
            Name_on_Account__c = 'Joey Chan',
            Name = 'Account 2'
        );
        uals.add(ual2);

        insert uals;

        uals = [
            SELECT Id, Annual_kWh__c, Proposed_kWh__c, Lead__r.Product__r.Customer_Subscription_Type__c, Name,
                Name_on_Account__c
            FROM Utility_Account_Log__c
            WHERE Id IN :uals
        ];

        Integer counter = 1;
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems();
        List<CSUtilityAccountSubscriptionFactory.UASOrder> uasOrders = new List<CSUtilityAccountSubscriptionFactory.UASOrder>();

        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            opportunities.add(new Opportunity(
                Name = 'Opp ' + counter,
                Shared_Solar_System__c = sss.Id
            ));
            ++counter;

            setMaximumSubscriptionCapactity(sss, ual.Proposed_kWh__c / 2);
        }
        update sharedSolarSystems;
        sharedSolarSystems = getSharedSolarSystems();

        System.assertEquals(2, opportunities.size());

        List<Utility_Account_Subscription__c> generatedUASes;
        generatedUASes = CSUtilityAccountSubscriptionFactory.generateSubscriptions(uals, sharedSolarSystems, opportunities, uasOrders);

        // 2 opps & 2 uals each = 4 subscriptions
        System.assertEquals(4, generatedUASes.size());
        System.assertEquals(4, uasOrders.size());

        for (Integer i = 0; i < generatedUASes.size(); i++ ) {
            System.assertNotEquals(null, uasOrders[i].uas);
            System.assertNotEquals(null, uasOrders[i].sOrder);
            System.assertEquals(generatedUASes[i].Id, uasOrders[i].uas.Id);
        }


    }

    @IsTest
    public static void testCreateUASforUALbyCost() {
        useMocks(true);
        List<Utility_Account_Log__c> uals = new List<Utility_Account_Log__c>();
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Annual_Cost_of_Electricity__c = 15000,
            Name_on_Account__c = 'Joey Chan',
            Name = 'Account 1'
        );

        insert ual;

        Integer counter = 1;
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems();
        List<CSUtilityAccountSubscriptionFactory.UASOrder> uasOrders = new List<CSUtilityAccountSubscriptionFactory.UASOrder>();

        Map<Id, Decimal> sssForSingleSubscription = new Map<Id, Decimal>();
        Map<Id, Decimal> sssForMultipleSubscription = new Map<Id, Decimal>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            opportunities.add(new Opportunity(
                Name = 'Opp ' + counter,
                Shared_Solar_System__c = sss.Id
            ));
            ++counter;

            // set the maximum cost to get 1 subscription
            sssForSingleSubscription.put(sss.Id, ual.Annual_Cost_of_Electricity__c);
            // set the maximum cost to get 2 subscriptions
            sssForMultipleSubscription.put(sss.Id, ual.Annual_Cost_of_Electricity__c / 2);
        }

        List<Utility_Account_Subscription__c> single = new List<Utility_Account_Subscription__c>();
        List<Utility_Account_Subscription__c> multiple = new List<Utility_Account_Subscription__c>();

        single.addAll(CSUtilityAccountSubscriptionFactory.createUASbyCost(ual, sssForSingleSubscription, opportunities, uasOrders));
        multiple.addAll(CSUtilityAccountSubscriptionFactory.createUASbyCost(ual, sssForMultipleSubscription, opportunities, uasOrders));

        System.assertEquals(1, single.size());
        System.assertEquals(2, multiple.size());
        //1 uasOrder for single and 2 for multiple
        System.assertEquals(3, uasOrders.size());
        System.assertNotEquals(null, uasOrders[0].sOrder);
        System.assertNotEquals(null, uasOrders[0].uas);
    }

    @IsTest
    public static void testCreateUASforUALbyCapacity() {
        useMocks(false);
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Proposed_kWh__c = 15000,
            Name_on_Account__c = 'Joey Chan',
            Name = 'Account 1'
        );

        insert ual;

        Integer counter = 1;
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems();

        Map<Id, Decimal> sssForSingleSubscription = new Map<Id, Decimal>();
        Map<Id, Decimal> sssForMultipleSubscription = new Map<Id, Decimal>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            opportunities.add(new Opportunity(
                Name = 'Opp ' + counter,
                Shared_Solar_System__c = sss.Id
            ));
            ++counter;

            // set the maximum cost to get 1 subscription
            sssForSingleSubscription.put(sss.Id, ual.Proposed_kWh__c);
            // set the maximum cost to get 2 subscriptions
            sssForMultipleSubscription.put(sss.Id, ual.Proposed_kWh__c / 2);
        }

        List<Utility_Account_Subscription__c> single = new List<Utility_Account_Subscription__c>();
        List<Utility_Account_Subscription__c> multiple = new List<Utility_Account_Subscription__c>();
        single.addAll(CSUtilityAccountSubscriptionFactory.createUASbyCapacity(ual, sssForSingleSubscription, opportunities));
        multiple.addAll(CSUtilityAccountSubscriptionFactory.createUASbyCapacity(ual, sssForMultipleSubscription, opportunities));

        System.assertEquals(1, single.size());
        System.assertEquals(2, multiple.size());
    }

    public static List<Shared_Solar_System__c> getSharedSolarSystems() {
        List<Shared_Solar_System__c> sharedSolarSystems = [
            SELECT Id, Maximum_Subscription_Capacity_kW_DC__c, Expected_Yield_kWh_kW__c, Maximum_Subscription_Cost__c,
                NMC_Value__c
            FROM Shared_Solar_System__c
        ];
        return sharedSolarSystems;
    }

    public static void setMaximumSubscriptionCapactity(Shared_Solar_System__c sss, Decimal maximumCapacity) {
        sss.Expected_Yield_kWh_kW__c = maximumCapacity / sss.Maximum_Subscription_Capacity_kW_DC__c;
    }

    @IsTest
    public static void testSetMaximumSubscriptionCapactity() {
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems();
        Decimal maximumCapacitykWh = CSUtilityAccountSubscriptionFactory.calculateMaximumkWh(sharedSolarSystems[0]);

        System.assertEquals(32500, maximumCapacitykWh);

        Test.startTest();
        Shared_Solar_System__c sss = sharedSolarSystems[0];
        setMaximumSubscriptionCapactity(sss, 40000);
        update sss;

        Test.stopTest();
        Shared_Solar_System__c sssAfterUpdate = [
            SELECT Id, Maximum_Subscription_Capacity_kW_DC__c, Expected_Yield_kWh_kW__c
            FROM Shared_Solar_System__c
            WHERE Id =: sss.Id
            LIMIT 1
        ];

        Decimal maximumCapacitykWhAfter = CSUtilityAccountSubscriptionFactory.calculateMaximumkWh(sssAfterUpdate);

        System.assertEquals(40000, maximumCapacitykWhAfter);
    }

    public static void setMaximumSubscriptionCost(Shared_Solar_System__c sss, Decimal maximumCost) {
        sss.Expected_Yield_kWh_kW__c = (maximumCost / (sss.Maximum_Subscription_Capacity_kW_DC__c * sss.NMC_Value__c));
    }

    @IsTest
    public static void testSetMaximumSubscriptionCost() {

        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems();

        System.assertEquals(6006.00, sharedSolarSystems[0].Maximum_Subscription_Cost__c);

        setMaximumSubscriptionCost(sharedSolarSystems[0], 4000.00);
        update sharedSolarSystems[0];

        Shared_Solar_System__c sssAfterUpdate = [
            SELECT Id, Maximum_Subscription_Cost__c
            FROM Shared_Solar_System__c
            WHERE Id =: sharedSolarSystems[0].Id
            LIMIT 1
        ];

        System.assertEquals(4000.00, sssAfterUpdate.Maximum_Subscription_Cost__c);
    }

    private static void useMocks(Boolean featureOn) {
        FeatureService.featureSelector = (FeatureSelector) Test.createStub(FeatureSelector.class, new FeatureServiceTest.MockCustomFeatureSelector(featureOn));
    }


}