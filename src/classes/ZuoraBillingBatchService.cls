// Tested by ZuoraBillingBatchServiceTest

public with sharing class ZuoraBillingBatchService {
    @TestVisible
    private AccountsSelector accountsSelector = new AccountsSelector();
    @TestVisible
    private ZuoraAccountSelector zuoraAcctSelector = new ZuoraAccountSelector();

    public static final String PRE_BILLING_BATCH = 'Batch1';
    public static final String BILLING_BATCH = 'Batch2';
    public static final String FINISHED_BILLING_BATCH = 'Batch3';

    public ZuoraAPI.ActionItems updateAccountBatches(Date invoiceDate) {
        ZuoraAPI.ActionItems actionItem = new ZuoraAPI.ActionItems();
        actionItem.type = 'Account';

        try {
            // We only want to get customers who have UASBs from the current period
            // We expect usage to be uploaded in the past few days, but we set to be 15 just to be safe.
            // Don't want to set to be > 30, because then may pick up usage from a previous period
            Date cutoffDate = invoiceDate.addDays(-15);
            Map<Id, Integer> accountsWithUsage = accountsSelector.selectAccountsWithUASBs(cutoffDate);
            List<Zuora__CustomerAccount__c> allAccounts = zuoraAcctSelector.getAllBillingAccounts();

            for (Zuora__CustomerAccount__c account : allAccounts){
                ZuoraAPI.ZuoraAccount zAccount = new ZuoraAPI.ZuoraAccount();
                Boolean hasUsage = accountsWithUsage.containsKey(account.Zuora__Account__c);
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
}