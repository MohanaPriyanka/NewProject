/*************************************************************************************
 * Created By: peteryao on 2019-08-24  
 * Description:
 * Test: ZuoraReturnedPaymentServiceTest, ZuoraInvoiceRegenServiceTest
 *************************************************************************************/

public with sharing class ZuoraController {
    @TestVisible
    private static ZuoraReturnedPaymentService returnedPaymentService = new ZuoraReturnedPaymentService();
    @TestVisible
    private static ZuoraPaymentSelector paymentSelector = new ZuoraPaymentSelector();

    @AuraEnabled
    public static PaymentReturnResult reverseReturnedPayment(Id paymentId) {
        PaymentReturnResult paymentReturnResult = new PaymentReturnResult();
        List<Zuora__Payment__c> payments = paymentSelector.selectById(new Set<Id>{paymentId});
        if (payments.size() != 1) {
            paymentReturnResult.message = 'Expected a single Zuora Payment record to reverse';
            paymentReturnResult.success = false;
            return paymentReturnResult;
        }
        try {
            List<ZuoraAPI.DebitMemo> debitMemos = returnedPaymentService.convertPaymentToDebitMemos(payments[0].Zuora__EXT_ID__c);
            if (ZuoraAPIHelper.getCalloutsRemaining() < 2*debitMemos.size() + 1) {
                throw new Util.FatalBWException('Not enough callouts remaining to create and post debit memos and mark ' +
                    'the payment as returned: ' + JSON.serialize(debitMemos));
            }
            ZuoraCreditDebitMemoService.createAndPostDebitMemos(debitMemos);
            returnedPaymentService.markPaymentReturned(payments[0].Zuora__EXT_ID__c);
            paymentReturnResult.debitMemos = debitMemos;
            paymentReturnResult.success = true;
            returnedPaymentService.removePaymentMethodFromAccount(payments[0]);
            Case newCase = returnedPaymentService.createCaseForReturns(payments[0]);
            insert newCase;
        } catch (Exception e) {
            String message = 'Failed reversing payment ' + paymentId + ':\n' + e.getMessage() + '\n' + e.getStackTraceString();
            Logger.logLater(
                'ZuoraController',
                'reverseReturnedPayment',
                message,
                Logger.ERROR
            );
            paymentReturnResult.message = message;
            paymentReturnResult.success = false;
        }
        Logger.flushLogs();
        return paymentReturnResult;
    }

    public class PaymentReturnResult {
        @AuraEnabled
        public List<ZuoraAPI.DebitMemo> debitMemos;
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String message;
    }

    public static String executeBillRun(Date invoiceDate) {
        ZuoraAPI.BillRun zBillRun = new ZuoraAPI.BillRun();
        zBillRun.AutoEmail = false;
        zBillRun.AutoPost = true;
        zBillRun.AutoRenewal = true;
        zBillRun.InvoiceDate = invoiceDate;
        zBillRun.TargetDate = invoiceDate;
        zBillRun.Batch = 'Batch2';

        HttpResponse billRunResponse = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/object/bill-run', zBillRun, true);
        return billRunResponse.getBody();
    }

    public static void regeneratePDFs(Date invoiceDate) {
        List<Zuora__ZInvoice__c> invoicesToRegen = ZuoraInvoiceSelector.getInvoicesByDate(invoiceDate);
        ZuoraInvoiceRegenerationService regen = new ZuoraInvoiceRegenerationService();
        regen.invoicesToUpdate = invoicesToRegen;
        regen.executeBatch();
    }
}