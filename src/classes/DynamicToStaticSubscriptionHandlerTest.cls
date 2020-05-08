@isTest
public with sharing class DynamicToStaticSubscriptionHandlerTest {
    @testSetup static void setupTestData() {
        RecalculateUALCostControllerTest.setupTestData();
        FeatureService.featureSelector = (FeatureSelector) Test.createStub(FeatureSelector.class, new FeatureServiceTest.MockCustomFeatureSelector(false));

    }

    @isTest static void testRollup() {

        Shared_Solar_System__c sss9 = [SELECT Id, Name, Expected_Yield_kWh_Kw__c,
                                       (SELECT Id, Name, NMC_Value__c
                                        FROM Opportunities__r)
                                       FROM Shared_Solar_System__c 
                                       WHERE Name = 'Closed Not Zed P2'];

        System.assertEquals(1300, sss9.Expected_Yield_kWh_Kw__c);
        System.assertEquals(4, sss9.Opportunities__r.size());
        Opportunity opp8, opp9;
        for (Opportunity o : sss9.Opportunities__r) {
            if (o.Name.equals('RecalcUALOpp8A')) {
                opp8 = o;
            } else if (o.Name.equals('RecalcUALOpp9A')) {
                opp9 = o;
            }
        }
        System.assertEquals(1, opp8.NMC_Value__c);

        List<Utility_Account_Subscription__c> uasList = 
            [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, UAS_Number__c,
             Customer_Subscription_KW_DC_STATIC__c, Customer_Subscription_KW_DC__c, Next_Schedule_Z_Status__c
             FROM Utility_Account_Subscription__c
             WHERE Opportunity__c = :opp8.Id];
                                                         
        System.assertEquals(3, uasList.size());
        Decimal answer = 0;

        for (Utility_Account_Subscription__c uas : uasList) {
            System.assert(uas.Customer_Subscription_KW_DC_STATIC__c == null);
            if (uas.UAS_Number__c == 2) {
                System.assertEquals(3000, uas.Subscribed_Annual_Cost_of_Electricity__c);
                System.assert(uas.Next_Schedule_Z_Status__c == 'Active Subscription');
            } else if (uas.UAS_Number__c == 3) {
                System.assertEquals(9000, uas.Subscribed_Annual_Cost_of_Electricity__c);
                System.assert(uas.Next_Schedule_Z_Status__c == 'Inactive Subscription');
            } else {
                System.assertEquals(10000, uas.Subscribed_Annual_Cost_of_Electricity__c);
                System.assert(uas.Next_Schedule_Z_Status__c == 'Active Subscription');
            }
            answer += uas.Customer_Subscription_KW_DC__C;
        }
        Test.startTest();
        DynamicToStaticSubscriptionHandler.DynamicToStaticSubscriptionHandler(sss9.Id);
        DynamicToStaticSubscriptionHandler.sumUASes(opp8.Id);
        Test.stopTest();
        
        uasList = 
            [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c,
             Customer_Subscription_KW_DC_STATIC__c, Customer_Subscription_KW_DC__c, 
             Next_Schedule_Z_Status__c, UAS_Number__c
             FROM Utility_Account_Subscription__c
             WHERE Opportunity__c = :opp8.Id];
             
        for (Utility_Account_Subscription__c uas : uasList) {
            System.assertEquals(uas.Customer_Subscription_KW_DC__c, uas.Customer_Subscription_KW_DC_STATIC__c);
            if (uas.UAS_Number__c == 2){
                System.assert(uas.Next_Schedule_Z_Status__c == 'Active Subscription');
            } else if (uas.UAS_Number__c == 3){
                System.assert(uas.Next_Schedule_Z_Status__c == 'Inactive Subscription');
            } else if (uas.UAS_Number__c == 1){
                System.assert(uas.Next_Schedule_Z_Status__c == 'Active Subscription');
            }
        }
    }
}