/**
 * Created by PeterYao on 1/7/2020.
 * Tested By: ZuoraPaymentServiceTest, ZuoraPaymentPageControllerTest
 */

public with sharing class ZuoraPaymentService implements ZuoraDataQueryService.Processor, Queueable, Database.AllowsCallouts {
    public List<ZuoraAPI.Payment> paymentsToApply;
    private ZuoraSubscriptionService zuoraSubscriptionService = new ZuoraSubscriptionService();
    private ZuoraOutstandingItemsService outstandingItemsService = new ZuoraOutstandingItemsService();

    public void applyPaymentToBalance(ZuoraAPI.Payment successfulPayment){
        String zuoraAccountId = successfulPayment.accountId;
        Integer numberOfGateways = zuoraSubscriptionService.getSubscriptionsByAccount(zuoraAccountId).getNumberOfGateways();
        if (numberOfGateways > 1) {
            ZuoraDataQueryService.ProcessingParameter processingParameter = new ZuoraDataQueryService.ProcessingParameter('ZuoraPaymentService');
            processingParameter.methodName = 'ApplyToMultiGatewayBalance';
            processingParameter.optionalStrings = new Set<String>();
            processingParameter.optionalStrings.add(JSON.serialize(successfulPayment));
            outstandingItemsService.startOutstandingItemsQuery(zuoraAccountId, processingParameter);
            return;
        }

        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems;
        outstandingItems = ZuoraOutstandingItemsService.getOutstandingItemParentsByDate(zuoraAccountId);
        ZuoraAPI.ZuoraPaymentApplication application = getPaymentApplicationForOutstandingItems(outstandingItems, successfulPayment);
        sendPaymentApplicationToZuora(successfulPayment, application);
    }

    private void sendPaymentApplicationToZuora(ZuoraAPI.Payment successfulPayment, ZuoraAPI.ZuoraPaymentApplication application) {
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

    public ZuoraAPI.ZuoraPaymentApplication getPaymentApplicationForOutstandingItems(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems,
        ZuoraAPI.Payment payment) {
        return getPaymentApplicationForOutstandingItems(outstandingItems, payment, true);
    }

    @TestVisible
    private ZuoraAPI.ZuoraPaymentApplication getPaymentApplicationForOutstandingItems(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems,
        ZuoraAPI.Payment payment, Boolean outstandingItemsAreParents) {
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
            if (item.PaymentGatewayId != null && item.PaymentGatewayId != payment.gatewayId) {
                continue;
            }
            // Don't expect anything in Zuora to have more than 2 decimals,
            // but just to be safe, we never want to apply with more than 2 decimals:
            paymentAmount = paymentAmount.setScale(2, RoundingMode.HALF_UP);
            item.AmountOutstanding = item.AmountOutstanding.setScale(2, RoundingMode.HALF_UP);
            applicationAmount = Math.min(paymentAmount,item.AmountOutstanding);
            paymentAmount -= applicationAmount;
            if (item.IsInvoiceItem) {
                if (outstandingItemsAreParents) {
                    application.invoices.add(new ZuoraAPI.ZuoraInvoiceApplication(item.Id, applicationAmount));
                } else {
                    application.invoices.add(new ZuoraAPI.ZuoraInvoiceApplication(item.ParentId, item.Id, applicationAmount));
                }
            } else {
                if (outstandingItemsAreParents) {
                    application.debitMemos.add(new ZuoraAPI.ZuoraDebitMemoApplication(item.Id, applicationAmount));
                } else {
                    application.debitMemos.add(new ZuoraAPI.ZuoraDebitMemoApplication(item.ParentId, item.Id, applicationAmount));
                }
            }
            if (item.EffectiveDate > effectiveDate) {
                effectiveDate = item.EffectiveDate;
            }
        }
        if (paymentAmount > 0){
            Logger.logLater('ZuoraPaymentService','applyPaymentToOutstandingItems','Payment was not completely applied: ' + String.valueOf(payment));
        }
        application.effectiveDate = DateUtil.convertGmtToDate(effectiveDate);
        return application;
    }

    public static void getAndApplyPaymentsWithUnappliedBalance(){
        ZuoraDataQueryService.ProcessingParameter parameter = new ZuoraDataQueryService.ProcessingParameter('ZuoraPaymentService');
        parameter.methodName = 'PaymentsWithUnappliedBalance';
        String queryString = 'SELECT p.Id, p.accountid, p.unappliedamount, p.paymentmethodid, p.status ' +
            'FROM Payment p ' +
            'INNER JOIN Account a ON p.accountid = a.Id ' +
            'WHERE (p.unappliedamount > 0 AND p.status = \'Processed\') ' +
            'AND (a.totalinvoicebalance > 0 OR a.totaldebitmemobalance > 0 )';
        ZuoraDataQueryService.callFromApex(queryString, parameter);
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        if (method.methodName == 'PaymentsWithUnappliedBalance') {
            paymentsToApply = (List<ZuoraAPI.Payment>)JSON.deserialize(response, List<ZuoraAPI.Payment>.class);
            for (ZuoraAPI.Payment payment : paymentsToApply){
                // We only want to distribute the unapplied amount, not the full amount in this case
                // Payment.Amount in Zuora will not and can not be updated by this change:
                payment.amount = payment.unappliedAmount;
            }
            queueApplyJob(paymentsToApply);
        } else if (method.methodName == 'ApplyToMultiGatewayBalance') {
            try {
                List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems =
                    (List<ZuoraOutstandingItemsService.OutstandingItem>) JSON.deserialize(response, List<ZuoraOutstandingItemsService.OutstandingItem>.class);
                ZuoraAPI.Payment successfulPayment = (ZuoraAPI.Payment) JSON.deserialize(new List<String>(method.optionalStrings)[0], ZuoraAPI.Payment.class);
                outstandingItems.sort();
                ZuoraAPI.ZuoraPaymentApplication application = getPaymentApplicationForOutstandingItems(outstandingItems, successfulPayment, false);
                sendPaymentApplicationToZuora(successfulPayment, application);
            } catch (Util.BWException bwe) {
                if (method.shouldRetry()) {
                    throw new ZuoraDataQueryService.RetriableException(bwe.getMessage());
                }
                throw new Util.FatalBWException(bwe.getMessage());
            }
        } else {
            Logger.logLater('ZuoraPaymentService', 'executePostQueryJob', 'Unknown method name in processing parameter: ' + method, Logger.ERROR);
        }
    }

    public void execute(QueueableContext context) {
        executeApplyJob();
    }

    private void executeApplyJob() {
        Integer recordCount = 0;
        Integer batchSize = 10;
        List<ZuoraAPI.Payment> nextJobQueue = new List<ZuoraAPI.Payment>();
        for (ZuoraAPI.Payment payment : paymentsToApply) {
            if (recordCount >= batchSize) {
                nextJobQueue.add(payment);
            } else {
                recordCount += 1;
                try {
                    applyPaymentToBalance(payment);
                } catch (Exception excep){
                    Logger.logLater('ZuoraPaymentService','executeApplyJob',excep.getMessage()+ '_' + excep.getStackTraceString()+ '_' + JSON.serialize(paymentsToApply));
                    continue;
                }
            }
        }
        if (recordCount >= batchSize) {
            Logger.flushLogs();
            queueApplyJob(nextJobQueue);
        }
    }

    private static void queueApplyJob(List<ZuoraAPI.Payment> paymentsToQueue){
        ZuoraPaymentService applyJob = new ZuoraPaymentService();
        applyJob.paymentsToApply = paymentsToQueue;
        System.enqueueJob(applyJob);
    }
}