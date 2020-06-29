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

        Utility_NMC_Tariff__c kwhSizingMethodR1 = new Utility_NMC_Tariff__c (
            Utility__c = 'Eversource',
            Name = 'Eversource R1',
            Class__c = 'Class 1',
            Value_of_Net_Metering_Credit__c = 0.1137,
            Size_Ratio__c = 1.2,
            Current_Billing_Rate__c = TRUE
        );

        Utility_NMC_Tariff__c kwhSizingMethodR2 = new Utility_NMC_Tariff__c (
            Name = 'Eversource R2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1137,
            Size_Ratio__c = 1.5,
            Current_Billing_Rate__c = TRUE,
            Customer_Type__c = 'Residential'
        );
        insert new List<Utility_NMC_Tariff__c>{nmcRate, kwhSizingMethodR1, kwhSizingMethodR2};

        Rate_Class__c rateClass = new Rate_Class__c(
            Name = 'Eversource R1',
            Utility_NMC_Tariff__c = kwhSizingMethodR2.Id
        );
        insert rateClass;

        Product2 costProduct = new Product2( Name = 'SREC Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            Sizing_Method__c = 'Project Ratio',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            Monthly_Late_Fee__c = 1);

        Product2 kwhProduct = new Product2( Name = 'SMART Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            Customer_Subscription_Type__c = 'kWh',
            Sizing_Method__c = 'Rate Class Ratio',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_In_Bill_Period__c = 30,
            Monthly_Late_Fee__c = 1);

        insert new List<Product2>{costProduct, kwhProduct};

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
            Product__c = costProduct.Id,
            Billing_Method__c = 'NMC',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25,
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
            Product__c = costProduct.Id,
            Billing_Method__c = 'NMC',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Sales_Partners__c = 'All'
        );

        Shared_Solar_System__c kwhSSS = new Shared_Solar_System__c(
            Name = 'kWh Shared Solar System 1',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Billing_Method__c = 'kWh',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 5832,
            Total_System_Size_kW_AC__c  = 996,
            Utility_NMC_Tariff__c = kwhSizingMethodR1.Id,
            Product__c = kwhProduct.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1316,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Capacity_kWDC__c = 25
        );

        Shared_Solar_System__c kwhSSS2 = new Shared_Solar_System__c(
            Name = 'kWh Shared Solar System 2',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Billing_Method__c = 'kWh',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 5832,
            Total_System_Size_kW_AC__c  = 996,
            Utility_NMC_Tariff__c = kwhSizingMethodR1.Id,
            Product__c = kwhProduct.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1316,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Capacity_kWDC__c = 25
        );

        insert new List<Shared_Solar_System__c>{sss1, sss2, kwhSSS, kwhSSS2};

    }

    @IsTest
    public static void testCanGeneratedSubscriptionsByCostForMultipleOpportunitiesAndUALs() {
        useMocks(false);
        Product2 csProduct = [
            SELECT Id, Name, Sizing_Method__c, Customer_Subscription_Type__c
            FROM Product2
            WHERE Name = 'SREC Community Solar'
            LIMIT 1
        ];

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
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems(csProduct.Name);

        // 2 shared solar systems => 2 opps
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            opportunities.add(new Opportunity(
                Name = 'Opp ' + counter,
                Shared_Solar_System__c = sss.Id
            ));
            ++counter;
            setMaximumSubscriptionCost(sss, ual.Annual_Cost_of_Electricity__c);
        }
        update sharedSolarSystems;
        sharedSolarSystems = getSharedSolarSystems(csProduct.Name);

        System.assertEquals(2, opportunities.size());


        List<Utility_Account_Subscription__c> generatedUASes;
        generatedUASes = CSUtilityAccountSubscriptionFactory.generateSubscriptions(uals, sharedSolarSystems, opportunities);

        // 2 opps (max = ual size)  = 2 subscriptions (one for each UAL)
        System.assertEquals(2, generatedUASes.size());
    }

    @IsTest
    public static void testCanGeneratedSubscriptionsBykWhForMultipleOpportunitiesAndUALs() {
        useMocks(true);
        Product2 kwhProduct = [
            SELECT Id, Name, Sizing_Method__c, Customer_Subscription_Type__c
            FROM Product2
            WHERE Name = 'SMART Community Solar'
            LIMIT 1
        ];

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
            Product__c = kwhProduct.Id,
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

        uals = getUtilityAccountLogs();

        Integer counter = 1;
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems(kwhProduct.Name);
        List<CSUtilityAccountSubscriptionFactory.UASOrder> uasOrders = new List<CSUtilityAccountSubscriptionFactory.UASOrder>();

        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            opportunities.add(new Opportunity(
                Name = 'Opp ' + counter,
                Shared_Solar_System__c = sss.Id
            ));
            ++counter;

            setMaximumSubscriptionCapactity(sss, ual.Proposed_kWh__c );
        }
        update sharedSolarSystems;
        sharedSolarSystems = getSharedSolarSystems(kwhProduct.Name);

        System.assertEquals(2, opportunities.size());

        List<Utility_Account_Subscription__c> generatedUASes;
        generatedUASes = CSUtilityAccountSubscriptionFactory.generateSubscriptions(uals, sharedSolarSystems, opportunities, uasOrders);

        // 2 opps (max = ual size) = 2 subscriptions (one for each UAL)
        System.assertEquals(2, generatedUASes.size());
        System.assertEquals(2, uasOrders.size());

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
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems('SREC Community Solar');
        List<CSUtilityAccountSubscriptionFactory.UASOrder> uasOrders = new List<CSUtilityAccountSubscriptionFactory.UASOrder>();

        Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription> sssSingleSubscriptionMap = new Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription>();
        Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription> sssMultipleSubscriptionMap = new Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            opportunities.add(new Opportunity(
                Name = 'Opp ' + counter,
                Shared_Solar_System__c = sss.Id
            ));
            ++counter;

            CSUtilityAccountSubscriptionFactory.SSSSubscription sssSubscription = new CSUtilityAccountSubscriptionFactory.SSSSubscription(sss);
            sssSubscription.sss = sss;
            // set the maximum cost to get 1 subscription
            sssSubscription.maximumCost = ual.Annual_Cost_of_Electricity__c;
            sssSingleSubscriptionMap.put(sss.Id, sssSubscription);

            CSUtilityAccountSubscriptionFactory.SSSSubscription sssSubscription2 = new CSUtilityAccountSubscriptionFactory.SSSSubscription(sss);
            sssSubscription2.sss = sss;
            // set the maximum cost to get 2 subscription
            sssSubscription2.maximumCost = ual.Annual_Cost_of_Electricity__c/2;
            sssMultipleSubscriptionMap.put(sss.Id, sssSubscription2);

        }
        CSUtilityAccountSubscriptionFactory.sssSubscriptionMap = sssSingleSubscriptionMap;
        List<Utility_Account_Subscription__c> single = new List<Utility_Account_Subscription__c>();
        single.addAll(CSUtilityAccountSubscriptionFactory.createUASbyCost(ual, opportunities, uasOrders));

        CSUtilityAccountSubscriptionFactory.sssSubscriptionMap = sssMultipleSubscriptionMap;
        List<Utility_Account_Subscription__c> multiple = new List<Utility_Account_Subscription__c>();
        multiple.addAll(CSUtilityAccountSubscriptionFactory.createUASbyCost(ual, opportunities, uasOrders));

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
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems('SMART Community Solar');

        Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription> sssSingleSubscriptionMap = new Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription>();
        Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription> sssMultipleSubscriptionMap = new Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            opportunities.add(new Opportunity(
                Name = 'Opp ' + counter,
                Shared_Solar_System__c = sss.Id
            ));
            ++counter;

            CSUtilityAccountSubscriptionFactory.SSSSubscription sssSubscription = new CSUtilityAccountSubscriptionFactory.SSSSubscription(sss);
            sssSubscription.sss = sss;
            // set the maximum cost to get 1 subscription
            sssSubscription.maximumkWh = ual.Proposed_kWh__c;
            sssSingleSubscriptionMap.put(sss.Id, sssSubscription);

            CSUtilityAccountSubscriptionFactory.SSSSubscription sssSubscription2 = new CSUtilityAccountSubscriptionFactory.SSSSubscription(sss);
            sssSubscription2.sss = sss;
            // set the maximum cost to get 2 subscriptions
            sssSubscription2.maximumkWh = ual.Proposed_kWh__c/2;
            sssMultipleSubscriptionMap.put(sss.Id, sssSubscription2);
        }
        CSUtilityAccountSubscriptionFactory.sssSubscriptionMap = sssSingleSubscriptionMap;
        List<Utility_Account_Subscription__c> single = new List<Utility_Account_Subscription__c>();
        single.addAll(CSUtilityAccountSubscriptionFactory.createUASbyCapacity(ual, opportunities));

        CSUtilityAccountSubscriptionFactory.sssSubscriptionMap = sssMultipleSubscriptionMap;
        List<Utility_Account_Subscription__c> multiple = new List<Utility_Account_Subscription__c>();
        multiple.addAll(CSUtilityAccountSubscriptionFactory.createUASbyCapacity(ual, opportunities));

        System.assertEquals(1, single.size());
        System.assertEquals(2, multiple.size());
    }

    public static List<Utility_Account_Log__c> getUtilityAccountLogs() {
        List<Utility_Account_Log__c> ualList = [
            SELECT Id, Name, Annual_Cost_of_Electricity__c, Name_on_Account__c, Lead__c, Utility__c,
                Annual_kWh__c, Proposed_kWh__c, Lead__r.Product__r.Customer_Subscription_Type__c,
                Utility_NMC_Tariff__c, Utility_Rate_Class__c, Utility_Rate_Class__r.Utility_NMC_Tariff__c,
                Utility_Rate_Class__r.Utility_NMC_Tariff__r.Size_Ratio__c, Subsc_Annual_Cost_of_Electricity_Rollup__c,
                Subscribed_Annual_kWhs_Rollup__c
            FROM Utility_Account_Log__c
            ORDER BY Annual_Cost_of_Electricity__c DESC
        ];
        return ualList;
    }

    //Mimic sssSelector.getSharedSolarSystemsForEnrollment() but add ability to query by product
    public static List<Shared_Solar_System__c> getSharedSolarSystems(String product) {
        return [
            SELECT Id, Name, Sales_Partners__c, Maximum_Subscription_Cost__c, Billing_Method__c, Product__r.Name,
                Product__c, Product__r.Sizing_Method__c, Product__r.Customer_Subscription_Type__c,
                Project_Capacity_Available_kW_DC__c, Estimated_COD_Date_Manual__c, Service_Territories__c,
                Reserved_Capacity_kW_DC__c, Service_Territory__c, Utility__c, Expected_Yield_kWh_kW__c,
                Utility_NMC_Tariff__c, Utility_NMC_Tariff__r.Size_Ratio__c, Credit_Score_Requirement__c, Assignment_Order__c, Maximum_Subscription_Capacity_kWDC__c,
                BWC_Project_Entity_Manual__c, BWC_Project_Entity_Manual__r.Gateway__c, NMC_Value__c
            FROM Shared_Solar_System__c
            WHERE Open__c = TRUE
            AND Capacity_Available_to_be_Reserved__c > 0
            AND Product__r.Name = :product
        ];
    }

    public static void setMaximumSubscriptionCapactity(Shared_Solar_System__c sss, Decimal maximumCapacity) {
        sss.Expected_Yield_kWh_kW__c = maximumCapacity / sss.Maximum_Subscription_Capacity_kWDC__c;
    }

    @IsTest
    public static void testSetMaximumSubscriptionCapacity() {
        useMocks(false);
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems('SMART Community Solar');
        Decimal maximumCapacitykWh = CSUtilityAccountSubscriptionFactory.calculateMaximumkWh(sharedSolarSystems[0], null);
        System.assertEquals(32900, maximumCapacitykWh);

        Test.startTest();
        Shared_Solar_System__c sss = sharedSolarSystems[0];
        setMaximumSubscriptionCapactity(sss, 40000);
        update sss;

        Test.stopTest();
        Shared_Solar_System__c sssAfterUpdate = [
            SELECT Id, Expected_Yield_kWh_kW__c, Maximum_Subscription_Capacity_kWDC__c
            FROM Shared_Solar_System__c
            WHERE Id =: sss.Id
            LIMIT 1
        ];

        Decimal maximumCapacitykWhAfter = CSUtilityAccountSubscriptionFactory.calculateMaximumkWh(sssAfterUpdate, null);
        System.assertEquals(40000, maximumCapacitykWhAfter);
    }

    public static void setMaximumSubscriptionCost(Shared_Solar_System__c sss, Decimal maximumCost) {
        sss.Expected_Yield_kWh_kW__c = (maximumCost / (sss.Maximum_Subscription_Capacity_kWDC__c * sss.NMC_Value__c));
    }

    @IsTest
    public static void testSetMaximumSubscriptionCost() {
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems('SREC Community Solar');
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

    @IsTest
    public static void testSizingMethodMissingRateClass(){
        useMocks(true);
        //CSAP Example: UAL does not have a Rate Class but has a Product that is "Rate Class Ratio"
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Annual_kWh__c = 15000,
            Name_on_Account__c = 'Sarah Renfro',
            Name = 'Account 1'
        );

        insert ual;

        //Requery to mimic CSSubscriptionEnroller queries for UALs and SSSs
        List<Utility_Account_Log__c> ualList = getUtilityAccountLogs();
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems('SMART Community Solar');

        Integer counter = 1;
        List<Opportunity> opportunities = new List<Opportunity>();
        Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription> sssSubscriptionMap = new Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            opportunities.add(new Opportunity(
                Name = 'Opp ' + counter,
                Shared_Solar_System__c = sss.Id
            ));
            ++counter;

            CSUtilityAccountSubscriptionFactory.SSSSubscription sssSubscription = new CSUtilityAccountSubscriptionFactory.SSSSubscription(sss);
            sssSubscriptionMap.put(sss.Id, sssSubscription);
        }
        CSUtilityAccountSubscriptionFactory.sssSubscriptionMap = sssSubscriptionMap;
        List<Utility_Account_Subscription__c> single = new List<Utility_Account_Subscription__c>();
        single.addAll(CSUtilityAccountSubscriptionFactory.createUASbyCapacity(ualList[0], opportunities));

        System.assertEquals(sharedSolarSystems[0].Utility_NMC_Tariff__c, single[0].Sizing_Method__c,
            'UAS should be assigned the Sizing Method from the SSS it is assigned to because the UAL does not have a Rate Class.');
        System.assertEquals(15000, single[0].Annual_kwh_subscription_future__c);
        //TODO: when Subscription Order work from W-019131 is completed, add assertions for subscription size

    }

    @IsTest
    public static void testSizingMethodRateClassRatioSingleSubscription() {
        useMocks(true);
        Utility_NMC_Tariff__c sizeRatio =  [
            SELECT Id, Size_Ratio__c
            FROM Utility_NMC_Tariff__c
            WHERE Name = 'Eversource R1'
            LIMIT 1
        ];

        Rate_Class__c rateClass = new Rate_Class__c(
            Name = 'Eversource R2',
            Utility_NMC_Tariff__c = sizeRatio.Id
        );
        insert rateClass;

        Utility_Account_Log__c ualSingle = new Utility_Account_Log__c(
            Annual_kWh__c = 15000,
            Name_on_Account__c = 'Sarah Renfro',
            Name = 'Account 1',
            Utility_Rate_Class__c = rateClass.Id
        );

        insert ualSingle;

        Product2 kWhProduct = [
            SELECT Id, Sizing_Method__c, Name
            FROM Product2
            WHERE Name = 'SMART Community Solar'
            LIMIT 1
        ];

        //Requery to mimic CSSubscriptionEnroller queries for UALs and SSSs
        List<Utility_Account_Log__c> ualList = getUtilityAccountLogs();
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems('SMART Community Solar');
        Integer counter = 1;
        List<Opportunity> opportunities = new List<Opportunity>();
        Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription> sssSubscriptionMap = new Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            opportunities.add(new Opportunity(
                Name = 'Opp ' + counter,
                Shared_Solar_System__c = sss.Id,
                Product__c = kWhProduct.Id
            ));
            ++counter;

            CSUtilityAccountSubscriptionFactory.SSSSubscription sssSubscription = new CSUtilityAccountSubscriptionFactory.SSSSubscription(sss);
            sssSubscriptionMap.put(sss.Id, sssSubscription);
        }
        CSUtilityAccountSubscriptionFactory.sssSubscriptionMap = sssSubscriptionMap;

        List<Utility_Account_Subscription__c> uasSingle = new List<Utility_Account_Subscription__c>();
        uasSingle.addAll(CSUtilityAccountSubscriptionFactory.createUASbyCapacity(ualList[0], opportunities));

        System.assertEquals(1, uasSingle.size());
        System.assertEquals(sizeRatio.Id, uasSingle[0].Sizing_Method__c,
            'UAS should be assigned the Sizing Method from the UALs Rate Class');
        System.assertEquals(15000, uasSingle[0].Annual_kwh_subscription_future__c);
        //TODO: when Subscription Order work from W-019131 is completed, add assertions for KW subscription size

    }
    @IsTest
    public static void testSizingMethodRateClassRatioMultipleSubscriptions() {
        useMocks(true);
        Utility_NMC_Tariff__c sizeRatio =  [
            SELECT Id, Size_Ratio__c
            FROM Utility_NMC_Tariff__c
            WHERE Name = 'Eversource R2'
            LIMIT 1
        ];

        Rate_Class__c rateClass = new Rate_Class__c(
            Name = 'Eversource R1',
            Utility_NMC_Tariff__c = sizeRatio.Id
        );
        insert rateClass;

        Utility_Account_Log__c ualMultiple = new Utility_Account_Log__c(
            Annual_kWh__c = 23000,
            Name_on_Account__c = 'Sarah Renfro',
            Name = 'Account 1',
            Utility_Rate_Class__c = rateClass.Id
        );

        insert ualMultiple;

        Product2 kWhProduct = [
            SELECT Id, Sizing_Method__c, Name
            FROM Product2
            WHERE Name = 'SMART Community Solar'
            LIMIT 1
        ];

        //Requery to mimic CSSubscriptionEnroller queries for UALs and SSSs
        List<Utility_Account_Log__c> ualList = getUtilityAccountLogs();
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems('SMART Community Solar');
        Integer counter = 1;
        List<Opportunity> opportunities = new List<Opportunity>();
        Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription> sssSubscriptionMap = new Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            opportunities.add(new Opportunity(
                Name = 'Opp ' + counter,
                Shared_Solar_System__c = sss.Id,
                Product__c = kWhProduct.Id
            ));
            ++counter;

            CSUtilityAccountSubscriptionFactory.SSSSubscription sssSubscription = new CSUtilityAccountSubscriptionFactory.SSSSubscription(sss);
            sssSubscriptionMap.put(sss.Id, sssSubscription);
        }

        CSUtilityAccountSubscriptionFactory.sssSubscriptionMap = sssSubscriptionMap;
        List<Utility_Account_Subscription__c> uasMultiple = new List<Utility_Account_Subscription__c>();
        uasMultiple.addAll(CSUtilityAccountSubscriptionFactory.createUASbyCapacity(ualList[0], opportunities));

        System.assertEquals(2, uasMultiple.size());
        System.assertEquals(sizeRatio.Id, uasMultiple[0].Sizing_Method__c,
            'UAS should be assigned the Sizing Method from the UALs Rate Class');
        System.assertEquals(sizeRatio.Id, uasMultiple[1].Sizing_Method__c,
            'UAS should be assigned the Sizing Method from the UALs Rate Class');
        // kwh SSS with Rate Class Ratio --> maximum kWh = (max kW DC * yield)/UAL's Rate ClassSize Ratio)
        // =(25 * 1316)/1.5 = 21933.33
        System.assertEquals(21933.33, uasMultiple[0].Annual_kwh_subscription_future__c);
        System.assertEquals(1066.67, uasMultiple[1].Annual_kwh_subscription_future__c);
        //TODO: when Subscription Order work from W-019131 is completed, add assertions for KW subscription size
    }

    @IsTest
    public static void testSizingMethodProjectRatioSubscriptions() {
        useMocks(true);
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Annual_kWh__c = 30000,
            Name_on_Account__c = 'Sarah Renfro',
            Name = 'Account 1'
        );

        insert ual;

        Product2 kwhProduct = [
            SELECT Id, Sizing_Method__c
            FROM Product2
            WHERE Name = 'SMART Community Solar'
            LIMIT 1
        ];
        kwhProduct.Sizing_Method__c = 'Project Ratio';
        update kwhProduct;

        List<Utility_Account_Log__c> ualList = getUtilityAccountLogs();
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems('SMART Community Solar');
        Integer counter = 1;
        List<Opportunity> opportunities = new List<Opportunity>();
        Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription> sssSubscriptionMap = new Map<Id, CSUtilityAccountSubscriptionFactory.SSSSubscription>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            opportunities.add(new Opportunity(
                Name = 'Opp ' + counter,
                Shared_Solar_System__c = sss.Id,
                Product__c = kWhProduct.Id
            ));
            ++counter;

            CSUtilityAccountSubscriptionFactory.SSSSubscription sssSubscription = new CSUtilityAccountSubscriptionFactory.SSSSubscription(sss);
            sssSubscriptionMap.put(sss.Id, sssSubscription);
        }
        CSUtilityAccountSubscriptionFactory.sssSubscriptionMap = sssSubscriptionMap;

        List<Utility_Account_Subscription__c> uasMultiple = new List<Utility_Account_Subscription__c>();
        uasMultiple.addAll(CSUtilityAccountSubscriptionFactory.createUASbyCapacity(ualList[0], opportunities));

        System.assertEquals(2, uasMultiple.size());
        System.assertEquals(sharedSolarSystems[0].Utility_NMC_Tariff__c, uasMultiple[0].Sizing_Method__c,
            'UAS should be assigned the Sizing Method from the SSS');
        // kwh SSS with Project Ratio --> maximum kWh = (max kW DC * yield)/Size Ratio) --> (25 * 1316)/1.2 = 27416.67
        System.assertEquals(27416.67, uasMultiple[0].Annual_kwh_subscription_future__c,
            'First UAS should be maxed out by SSS Maximum kWh after Sizing Ratio has been applied');
        System.assertEquals(sharedSolarSystems[1].Utility_NMC_Tariff__c, uasMultiple[1].Sizing_Method__c,
            'Second UAS should be remaining annual kWh');
        System.assertEquals(2583.33, uasMultiple[1].Annual_kwh_subscription_future__c);
        //TODO: when Subscription Order work from W-019131 is completed, add assertions for KW subscription size

    }

    @IsTest
    public static void testCalculateMaximumkWhRateClassRatio() {
        useMocks(true);
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Annual_kWh__c = 15000,
            Name_on_Account__c = 'Sarah Renfro',
            Name = 'Account 1'
        );

        insert ual;

        Shared_Solar_System__c sss = [
            SELECT Id, Expected_Yield_kWh_kW__c, Maximum_Subscription_Capacity_kWDC__c,
                Product__r.Sizing_Method__c, Product__r.Customer_Subscription_Type__c,
                Utility_NMC_Tariff__r.Size_Ratio__c
            FROM Shared_Solar_System__c
            WHERE Product__r.Name = 'SMART Community Solar'
            LIMIT 1
        ];

        Decimal maxKwh = CSUtilityAccountSubscriptionFactory.calculateMaximumkWh(sss, ual);
        System.assertEquals(32900, maxKwh,
            'Maximum kwh should be (SSS.MaxKWDC * Yield) for a Rate Class Ratio project when the UAL does not have a Rate Class');

        Rate_Class__c rateClass = [
            SELECT Id, Utility_NMC_Tariff__c, Utility_NMC_Tariff__r.Size_Ratio__c
            FROM Rate_Class__c
            LIMIT 1
        ];

        ual.Utility_Rate_Class__c = rateClass.Id;
        update ual;

        //Requery for the UAL to get relationships
        ual = getUtilityAccountLogs()[0];

        maxKwh = CSUtilityAccountSubscriptionFactory.calculateMaximumkWh(sss, ual);
        //Maximum kWh Subscription = (25 * 1316)/1.5
        System.assertEquals(21933.33, maxKwh, 'Maximum kWh should be (SSS.MaxKWDC * Yield)/UAL.RateClass.SizeRatio for a Rate Class Ratio project');
    }



    @IsTest
    public static void testCalculateMaximumkWhProjectRatio() {
        useMocks(true);
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Annual_kWh__c = 15000,
            Name_on_Account__c = 'Sarah Renfro',
            Name = 'Account 1'
        );

        insert ual;

        Product2 kwhProduct = [
            SELECT Id, Sizing_Method__c
            FROM Product2
            WHERE Name = 'SMART Community Solar'
            LIMIT 1
        ];
        kwhProduct.Sizing_Method__c = 'Project Ratio';
        update kwhProduct;

        Shared_Solar_System__c sss = [
            SELECT Id, Expected_Yield_kWh_kW__c, Maximum_Subscription_Capacity_kWDC__c,
                Product__r.Sizing_Method__c, Product__r.Customer_Subscription_Type__c,
                Utility_NMC_Tariff__r.Size_Ratio__c
            FROM Shared_Solar_System__c
            WHERE Product__r.Name = 'SMART Community Solar'
            LIMIT 1
        ];

        //Maximum kWh Subscription = (25 * 1316)/1.2
        Decimal maxKwh = CSUtilityAccountSubscriptionFactory.calculateMaximumkWh(sss, ual);
        System.assertEquals(27416.67, maxKwh );
    }


    private static void useMocks(Boolean featureOn) {
        FeatureService.featureSelector = (FeatureSelector) Test.createStub(FeatureSelector.class, new FeatureServiceTest.MockCustomFeatureSelector(featureOn));
    }

}