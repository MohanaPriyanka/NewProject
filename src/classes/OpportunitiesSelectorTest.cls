/*************************************************************************************
 * Created By: peteryao on 1/19/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class OpportunitiesSelectorTest {
    @TestSetup public static void testSetup() {
        Util.disableAllTriggers();

        TestFactory.insertBWAddress();
        Test.loadData(Utility__c.SObjectType, 'TestCSUtility');
        Test.loadData(Utility_NMC_Tariff__c.SObjectType, 'TestCSUtilityNMCTariff');
        Test.loadData(Load_U__c.SObjectType, 'TestCSLoadU');
        Test.loadData(ChargentBase__Gateway__c.SObjectType, 'TestCSGateway');
        Test.loadData(Contact.SObjectType, 'TestCSContact');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Test.loadData(Entity__c.SObjectType, 'TestCSEntity');
        Test.loadData(Shared_Solar_System__c.SObjectType, 'TestCSSharedSolarSystem');
        Test.loadData(Utility_Account_Log__c.SObjectType, 'TestCSUtilityAccountLog');
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Test.loadData(Utility_Account_Subscription__c.SObjectType, 'TestCSUtilityAccountSubscription');

        Util.enableAllTriggers();
    }

    @IsTest public static void testSelectAllCompleteCSWithUASesAndSystemBills() {
        System.assert(OpportunitiesSelector.selectAllCompleteCSWithUASesAndSystemBills().size() > 0, 'Expected Complete CS Opps');
    }

    @IsTest public static void testSelectForContractSend() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        System.assertNotEquals(null, OpportunitiesSelector.selectForContractSend(opp.Id));
    }

    @IsTest
    public static void testSelectForMap() {
        List<Opportunity> opps = [SElECT Id FROM Opportunity LIMIT 3];
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : opps) {
            oppIds.add(opp.Id);
        }
        System.assertNotEquals(null, OpportunitiesSelector.selectOpportunityMap(oppIds));
    }
}