/*************************************************************************************
 * Created By: peteryao on 1/20/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class UASSelectorTest {
    @TestSetup public static void testSetup() {
        Util.disableTrigger('Disable_System_Bill_Trigger__c');
        Util.disableTrigger('Disable_AccountBillTrigger__c');
        Util.disableTrigger('Disable_UASBTrigger__c');
        Util.disableTrigger('Disable_OpportunityTrigger__c');
        Util.disableTrigger('Disable_ChargentOrderTrigger__c');
        Util.disableTrigger('Disable_EnergyUsageUpdateTrigger__c');
        Util.disableTrigger('Disable_SharedSolarSystemTrigger__c');
        Util.disableTrigger('Disable_AccountTrigger__c');
        Util.disableTrigger('Disable_ContactTrigger__c');
        Util.disableTrigger('Disable_UserTrigger__c');
        Util.disableTrigger('Disable_ScheduleZTrigger__c');

        TestFactory.insertBWAddress();
        Test.loadData(Utility__c.SObjectType, 'TestCSUtility');
        Test.loadData(Utility_NMC_Tariff__c.SObjectType, 'TestCSUtilityNMCTariff');
        Test.loadData(Load_U__c.SObjectType, 'TestCSLoadU');
        Test.loadData(ChargentBase__Gateway__c.SObjectType, 'TestCSGateway');
        Test.loadData(Entity__c.SObjectType, 'TestCSEntity');
        Test.loadData(Shared_Solar_System__c.SObjectType, 'TestCSSharedSolarSystem');
        Test.loadData(Contact.SObjectType, 'TestCSContact');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Test.loadData(Utility_Account_Log__c.SObjectType, 'TestCSUtilityAccountLog');
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Test.loadData(Utility_Account_Subscription__c.SObjectType, 'TestCSUtilityAccountSubscription');

        Util.enableTrigger('Disable_System_Bill_Trigger__c');
        Util.enableTrigger('Disable_AccountBillTrigger__c');
        Util.enableTrigger('Disable_UASBTrigger__c');
        Util.enableTrigger('Disable_OpportunityTrigger__c');
        Util.enableTrigger('Disable_ChargentOrderTrigger__c');
        Util.enableTrigger('Disable_EnergyUsageUpdateTrigger__c');
        Util.enableTrigger('Disable_SharedSolarSystemTrigger__c');
        Util.enableTrigger('Disable_AccountTrigger__c');
        Util.enableTrigger('Disable_ContactTrigger__c');
        Util.enableTrigger('Disable_UserTrigger__c');
        Util.enableTrigger('Disable_ScheduleZTrigger__c');
    }

    @IsTest public static void testSelectByAccounts() {
        Set<Id> accountIds = (new Map<Id, Account>([SELECT Id FROM Account])).keySet();
        System.assert(UASSelector.selectByAccounts(accountIds).size() > 0, 'Expected UASes for accounts');
    }

    @IsTest public static void testSelectByUAL() {
        Set<Id> ualIds = (new Map<Id, Utility_Account_Log__c>([SELECT Id FROM Utility_Account_Log__c])).keySet();
        System.assert(UASSelector.selectByUAL(ualIds).size() > 0, 'Expected UALs for accounts');
    }
}