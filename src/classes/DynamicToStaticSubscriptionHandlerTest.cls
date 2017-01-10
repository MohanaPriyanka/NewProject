@isTest
public with sharing class DynamicToStaticSubscriptionHandlerTest {
    // The Opportunity's CS_Capacity_Allocated__c field should be a rollup of
    // related Utility Account Subscription Customer_Subscription_KW_DC__c values
    //
    // It should also set all related Utility Account Subscription Customer_Subscription_KW_DC_STATIC__c
    // values to Customer_Subscription_KW_DC__C

    @testSetup static void setupTestData() {
        RecalculateUALCostControllerTest.setupTestData();
    }

    @isTest static void testRollup() {
        Shared_Solar_System__c sss8 = [SELECT Id, Name, Expected_Yield_kWh_Kw__c,
                                       (SELECT Id, Name, CS_Capacity_Allocated__c, NMC_Value__c
                                        FROM Opportunities__r)
                                       FROM Shared_Solar_System__c 
                                       WHERE Name = 'Closed Not Zed P2'];

        System.assertEquals(1300, sss8.Expected_Yield_kWh_Kw__c);
        System.assertEquals(2, sss8.Opportunities__r.size());
        Opportunity opp8, opp9;
        for (Opportunity o : sss8.Opportunities__r) {
            if (o.Name.equals('Opp8')) {
                opp8 = o;
            } else if (o.Name.equals('Opp9')) {
                opp9 = o;
            }
        }
        System.assertEquals(1, opp8.NMC_Value__c);

        List<Utility_Account_Subscription__c> uasList = 
            [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, UAS_Number__c,
             Customer_Subscription_KW_DC_STATIC__c, Customer_Subscription_KW_DC__c
             FROM Utility_Account_Subscription__c
             WHERE Opportunity__c = :opp8.Id];
                                                         
        System.assertEquals(3, uasList.size());
        Decimal answer = 0;
        for (Utility_Account_Subscription__c uas : uasList) {
            System.assert(uas.Customer_Subscription_KW_DC_STATIC__c == null);
            if (uas.UAS_Number__c == 2) {
                System.assertEquals(3000, uas.Subscribed_Annual_Cost_of_Electricity__c);
                System.assertEquals(2.3077, uas.Customer_Subscription_KW_DC__c);
            } else if (uas.UAS_Number__c == 3) {
                System.assertEquals(9000, uas.Subscribed_Annual_Cost_of_Electricity__c);
                System.assertEquals(6.9231, uas.Customer_Subscription_KW_DC__c);
            } else {
                System.assertEquals(10000, uas.Subscribed_Annual_Cost_of_Electricity__c);
                System.assertEquals(7.6923, uas.Customer_Subscription_KW_DC__c);
            }
            answer += uas.Customer_Subscription_KW_DC__C;
        }
        
        DynamicToStaticSubscriptionHandler.DynamicToStaticSubscriptionHandler(sss8.Id);

        sss8 = [SELECT Id, Name,
                (SELECT Id, Name, CS_Capacity_Allocated__c
                 FROM Opportunities__r)
                FROM Shared_Solar_System__c 
                WHERE Name = 'Closed Not Zed P2'];
        for (Opportunity o : sss8.Opportunities__r) {
            if (o.Name.equals('Opp8')) {
                opp8 = o;
            } else if (o.Name.equals('Opp9')) {
                opp9 = o;
            }
        }
        System.assertEquals(answer, opp8.CS_Capacity_Allocated__c);
        System.assertEquals(7.6923, opp9.CS_Capacity_Allocated__c);

        uasList = 
            [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c,
             Customer_Subscription_KW_DC_STATIC__c, Customer_Subscription_KW_DC__c
             FROM Utility_Account_Subscription__c
             WHERE Opportunity__c = :opp8.Id];
        for (Utility_Account_Subscription__c uas : uasList) {
            System.assertEquals(uas.Customer_Subscription_KW_DC__c, uas.Customer_Subscription_KW_DC_STATIC__c);
        }
    }
}