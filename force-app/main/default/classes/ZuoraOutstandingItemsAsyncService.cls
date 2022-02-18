/*************************************************************************************
 * Created By: peteryao on 2019-07-19  
 * Description: Because getting outstanding items for a single account can result in more callouts than Salesforce allows,
 *   we need to make it a chained queueable amd process the outstanding items after they are all retrieved
 * Test: ZuoraOutstandingItemsAsyncServiceTest
 *************************************************************************************/

public with sharing class ZuoraOutstandingItemsAsyncService implements Queueable, Database.AllowsCallouts {
    @TestVisible
    private List<ZuoraAPI.Invoice> invoices;
    @TestVisible
    private List<ZuoraAPI.ZuoraDebitMemo> debitMemos;
    @TestVisible
    private ZuoraOutstandingItemsService.ProcessingParameter processingParameter;
    @TestVisible
    private ZuoraOutstandingItemsAsyncService nextChainedJob;

    public ZuoraOutstandingItemsAsyncService(List<ZuoraAPI.Invoice> invoices, List<ZuoraAPI.ZuoraDebitMemo> debitMemos,
        ZuoraOutstandingItemsService.ProcessingParameter processingParameter) {
        if (invoices == null) {
            this.invoices = new List<ZuoraAPI.Invoice>();
        } else {
            this.invoices = invoices;
        }
        if (debitMemos == null) {
            this.debitMemos = new List<ZuoraAPI.ZuoraDebitMemo>();
        } else {
            this.debitMemos = debitMemos;
        }
        if (processingParameter == null) {
            this.processingParameter = new ZuoraOutstandingItemsService.ProcessingParameter();
        } else {
            this.processingParameter = processingParameter;
        }
    }

    // Excepted exceptions caught could be due to callout limits reached, or Zuora runtime errors
    public void execute(QueueableContext context) {
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems = new List<ZuoraOutstandingItemsService.OutstandingItem>();
        while (!invoices.isEmpty()) {
            try {
                ZuoraAPI.InvoiceWithItems invoiceItems = ZuoraOutstandingItemsService.getInvoiceItems(invoices[0]);
                outstandingItems = ZuoraOutstandingItemsService.convertInvoiceItems(invoiceItems);
                processingParameter.allOutstandingItems.addAll(outstandingItems);
                invoices.remove(0);
            } catch (Exception e) {
                requeueJob();
                return;
            }
        }

        while (!debitMemos.isEmpty()) {
            try {
                ZuoraAPI.DebitMemoWithItems debitMemoItems = ZuoraOutstandingItemsService.getDebitMemoItems(debitMemos[0]);
                outstandingItems = ZuoraOutstandingItemsService.convertDebitMemoItems(debitMemoItems);
                processingParameter.allOutstandingItems.addAll(outstandingItems);
                debitMemos.remove(0);
            } catch (Exception e) {
                requeueJob();
                return;
            }
        }

        processingParameter.allOutstandingItems.sort();

        if (invoices.size() == 0 && debitMemos.size() == 0) {
            try {
                processOutstandingItems();
            } catch (Util.BWException e) {
                Logger.logLater('ZuoraOutstandingItems', 'execute',
                    'Requeueing after catching BWException processing outstanding items: ' +
                        JSON.serialize(processingParameter.allOutstandingItems) + '\n' +
                        e.getMessage() + '\n' +
                        e.getStackTraceString(),
                    Logger.ERROR
                );
                requeueJob();
                return;
            } catch (Exception e) {
                Logger.logLater('ZuoraOutstandingItems', 'execute',
                    'Caught fatal exception while processing outstanding items: ' +
                        JSON.serialize(processingParameter.allOutstandingItems) + '\n' +
                        e.getMessage() + '\n' +
                        e.getStackTraceString(),
                    Logger.ERROR
                );
            }
        } else {
            requeueJob();
        }
        Logger.flushLogs();
    }

    private void requeueJob() {
        ZuoraOutstandingItemsAsyncService asyncService =
            new ZuoraOutstandingItemsAsyncService(invoices, debitMemos, processingParameter);
        if (!Test.isRunningTest()) {
            System.enqueueJob(asyncService);
        } else {
            nextChainedJob = asyncService;
        }
        Logger.flushLogs();
    }

    private void processOutstandingItems() {
        if (processingParameter.processorClassName != null) {
            ZuoraOutstandingItemsService.Processor processor =
                (ZuoraOutstandingItemsService.Processor) Type.forName(processingParameter.processorClassName).newInstance();
            // Could be applying a credit memo or payment
            processor.processOutstandingItems(processingParameter.allOutstandingItems, processingParameter);
        }
    }
}