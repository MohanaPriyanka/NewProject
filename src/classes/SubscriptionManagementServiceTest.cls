/**
 * Created by SarahRenfro on 11/15/2019.
 */

@IsTest
private class SubscriptionManagementServiceTest {
    private static String sssId = 'a1J29000000tjOkEAI';

    @TestSetup
    public static void setupData() {
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );
        insert eversource;

        Shared_Solar_System__c sss = new Shared_Solar_System__c(   Name = 'SSS Test',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1095.84,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);
        insert sss;

        Shared_Solar_System_Order__c sssoSize = new Shared_Solar_System_Order__c(
            Shared_Solar_System__c = sss.Id,
            Total_System_Size_kW_DC__c = 2891.72,
            Approval_Status__c = 'Approved'
        );

        Shared_Solar_System_Order__c sssoUpdate = new Shared_Solar_System_Order__c(
            Shared_Solar_System__c = sss.Id,
            Total_System_Size_kW_DC__c = 2891.72,
            Approval_Status__c = 'New'
        );

        insert new List<Shared_Solar_System_Order__c>{sssoSize, sssoUpdate};
    }


    @IsTest
    static void testSubscriptionOrderInsert() {
        useMocks();

        Subscription_Order__c so = new Subscription_Order__c(
            Utility_Account_Subscription__c = 'a1d29000001C3xuAAC'
        );

        SubscriptionManagementService subscriptionManagementService = new SubscriptionManagementService();
        subscriptionManagementService.populateSubscriptionOrder(new List<Subscription_Order__c> {so});

        System.assertNotEquals(null, so);
        System.assertEquals(1300, so.Expected_Yield_kWh_kW__c);
        System.assertEquals(1095.84, so.Total_System_Size_kW_DC__c);
        System.assertEquals(2, so.Utility_Number_of_Decimal_Places__c );
        System.assertEquals(0.1848, so.Value_of_NMC__c);
        System.assertNotEquals(null, so.Product__c);

    }

    @IsTest
    private static void testSubscriptionOrderTrigger(){
        Util.disableTrigger('Disable_Client_Objects_Trigger__c');
        useMocks();

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Name = '000123'
        );
        insert ual;

        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = '000234',
            Utility_Account_Log__c = ual.Id
        );
        insert uas;

        Subscription_Order__c so = new Subscription_Order__c(
            Utility_Account_Subscription__c = uas.Id
        );
        insert so;

        System.assertNotEquals(null, so.Id);
    }

    @IsTest
    private static void testSharedSolarSystemOrderTrigger() {
        useMocks();
        Shared_Solar_System_Order__c ssso = [
            SELECT Id
            FROM Shared_Solar_System_Order__c
            WHERE Approval_Status__c = 'New'
            LIMIT 1
        ];

        ssso.Total_System_Size_kW_DC__c = 3000;
        update ssso;

        ssso = [
            SELECT Id, Total_System_Size_kW_DC__c
            FROM Shared_Solar_System_Order__c
            WHERE Id = :ssso.Id
            LIMIT 1
        ];

        List<Subscription_Order__c> soList = [
            SELECT Id
            FROM Subscription_Order__c
            WHERE Shared_Solar_System_Order__c = :ssso.Id
        ];

        System.assertEquals(3000, ssso.Total_System_Size_kW_DC__c);
        System.assertEquals(0, soList.size());
    }

    @IsTest
    private static void testApprovedSSSO() {
        useMocks();
        Shared_Solar_System_Order__c sssoApproved = new Shared_Solar_System_Order__c(
            Shared_Solar_System__c = sssId,
            Total_System_Size_kW_DC__c = 2891.72,
            Approval_Status__c = 'Approved'
        );

        Shared_Solar_System_Order__c sssoOld = new Shared_Solar_System_Order__c(
            Shared_Solar_System__c = sssId,
            Total_System_Size_kW_DC__c = 2891.72,
            Approval_Status__c = 'New'
        );

        SubscriptionManagementService service = new SubscriptionManagementService();
        Map<Id, Shared_Solar_System_Order__c> oldMap = new Map<Id, Shared_Solar_System_Order__c>();
        oldMap.put(sssoOld.Id, sssoOld);
        List<Shared_Solar_System_Order__c> checkSSSO = service.checkSSSOApproval(new List<Shared_Solar_System_Order__c>{sssoApproved}, oldMap);
        System.assertEquals(1, checkSSSO.size());
    }


    @IsTest
    private static void testUpdateSSS() {
        useMocks();

        Shared_Solar_System_Order__c ssso = [
            SELECT Id, Shared_Solar_System__c, Yield__c, Total_System_Size_kW_DC__c
            FROM Shared_Solar_System_Order__c
            WHERE Total_System_Size_kW_DC__c != null
            LIMIT 1
        ];

        SubscriptionManagementService service = new SubscriptionManagementService();
        Shared_Solar_System__c checkSSS = service.updateSSSFromSSSO(ssso);

        System.assertEquals('Test SSS', checkSSS.Name);
        System.assertEquals(ssso.Total_System_Size_kW_DC__c, checkSSS.Total_System_Size_kWh_DC__c);

    }

    @IsTest
    private static void testCreateSubscriptionOrders() {
        useMocks();
        Shared_Solar_System_Order__c ssso = [
            SELECT Id, Shared_Solar_System__c, Yield__c, Total_System_Size_kW_DC__c
            FROM Shared_Solar_System_Order__c
            LIMIT 1
        ];

        UASSelector uasSelector = (UASSelector) Test.createStub(UASSelector.class, new MockUASSelector());
        List<Utility_Account_Subscription__c> uasList = uasSelector.selectBySharedSolarSystem(ssso.Shared_Solar_System__c);

        SubscriptionManagementService service = new SubscriptionManagementService();
        List<Subscription_Order__c> soToInsert = service.createSystemChangeOrders(uasList, ssso);

        System.assertEquals(2, soToInsert.size());

    }


    private static void useMocks() {
        SubscriptionManagementService.uasSelector = (UASSelector) Test.createStub(UASSelector.class, new MockUASSelector());
        SubscriptionManagementService.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockSSSSelector());
    }

    public class MockSSSSelector extends MockProvider {
        public MockSSSSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            return new Shared_Solar_System__c(
                Name = 'Test SSS',
                Id = 'a1J29000000tjOkEAI',
                Expected_Yield_kWh_kW__c = 1300.0000,
                Total_System_Size_kWh_DC__c = 1095.84
            );
        }
    }

    public class MockUASSelector extends MockProvider {
        public MockUASSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String uasBySSS = '[{"attributes" : {"type" : "Utility_Account_Subscription__c","url" : "/services/data/v47.0/sobjects/Utility_Account_Subscription__c/a1d29000001C3xuAAC"},' +
                '"Id" : "a1d29000001C3xuAAC",' +
                '"Name" : "0001234",' +
                '"Future_Customer_Subscription_KWDC_Rollup__c" : 12.5,' +
                '"Annual_kWh_Subscription_Future_Rollup__c" : 16240.38,' +
                '"Future_Share_of_System_Rollup__c" : 1.14,' +
                '"Annual_Cost_Future_Rollup__c" : 2420.00,' +
                '"Shared_Solar_System__c": "a1J29000000tjOkEAI"' +
                '},' +
                '{"attributes" : {"type" : "Utility_Account_Subscription__c","url" : "/services/data/v47.0/sobjects/Utility_Account_Subscription__c/a1d29000001C3xuAAC"},' +
                '"Id" : "a1d2900000222xuAAC",' +
                '"Name" : "0001234",' +
                '"Future_Customer_Subscription_KWDC_Rollup__c" : 12.5,' +
                '"Annual_kWh_Subscription_Future_Rollup__c" : 16240.38,' +
                '"Future_Share_of_System_Rollup__c" : 1.14,' +
                '"Annual_Cost_Future_Rollup__c" : 2420.00,' +
                '"Shared_Solar_System__c": "a1J29000000tjOkEAI"' +
                '}]';

            String uasByMap = '[{"attributes" : {"type" : "Utility_Account_Subscription__c","url" : "/services/data/v47.0/sobjects/Utility_Account_Subscription__c/a1d29000001C3xuAAC"},' +
                '"Id" : "a1d29000001C3xuAAC",' +
                '"Opportunity__c" : "00629000008boK7AAI",' +
                '"Opportunity__r":{"attributes" : {"type" : "Opportunity","url" : "/services/data/v47.0/sobjects/Opportunity/00629000009SnvfAAC"},' +
                '"Id" : "00629000008boK7AAI",' +
                '"NMC_Tariff__c" : "a1D29000000cScGEAU",' +
                '"NMC_Tariff__r":{ "attributes" : {"type" : "Utility_NMC_Tariff__c","url" : "/services/data/v47.0/sobjects/Utility_NMC_Tariff__c/a1D29000000cScGEAU"},' +
                '"Id" : "a1D29000000cScGEAU",' +
                '"Value_of_NMC__c" : 0.184800},' +
                '"Product__c" : "01t29000003pkTBAAY"},' +
                '"Shared_Solar_System__c": "a1J29000000tjOkEAI",' +
                '"Shared_Solar_System__r": { "attributes" : {"type" : "Shared_Solar_System__c","url" : "/services/data/v47.0/sobjects/Shared_Solar_System__c/a1J29000000tjOkEAI"},' +
                '"Id" : "a1J29000000tjOkEAI",' +
                '"Name" : "SSS Test",' +
                '"Client_Account__c" : "0012900000WKlZoAAL",' +
                '"Expected_Yield_kWh_kW__c" : 1300.0000,' +
                '"Total_System_Size_kWh_DC__c" : 1095.84,' +
                '"Utility__c" : "a1M290000013TkMEAU",' +
                '"Utility__r": {"attributes" : {"type" : "Utility__c","url" : "/services/data/v47.0/sobjects/Utility__c/a1M290000013TkMEAU"},' +
                '"Id" : "a1M290000013TkMEAU",' +
                '"Number_of_Decimal_Places__c" : 2 }' +
                '}' +
                '}, ' +
                '{ "attributes" : {"type" : "Utility_Account_Subscription__c","url" : "/services/data/v47.0/sobjects/Utility_Account_Subscription__c/a1d29000001C3xuAAC"},' +
                '"Id" : "a1d2900000222xuAAC",' +
                '"Opportunity__c" : "00629000008boJ7AAI",' +
                '"Opportunity__r":{"attributes" : {"type" : "Opportunity","url" : "/services/data/v47.0/sobjects/Opportunity/00629000009SnvfAAC"},' +
                '"Id" : "00629000008boJ7AAI",' +
                '"NMC_Tariff__c" : "a1D29000000cScGEAU",' +
                '"NMC_Tariff__r":{ "attributes" : {"type" : "Utility_NMC_Tariff__c","url" : "/services/data/v47.0/sobjects/Utility_NMC_Tariff__c/a1D29000000cScGEAU"},' +
                '"Id" : "a1D29000000cScGEAU",' +
                '"Value_of_NMC__c" : 0.184800},' +
                '"Product__c" : "01t29000003pkTBAAY"},' +
                '"Shared_Solar_System__c": "a1J29000000tjOkEAI",' +
                '"Shared_Solar_System__r": { "attributes" : {"type" : "Shared_Solar_System__c","url" : "/services/data/v47.0/sobjects/Shared_Solar_System__c/a1J29000000tjOkEAI"},' +
                '"Id" : "a1J29000000tjOkEAI",' +
                '"Name" : "SSS Test",' +
                '"Client_Account__c" : "0012900000WKlZoAAL",' +
                '"Expected_Yield_kWh_kW__c" : 1300.0000,' +
                '"Total_System_Size_kWh_DC__c" : 1095.84,' +
                '"Utility__c" : "a1M290000013TkMEAU",' +
                '"Utility__r": {"attributes" : {"type" : "Utility__c","url" : "/services/data/v47.0/sobjects/Utility__c/a1M290000013TkMEAU"},' +
                '"Id" : "a1M290000013TkMEAU",' +
                '"Number_of_Decimal_Places__c" : 2 }' +
                '}' +
                '}]';

            switch on methodCall.stubbedMethodName {
                when 'selectBySharedSolarSystem' {
                    return (List<Utility_Account_Subscription__c>) JSON.deserialize(uasBySSS, List<Utility_Account_Subscription__c>.class);
                }
                when 'getUASMap' {
                    Map<Id, Utility_Account_Subscription__c> uasMap = new Map<Id, Utility_Account_Subscription__c>();
                    List<Utility_Account_Subscription__c> uasList = (List<Utility_Account_Subscription__c>) JSON.deserialize(uasByMap, List<Utility_Account_Subscription__c>.class);
                    for (Utility_Account_Subscription__c uas : uasList) {
                        uasMap.put(uas.Id, uas);
                    }
                    return uasMap;
                }
            }
            return null;
        }
    }


}