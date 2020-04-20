/**
 * Created by PeterYao on 1/7/2020.
 * Tested By: ZuoraPaymentServiceTest, ZuoraPaymentPageControllerTest
 */

public with sharing class ZuoraPaymentService implements ZuoraDataQueryService.Processor, Queueable, Database.AllowsCallouts {
    public List<ZuoraAPI.Payment> paymentsToApply;

    public void applyPaymentToBalance(ZuoraAPI.Payment successfulPayment){
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems;
        outstandingItems = ZuoraOutstandingItemsService.getOutstandingItemParentsByDate(successfulPayment.accountId);
        ZuoraAPI.ZuoraPaymentApplication application = applyPaymentToOutstandingItems(outstandingItems, successfulPayment);
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('PUT', '/v1/payments/' + successfulPayment.id + '/apply', application);
        ZuoraPaymentPageController.PaymentResponse result =
            (ZuoraPaymentPageController.PaymentResponse) System.JSON.deserialize(response.getBody(), ZuoraPaymentPageController.PaymentResponse.class);
        if (!result.success) {
            if (response.getBody().contains('optimistic locking failed')) {
                throw new Util.BWException(response.getBody() + '\n' + String.valueOf(successfulPayment));
            } else {
                throw new Util.FatalBWException('Failure in Zuora:\n' + response.getBody() + '\n' + String.valueOf(successfulPayment));
            }
        }
    }

    @TestVisible
    private ZuoraAPI.ZuoraPaymentApplication applyPaymentToOutstandingItems(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems,
        ZuoraAPI.Payment payment){
        ZuoraAPI.ZuoraPaymentApplication application = new ZuoraAPI.ZuoraPaymentApplication();
        application.invoices = new List<ZuoraAPI.ZuoraInvoiceApplication>();
        application.debitMemos = new List<ZuoraAPI.ZuoraDebitMemoApplication>();

        Decimal paymentAmount = payment.amount;
        Decimal applicationAmount;
        Datetime effectiveDate = System.now();
        for (ZuoraOutstandingItemsService.OutstandingItem item : outstandingItems){
            if (paymentAmount == 0){
                break;
            }
            // Don't expect anything in Zuora to have more than 2 decimals,
            // but just to be safe, we never want to apply with more than 2 decimals:
            paymentAmount = paymentAmount.setScale(2, RoundingMode.HALF_UP);
            item.AmountOutstanding = item.AmountOutstanding.setScale(2, RoundingMode.HALF_UP);
            applicationAmount = Math.min(paymentAmount,item.AmountOutstanding);
            paymentAmount -= applicationAmount;
            if (item.IsInvoiceItem){
                ZuoraAPI.ZuoraInvoiceApplication invoice = new ZuoraAPI.ZuoraInvoiceApplication();
                invoice.invoiceId = item.Id;
                invoice.amount = applicationAmount;
                application.invoices.add(invoice);
            } else {
                ZuoraAPI.ZuoraDebitMemoApplication debitMemo = new ZuoraAPI.ZuoraDebitMemoApplication();
                debitMemo.debitMemoId = item.Id;
                debitMemo.amount = applicationAmount;
                application.debitMemos.add(debitMemo);
            }
            if (item.EffectiveDate > effectiveDate) {
                effectiveDate = item.EffectiveDate;
            }
        }
        if (paymentAmount > 0){
            Logger.logLater('ZuoraPaymentPageController','applyPaymentToOutstandingItems','Payment was not completely applied: ' + String.valueOf(payment));
        }
        application.effectiveDate = DateUtil.convertGmtToDate(effectiveDate);
        return application;
    }

    public static void getAndApplyPaymentsWithUnappliedBalance(){
        ZuoraDataQueryService.ProcessingParameter parameter = new ZuoraDataQueryService.ProcessingParameter();
        parameter.className = 'ZuoraPaymentService';
        String queryString = 'SELECT p.Id, p.accountid, p.unappliedamount, p.paymentmethodid, p.status ' +
            'FROM Payment p ' +
            'INNER JOIN Account a ON p.accountid = a.Id ' +
            'WHERE (p.unappliedamount > 0 AND p.status = \'Processed\') ' +
            'AND (a.totalinvoicebalance > 0 OR a.totaldebitmemobalance > 0 )';
        ZuoraDataQueryService.callFromApex(queryString, parameter);
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        paymentsToApply = (List<ZuoraAPI.Payment>)JSON.deserialize(response, List<ZuoraAPI.Payment>.class);
        for (ZuoraAPI.Payment payment : paymentsToApply){
            // We only want to distribute the unapplied amount, not the full amount in this case
            // Payment.Amount in Zuora will not and can not be updated by this change:
            payment.amount = payment.unappliedamount;
        }
        queueApplyJob(paymentsToApply);
    }

    public void execute(QueueableContext context) {
        executeApplyJob();
    }

    private void executeApplyJob() {
        try {
            Integer recordCount = 0;
            Integer batchSize = 10;
            List<ZuoraAPI.Payment> nextJobQueue = new List<ZuoraAPI.Payment>();

            for (ZuoraAPI.Payment payment : paymentsToApply) {
                if (recordCount >= batchSize) {
                    nextJobQueue.add(payment);
                } else {
                    applyPaymentToBalance(payment);
                }
                recordCount += 1;
            }
            if (recordCount >= batchSize) {
                queueApplyJob(nextJobQueue);
            }
        } catch (Exception excep){
            Logger.logNow('ZuoraPaymentService','executeApplyJob',excep.getMessage()+ '_' + excep.getStackTraceString()+ '_' + JSON.serialize(paymentsToApply));

        }
    }

    private static void queueApplyJob(List<ZuoraAPI.Payment> paymentsToQueue){
        ZuoraPaymentService applyJob = new ZuoraPaymentService();
        applyJob.paymentsToApply = paymentsToQueue;
        System.enqueueJob(applyJob);
    }
}