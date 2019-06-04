/*************************************************************************************
 * Created By: peteryao on 2019-05-11  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraAccountAsyncServiceTest {
    @TestSetup
    public static void testSetup() {
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
    }

    @IsTest
    public static void testBatchAccountCreation() {
        List<Account> accountsToCreate = [
            SELECT Id, Name
            FROM Account
        ];
        for (Account account : accountsToCreate) {
            account.Zuora_Id__c = null;
        }
        // Clear out Zuora Id from all accounts, since we import with it set
        update accountsToCreate;

        // TestCSAccounts includes 27 accounts, not all of which has a Send Bills Contact
        System.assertEquals(27, accountsToCreate.size());
        Map<Id, Account> accountMap = new Map<Id, Account>(accountsToCreate);
        ZuoraAccountAsyncService asyncService =
            new ZuoraAccountAsyncService(AccountsSelector.selectWithSendBillsContact(accountMap.keySet()));
        Test.startTest();
        asyncService.startBatch(50);
        Test.stopTest();
        accountsToCreate = [
            SELECT Id, Send_Bills_Contact__c, Zuora_Id__c
            FROM Account
        ];
        // Still 27 accounts, all of which should now have a Zuora Id
        System.assertEquals(27, accountsToCreate.size());
        for (Account account : accountsToCreate) {
            System.assertNotEquals(null, account.Zuora_Id__c);
        }
        Set<Id> contacts = new Set<Id>();
        for (Account account : accountsToCreate) {
            if (account.Send_Bills_Contact__c != null) {
                contacts.add(account.Send_Bills_Contact__c);
            }
        }
        List<Contact> contactList = [
            SELECT Id,
            (SELECT Id FROM Zuora_Contacts__r)
            FROM Contact
            WHERE Id IN :contacts
        ];
        // There should be two contacts, both of which should have a Zuora Contact under it
        System.assertEquals(2, contactList.size());
        for (Contact contact : contactList) {
            System.assertEquals(1, contact.Zuora_Contacts__r.size());
        }
    }

    @IsTest
    public static void testBatchAccountCreationException() {
        Account accountToCreate = [
            SELECT Id
            FROM Account
            WHERE Zuora_Id__c = NULL
            LIMIT 1
        ];
        // To force an exception to be thrown
        accountToCreate.Name = 'ThrowException';
        update accountToCreate;

        ZuoraAccountAsyncService asyncService =
            new ZuoraAccountAsyncService(AccountsSelector.selectWithSendBillsContact(new Set<Id>{accountToCreate.Id}));
        Test.startTest();
        asyncService.startBatch(50);
        Test.stopTest();
        accountToCreate = [
            SELECT Id, Send_Bills_Contact__c, Zuora_Id__c
            FROM Account
            WHERE Id = :accountToCreate.Id
        ];
        // We expect Zuora ID to still be null
        System.assertEquals(null, accountToCreate.Zuora_Id__c);
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
        ];
        // There should have been an error logged:
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Zuora account creation failed for accounts'));
    }
}