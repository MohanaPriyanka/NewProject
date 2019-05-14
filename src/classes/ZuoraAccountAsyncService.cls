/**
 * Created by PeterYao on 4/30/2019.
 * Description: Used by lead conversion for CS leads from CSAP and the Originations platform, and data migration
 * Tested By: ZuoraAccountServiceTest
 */

public without sharing class ZuoraAccountAsyncService implements Queueable, Database.AllowsCallouts, Database.Batchable<Account> {
    private Id leadId;
    private List<Account> accountsToCreate;

    public ZuoraAccountAsyncService(Id leadId) {
        this.leadId = leadId;
    }
    public ZuoraAccountAsyncService(List<Account> accounts) {
        this.accountsToCreate = accounts;
    }

    public void execute(QueueableContext context) {
        try {
            ZuoraAccountService.createAccountsFromLeads(new List<Id>{leadId});
        } catch (Exception e) {
            Logger.flushLogs();
            Logger.logNow('ZuoraAccountAsyncService', 'execute',
                'Zuora account creation failed for lead: ' + leadId + '\n' + e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR);
        }
    }

    public List<Account> start(Database.BatchableContext context) {
        return accountsToCreate;
    }

    public void execute(Database.BatchableContext batchableContext, List<Account> scope) {
        try {
            ZuoraAccountService.createAccounts(scope);
        } catch (Exception e) {
            Logger.flushLogs();
            Logger.logNow('ZuoraAccountAsyncService', 'execute',
                'Zuora account creation failed for accounts: ' + scope + '\n' + e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR);
        }
    }

    public void finish(Database.BatchableContext batchableContext) {
    }

    public void startBatch(Integer batchSize) {
        Database.executeBatch(this, batchSize);
    }
}