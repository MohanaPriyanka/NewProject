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
    public Boolean previewOnly;

    public CSCancellationScheduler() {
        previewOnly = false;
    }

    public CSCancellationScheduler(Boolean previewOnly) {
        this.previewOnly = previewOnly;
    }

    public void execute(SchedulableContext sc) {
        if (previewOnly) {
            previewCancellation();
            return;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            overdueAccounts =
                CSCancellationService.handleOverdueAccounts();
            cancelledOpportunities =
                CSCancellationService.cancelOpportunities(CSCancellationService.getOpportunitiesToCancel());
            accountsRemovedFromAllProjects =
                CSCancellationService.processAccountsRemovedFromAllProjects(CSCancellationService.getAccountsRemovedFromAllProjectsWithUpdatedDate());
            if (!overdueAccounts.isEmpty() ||
                !cancelledOpportunities.isEmpty() ||
                !accountsRemovedFromAllProjects.isEmpty()) {
                String message = '';
                message += 'Overdue Accounts set as overdue: ' + sobjectListToIdString(overdueAccounts) + '\n\n';
                message += 'Cancelled Opps: ' + sobjectListToIdString(cancelledOpportunities) + '\n\n';
                message += 'Accounts removed from all projects: ' + sobjectListToIdString(accountsRemovedFromAllProjects) + '\n\n';
                message += 'Limits:\n' +
                    Util.getCPULimit('CPU') + '\n' +
                    Util.getHeapLimit('Heap') + '\n' +
                    Util.getSOQLLimit('Queries') + '\n' +
                    Util.getRowLimit('Rows');
                Logger.logNow('CSCancellationScheduler', 'execute', message, Logger.WARN);
            }
        } catch (Exception e) {
            Database.rollback(sp);
            Logger.logNow('CSCancellationScheduler', 'execute', e.getMessage() + e.getStackTraceString());
        }
    }

    private void previewCancellation() {
        String previewMessage = '';
        List<Account> accountList = AccountsSelector.selectCS67DaysPastDueWithAnchorOpps();
        previewMessage += 'These accounts, if any, will get a Cancellation Reason of "Lack of Payment", a Cancellation ' +
            'Request Date of today, and an automated cancellation comment, and subsequently be emailed of their cancellation. ' +
            'To exclude them, check the Override Delinquency Removal checkbox on the account\n-------------\n';
        for (Account account : accountList) {
            previewMessage += account.Id + ', ' + account.Name + ' ' + account.Days_Past_Due__c + '\n';
        }

        previewMessage += '\n\nThese opportunities, if any, will get their Stage set to Cancelled because we\'re done billing' +
            ' them, they don\'t have all UASes transferring, and don\'t have any active UASes\n-------------\n';
        List<Opportunity> opportunities = CSCancellationService.getOpportunitiesToCancel();
        for (Opportunity opportunity : opportunities) {
            previewMessage += opportunity.Id + ', ' + opportunity.Name + '\n';
        }

        previewMessage += '\n\nThese accounts, if any, will be marked with a Date Removed From Last Project because all of' +
            ' their opportunities have a Date Removed From Project, and subsequently be emailed that they are off all' +
            ' projects.\n-------------\n';
        List<Account> accountsRemovedFromAllProjects = CSCancellationService.getAccountsRemovedFromAllProjectsWithUpdatedDate();
        for (Account account : accountsRemovedFromAllProjects) {
            previewMessage += account.Id + ', ' + account.Name + ', ' + account.Date_Removed_from_Project__c + '\n';
        }

        Logger.logNow('CSCancellationScheduler', 'previewCancellation', previewMessage, Logger.INFO);
    }

    private String sobjectListToIdString(List<SObject> sObjects) {
        Map<Id, SObject> sobjMap = new Map<Id, SObject>();
        sobjMap.putAll(sObjects);
        Set<Id> idSet = sobjMap.keySet();
        return String.join(new List<Id>(idSet), ', ');
    }
}