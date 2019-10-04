/**
 * Created by PeterYao on 4/30/2019.
 * Description: Used by lead conversion for CS leads from CSAP and the Originations platform, and data migration
 * Tested By: ZuoraAccountServiceTest, ZuoraAccountReconciliationServiceTest
 */

public without sharing class ZuoraAccountAsyncService implements Queueable, Database.AllowsCallouts, Database.Batchable<Account> {
    public enum OperationType {CREATE, RECONCILE}
    public OperationType mode;
    private Id leadId;
    private List<Account> accountsToCreate;
    private Set<String> zuoraAccountIds;
    private Set<String> zuoraAccountIdsReconciled;
    @TestVisible
    private ZuoraAccountReconciliationService accountReconciliationService = new ZuoraAccountReconciliationService();

    public ZuoraAccountAsyncService(Id leadId) {
        this.mode = OperationType.CREATE;
        this.leadId = leadId;
    }
    public ZuoraAccountAsyncService(List<Account> accounts) {
        this.mode = OperationType.CREATE;
        this.accountsToCreate = accounts;
    }
    public ZuoraAccountAsyncService(Set<String> zuoraAccountIds) {
        this(zuoraAccountIds, new Set<String>());
    }
    public ZuoraAccountAsyncService(Set<String> zuoraAccountIds, Set<String> zuoraAccountIdsReconciled) {
        this.mode = OperationType.RECONCILE;
        this.zuoraAccountIds = zuoraAccountIds;
        this.zuoraAccountIdsReconciled = zuoraAccountIdsReconciled;
    }

    public void execute(QueueableContext context) {
        try {
            if (mode == OperationType.CREATE) {
                ZuoraAccountService.createAccountsFromLeads(new List<Id>{leadId});
            } else {
                accountReconciliationService.reconcileZuoraWithSFDC(zuoraAccountIds, zuoraAccountIdsReconciled);
            }
        } catch (Exception e) {
            Logger.flushLogs();
            Logger.logNow('ZuoraAccountAsyncService', 'execute',
                'Zuora account async ' + mode + ' operation failed for lead: ' + leadId + '\n' +
                    'zuoraAccountIds: ' + zuoraAccountIds + '\n' + e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR);
        }
    }

    public List<Account> start(Database.BatchableContext context) {
        return accountsToCreate;
    }

    public void execute(Database.BatchableContext batchableContext, List<Account> scope) {
        if (mode == OperationType.CREATE) {
            try {
                ZuoraAccountService.createAccounts(scope);
            } catch (Exception e) {
                Logger.flushLogs();
                Logger.logNow('ZuoraAccountAsyncService', 'execute',
                    'Zuora account creation failed for accounts: ' + scope + '\n' + e.getMessage() + '\n' + e.getStackTraceString(),
                    Logger.ERROR);
            }
        }
    }

    public void finish(Database.BatchableContext batchableContext) {
    }

    public void startBatch(Integer batchSize) {
        Database.executeBatch(this, batchSize);
    }
}