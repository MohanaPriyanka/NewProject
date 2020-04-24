/*************************************************************************************
 * Created By: peteryao on 2019-08-24  
 * Description:
 * Test: ZuoraReturnedPaymentServiceTest, ZuoraInvoiceRegenServiceTest
 *************************************************************************************/

public with sharing class ZuoraController implements ZuoraDataQueryService.Processor  {
    @TestVisible
    private static ZuoraReturnedPaymentService returnedPaymentService = new ZuoraReturnedPaymentService();
    @TestVisible
    private static ZuoraPaymentSelector paymentSelector = new ZuoraPaymentSelector();

    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled
    public static PaymentReturnResult reverseReturnedPayment(Id paymentId) {
        PaymentReturnResult paymentReturnResult = new PaymentReturnResult();
        List<Zuora__Payment__c> payments = paymentSelector.selectById(new Set<Id>{paymentId});
        if (payments.size() != 1) {
            paymentReturnResult.message = 'Expected a single Zuora Payment record to reverse';
            paymentReturnResult.success = false;
            return paymentReturnResult;
        }
        ZuoraAPI.Payment zuoraPayment = returnedPaymentService.checkIfPaymentIsAlreadyReturned(payments[0].Zuora__EXT_ID__c);
        Zuora__Payment__c sfPayment = payments[0];
        paymentReturnResult = executeMarkPaymentAsReturned(zuoraPayment,sfPayment);
        Logger.flushLogs();
        Case newCase = returnedPaymentService.createCaseForReturns(sfPayment);
        insert newCase;
        return paymentReturnResult;
    }

    public static PaymentReturnResult executeMarkPaymentAsReturned(ZuoraAPI.Payment zuoraPayment, Zuora__Payment__c sfPayment) {
        PaymentReturnResult paymentReturnResult = new PaymentReturnResult();
        try {
            List<ZuoraAPI.DebitMemo> debitMemos = returnedPaymentService.convertPaymentToDebitMemos(zuoraPayment);
            if (ZuoraAPIHelper.getCalloutsRemaining() < 2*debitMemos.size() + 1) {
                throw new Util.FatalBWException('Not enough callouts remaining to create and post debit memos and mark ' +
                    'the payment as returned: ' + JSON.serialize(debitMemos));
            }
            ZuoraCreditDebitMemoService.createAndPostDebitMemos(debitMemos);
            returnedPaymentService.markPaymentReturned(sfPayment.Zuora__EXT_ID__c);
            paymentReturnResult.debitMemos = debitMemos;
            paymentReturnResult.success = true;
            returnedPaymentService.removePaymentMethodFromAccount(sfPayment);
        } catch (Exception e) {
            String message = 'Failed reversing payment ' + sfPayment.Id + ':\n' + e.getMessage() + '\n' + e.getStackTraceString();
            Logger.logLater(
                'ZuoraController',
                'reverseReturnedPayment',
                message,
                Logger.ERROR
            );
            paymentReturnResult.message = message;
            paymentReturnResult.success = false;
        }
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

    public static void queueDataQueryForTemplateFields(Date startDate, Date endDate) {
        String queryString = ZuoraInvoiceSelector.getInvoiceTotalQuery(startDate, endDate);
        ZuoraDataQueryService.ProcessingParameter methodToRunWhenComplete = new ZuoraDataQueryService.ProcessingParameter();
        methodToRunWhenComplete.className = 'ZuoraController';
        methodToRunWhenComplete.methodName = 'updateCustomTemplateFields';
        ZuoraDataQueryService.callFromApex(queryString,methodToRunWhenComplete);
    }

    @TestVisible
    private class InvoiceSummaryFields{
        String AccountId;
        String LastInvoice;
        Decimal PaymentSum;
        Decimal CreditMemoSum;
        Decimal DebitMemoSum;
    }

    // Can't use ZuoraAPI.Invoice because Id needs to capitalized for Action Update call, but lowercase for other uses:
    public class InvoiceCustomFields{
        public String Id;
        public Decimal CustomTemplateMerge_1_Zcustom;
        public Decimal CustomTemplateMerge_2_Zcustom;
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter parameter, String response){
        if (parameter.methodName == 'updateCustomTemplateFields'){
            updateCustomTemplateFields(response);
        }
    }

    public static ZuoraAPI.ActionItems updateCustomTemplateFields(String queryData) {
        ZuoraAPI.ActionItems actionItem = new ZuoraAPI.ActionItems();
        actionItem.type = 'Invoice';
        actionItem.objects = new List<InvoiceCustomFields>();

        try {
            List<InvoiceSummaryFields> summaryList;
            summaryList = (List<InvoiceSummaryFields>)JSON.deserialize(queryData, List<InvoiceSummaryFields>.class);

            for (InvoiceSummaryFields summary : summaryList){
                if (summary.LastInvoice != null) {
                    InvoiceCustomFields invoiceToUpdate = new InvoiceCustomFields();
                    invoiceToUpdate.Id = summary.LastInvoice;
                    Decimal memoSum = Util.nullToZero(summary.DebitMemoSum) - Util.nullToZero(summary.CreditMemoSum);
                    invoiceToUpdate.CustomTemplateMerge_1_Zcustom = memoSum;
                    invoiceToUpdate.CustomTemplateMerge_2_Zcustom = Util.nullToZero(summary.PaymentSum);
                    actionItem.objects.add(invoiceToUpdate);
                }
            }
            ZuoraGenericBatchOperation batchUpdate = new ZuoraGenericBatchOperation(actionItem, ZuoraAPIHelper.actionDMLOperations.DMLUPDATE);
            Database.executeBatch(batchUpdate, 50);
        } catch (Exception excep) {
            Logger.logNow('ZuoraController', 'updateCustomTemplateFields', excep.getMessage() + excep.getStackTraceString(), 'ERROR');
        }
        return actionItem;
    }
}