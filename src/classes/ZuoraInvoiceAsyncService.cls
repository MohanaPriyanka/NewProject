/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 * Description: This class starts batches of chained queueables, since we need to
 *    download PDFs from Zuora staying under the callout and heap size limits.
 * Test: ZuoraInvoiceServiceTest
 *************************************************************************************/

public with sharing class ZuoraInvoiceAsyncService implements Queueable, Database.AllowsCallouts, Database.Batchable<Zuora__ZInvoice__c> {
    public List<Zuora__ZInvoice__c> allInvoicesToDownload;

    public ZuoraInvoiceAsyncService() {
        allInvoicesToDownload = new List<Zuora__ZInvoice__c>();
    }

    public ZuoraInvoiceAsyncService(List<Zuora__ZInvoice__c> sfdcZInvoices) {
        allInvoicesToDownload = sfdcZInvoices;
    }

    public void initForDownload() {
        allInvoicesToDownload = ZuoraInvoiceSelector.getInvoicesToDownload();
    }

    public Iterable<Zuora__ZInvoice__c> start(Database.BatchableContext context) {
        return allInvoicesToDownload;
    }

    public void execute(Database.BatchableContext context, List<Zuora__ZInvoice__c> scope) {
        ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(scope);
        invoiceService.downloadPDFs();
    }

    public void finish(Database.BatchableContext context) {
    }

    public void execute(QueueableContext context) {
        ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(allInvoicesToDownload);
        invoiceService.downloadPDFs();
    }
}