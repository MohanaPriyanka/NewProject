/**
 * Created by peteryao on 12/13/19.
 */
@IsTest
public with sharing class ZuoraPaymentRunSchedulerTest {
    @IsTest
    private static void testPaymentRunCreation() {
        String queryResponse = '[{"DueDate":"2019-11-09"}]';
        ZuoraPaymentRunScheduler paymentRunScheduler = new ZuoraPaymentRunScheduler();
        paymentRunScheduler.executePostQueryJob(null, queryResponse);
        System.assertEquals(1, ZuoraAPIHelper.endpointsCalled.size());
        System.assert(ZuoraAPIHelper.endpointsCalled[0].endpoint.contains('payment-runs'), 'Expected to post a new payment run');
    }

    @IsTest
    private static void testNoPaymentRun() {
        String queryResponse = '[]';
        ZuoraPaymentRunScheduler paymentRunScheduler = new ZuoraPaymentRunScheduler();
        paymentRunScheduler.executePostQueryJob(null, queryResponse);
        System.assertEquals(0, ZuoraAPIHelper.endpointsCalled.size());
        System.assertEquals(1, [SELECT Id FROM Error_Log__c WHERE Severity__c = :Logger.ERROR AND Class__c = 'ZuoraPaymentRunScheduler'].size());
    }

    @IsTest
    private static void testPaymentRunExecute() {
        ZuoraPaymentRunScheduler paymentRunScheduler = new ZuoraPaymentRunScheduler();
        Boolean caughtException = false;
        try {
            Test.startTest();
            System.schedule('TestPaymentRunScheduler', '0 0 9 1 * ? *', paymentRunScheduler);
            Test.stopTest();
        } catch (Exception e) {
            caughtException = true;
        }
        System.assert(!caughtException, 'Expected the scheduled job to run without exception');
    }

}