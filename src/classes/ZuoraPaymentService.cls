/**
 * Created by PeterYao on 1/7/2020.
 * Tested By: ZuoraPaymentServiceTest, ZuoraPaymentPageControllerTest
 */

public with sharing class ZuoraPaymentService {
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
        }
        if (paymentAmount > 0){
            Logger.logLater('ZuoraPaymentPageController','applyPaymentToOutstandingItems','Payment was not completely applied: ' + String.valueOf(payment));
        }
        return application;
    }

}