/**
 * Created by peteryao on 12/26/19.
 * Description: Handles Queueable interface for TestcaseRecordDeleter, since a class can't implement Queueable and Scheduable
 * at the same time. This also can't be a future method in TestcaseRecordDeleter, since it starts a batch (which can't
 * be done in a future method).
 * Tested By: TestcaseRecordDeleterTest
 */

public virtual with sharing class TestcaseRecordAsyncDeleter implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) {
        try {
            deleteSFDCAndZuoraTestcaseAccounts();
        } catch (Exception e) {
            Logger.logLater('TestcaseRecordAsyncDeleter', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    private void deleteSFDCAndZuoraTestcaseAccounts() {
        List<ZuoraAPI.ZuoraAccount> zuoraAccounts = getZuoraTestcaseAccounts();
        ZuoraAPI.ActionItems zuoraAccountsToDelete = deleteSFDCAccounts(zuoraAccounts);
        ZuoraGenericBatchOperation genericBatchOperation = new ZuoraGenericBatchOperation(zuoraAccountsToDelete, ZuoraAPIHelper.ActionDMLOperations.DMLDELETE);
        Database.executeBatch(genericBatchOperation, ZuoraAPIHelper.maxActionUpdateRecords);
    }

    protected virtual List<ZuoraAPI.ZuoraAccount> getZuoraTestcaseAccounts() {
        Datetime twoWeeksAgo = System.now() - 14;
        String twoWeeksAgoFormatted = twoWeeksAgo.format('yyyy-MM-dd')+'T00:00:00';
        // ZOQL (unlike DataQuery) is case insensitive, so Testcase will match TeStCaSe, etc.
        String response =
            ZuoraAPIHelper.query('SELECT Id, CRMId FROM Account WHERE Name LIKE \'%Testcase%\' AND CreatedDate < \'' + twoWeeksAgoFormatted + '\'', false);
        ZuoraAccountSelector.QueryResultAccount zuoraQueryResult =
            (ZuoraAccountSelector.QueryResultAccount) JSON.deserialize(response, ZuoraAccountSelector.QueryResultAccount.class);
        Logger.logLater('DeleteTestcaseRecordsAsync', 'execute', 'Found ' + zuoraQueryResult.records.size() + ' accounts to delete in Zuora and Salesforce.', Logger.INFO);
        return zuoraQueryResult.records;
    }

    private ZuoraAPI.ActionItems deleteSFDCAccounts(List<ZuoraAPI.ZuoraAccount> zuoraAccounts) {
        ZuoraAPI.ActionItems actionItems = new ZuoraAPI.ActionItems();
        actionItems.type = 'Account';
        List<Account> accountsToDelete = new List<Account>();
        for (ZuoraAPI.ZuoraAccount zuoraAccount : zuoraAccounts) {
            Account account = new Account(
                Id = zuoraAccount.CrmId,
                Zuora_Id__c = null
            );
            accountsToDelete.add(account);
            actionItems.ids.add(zuoraAccount.Id);
        }
        Util.updateAndLog(accountsToDelete, 'TestcaseRecordDeleter', 'deleteSFDCAccounts');
        Database.DeleteResult[] testCaseDeletion = Database.delete(accountsToDelete, false);
        TestcaseRecordDeleter.processRecords(testCaseDeletion);
        return actionItems;
    }
}