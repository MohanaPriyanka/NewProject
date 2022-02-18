// Tested by ZuoraBillingBatchServiceTest

public with sharing class ZuoraBillingBatchService implements ZuoraDataQueryService.Processor {
    @TestVisible
    private ZuoraAccountSelector zuoraAcctSelector = new ZuoraAccountSelector();

    public static final String PRE_BILLING_BATCH = 'Batch1';
    public static final String BILLING_BATCH = 'Batch2';
    public static final String FINISHED_BILLING_BATCH = 'Batch3';

    public static void queueDataQuery(){
        String queryString = 'SELECT us.AccountId FROM Usage us WHERE us.rbeStatus = \'Pending\' GROUP BY us.AccountId';
        ZuoraDataQueryService.ProcessingParameter param = new ZuoraDataQueryService.ProcessingParameter();
        param.className = 'ZuoraBillingBatchService';
        ZuoraDataQueryService.callFromApex(queryString,param);
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        updateAccountBatches(response);
    }

    @TestVisible
    private ZuoraAPI.ActionItems updateAccountBatches(String dataQueryResponse) {
        ZuoraAPI.ActionItems actionItem = new ZuoraAPI.ActionItems();
        actionItem.type = 'Account';
        try {
            Set<String> accountsWithUsage = getAccountsWithPendingUsage(dataQueryResponse);
            List<Zuora__CustomerAccount__c> allAccounts = zuoraAcctSelector.getAllBillingAccounts();
            for (Zuora__CustomerAccount__c account : allAccounts){
                ZuoraAPI.ZuoraAccount zAccount = new ZuoraAPI.ZuoraAccount();
                Boolean hasUsage = accountsWithUsage.contains(account.Zuora__Zuora_Id__c);
                if (account.Zuora__Batch__c != BILLING_BATCH && hasUsage){
                    zAccount.Id = account.Zuora__Zuora_Id__c;
                    zAccount.Batch = BILLING_BATCH;
                    actionItem.objects.add(zAccount);
                } else if (account.Zuora__Batch__c == BILLING_BATCH && !hasUsage) {
                    zAccount.Id = account.Zuora__Zuora_Id__c;
                    zAccount.Batch = FINISHED_BILLING_BATCH;
                    actionItem.objects.add(zAccount);
                }
            }
            ZuoraGenericBatchOperation batchUpdate = new ZuoraGenericBatchOperation(
                actionItem,
                ZuoraAPIHelper.actionDMLOperations.DMLUPDATE
            );
            Database.executeBatch(batchUpdate, 50);
        } catch (Exception e) {
            Logger.logNow('ZuoraBillingBatchService','setOffFutureBatchUpdate', 'Batch Update Failed:'
                + '\n' + e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR);
        }
        return actionItem;
    }

    private Set<String> getAccountsWithPendingUsage(String response){
        List<ZuoraUsageService.ZuoraUsage> usageList;
        usageList = (List<ZuoraUsageService.ZuoraUsage>) System.JSON.deserialize(response, List<ZuoraUsageService.ZuoraUsage>.class);
        Set<String> accountsWithUsage = new Set<String>();
        for (ZuoraUsageService.ZuoraUsage usage : usageList){
            accountsWithUsage.add(usage.AccountId);
        }
        return accountsWithUsage;
    }
}