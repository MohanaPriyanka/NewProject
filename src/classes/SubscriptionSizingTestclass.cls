/**
 * Created by SarahRenfro on 4/17/2020.
 *
 * This testclass creates UASes that mimic the rounded and unrounded values in Production. It was made to fail until the
 * Subscription Orders subscription sizes that rolled up to the UAS matched the kW_Allocation__c on the UAS.
 *
 * To make the assertions pass, code was added to the SubscriptionManagementService.stampApprovedValues() to round the subscription size
 * and therefore match the kw Allocation.
 *
 * There are also assertions to ensure the Percent Share is correctly calculated despite the change.
 */


@IsTest
public with sharing class SubscriptionSizingTestclass {

    @IsTest
    public static void testSubscriptionSizing() {
        FeatureService.featureSelector = (FeatureSelector) Test.createStub(FeatureSelector.class, new FeatureServiceTest.MockCustomFeatureSelector(true));

        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );
        insert eversource;

        Utility_NMC_Tariff__c kwhNMCTarrif = new Utility_NMC_Tariff__c (Name = 'kwh Tariff? ',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1137,
            Current_Billing_Rate__c = TRUE);
        insert kwhNMCTarrif;

        Utility_NMC_Tariff__c costNMCTariff = new Utility_NMC_Tariff__c (Name = 'Cost Tariff',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1812,
            Current_Billing_Rate__c = TRUE);
        insert costNMCTariff;


        Product2 costProduct = new Product2( Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_In_Bill_Period__c = 30,
            Monthly_Late_Fee__c = 1);

        Product2 kwhProduct = new Product2( Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            Customer_Subscription_Type__c = 'kWh',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_In_Bill_Period__c = 30,
            Monthly_Late_Fee__c = 1);

        insert new List<Product2>{costProduct, kwhProduct};

        Shared_Solar_System__c costSSS = new Shared_Solar_System__c(
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Billing_Method__c = 'NMC',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1082.88,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Capacity_kWDC__c = 25
        );

        Shared_Solar_System__c kwhSSS = new Shared_Solar_System__c(
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Billing_Method__c = 'kWh',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 5832,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1316,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Capacity_kWDC__c = 25
        );

        insert new List<Shared_Solar_System__c>{costSSS, kwhSSS};

        Opportunity opportunityA = new Opportunity(
            Name = 'Ashley Smith',
            Shared_Solar_System__c = kwhSSS.Id,
            NMC_Tariff__c = kwhNMCTarrif.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = kwhProduct.Id,
            CloseDate = System.today()
        );

        Opportunity opportunityB = new Opportunity(
            Name = 'Stephen Ward',
            Shared_Solar_System__c = kwhSSS.Id,
            NMC_Tariff__c = kwhNMCTarrif.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = kwhProduct.Id,
            CloseDate = System.today()
        );

        Opportunity opportunityC = new Opportunity(
            Name = 'Nafisa Wong',
            Shared_Solar_System__c = costSSS.Id,
            NMC_Tariff__c = costNMCTariff.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = costProduct.Id,
            CloseDate = System.today()
        );

        Opportunity opportunityD = new Opportunity(
            Name = 'Ritik Mann',
            Shared_Solar_System__c = costSSS.Id,
            NMC_Tariff__c = costNMCTariff.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = costProduct.Id,
            CloseDate = System.today()
        );

        insert new List<Opportunity>{opportunityA, opportunityB, opportunityC, opportunityD};

        Utility_Account_Log__c ualA = new Utility_Account_Log__c(
            Name = '00088888'
        );

        Utility_Account_Log__c ualB = new Utility_Account_Log__c(
            Name = '00088888'
        );

        Utility_Account_Log__c ualC = new Utility_Account_Log__c(
            Name = '00088888'
        );

        Utility_Account_Log__c ualD = new Utility_Account_Log__c(
            Name = '00088888'
        );

        insert new List<Utility_Account_Log__c>{ualA, ualB, ualC, ualD};

        Utility_Account_Subscription__c uasA = new Utility_Account_Subscription__c(
            Name = '0000111',
            Utility_Account_Log__c = ualA.Id,
            Opportunity__c = opportunityA.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Annual_kwh_subscription_future__c = 7587
        );

        Utility_Account_Subscription__c uasB = new Utility_Account_Subscription__c(
            Name = '0000222',
            Utility_Account_Log__c = ualB.Id,
            Opportunity__c =  opportunityB.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Annual_kwh_subscription_future__c = 14345
        );

        Utility_Account_Subscription__c uasC = new Utility_Account_Subscription__c(
            Name = '0000333',
            Utility_Account_Log__c = ualC.Id,
            Opportunity__c = opportunityC.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Subscribed_Annual_Cost_of_Electricity__c = 5889
        );

        Utility_Account_Subscription__c uasD = new Utility_Account_Subscription__c(
            Name = '0000444',
            Utility_Account_Log__c = ualD.Id,
            Opportunity__c = opportunityD.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Subscribed_Annual_Cost_of_Electricity__c = 720.75
        );

        insert new List<Utility_Account_Subscription__c> {uasA, uasB, uasC, uasD};

        List<Utility_Account_Subscription__c> checkUASes = [
            SELECT Id, Name, kW_Allocation__c, Customer_Subscription_KW_DC__c,
                Future_Customer_Subscription_KWDC_Rollup__c, Future_Share_of_System_Rollup__c
            FROM Utility_Account_Subscription__c
            ORDER BY Name
        ];


        for (Utility_Account_Subscription__c uas : checkUASes) {
            if (uas.Name == '0000111') {
                //Unrounded: 5.7652
                System.assertEquals(5.832, uas.kW_Allocation__c);
                System.assertEquals(5.832, uas.Future_Customer_Subscription_KWDC_Rollup__c);
                System.assertEquals(.1, uas.Future_Share_of_System_Rollup__c);
            } else if (uas.Name == '0000222') {
                //Unrounded: 10.9005
                System.assertEquals(11.0808, uas.kW_Allocation__c);
                System.assertEquals(11.0808, uas.Future_Customer_Subscription_KWDC_Rollup__c);
                System.assertEquals(.19, uas.Future_Share_of_System_Rollup__c);
            } else if (uas.Name == '0000333') {
                //Unrounded: 25
                System.assertEquals(25.014528, uas.kW_Allocation__c);
                System.assertEquals(25.014528, uas.Future_Customer_Subscription_KWDC_Rollup__c);
                System.assertEquals(2.31, uas.Future_Share_of_System_Rollup__c);
            } else {
                //Unrounded: 3.0597
                System.assertEquals(3.032064, uas.kW_Allocation__c);
                System.assertEquals(3.032064, uas.Future_Customer_Subscription_KWDC_Rollup__c);
                System.assertEquals(.28, uas.Future_Share_of_System_Rollup__c);
            }
        }

    }
}