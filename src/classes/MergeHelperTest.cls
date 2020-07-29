/**
 * Created by peteryao on 7/27/20.
 */
@IsTest
public with sharing class MergeHelperTest {
    @IsTest
    private static void testInvocablePrepForMerge() {
        InvocableMergeHelper.mergeHelper = (MergeHelper) Test.createStub(MergeHelper.class, new MockMergeHelperImpl());

        Id accountId = Util.getFakeId(Account.SObjectType);
        Id anotherAccountId = Util.incrementFakeId(accountId);
        try {
            InvocableMergeHelper.prepForMerge(new List<Id>{accountId, anotherAccountId});
            System.assert(false, 'Expected an exception invoking with multiple account ids');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Only one account supported'), e.getMessage());
        }
        try {
            InvocableMergeHelper.prepForMerge(new List<Id>{accountId});
            System.assert(true, 'Did not expect an exception, and for the merge helper to be called');
        } catch (Exception e) {
            System.assert(false, e.getMessage());
        }
    }

    @IsTest
    private static void testPrepForMergeSystemTest() {
        MergeHelper.subscriptionService = (ZuoraSubscriptionService) Test.createStub(ZuoraSubscriptionService.class, new MockSubscriptionService());
        Account propertyAccount = new Account(
            Name = 'Test',
            Zuora_Id__c = '123456'
        );
        insert propertyAccount;
        try {
            delete propertyAccount;
            System.assert(false, 'Expected an exception when deleting a property account that has a Zuora Id');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('This account has a Zuora Id'), e.getMessage());
        }
        Zuora_Contact__c zuoraContact = new Zuora_Contact__c(
            Zuora_Id__c = '2c92a0076ec9c0a9016ecc1ad5c034dc'
        );
        insert zuoraContact;

        Test.startTest();
        MergeHelper helper = new MergeHelper();
        helper.prepForMerge(propertyAccount.Id);
        Test.stopTest();

        Account preppedPropertyAccount = [
            SELECT Id, Name, Zuora_Id__c
            FROM Account
            WHERE Id = :propertyAccount.Id
        ];
        System.assertEquals(null, preppedPropertyAccount.Zuora_Id__c,
            'Expected Zuora Id to be nulled after being prepped for merge');
        System.assertEquals(propertyAccount.Name + ' dupe', preppedPropertyAccount.Name,
            'Expected the account name to be suffixed with dupe to make for easier merges');

        List<Zuora_Contact__c> zuoraContacts = [
            SELECT Id
            FROM Zuora_Contact__c
            WHERE Id = :zuoraContact.Id
        ];
        System.assertEquals(0, zuoraContacts.size(), 'Expected the zuora contact record to be deleted');

        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'MergeHelper'
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected an Info log for MergeHelper');
        System.assert(errorLogs[0].Message__c.contains('Zuora Accounts being deleted'),
            'Expected to log which Zuora account was deleted, but got this: ' + errorLogs[0].Message__c);
    }

    @IsTest
    private static void testPrepForMergeWithSubscriptions() {
        MergeHelper.accountsSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new MockAccountsSelector('BW-12345'));

        Test.startTest();
        MergeHelper mergeHelper = new MergeHelper();
        try {
            mergeHelper.prepForMerge(Util.getFakeId(Account.SObjectType));
            System.assert(false, 'ZuoraSubscriptionService Mock should return subscriptions by default, and not let prepForMerge continue');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Did not delete the Zuora account'),
                'Expected an exception about not deleting the account, but got this:\n' + e.getMessage());
        }
        Test.stopTest();
    }

    /*************
      *** MOCKS ***
      *************/
    @TestVisible
    private class MockSubscriptionService extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getSubscriptionsByAccount' {
                    ZuoraAPI.SubscriptionsByAccount subscriptionsByAccount = new ZuoraAPI.SubscriptionsByAccount();
                    subscriptionsByAccount.subscriptions = new List<ZuoraAPI.Subscription>();
                    return subscriptionsByAccount;
                }
            }
            return null;
        }
    }

    @TestVisible
    private class MockMergeHelperImpl extends MockProvider {
    }

    @TestVisible
    private class MockAccountsSelector extends MockProvider {
        private String accountNumber;
        public MockAccountsSelector(String accountNumber) {
            this.accountNumber = accountNumber;
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectOne' {
                    String json = '{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001S000000yKIYqIAO"},' +
                        '"Id":"001S000000yKIYqIAO",' +
                        '"Name":"Keith Morgan",' +
                        '"Account_Number__c":"'+accountNumber+'",' +
                        '"BillingStreet":"8888 Main Street",' +
                        '"BillingCity":"Boston",' +
                        '"BillingState":"Massachusetts",' +
                        '"BillingStateCode":"MA",' +
                        '"BillingPostalCode":"12312",' +
                        '"BillingCountry":"United States",' +
                        '"Send_Bills_Contact__c":"003S0000016Y23tIAC",' +
                        '"Zuora_Id__c":"2c92c0f86e5e38b0016e5fc9f13d15fb",' +
                        '"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/003S0000016Y23tIAC"},' +
                        '"Id":"003S0000016Y23tIAC",' +
                        '"Email":"bulk@bluewavesolar.com.disabledagain",' +
                        '"FirstName":"Keith",' +
                        '"LastName":"Morgan"}}';
                    Account account = (Account) System.JSON.deserialize(json, Account.class);
                    return account;
                }
            }
            return null;
        }
    }
}