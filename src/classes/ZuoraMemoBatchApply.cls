/*************************************************************************************
 * Created By:  Jordan Pentaleri
 * Queries for credit memos in groups of 40 (max we can query for at a time) sorted by Date
 * Applies the 40 credit memos in batches of 5, to avoid hitting 100 callout limit
 * After the batch completes, fires another batch with the next 40 credit memos in the list
 *
 * Test: ZuoraCreditMemoAllocationTest
 *************************************************************************************/


public without sharing class ZuoraMemoBatchApply implements Database.Batchable<ZuoraAPI.CreditMemoWithItem>, Database.AllowsCallouts{
    public List<ZuoraAPI.CreditMemoWithItem> creditMemosToApply;
    public String nextPage;

    public void startApplication(){
        ZuoraCreditMemoAllocationService.QueryResultCreditMemo query;
        query = ZuoraCreditMemoAllocationService.getFirstPageCreditMemos(40);
        handleQuery(query);
    }

    public void handleQuery(ZuoraCreditMemoAllocationService.QueryResultCreditMemo query){
        init(query.creditmemos);

        if (query.nextPage != null){
            this.nextPage = query.nextPage;
        }
    }

    public void runBatch(Integer batchSize){
        Database.executeBatch(this, batchSize);
    }

    public void init(List<ZuoraAPI.ZuoraCreditMemo> creditMemos){
        Set<String> zuoraAcctIds = new Set<String>();
        List<ZuoraAPI.CreditMemoWithItem> outstandingCreditMemosWithItem = new List<ZuoraAPI.CreditMemoWithItem>();

        for (ZuoraAPI.ZuoraCreditMemo creditMemo : creditMemos){
            if (creditMemo.unappliedAmount > 0){
                zuoraAcctIds.add(creditMemo.accountId);
                outstandingCreditMemosWithItem.add(ZuoraCreditMemoAllocationService.getItemFromCreditMemo(creditMemo));
            }
        }
        this.creditMemosToApply = outstandingCreditMemosWithItem;
    }

    public List<ZuoraAPI.CreditMemoWithItem> start(Database.BatchableContext bc){
        return creditMemosToApply;
    }

    public void execute(Database.BatchableContext bc, List<ZuoraAPI.CreditMemoWithItem> scope) {
        try {
            for (ZuoraAPI.CreditMemoWithItem creditMemo : scope) {
                ZuoraCreditMemoAllocationService.CreditMemoApplication application;
                application = ZuoraCreditMemoAllocationService.getCreditMemoApplication(creditMemo);
                String urlString = '/v1/creditmemos/' + creditMemo.creditMemo.Id +'/apply';
                ZuoraAPIHelper.callJSONEndpoint( 'PUT', urlString, application, false);
            }
        } catch(Exception excep) {
            Logger.logLater('ZuoraMemoBatchApply', 'execute', excep.getMessage() + '\n' + excep.getStackTraceString());
        }
        Logger.flushLogs();
    }

    public void finish(Database.BatchableContext bc){
        if (this.nextPage != null){
            ZuoraCreditMemoAllocationService.QueryResultCreditMemo query;
            query = ZuoraCreditMemoAllocationService.getCreditMemosByPage(this.nextPage);
            ZuoraMemoBatchApply batchJob = new ZuoraMemoBatchApply();
            handleQuery(query);
            batchJob.runBatch(5);
        } else {
            Logger.logNow('ZuoraMemoBatchApply', 'finish', 'ZuoraMemoBatchApply has finished');
        }
    }
}