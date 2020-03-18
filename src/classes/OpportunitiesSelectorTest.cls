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

    @IsTest public static void testCommissionQueries() {
        List<Opportunity> oppList = [
            SELECT Id, AccountId
            FROM Opportunity
            LIMIT 3
        ];

        Commission_Structure__c onlyBill = new Commission_Structure__c(
            Cents_kW_DC_First_Bill_Paid__c = 0.07,
            Cents_kW_DC_First_Bill__c = 0
        );
        insert onlyBill;
        Commission_Structure__c onlyPayment = new Commission_Structure__c(
            Cents_kW_DC_First_Bill_Paid__c = 0,
            Cents_kW_DC_First_Bill__c = 0.13
        );
        insert onlyPayment;
        Commission_Structure__c both = new Commission_Structure__c(
            Cents_kW_DC_First_Bill_Paid__c = 0.07,
            Cents_kW_DC_First_Bill__c = 0.13
        );
        insert both;

        oppList[0].Commission_Structure__c = onlyBill.Id;
        oppList[1].Commission_Structure__c = both.Id;
        oppList[2].Commission_Structure__c = onlyPayment.Id;

        Account newAccount = new Account(Name = 'Test Acct');
        insert newAccount;
        Set<Id> accountIdSet = new Set<Id>{newAccount.Id};
        OpportunitiesSelector selector = new OpportunitiesSelector();
        System.assertEquals(0, selector.selectWithoutFirstInvoiceCommission(accountIdSet).size());
        System.assertEquals(0, selector.selectWithoutFirstPaymentCommission(accountIdSet).size());
    }

    @IsTest
    public static void testSelectBySSSId() {
        Opportunity opp = [
            SELECT Id, Shared_Solar_System__c
            FROM Opportunity
            WHERE Shared_Solar_System__c != null
            LIMIT 1
        ];
        Set<Id> sssIds = new Set<Id>();
        sssIds.add(opp.Shared_Solar_System__c);
        OpportunitiesSelector selector = new OpportunitiesSelector();
        System.assert(selector.getOppsFromSSS(sssIds).size() > 0);
    }
}