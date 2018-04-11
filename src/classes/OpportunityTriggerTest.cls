@isTest
public with sharing class OpportunityTriggerTest {
    @testSetup static void setupData() {
        RecalculateUALCostControllerTest.setupTestData();
    }

    @isTest static void testRollup() {        
        Map<String, Opportunity> oppMap = new Map<String, Opportunity>();
       
        Utility_NMC_Tariff__c tariff = [SELECT Id FROM Utility_NMC_Tariff__c LIMIT 1];

        for(Opportunity opp : [SELECT Id, Name, 
                                Subscription_Size_for_Invoicing__c 
                                FROM Opportunity 
                                ORDER BY Name]){
            opp.NMC_Tariff__c = tariff.Id;
            opp.StageName = 'New';
            oppMap.put(opp.Name, opp);
        }
        update oppMap.values();
        List<Utility_Account_Subscription__c> uasList = [SELECT Id, Name, 
                                                        Customer_Subscription_KW_DC__c, Opportunity__r.Name, Opportunity__c 
                                                        FROM Utility_Account_Subscription__c
                                                        WHERE (Opportunity__r.Name = 'Opp1' 
                                                        OR Opportunity__r.Name = 'Opp8')
                                                        ORDER BY Name];

        System.assertEquals(4,uasList.size());
       
        System.assertEquals(3.8462, uasList[0].Customer_Subscription_KW_DC__c);
        System.assertEquals('Opp1', uasList[0].Opportunity__r.Name);

        System.assertEquals(7.6923, uasList[1].Customer_Subscription_KW_DC__c);
        System.assertEquals(2.3077, uasList[2].Customer_Subscription_KW_DC__c);
        System.assertEquals(6.9231, uasList[3].Customer_Subscription_KW_DC__c);
        System.assertEquals('Opp8', uasList[1].Opportunity__r.Name);
        System.assertEquals('Opp8', uasList[2].Opportunity__r.Name);
        System.assertEquals('Opp8', uasList[3].Opportunity__r.Name);

        Opportunity one = oppMap.get('Opp1');
        Opportunity eight = oppMap.get('Opp8');
        System.assertEquals(null, one.Subscription_Size_for_Invoicing__c);
        System.assertEquals(null, eight.Subscription_Size_for_Invoicing__c);

        Test.StartTest();

        one.StageName = 'Complete';
        eight.StageName  = 'Complete';
        update new List<Opportunity> {one, eight};

        Test.StopTest();

        List<Opportunity> updatedOpp = [SELECT Id, Name, 
                                        Subscription_Size_for_Invoicing__c 
                                        FROM Opportunity 
                                        WHERE (Name = 'Opp1' OR Name = 'Opp8')
                                        ORDER BY Name];

        System.assertEquals(3.8462, updatedOpp[0].Subscription_Size_for_Invoicing__c);
        System.assertEquals(16.9231, updatedOpp[1].Subscription_Size_for_Invoicing__c);
    }
}