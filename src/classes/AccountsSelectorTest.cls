/*************************************************************************************
 * Created By: peteryao on 1/20/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class AccountsSelectorTest {
    @TestSetup public static void testSetup() {
        Util.disableTrigger('Disable_AccountTrigger__c');
        Util.disableTrigger('Disable_ContactTrigger__c');

        Test.loadData(Contact.SObjectType, 'TestCSContact');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Util.enableTrigger('Disable_AccountTrigger__c');
        Util.enableTrigger('Disable_ContactTrigger__c');
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
}