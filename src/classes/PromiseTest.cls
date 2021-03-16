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
        // Should enqueueJob, but get this:
        // https://salesforce.stackexchange.com/questions/336329/apex-tests-using-finalizers-causes-metadata-api-deploy-to-result-in-limit-exceed
        // System.enqueueJob(dp);
        dp.chain = new Chain(dp.promises, dp.passThrough, false);
        dp.execute();
        Test.stopTest();

        Account checkAccount = [SELECT ShippingStreet, BillingStreet FROM Account WHERE Id = :account.Id LIMIT 1];
        System.assertEquals(1, Integer.valueOf(checkAccount.ShippingStreet),
            'If running the queueable and finalizer, should expect 3 instances of the queuable to have been run, each ' +
                'incrementing Shipping Street by 1, but we are working around it right now');
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
        // System.enqueueJob(dp);
        dp.chain = new Chain(dp.promises, dp.passThrough, false);
        dp.execute();
        Test.stopTest();

        Account checkAccount = [SELECT ShippingStreet, BillingStreet FROM Account WHERE Id = :account.Id LIMIT 1];
        System.assertEquals(1, Integer.valueOf(checkAccount.ShippingStreet),
            'If running the queueable and finalizer, should expect 3 instances of the queuable to have been run, each ' +
                'incrementing Shipping Street by 1, but we are working around it right now');
    }

    @IsTest
    private static void testNoExecutionAfterFailure() {
        Chain finalizer = new Chain(new List<Promise>{new DemoPromise(Util.getFakeId(Account.SObjectType))}, null, false);
        finalizer.execute(null, ParentJobResult.UNHANDLED_EXCEPTION, 'Test exception message');
        System.assertEquals(null, Chain.nextPromise,
            'Should not queue the next promise in the chain, if continueAfterFailure is false');
        System.assertEquals(1, [SELECT Id FROM Error_Log__c WHERE Class__c = 'Chain' AND Severity__c = :Logger.ERROR].size(),
            'Expected one error log for a failed queueable job');
    }

    @IsTest
    private static void testExecutionAfterFailure() {
        Chain finalizer = new Chain(new List<Promise>{new DemoPromise(Util.getFakeId(Account.SObjectType))}, null, true);
        finalizer.execute(null, ParentJobResult.UNHANDLED_EXCEPTION, 'Test exception message');
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

        public override void execute() {
            Account acct = [SELECT Name, ShippingStreet FROM Account WHERE Id = :this.accountId];
            Integer x = Integer.valueOf(acct.ShippingStreet);
            acct.ShippingStreet = String.valueOf(x+1);
            if (this.passThrough != null) {
                this.passThrough = 1 + (Integer) this.passThrough;
                acct.BillingStreet = String.valueOf(this.passThrough);
                chain.updatePassThrough(this.passThrough);

            }
            update acct;
        }
    }
}