public without sharing class ZuoraMemoBatchApply implements Database.Batchable<ZuoraAPI.CreditMemoWithItem>, Database.Stateful, Database.AllowsCallouts{
    public void executeBatch(){
        Database.executeBatch(this, 20);
    }

    public List<ZuoraAPI.CreditMemoWithItem> start(Database.BatchableContext bc){
        Set<String> zuoraAcctIds = new Set<String>();
        List<ZuoraAPI.ZuoraCreditMemo> creditMemos = ZuoraCreditMemoAllocationService.getAllCreditMemos();
        List<ZuoraAPI.CreditMemoWithItem> outstandingCreditMemosWithItem = new List<ZuoraAPI.CreditMemoWithItem>();

        for (ZuoraAPI.ZuoraCreditMemo creditMemo : creditMemos){
            if (creditMemo.unappliedAmount > 0){
                zuoraAcctIds.add(creditMemo.accountId);
                outstandingCreditMemosWithItem.add(ZuoraCreditMemoAllocationService.getItemFromCreditMemo(creditMemo));
            }
        }
        outstandingCreditMemosWithItem = ZuoraCreditMemoAllocationService.sortByDate(outstandingCreditMemosWithItem);
        return outstandingCreditMemosWithItem;
    }

    public void execute(Database.BatchableContext bc, List<ZuoraAPI.CreditMemoWithItem> scope) {
        try {
            for (ZuoraAPI.CreditMemoWithItem creditMemo : scope) {
                ZuoraCreditMemoAllocationService.CreditMemoApplication application;
                application = ZuoraCreditMemoAllocationService.applyCreditMemoToAccount(creditMemo);
                String urlString = '/v1/creditmemos/' + creditMemo.creditMemo.Id +'/apply';
                ZuoraAPIHelper.callJSONEndpoint( 'PUT', urlString, application, false);
            }
        } catch(Exception excep) {
            Logger.logLater('ZuoraMemoBatchApply', 'execute', excep.getMessage() + '\n' + excep.getStackTraceString());
        }
        Logger.flushLogs();
    }

    public void finish(Database.BatchableContext bc){
        Logger.logNow('ZuoraMemoBatchApply', 'finish', 'ZuoraMemoBatchApply has finished');
    }
}