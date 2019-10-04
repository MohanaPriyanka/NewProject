/*************************************************************************************
 * Created By: peteryao on 1/20/19
 * Description:
 * Test:
 *************************************************************************************/
@IsTest
public with sharing class AccountsSelectorTest {
    @TestSetup public static void testSetup() {
        Util.disableAllTriggers();
        Test.loadData(Utility__c.SObjectType, 'TestCSUtility');
        Test.loadData(Utility_NMC_Tariff__c.SObjectType, 'TestCSUtilityNMCTariff');
        Test.loadData(Load_U__c.SObjectType, 'TestCSLoadU');
        Test.loadData(ChargentBase__Gateway__c.SObjectType, 'TestCSGateway');
        Test.loadData(Contact.SObjectType, 'TestCSContact');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Test.loadData(Entity__c.SObjectType, 'TestCSEntity');
        Test.loadData(Shared_Solar_System__c.SObjectType, 'TestCSSharedSolarSystem');
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Util.enableAllTriggers();
    }

    @IsTest public static void testSelectCS67() {
        System.assert(AccountsSelector.selectCS67DaysPastDueWithAnchorOpps() != null, 'Expected a list of accounts');
    }

    @IsTest public static void testSelectCSNotRemoved() {
        System.assert(AccountsSelector.selectCSNotRemoved() != null, 'Expected a list of accounts');
    }
    @IsTest public static void testSelectNotClosed() {
        Set<Id> accountIds = (new Map<Id, Account>([SELECT Id FROM Account])).keySet();
        System.assert(AccountsSelector.selectNotClosed(accountIds) != null, 'Expected a list of accounts');
    }
    @IsTest public static void testSelectWithSendBillsContact() {
        Account autoEmailerAccount = [SELECT Id FROM Account WHERE Name = 'AutoEmailer Account A'];
        System.assertEquals(
            'example@example.com',
            AccountsSelector.selectWithSendBillsContact(new Set<Id>{autoEmailerAccount.Id})[0].Send_Bills_Contact__r.Email,
            'Expected to find an account with send bills contact'
        );
    }

    @IsTest public static void testSelectOne() {
        List<Account> accountIds = (new List<Account>([SELECT Id FROM Account]));
        AccountsSelector accountsSelector = new AccountsSelector();
        System.assert(accountsSelector.selectOne(accountIds.get(0).Id) != null, 'Expected a single account');
    }
    @IsTest public static void testSelectAll() {
        Set<Id> accountIds = (new Map<Id, Account>([SELECT Id FROM Account])).keySet();
        AccountsSelector accountsSelector = new AccountsSelector();
        System.assert(accountsSelector.selectAll(accountIds) != null, 'Expected a list of accounts');
    }

    @IsTest public static void testSelectPropertyAccountsByLeadIds() {
        Lead newLead = new Lead(
            FirstName = 'test',
            LastName = 'test',
            Company = 'Test Company'
        );
        insert newLead;

        Id propertyRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
        Account propertyAccount = new Account(
            RecordTypeId = propertyRecordTypeId,
            Lead__c = newLead.Id,
            Name = 'Test Account'
        );
        insert propertyAccount;

        AccountsSelector accountsSelector = new AccountsSelector();
        System.assertEquals(accountsSelector.selectPropertyAccountsByLeadIds(new Set<Id>{newLead.Id}).size(), 1, 'Expected only one property account to be returned');
    }

    @IsTest public static void testselectAccountsWithBillMessages() {
        Id propertyRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
        Account propertyAccount = new Account(
            RecordTypeId = propertyRecordTypeId,
            Name = 'Test Account',
            Zuora_Invoice_Message_2_of_2__c = 'XXX',
            Zuora_Invoice_Message_1_of_2__c = 'xxx'
        );
        insert propertyAccount;

        System.assertEquals(1,AccountsSelector.selectAccountsWithBillMessages().size());
    }

    @IsTest
    public static void testSelectForReconciliation() {
        List<String> zuoraAccountIds = new List<String>{'2c92c0f86ab120de016ab427c9032366', '2c92c0f86ab120de016ab427c9032362'};
        AccountsSelector accountSelector = new AccountsSelector();
        List<Map<String, Object>> accounts = accountSelector.selectForReconciliation(zuoraAccountIds);
        System.assertEquals(2, accounts.size());

        zuoraAccountIds = new List<String>{'foo', 'bar'};
        accounts = accountSelector.selectForReconciliation(zuoraAccountIds);
        System.assertEquals(0, accounts.size());
    }
}