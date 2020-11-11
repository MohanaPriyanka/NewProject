/*************************************************************************************
 * Created By: peteryao on 2019-08-24  
 * Description:
 * Test: ZuoraReturnedPaymentServiceTest, ZuoraInvoiceRegenServiceTest
 *************************************************************************************/

public with sharing class ZuoraController implements ZuoraDataQueryService.Processor  {
    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled
    public static ZuoraReturnedPaymentService.PaymentReturnResult reverseReturnedPayment(Id paymentId) {
        return new ZuoraReturnedPaymentService().performReturn(paymentId);
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
            ZuoraGenericBatchOperation batchUpdate = new ZuoraGenericBatchOperation(actionItem, ZuoraAPIHelper.ActionDMLOperations.DMLUPDATE);
            Database.executeBatch(batchUpdate, 50);
        } catch (Exception excep) {
            Logger.logNow('ZuoraController', 'updateCustomTemplateFields', excep.getMessage() + excep.getStackTraceString(), 'ERROR');
        }
        return actionItem;
    }
}