/**
 * Created by PeterYao on 1/7/2020.
 * Tested By: ZuoraPaymentServiceTest, ZuoraPaymentPageControllerTest
 */

public with sharing class ZuoraPaymentService implements ZuoraDataQueryService.Processor, Queueable, Database.AllowsCallouts {
    public List<ZuoraAPI.Payment> paymentsToApply;
    private ZuoraSubscriptionService zuoraSubscriptionService = new ZuoraSubscriptionService();
    private ZuoraOutstandingItemsService outstandingItemsService = new ZuoraOutstandingItemsService();
    private ZuoraAccountSelector zuoraAccountSelector = new ZuoraAccountSelector();

    public ZuoraPaymentService() {
    }
    public ZuoraPaymentService(List<ZuoraAPI.Payment> paymentsToApply) {
        this.paymentsToApply = paymentsToApply;
    }

    public void applyPaymentToBalance(ZuoraAPI.Payment successfulPayment) {
        applyPaymentToBalance(successfulPayment, new List<ZuoraAPI.Payment>());
    }
    public void applyPaymentToBalance(ZuoraAPI.Payment successfulPayment, List<ZuoraAPI.Payment> otherPaymentsToApply) {
        String zuoraAccountId = successfulPayment.accountId;
        Integer numberOfGateways = zuoraSubscriptionService.getSubscriptionsByAccount(zuoraAccountId).getNumberOfGateways();
        if (numberOfGateways > 1) {
            ZuoraDataQueryService.ProcessingParameter processingParameter = new ZuoraDataQueryService.ProcessingParameter('ZuoraPaymentService');
            processingParameter.methodName = 'ApplyToMultiGatewayBalance';
            processingParameter.optionalStrings = new Map<String, String>();
            processingParameter.optionalStrings.put('Payment', JSON.serialize(successfulPayment, true));
            processingParameter.optionalStrings.put('OtherPaymentsToApply', JSON.serialize(otherPaymentsToApply, true));
            processingParameter.enableRetries();
            outstandingItemsService.startOutstandingItemsQuery(zuoraAccountId, processingParameter);
            return;
        }

        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems;
        outstandingItems = ZuoraOutstandingItemsService.getOutstandingItemParentsByDate(zuoraAccountId);
        ZuoraAPI.ZuoraPaymentApplication application = getPaymentApplicationForOutstandingItems(outstandingItems, successfulPayment);
        sendPaymentApplicationToZuora(successfulPayment, application);
        if (!otherPaymentsToApply.isEmpty()) {
            System.enqueueJob(new ZuoraPaymentService(otherPaymentsToApply));
        }
    }

    private void sendPaymentApplicationToZuora(ZuoraAPI.Payment successfulPayment, ZuoraAPI.ZuoraPaymentApplication application) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('PUT', '/v1/payments/' + successfulPayment.id + '/apply', application);
        ZuoraPaymentPageController.PaymentResponse result =
            (ZuoraPaymentPageController.PaymentResponse) System.JSON.deserialize(response.getBody(), ZuoraPaymentPageController.PaymentResponse.class);
        if (!result.success) {
            if (response.getBody().contains('optimistic locking failed')) {
                throw new Util.BWException(response.getBody() + '\n' + JSON.serialize(successfulPayment) + '\n' + JSON.serialize(application));
            } else {
                throw new Util.FatalBWException('Failure in Zuora:\n' + response.getBody() + '\n' + JSON.serialize(successfulPayment));
            }
        }
    }

    @TestVisible
    private ZuoraAPI.ZuoraPaymentApplication getPaymentApplicationForOutstandingItems(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems,
        ZuoraAPI.Payment payment) {
        return getPaymentApplicationForOutstandingItems(outstandingItems, payment, true);
    }

    @TestVisible
    private ZuoraAPI.ZuoraPaymentApplication getPaymentApplicationForOutstandingItems(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems,
        ZuoraAPI.Payment payment, Boolean outstandingItemsAreDebitMemosOrInvoicesNotItems) {
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
                if (outstandingItemsAreDebitMemosOrInvoicesNotItems) {
                    application.invoices.add(new ZuoraAPI.ZuoraInvoiceApplication(item.Id, applicationAmount));
                } else {
                    application.invoices.add(new ZuoraAPI.ZuoraInvoiceApplication(item.ParentId, item.Id, applicationAmount));
                }
            } else {
                if (outstandingItemsAreDebitMemosOrInvoicesNotItems) {
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

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        if (method.methodName == 'PaymentsWithUnappliedBalance') {
            paymentsToApply = (List<ZuoraAPI.Payment>)JSON.deserialize(response, List<ZuoraAPI.Payment>.class);
            for (ZuoraAPI.Payment payment : paymentsToApply){
                // We only want to distribute the unapplied amount, not the full amount in this case
                // Payment.Amount in Zuora will not and can not be updated by this change:
                payment.amount = payment.unappliedAmount;
                // Because we can't query for gateway id, just gateway name, we need to convert it.
                payment.gatewayId = zuoraAccountSelector.getGatewayIdFromGatewayName(payment.gatewayName).id;
            }
            System.enqueueJob(new ZuoraPaymentService(paymentsToApply));
        } else if (method.methodName == 'ApplyToMultiGatewayBalance') {
            applyToMultiGatewayBalance(response, method);
        } else {
            Logger.logLater('ZuoraPaymentService', 'executePostQueryJob', 'Unknown method name in processing parameter: ' + method, Logger.ERROR);
        }
    }

    @TestVisible
    private List<ZuoraAPI.Payment> applyToMultiGatewayBalance(String response, ZuoraDataQueryService.ProcessingParameter method) {
        try {
            List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems =
                (List<ZuoraOutstandingItemsService.OutstandingItem>) JSON.deserialize(response, List<ZuoraOutstandingItemsService.OutstandingItem>.class);
            ZuoraAPI.Payment successfulPayment = (ZuoraAPI.Payment) JSON.deserialize(method.optionalStrings.get('Payment'), ZuoraAPI.Payment.class);
            outstandingItems.sort();
            ZuoraAPI.ZuoraPaymentApplication application = getPaymentApplicationForOutstandingItems(outstandingItems, successfulPayment, false);
            sendPaymentApplicationToZuora(successfulPayment, application);
            return queueAdditionalPaymentsToApply(method);
        } catch (Util.BWException bwe) {
            if (method.shouldRetry(Util.getSystemPropertyDecimal('Zuora_Payment_Application_Retries__c'))) {
                method.incrementRetryAttempt();
                throw new ZuoraDataQueryService.RetriableException(bwe.getMessage());
            }
            throw new Util.FatalBWException(bwe.getMessage());
        }
    }

    private List<ZuoraAPI.Payment> queueAdditionalPaymentsToApply(ZuoraDataQueryService.ProcessingParameter method) {
        String otherPaymentsJSON = method.optionalStrings.get('OtherPaymentsToApply');
        if (otherPaymentsJSON != null) {
            List<ZuoraAPI.Payment> paymentsToApply = (List<ZuoraAPI.Payment>) JSON.deserialize(otherPaymentsJSON, List<ZuoraAPI.Payment>.class);
            if (!paymentsToApply.isEmpty()) {
                if (Test.isRunningTest()) {
                    return paymentsToApply;
                } else {
                    System.enqueueJob(new ZuoraPaymentService(paymentsToApply));
                }
            }
        }
        return null;
    }

    public void execute(QueueableContext context) {
        try {
            ZuoraAPI.Payment paymentToApply = paymentsToApply.remove(0);
            applyPaymentToBalance(paymentToApply, paymentsToApply);
        } catch (Exception excep) {
            Logger.logNow('ZuoraPaymentService','executeApplyJob',excep.getMessage()+ '\n' + excep.getStackTraceString()+ '\n' + JSON.serialize(paymentsToApply));
        }
    }
}