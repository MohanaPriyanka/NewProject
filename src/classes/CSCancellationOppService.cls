/**
 * @description Handles opportunity related cancellation activity. See the Cancellation Process lucid chart for more detail:
 * https://lucid.app/lucidchart/28ddde15-529b-4b09-b858-35bba5e77e37/edit?shared=true&invitationId=inv_805406f1-b7d7-46cc-af1a-45901bb1d4e2&page=0_0#
 * Tested By: CSCancellationServiceTest
 */
public without sharing class CSCancellationOppService implements Database.Batchable<Opportunity>, Database.Stateful {
    private static final String OPPORTUNITY_CANCELLATION_DESCRIPTION =
        'These opportunities, if any, will get their Stage set to Cancelled because we\'re done billing' +
            ' them, they don\'t have all UASes transferring, and don\'t have any active UASes' +
            '\n-------------';
    @TestVisible private List<Opportunity> opportunitiesProcessed = new List<Opportunity>();
    private Boolean preview;
    private Autopay_Schedule__c cancellationSchedule;

    public CSCancellationOppService(Boolean preview, Autopay_Schedule__c cancellationSchedule) {
        this.preview = preview;
        this.cancellationSchedule = cancellationSchedule;
    }

    public List<Opportunity> start(Database.BatchableContext context) {
        List<Opportunity> completeCSOpps = OpportunitiesSelector.selectAllCompleteCSWithUASesAndSystemBills();
        Logger.logNow(
            'CSCancellationOppService',
            'start',
            'Logging in case this transaction is close to limits',
            Logger.FINE
        );
        return completeCSOpps;
    }

    public void execute(Database.BatchableContext context, List<Opportunity> scopedCompleteCSOpportunities) {
        List<Opportunity> opportunitiesToCancel = getOpportunitiesToCancel(scopedCompleteCSOpportunities);
        if (!preview) {
            cancelOpportunities(opportunitiesToCancel);
        }
        opportunitiesProcessed.addAll(opportunitiesToCancel);
        Logger.logNow(
            'CSCancellationOppService',
            'execute',
            'Logging in case this transaction is close to limits',
            Logger.FINE
        );
    }

    public void finish(Database.BatchableContext context) {
        String outputMessage = '\n\n' + OPPORTUNITY_CANCELLATION_DESCRIPTION;
        if (!preview) {
            outputMessage = outputMessage.replace('will get', 'got');
        }
        for (Opportunity opportunity : opportunitiesProcessed) {
            outputMessage += '\n' + opportunity.Id + ', ' + opportunity.Name;
        }
        cancellationSchedule.Summary__c += outputMessage;
        update cancellationSchedule;
        if (!Test.isRunningTest()) {
            Database.executeBatch(new CSCancellationProjectRemover(preview, cancellationSchedule));
        }
    }

    // W-008425: Called by the CSCancellationScheduler daily to mark Opportunities as cancelled if:
    // 1. Opportunity Stage is Complete AND
    // 2. All UASes are inactive and there are no SZSes for them (waitlist cancellation) OR
    // 3. We've sent System Bills, but not for 45 days (15 days after we expect to send), so we're finished billing
    //
    // Once all opportunities under a property account are cancelled (or Duplicate, Expired, or Dead), another scheduled job
    // will send a termination letter
    @TestVisible private void cancelOpportunities(List<Opportunity> oppToCancelList) {
        try {
            Opportunities opportunities = new Opportunities(oppToCancelList);
            opportunities.cancel();
        } catch (Exception e) {
            Logger.logNow('CSCancellationOppService', 'cancelOpportunities', e.getMessage() + '\n\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    @TestVisible private List<Opportunity> getOpportunitiesToCancel(List<Opportunity> completeCSOpps) {
        List<Opportunity> oppsToCancel = new List<Opportunity>();
        for (Opportunity opportunity : completeCSOpps) {
            if (Opportunities.shouldCancel(opportunity)) {
                oppsToCancel.add(opportunity);
            }
        }

        return oppsToCancel;
    }

    // W-008426: Called by the OpportunityTrigger to check to see if all CS opportunities are Cancelled, Expired, Duplicate,
    // or Dead. If so, we update the Account Status__c field and send the final termination letter email.
    public static List<Account> getAccountsToClose(Map<Id, Opportunity> newOppMap, Map<Id, Opportunity> oldOppMap) {
        //get all accounts where opportunities are either Cancelled, DUPLICATE, Expired or Dead
        Set<Id> accountIds = new Set<Id>();
        List<Account> accountsToClose = new List<Account>();
        for (Opportunity opp : newOppMap.values()) {
            if (opp.Product_Line__c == 'Community Solar' &&
                Opportunities.isActive(oldOppMap.get(opp.Id).StageName) && !Opportunities.isActive(opp.StageName)) {
                accountIds.add(opp.AccountId);
            }
        }

        List<Account> acctsToCheck = AccountsSelector.selectNotClosed(accountIds);
        for (Account acct : acctsToCheck) {
            if (new Opportunities(acct.Opportunities).allInactive()) {
                accountsToClose.add(acct);
            }
        }
        return accountsToClose;
    }
}