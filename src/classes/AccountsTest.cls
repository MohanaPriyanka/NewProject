/*************************************************************************************
 * Created By: peteryao on 1/18/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class AccountsTest {
    @IsTest
    public static void testClose() {
        List<Account> accts = new List<Account>();
        for (Integer i = 0; i < 100; i++) {
            accts.add(new Account(Name = 'Test Account'));
        }
        insert accts;

        List<Account> closedAccounts = [SELECT Id FROM Account WHERE Status__c = 'Closed'];
        // We shouldn't have any closed accounts
        System.assertEquals(0, closedAccounts.size());

        Test.startTest();
        Accounts domainAccounts = new Accounts(accts);
        domainAccounts.close();
        Test.stopTest();

        // Now all the account should be closed
        closedAccounts = [SELECT Id FROM Account WHERE Status__c = 'Closed'];
        System.assertEquals(100, closedAccounts.size());
    }
}