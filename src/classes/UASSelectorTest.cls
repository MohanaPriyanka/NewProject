/*************************************************************************************
 * Created By: peteryao on 1/20/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class UASSelectorTest {
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

    @IsTest public static void testSelectByAccounts() {
        Set<Id> accountIds = (new Map<Id, Account>([SELECT Id FROM Account])).keySet();
        System.assert(UASSelector.selectByAccounts(accountIds).size() > 0, 'Expected UASes for accounts');
    }

    @IsTest public static void testSelectByUAL() {
        Set<Id> ualIds = (new Map<Id, Utility_Account_Log__c>([SELECT Id FROM Utility_Account_Log__c])).keySet();
        System.assert(UASSelector.selectByUAL(ualIds).size() > 0, 'Expected UALs for accounts');
    }

    @IsTest public static void testSelectClientMap() {
        Set<Id> idList = new Set<Id>();
        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id
            FROM Utility_Account_Subscription__c
            LIMIT 3
        ];

        for (Utility_Account_Subscription__c uas : uasList){
            idList.add(uas.Id);
        }

        System.assertEquals(3,UASSelector.selectByIdsAsMap(idList).values().size());
    }

    @IsTest public static void testGetBrandKeySummary() {
        // Test setup: link properties to a parent account:
        Map<Id,Opportunity> oppsToUpdate = new Map<Id,Opportunity>();
        Account parentAccount = new Account(
            Name = 'Parent'
        );
        insert parentAccount;
        Account propertyAccount = new Account(
            Name = 'Property',
            Parent_Account__c = parentAccount.Id
        );
        insert propertyAccount;

        List<Utility_Account_Subscription__c> uases = [
            SELECT Id, Opportunity__r.Id
            FROM Utility_Account_Subscription__c
        ];
        for (Utility_Account_Subscription__c uas : uases){
            Opportunity opp = new Opportunity(
                Id = uas.Opportunity__r.Id,
                AccountId = propertyAccount.Id
            );
            oppsToUpdate.put(opp.Id, opp);
        }
        update oppsToUpdate.values();
        UASSelector selector = new UASSelector();
        System.assert(selector.getBrandKeySummary(new Set<Id>{parentAccount.Id}).size() > 0, 'Expected UAL Summary');
    }
}