/**
 * Created by peteryao on 12/13/19.
 * Tested By: ZuoraPaymentRunSchedulerTest
 */

public with sharing class ZuoraPaymentRunScheduler implements ZuoraDataQueryService.Processor, Schedulable {
    public void execute(SchedulableContext schedulableContext) {
        ZuoraDataQueryService.ProcessingParameter parameter = new ZuoraDataQueryService.ProcessingParameter();
        parameter.className = 'ZuoraPaymentRunScheduler';
        ZuoraDataQueryService.callFromApex(ZuoraInvoiceSelector.getLatestDueDateForAutopayAccounts(), parameter);
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String queryResponse) {
        try {
            List<InvoiceDueDate> invoiceDueDates = (List<InvoiceDueDate>) JSON.deserialize(queryResponse, List<InvoiceDueDate>.class);
            if (invoiceDueDates.size() != 1 || invoiceDueDates[0].dueDate == null) {
                Logger.logLater('ZuoraPaymentRunScheduler', 'executePostQueryJob', 'Expected to find the latest invoice due date, but found: ' + queryResponse, Logger.ERROR);
                return;
            }
            ZuoraAPI.PaymentRun paymentRun = new ZuoraAPI.PaymentRun(invoiceDueDates[0].dueDate);
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/payment-runs', paymentRun, false);
            paymentRun = (ZuoraAPI.PaymentRun) JSON.deserialize(response.getBody(), ZuoraAPI.PaymentRun.class);
            if (paymentRun.success) {
                Logger.logLater('ZuoraPaymentRunScheduler', 'executePostQueryJob', 'Successfully created a payment run: ' + response.getBody(), Logger.INFO);
            } else {
                Logger.logLater('ZuoraPaymentRunScheduler', 'executePostQueryJob', 'Payment Run failed creation: ' + response.getBody(), Logger.ERROR);
            }
        } catch (Exception e) {
            Logger.logLater('ZuoraPaymentRunScheduler', 'executePostQueryJob', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    public class InvoiceDueDate {
        public Date dueDate;
    }
}