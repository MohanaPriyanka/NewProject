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

    // Should be called by Bill Generation Console:
    public void startApplication(){
        ZuoraCreditMemoAllocationService.QueryResultCreditMemo creditMemosByPage;
        creditMemosByPage = ZuoraCreditMemoAllocationService.getFirstPageCreditMemos(40);
        setOutstandingCreditMemoItemsToApply(creditMemosByPage);
    }

    public void setOutstandingCreditMemoItemsToApply(ZuoraCreditMemoAllocationService.QueryResultCreditMemo creditMemosByPage){
        if (creditMemosByPage.nextPage != null){
            this.nextPage = creditMemosByPage.nextPage;
        }
        Set<String> zuoraAcctIds = new Set<String>();
        List<ZuoraAPI.CreditMemoWithItem> outstandingCreditMemosWithItem = new List<ZuoraAPI.CreditMemoWithItem>();

        for (ZuoraAPI.ZuoraCreditMemo creditMemo : creditMemosByPage.creditMemos){
            if (creditMemo.unappliedAmount > 0){
                zuoraAcctIds.add(creditMemo.accountId);
                outstandingCreditMemosWithItem.add(ZuoraCreditMemoAllocationService.getItemFromCreditMemo(creditMemo));
            }
        }
        this.creditMemosToApply = outstandingCreditMemosWithItem;
    }

    public void runBatch(Integer batchSize){
        Database.executeBatch(this, batchSize);
    }

    public void init(List<ZuoraAPI.ZuoraCreditMemo> creditMemos){

    }

    public List<ZuoraAPI.CreditMemoWithItem> start(Database.BatchableContext bc){
        return creditMemosToApply;
    }

    public void execute(Database.BatchableContext bc, List<ZuoraAPI.CreditMemoWithItem> scope) {
        try {
            for (ZuoraAPI.CreditMemoWithItem creditMemo : scope) {
                ZuoraCreditMemoAllocationService.CreditMemoApplication application;
                application = ZuoraCreditMemoAllocationService.getCreditMemoApplication(creditMemo);
                String urlString = '/v1/creditmemos/' + creditMemo.creditMemo.id +'/apply';
                ZuoraAPIHelper.callJSONEndpoint( 'PUT', urlString, application, false);
            }
        } catch(Exception excep) {
            Logger.logLater('ZuoraMemoBatchApply', 'execute', excep.getMessage() + '\n' + excep.getStackTraceString());
        }
        Logger.flushLogs();
    }

    public void finish(Database.BatchableContext bc){
        if (this.nextPage != null){
            ZuoraCreditMemoAllocationService.QueryResultCreditMemo creditMemosByPage;
            creditMemosByPage = ZuoraCreditMemoAllocationService.getCreditMemosByPage(this.nextPage);
            ZuoraMemoBatchApply batchJob = new ZuoraMemoBatchApply();
            batchJob.setOutstandingCreditMemoItemsToApply(creditMemosByPage);
            batchJob.runBatch(5);
        } else {
            Logger.logNow('ZuoraMemoBatchApply', 'finish', 'ZuoraMemoBatchApply has finished');
        }
    }
}