/*************************************************************************************
 * Created By: peteryao on 2019-07-23  
 * Description: Used to load historical payments, could be deleted after our data migration
 * Test: ZuoraHistoricalApplicationTest
 *************************************************************************************/

public with sharing class ZuoraHistoricalBatchApply implements Database.Batchable<Account>, Database.AllowsCallouts {
    public List<Account> accountsToLoad;
    @TestVisible
    private ChargentTransactionSelector transactionSelector = new ChargentTransactionSelector();
    @TestVisible
    private ZuoraMemoBatchApply zuoraMemoBatchApply = new ZuoraMemoBatchApply();
    @TestVisible
    private static ZuoraOutstandingItemsAsyncService asyncServiceEnqueued;

    public void init() {
        accountsToLoad = [
            SELECT Id, Zuora_Id__c, CreatedDate
            FROM Account
            WHERE RecordType.Name = 'Property'
        ];
    }

    public List<Account> start(Database.BatchableContext bc) {
        return accountsToLoad;
    }

    // Batch execution starts a queueable chain (getting outstanding items).
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        if (scope.size() > 1) {
            throw new Util.BWException('Run ZuoraHistoricalBatchApply with a batch size of 1 since it relies' +
                ' on chained queueables');
        }
        if (String.isBlank(scope[0].Zuora_Id__c)) {
            throw new Util.BWException('Skipping property ' + scope[0].Id + ' created ' + scope[0].CreatedDate +
                ' because it has no Zuora Id');
        }
        try {
            queuePayableApplicationForAccount(scope[0]);
        } catch (Exception e) {
            Logger.logLater('ZuoraHistoricalBatchApply', 'execute',
                'Exception caught loading history for account: ' + scope[0].Id + '\n' +
                    e.getMessage() + '\n' +
                    e.getStackTraceString(),
                Logger.ERROR
            );
        }
        Logger.flushLogs();
    }

    public void finish(Database.BatchableContext bc) {
    }

    public void queuePayableApplicationForAccount(Account account) {
        ZuoraCreditMemoAllocationService.QueryResultCreditMemo creditMemosByPage =
            ZuoraCreditMemoAllocationService.getFirstPageCreditMemos(account.Zuora_Id__c);
        // We don't expect more than 40 credit memos right now - as of July 2019, beyond fitness has the most with 30
        if (creditMemosByPage.NextPage != null) {
            throw new Util.BWException('Found more than 40 credit memos for account ' + account.Id + ', which is not supported');
        }
        // One callout per credit memo
        zuoraMemoBatchApply.setOutstandingCreditMemoItemsToApply(creditMemosByPage);

        List<ChargentOrders__Transaction__c> transactions = transactionSelector.selectForZuoraHistory(account.Zuora_Id__c);

        if ((zuoraMemoBatchApply.creditMemosToApply == null ||
            zuoraMemoBatchApply.creditMemosToApply.size() == 0) &&
            transactions.size() == 0) {
            return;
        }

        List<ZuoraHistoricalApplicationService.Payable> payablesByDate =
            ZuoraHistoricalApplicationService.getSortedPayables(zuoraMemoBatchApply.creditMemosToApply, transactions);

        List<ZuoraAPI.Invoice> invoices = ZuoraOutstandingItemsService.getOutstandingInvoices(account.Zuora_Id__c);
        List<ZuoraAPI.ZuoraDebitMemo> debitMemos = ZuoraOutstandingItemsService.getOutstandingDebitMemos(account.Zuora_Id__c);

        ZuoraOutstandingItemsService.ProcessingParameter processingParameter =
            new ZuoraOutstandingItemsService.ProcessingParameter('ZuoraHistoricalApplicationService', (List<ZuoraHistoricalApplicationService.Payable>) payablesByDate);
        ZuoraOutstandingItemsAsyncService asyncService = new ZuoraOutstandingItemsAsyncService(invoices, debitMemos, processingParameter);
        System.enqueueJob(asyncService);
        ZuoraHistoricalBatchApply.asyncServiceEnqueued = asyncService;
    }
}