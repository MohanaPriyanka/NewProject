/**
 * Created by PeterYao on 1/7/2020.
 * Tested By: ZuoraPaymentServiceTest, ZuoraPaymentPageControllerTest
 */

public with sharing class ZuoraPaymentAsyncService implements Queueable, Database.AllowsCallouts {
    private ZuoraAPI.Payment successfulPayment;
    @TestVisible
    private Integer retryCounter;
    @TestVisible
    private static ZuoraPaymentAsyncService nextAsyncService;

    public ZuoraPaymentAsyncService() {
        this.retryCounter = 0;
    }

    public ZuoraPaymentAsyncService(Integer retryCount) {
        this.retryCounter = retryCount;
    }

    public void setPaymentToApply(ZuoraAPI.Payment payment) {
        this.successfulPayment = payment;
    }

    public void execute(QueueableContext context) {
        try {
            if (retryCounter >= Util.getSystemPropertyDecimal('Zuora_Payment_Application_Retries__c')) {
                throw new Util.FatalBWException('Hit max retries');
            }
            ZuoraPaymentService paymentService = new ZuoraPaymentService();
            paymentService.applyPaymentToBalance(successfulPayment);
        } catch (Util.BWException bwe) {
            ZuoraPaymentAsyncService nextPaymentAsyncService = new ZuoraPaymentAsyncService(retryCounter+1);
            nextPaymentAsyncService.setPaymentToApply(this.successfulPayment);
            if (!Test.isRunningTest()) {
                System.enqueueJob(nextPaymentAsyncService);
            } else {
                ZuoraPaymentAsyncService.nextAsyncService = nextPaymentAsyncService;
            }
            Logger.logLater(
                'ZuoraPaymentAsyncService',
                'execute',
                'BWException caught, but retrying\n' + bwe.getMessage() + '\n' + bwe.getStackTraceString(),
                Logger.WARN
            );
        } catch (Exception e) {
            Logger.logLater(
                'ZuoraPaymentAsyncService',
                'execute',
                'Exception caught, not retrying\n' + e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR
            );
        } finally {
            Logger.flushLogs();
        }
    }
}