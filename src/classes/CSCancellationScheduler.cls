/**
 * Created by Sarah Renfro on 12/6/2018.
 *
 * Tested By: CSCancellationSchedulerTest
 */

public without sharing class CSCancellationScheduler implements Schedulable{
    @TestVisible private CSCancellationAccountService cancellationAccountService = new CSCancellationAccountService();
    @TestVisible private CSCancellationOppService cancellationOppService = new CSCancellationOppService();
    @TestVisible private CSCancellationProjectRemover cancellationProjectRemover = new CSCancellationProjectRemover();

    public static final String ACCOUNT_OVERDUE_DESCRIPTION =
        'These accounts, if any, will get a Cancellation Reason of "Lack of Payment", a Cancellation ' +
            'Request Date of today, and an automated cancellation comment.\n' +
            'Salesforce will subsequently email the customer of their cancellation.\n' +
            'To exclude accounts, check the Override Delinquency Removal checkbox on the account' +
            '\n-------------\n';
    public static final String OPPORTUNITY_CANCELLATION_DESCRIPTION =
        'These opportunities, if any, will get their Stage set to Cancelled because we\'re done billing' +
            ' them, they don\'t have all UASes transferring, and don\'t have any active UASes' +
            '\n-------------\n';
    public static final String ACCOUNT_REMOVAL_DESCRIPTION =
        'These accounts, if any, will get marked with a Date Removed From Last Project because all of' +
            ' their opportunities have a Date Removed From Project, and subsequently be emailed that they are off all' +
            ' projects.' +
            '\n-------------\n';
    public static final Integer DAYS_PAST_DUE_DEACTIVATION_TRIGGER = 67;
    public static final Integer DAYS_PAST_DUE_BAD_DEBT_TRIGGER = 90;

    public void execute(SchedulableContext sc) {
        Autopay_Schedule__c schedule = getSchedule(System.today());
        if (schedule != null) {
            handleAccountsAndOpportunities(schedule.Preview__c, schedule);
        }
        Logger.logNow(
            'CSCancellationScheduler',
            'execute',
            'CSCancellationScheduler Complete, logging in case this transaction is close to limits',
            Logger.FINE
        );
    }

    @TestVisible
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private Autopay_Schedule__c getSchedule(Date today) {
        List<Autopay_Schedule__c> schedules = [
            SELECT Id, Run_Date__c, Preview__c, Send_Results_To__r.Email
            FROM Autopay_Schedule__c
            WHERE Run_Date__c = :today
        ];
        if (!schedules.isEmpty()) {
            return schedules[0];
        } else {
            return null;
        }
    }

    private void handleAccountsAndOpportunities(Boolean preview, Autopay_Schedule__c schedule) {
        Savepoint sp = Database.setSavepoint();
        try {
            cancel(preview, schedule);
        } catch (Exception e) {
            Database.rollback(sp);
            Logger.logNow('CSCancellationScheduler', 'execute', e.getMessage() + e.getStackTraceString());
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void cancel(Boolean preview, Autopay_Schedule__c schedule) {
        String outputMessage = '';
        outputMessage = cancellationAccountService.handleOverdueAccounts(preview);

        outputMessage += '\n\n';
        outputMessage += cancellationOppService.handleOpportunities(preview);

        outputMessage += '\n\n';
        outputMessage += cancellationProjectRemover.handleAccountsToRemove(preview);
        outputMessage += '\n\n';
        outputMessage += 'Limits:\n' +
            Util.getCPULimit('CPU') + '\n' +
            Util.getHeapLimit('Heap') + '\n' +
            Util.getSOQLLimit('Queries') + '\n' +
            Util.getRowLimit('Rows');

        schedule.Summary__c = outputMessage;
        schedule.Time_Finished__c = System.now();
        update schedule;

        if (schedule.Send_Results_To__r.Email != null) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setPlainTextBody(outputMessage);
            mail.setToAddresses(new List<String>{schedule.Send_Results_To__r.Email});
            mail.setSubject('CS Cancellation'+(preview?' Preview':'')+' Results');
            MessagingService.sendEmail(new List<Messaging.Email>{mail});
        }
    }
}