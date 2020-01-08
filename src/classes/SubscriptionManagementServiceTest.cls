/**
 * Created by SarahRenfro on 11/15/2019.
 */

@IsTest
private class SubscriptionManagementServiceTest {
    @TestSetup
    public static void setupData() {
        Shared_Solar_System_Order__c sssoSize = new Shared_Solar_System_Order__c(
            Shared_Solar_System__c = 'a1J29000000tjOkEAI',
            Total_System_Size_kW_DC__c = 2891.72,
            Approval_Status__c = 'Approved'
        );

        insert sssoSize;

    }


    @IsTest
    static void testSubscriptionOrderInsert() {
        useMocks();
        Subscription_Order__c so = new Subscription_Order__c(
            Utility_Account_Subscription__c = 'a1d29000001C3xuAAC'
        );

        insert so;

        Subscription_Order__c checkSO = [
            SELECT Id, Client_Account__c, Expected_Yield_kWh_kW__c, Total_System_Size_kW_DC__c, Utility_NMC_Tariff__c,
                Utility_Number_of_Decimal_Places__c, Value_of_NMC__c, Product__c
            FROM Subscription_Order__c
            LIMIT 1
        ];

        System.assertNotEquals(null, checkSO);
        System.assertEquals(1300, checkSO.Expected_Yield_kWh_kW__c);
        System.assertEquals(1095.84, checkSO.Total_System_Size_kW_DC__c);
        System.assertEquals(2, checkSO.Utility_Number_of_Decimal_Places__c );
        System.assertEquals(0.1848, checkSO.Value_of_NMC__c);
        System.assertNotEquals(null, checkSO.Product__c);

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
        System.assertEquals(2891.72, checkSSS.Total_System_Size_kWh_DC__c);

    }

    @IsTest
    private static void testCreateSubscriptionOrders() {
        useMocks();
        Shared_Solar_System_Order__c ssso = [
            SELECT Id, Shared_Solar_System__c, Yield__c, Total_System_Size_kW_DC__c
            FROM Shared_Solar_System_Order__c
            LIMIT 1
        ];

        SubscriptionManagementService service = new SubscriptionManagementService();
        List<Subscription_Order__c> soToInsert = service.createSubscriptionOrdersFromSSSO(ssso);

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
            String uasListAsJSON = '[{"attributes" : {"type" : "Utility_Account_Subscription__c","url" : "/services/data/v47.0/sobjects/Utility_Account_Subscription__c/a1d29000001C3xuAAC"},' +
                '"Id" : "a1d29000001C3xuAAC",' +
                '"Name" : "0001234",' +
                '"Utility_Account_Log__c" : "a1b29000001CJyIAAW",' +
                '"Next_Schedule_Z_Status__c" : "Active Subscription",' +
                '"Future_Customer_Subscription_KWDC_Rollup__c" : 12.5,' +
                '"Annual_kWh_Subscription_Future_Rollup__c" : 16240.38,' +
                '"Opportunity__c" : "00629000008boK7AAI",' +
                '"Opportunity__r":{"attributes" : {"type" : "Opportunity","url" : "/services/data/v47.0/sobjects/Opportunity/00629000009SnvfAAC"},' +
                '"Id" : "00629000008boK7AAI",' +
                '"NMC_Tariff__c" : "a1D29000000cScGEAU",' +
                '"NMC_Tariff__r":{ "attributes" : {"type" : "Utility_NMC_Tariff__c","url" : "/services/data/v47.0/sobjects/Utility_NMC_Tariff__c/a1D29000000cScGEAU"},' +
                '"Id" : "a1D29000000cScGEAU",' +
                '"Value_of_NMC__c" : 0.184800},' +
                '"Product__c" : "01t29000003pkTBAAY",' +
                '"Name" : "SubscriptionOrder Testcase"},' +
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
                '"Name" : "0005678",' +
                '"Utility_Account_Log__c" : "a1b29000001CKyIAAW",' +
                '"Next_Schedule_Z_Status__c" : "Active Subscription",' +
                '"Future_Customer_Subscription_KWDC_Rollup__c" : 13.5,' +
                '"Annual_kWh_Subscription_Future_Rollup__c" : 16260.38,' +
                '"Opportunity__c" : "00629000008boJ7AAI",' +
                '"Opportunity__r":{"attributes" : {"type" : "Opportunity","url" : "/services/data/v47.0/sobjects/Opportunity/00629000009SnvfAAC"},' +
                '"Id" : "00629000008boJ7AAI",' +
                '"NMC_Tariff__c" : "a1D29000000cScGEAU",' +
                '"NMC_Tariff__r":{ "attributes" : {"type" : "Utility_NMC_Tariff__c","url" : "/services/data/v47.0/sobjects/Utility_NMC_Tariff__c/a1D29000000cScGEAU"},' +
                '"Id" : "a1D29000000cScGEAU",' +
                '"Value_of_NMC__c" : 0.184800},' +
                '"Product__c" : "01t29000003pkTBAAY",' +
                '"Name" : "SubscriptionOrderTWO Testcase"},' +
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



            //'"Annual_Cost_Future_Rollup__c" : 0.000000,' +
            //dont have utility number of decimal places and NMC Tariff value of nmc
            //maybe i can just have the uases be mocked and then insert the subscription orders in the testSetup

            switch on methodCall.stubbedMethodName {
                when 'selectBySharedSolarSystem' {
                    return (List<Utility_Account_Subscription__c>) JSON.deserialize(uasListAsJSON, List<Utility_Account_Subscription__c>.class);
                }
                when 'getUASMap' {
                    Map<Id, Utility_Account_Subscription__c> uasMap = new Map<Id, Utility_Account_Subscription__c>();
                    List<Utility_Account_Subscription__c> uasList = (List<Utility_Account_Subscription__c>) JSON.deserialize(uasListAsJSON, List<Utility_Account_Subscription__c>.class);
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