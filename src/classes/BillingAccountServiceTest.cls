@IsTest
public with sharing class BillingAccountServiceTest {
    @TestSetup public static void testSetup() {
        Integer i;
        List<Account> accountsToInsert = new List<Account>();
        List<Zuora__CustomerAccount__c> zAccountsToInsert = new List<Zuora__CustomerAccount__c>();

        for (i = 0; i < 10; i++) {
            Account newSFAccount = new Account(
                Name = 'Account Name' + String.valueOf(i),
                Recurring_Billing__c = false
            );
            accountsToInsert.add(newSFAccount);
        }
        insert accountsToInsert;

        for (i = 0; i < 10; i++) {
            Zuora__CustomerAccount__c newAccount = new Zuora__CustomerAccount__c(
                Name = 'Account Name',
                Zuora__Account__c = accountsToInsert[i].Id,
                Zuora__Zuora_Id__c = '2c92c0f86b78f56c016b7b0048' + String.valueOf(i),
                Zuora__AutoPay__c = false
            );
            zAccountsToInsert.add(newAccount);
        }
        insert zAccountsToInsert;
    }

    @IsTest public static void testDisableTrigger() {
        List<Account> originalAutopayAccounts = [
            SELECT Id, Recurring_Billing__c
            FROM Account
            WHERE Recurring_Billing__c = true
        ];
        System.assertEquals(0,originalAutopayAccounts.size());

        List<Zuora__CustomerAccount__c> zuoraAccounts = [
            SELECT Id, Zuora__AutoPay__c
            FROM Zuora__CustomerAccount__c
            LIMIT 5
        ];

        for (Zuora__CustomerAccount__c acct : zuoraAccounts){
            acct.Zuora__AutoPay__c = true;
        }

        Test.startTest();
        Util.disableAllTriggers();
        update zuoraAccounts;
        Test.stopTest();

        List<Account> updatedAutopayAccounts = [
            SELECT Id, Recurring_Billing__c
            FROM Account
            WHERE Recurring_Billing__c = true
        ];
        System.assertEquals(0,updatedAutopayAccounts.size());
    }

    @IsTest public static void testAutopayUpdate() {
        List<Account> originalAutopayAccounts = [
            SELECT Id, Recurring_Billing__c
            FROM Account
            WHERE Recurring_Billing__c = true
        ];
        System.assertEquals(0,originalAutopayAccounts.size());

        List<Zuora__CustomerAccount__c> zuoraAccounts = [
            SELECT Id, Zuora__AutoPay__c
            FROM Zuora__CustomerAccount__c
            LIMIT 5
        ];

        for (Zuora__CustomerAccount__c acct : zuoraAccounts){
            acct.Zuora__AutoPay__c = true;
        }

        Test.startTest();
        update zuoraAccounts;
        Test.stopTest();

        List<Account> updatedAutopayAccounts = [
            SELECT Id, Recurring_Billing__c
            FROM Account
            WHERE Recurring_Billing__c = true
        ];
        System.assertEquals(5,updatedAutopayAccounts.size());
    }
}