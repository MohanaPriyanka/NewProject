/**
 * @description: Adapted from: https://github.com/codefriar/promiseV3/blob/master/force-app/main/default/classes/DemoPromiseTests.cls
 */
@IsTest
public with sharing class PromiseTest {
    @TestSetup
    private static void testSetup() {
        Util.disableTrigger('Disable_AccountTrigger__c');
        Account account = new Account(
            Name = 'TestAccount',
            ShippingStreet = '0'
        );
        insert account;
    }

    @IsTest
    private static void basicEndToEndTest() {
        Chain.callQueueableChain = true;
        Account account = [SELECT Id FROM Account WHERE Name = 'TestAccount' LIMIT 1];
        Test.startTest();
        DemoPromise dp = new DemoPromise(account.Id);
        dp.passThrough = (Integer) 0;
        dp.promises = new List<Promise>{new DemoPromise(account.Id), new DemoPromise(account.Id)};
        System.enqueueJob(dp);
        Test.stopTest();

        Account checkAccount = [SELECT ShippingStreet, BillingStreet FROM Account WHERE Id = :account.Id LIMIT 1];
        System.assertEquals(3, Integer.valueOf(checkAccount.ShippingStreet),
            'Expected 3 instances of the queuable to have been run, each incrementing Shipping Street by 1');
        System.assertEquals(3, Integer.valueOf(checkAccount.BillingStreet),
            'Expected 3 instances of the queuable to have been run, each incrementing Shipping Street by 1');
    }

    @IsTest
    private static void thenTest() {
        Chain.callQueueableChain = true;
        Account account = [SELECT Id FROM Account WHERE Name = 'TestAccount' LIMIT 1];
        Test.startTest();
        DemoPromise dp = new DemoPromise(account.Id);
        dp.passThrough = (Integer) 0;
        dp.then(new DemoPromise(account.Id))
            .then(new DemoPromise(account.Id));
        System.enqueueJob(dp);
        Test.stopTest();

        Account checkAccount = [SELECT ShippingStreet, BillingStreet FROM Account WHERE Id = :account.Id LIMIT 1];
        System.assertEquals(3, Integer.valueOf(checkAccount.ShippingStreet),
            'Expected 3 instances of the queuable to have been run, each incrementing by 1');
        System.assertEquals(3, Integer.valueOf(checkAccount.BillingStreet),
            'Expected 3 instances of the queuable to have been run, each incrementing by 1');
    }

    @IsTest
    private static void testNoExecutionAfterFailure() {
        Chain finalizer = new Chain(new List<Promise>{new DemoPromise(Util.getFakeId(Account.SObjectType))}, null, false);
        finalizer.handleFailedQueueableJob(null, 'Test exception message');
        System.assertEquals(null, Chain.nextPromise,
            'Should not queue the next promise in the chain, if continueAfterFailure is false');
        System.assertEquals(1, [SELECT Id FROM Error_Log__c WHERE Class__c = 'Chain' AND Severity__c = :Logger.ERROR].size(),
            'Expected one error log for a failed queueable job');
    }

    @IsTest
    private static void testExecutionAfterFailure() {
        Chain finalizer = new Chain(new List<Promise>{new DemoPromise(Util.getFakeId(Account.SObjectType))}, null, true);
        finalizer.handleFailedQueueableJob(null, 'Test exception message');
        System.assertNotEquals(null, Chain.nextPromise,
            'Should queue the next promise in the chain, if continueAfterFailure is true');
        System.assertEquals(1, [SELECT Id FROM Error_Log__c WHERE Class__c = 'Chain' AND Severity__c = :Logger.ERROR].size(),
            'Expected one error log for a failed queueable job');
    }

    public class DemoPromise extends Promise {
        Id accountId;

        public DemoPromise(Id accountId) {
            this.accountId = accountId;
        }

        public DemoPromise(Id accountId, Promise[] promises) {
            this.accountId = accountId;
            this.promises = promises;
        }

        public override void execute() {
            Account acct = [SELECT Name, ShippingStreet FROM Account WHERE Id = :this.accountId];
            Integer x = Integer.valueOf(acct.ShippingStreet);
            acct.ShippingStreet = String.valueOf(x+1);
            if (this.passThrough != null) {
                this.passThrough = 1 + (Integer) this.passThrough;
                acct.BillingStreet = String.valueOf(this.passThrough);
            }
            update acct;
        }
    }

    public class ExceptionThrowingPromise extends Promise {
        public override void execute() {
            Logger.logLater(
                'ExceptionThrowingPromise',
                'execute',
                'The exception should be unhandled, but that results in the apex test failing when it should not',
                Logger.ERROR
            );
        }
    }
}