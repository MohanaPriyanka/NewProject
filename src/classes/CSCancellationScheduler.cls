/**
 * Created by Sarah Renfro on 12/6/2018.
 *
 * Tested By: CSCancellationSchedulerTest
 */

public without sharing class CSCancellationScheduler implements Schedulable{
    @TestVisible
    private List<Account> overdueAccounts = new List<Account>();
    @TestVisible
    private List<Opportunity> cancelledOpportunities = new List<Opportunity>();
    @TestVisible
    private List<Account> accountsRemovedFromAllProjects = new List<Account>();

    public void execute(SchedulableContext sc) {
        Savepoint sp = Database.setSavepoint();
        try {
            overdueAccounts =
                CSCancellationService.handleOverdueAccounts();
            cancelledOpportunities =
                CSCancellationService.cancelOpportunities(CSCancellationService.getOpportunitiesToCancel());
            accountsRemovedFromAllProjects =
                CSCancellationService.processAccountsRemovedFromAllProjects(CSCancellationService.getAccountsRemovedFromAllProjects());
            if (!overdueAccounts.isEmpty() ||
                !cancelledOpportunities.isEmpty() ||
                !accountsRemovedFromAllProjects.isEmpty()) {
                String message = '';
                message += 'Overdue Accounts set as overdue: ' + sobjectListToIdString(overdueAccounts) + '\n\n';
                message += 'Cancelled Opps: ' + sobjectListToIdString(cancelledOpportunities) + '\n\n';
                message += 'Accounts removed from all projects: ' + sobjectListToIdString(accountsRemovedFromAllProjects) + '\n\n';
                message += 'Took ' +
                    Limits.getCpuTime() + 'ms of CPU time (of ' + Limits.getLimitCpuTime() + 'ms), ' +
                    Limits.getHeapSize()/1000000 + 'MB of heap (of ' + Limits.getLimitHeapSize()/1000000 + 'MB), and ' +
                    Limits.getQueries() + ' queries (of ' + Limits.getLimitQueries() + ' queries)';
                Logger.logNow('CSCancellationScheduler', 'execute', message);
            }
        } catch (Exception e) {
            Database.rollback(sp);
            Logger.logNow('CSCancellationScheduler', 'execute', e.getMessage() + e.getStackTraceString());
        }
    }

    private String sobjectListToIdString(List<SObject> sObjects) {
        Map<Id, SObject> sobjMap = new Map<Id, SObject>();
        sobjMap.putAll(sObjects);
        Set<Id> idSet = sobjMap.keySet();
        return String.join(new List<Id>(idSet), ', ');
    }
}