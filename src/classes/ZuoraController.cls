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

    public class InvoiceCustomFields{
        String Id;
        Decimal CustomTemplateMerge_1_Zcustom;
        Decimal CustomTemplateMerge_2_Zcustom;
    }

    public static void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter parameter, String response){
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
            ZuoraGenericBatchOperation batchUpdate = new ZuoraGenericBatchOperation(actionItem, ZuoraAPIHelper.actionDMLOperations.UPDATE_action);
            Database.executeBatch(batchUpdate, 50);
        } catch (Exception excep) {
            Logger.logNow('ZuoraController', 'updateCustomTemplateFields', excep.getMessage() + excep.getStackTraceString(), 'ERROR');
        }
        return actionItem;
    }
}