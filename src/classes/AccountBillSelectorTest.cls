/**
 * Created by mstackhouse on 1/16/2019.
 * Description: 
 * Test: 
 */

@IsTest
public with sharing class AccountBillSelectorTest {
    @IsTest
    public static void testCanGetAllReadyAccountBillsWithoutIDs() {
        Account accountParent1 = getParentAccount();
        ContentDocument doc = getContentDocument();

        Date billDate = Date.newInstance(2019, 2, 12);

        Account_Bill__c readyAccountBill = new Account_Bill__c(
            Parent_Account__c = accountParent1.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Date__c = billDate,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Attach_Document__c = doc.Id
        );

        Account_Bill__c unPublishedAccountBill = new Account_Bill__c(
            Parent_Account__c = accountParent1.Id,
            Bill_Number__c = 2,
            Published__c = false,
            Date__c = billDate,
            Ready_For_Paper_Bill_Queue__c = false,
            Bill_Attach_Document__c = doc.Id
        );

        Account_Bill__c publishedNotReadyAccountBill = new Account_Bill__c(
            Parent_Account__c = accountParent1.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Date__c = billDate,
            Ready_For_Paper_Bill_Queue__c = false,
            Bill_Attach_Document__c = doc.Id
        );

        Account_Bill__c noDocAccountBill = new Account_Bill__c(
            Parent_Account__c = accountParent1.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Date__c = billDate,
            Ready_For_Paper_Bill_Queue__c = false
        );

        insert new List<Account_Bill__c>{readyAccountBill, unPublishedAccountBill, publishedNotReadyAccountBill, noDocAccountBill};

        List<Account_Bill__c> queriedBills = AccountBillSelector.getAccountBillsReadyToBeSent(null);
        System.assertEquals(1, queriedBills.size());

        List<AggregateResult> abSummary = AccountBillSelector.getAccountBillSummary(2, '2019');
        System.assertEquals(3, abSummary.size());
    }

    @IsTest
    public static void testCanGetAllReadyAccountBillsByIDs() {
        Account accountParent1 = getParentAccount();
        ContentDocument doc = getContentDocument();

        Account_Bill__c readyAccountBill = new Account_Bill__c(
            Parent_Account__c = accountParent1.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Attach_Document__c = doc.Id
        );

        Account_Bill__c unPublishedAccountBill = new Account_Bill__c(
            Parent_Account__c = accountParent1.Id,
            Bill_Number__c = 2,
            Published__c = false,
            Ready_For_Paper_Bill_Queue__c = false,
            Bill_Attach_Document__c = doc.Id
        );

        Account_Bill__c publishedNotReadyAccountBill = new Account_Bill__c(
            Parent_Account__c = accountParent1.Id,
            Bill_Number__c = 2,
            Published__c = true,
            Ready_For_Paper_Bill_Queue__c = false,
            Bill_Attach_Document__c = doc.Id
        );

        insert new List<Account_Bill__c>{readyAccountBill, unPublishedAccountBill, publishedNotReadyAccountBill};
        Set<Id> accountBillIds = new Set<Id>{
            readyAccountBill.Id,
            unPublishedAccountBill.Id,
            publishedNotReadyAccountBill.Id
        };

        List<Account_Bill__c> queriedBills = AccountBillSelector.getAccountBillsReadyToBeSent(accountBillIds);
        System.assertEquals(1, queriedBills.size());
    }

    public static Account getParentAccount() {
        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent1 = new Account(
            name = 'Account Parent',
            RecordTypeId = parentAccountRT,
            BillingStreet = '123 Fake St',
            BillingCity = 'City',
            BillingState = 'Colorado',
            BillingPostalCode = '80525'
        );
        insert accountParent1;
        return accountParent1;
    }

    public static ContentDocument getContentDocument() {
        ContentVersion documentVersion3 = new ContentVersion(
            Title = 'test document',
            PathOnClient = 'test_Doc.pdf',
            VersionData = Blob.valueOf('testDoc')
        );
        Util.insertSObjs(new List<ContentVersion>{documentVersion3});

        ContentDocument contentDocument = [
            SELECT Id, LatestPublishedVersionId
            FROM ContentDocument
            WHERE LatestPublishedVersionId = : documentVersion3.Id
            LIMIT 1
        ];

        return contentDocument;
    }
}