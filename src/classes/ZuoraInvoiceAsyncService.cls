/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 * Description: This class starts batches of chained queueables, since we need to
 *    download PDFs from Zuora staying under the callout and heap size limits.
 * Test: ZuoraInvoiceServiceTest
 *************************************************************************************/

public with sharing class ZuoraInvoiceAsyncService implements Queueable, Database.AllowsCallouts, Database.Batchable<Zuora__ZInvoice__c> {
    public enum OperationType {DOWNLOAD, MAIL}
    public OperationType mode;
    public List<Zuora__ZInvoice__c> allInvoicesToDownload;
    public List<Zuora__ZInvoice__c> allInvoicesToMail;
    public List<Zuora__ZInvoice__c> invoicesAlreadySent;

    public ZuoraInvoiceAsyncService(List<Zuora__ZInvoice__c> sfdcZInvoices) {
        mode = OperationType.DOWNLOAD;
        allInvoicesToDownload = sfdcZInvoices;
    }

    public ZuoraInvoiceAsyncService(OperationType mode) {
        this.mode = mode;
        this.allInvoicesToMail = new List<Zuora__ZInvoice__c>();
        this.invoicesAlreadySent = new List<Zuora__ZInvoice__c>();
    }

    public void initForDownload() {
        allInvoicesToDownload = ZuoraInvoiceSelector.getInvoicesToDownload();
    }

    public Iterable<Zuora__ZInvoice__c> start(Database.BatchableContext context) {
        if (mode == OperationType.DOWNLOAD) {
            return allInvoicesToDownload;
        } else {
            return allInvoicesToMail;
        }
    }

    public void execute(Database.BatchableContext context, List<Zuora__ZInvoice__c> scope) {
        try {
            ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(scope);
            if (mode == OperationType.DOWNLOAD) {
                invoiceService.downloadPDFs();
            } else {
                invoiceService.queueInvoicesToMail(scope);
            }
        } catch (Exception e) {
            Logger.logNow(
                'ZuoraInvoiceAsyncService',
                'execute batch',
                e.getMessage() + '\n' + e.getStackTraceString() + '\n' + scope,
                Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    public void finish(Database.BatchableContext context) {
    }

    public void execute(QueueableContext context) {
        try {
            ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(allInvoicesToDownload);
            invoiceService.downloadPDFs();
        } catch (Exception e) {
            Logger.logNow(
                'ZuoraInvoiceAsyncService',
                'execute queueable',
                e.getMessage() + '\n' + e.getStackTraceString() + '\n' + allInvoicesToDownload,
                Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }
}