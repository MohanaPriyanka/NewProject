/**
 * Created by Sarah Renfro on 12/6/2018.
 *
 * Tested By: CSCancellationSchedulerTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CSCancellationScheduler implements Schedulable {
    public static final Integer DAYS_PAST_DUE_DEACTIVATION_TRIGGER = 67;
    public static final Integer DAYS_PAST_DUE_BAD_DEBT_TRIGGER = 90;

    public void execute(SchedulableContext sc) {
        Autopay_Schedule__c schedule = getSchedule(System.today());
        if (schedule != null) {
            Database.executeBatch(new CSCancellationAccountService(schedule.Preview__c, schedule));
        }
    }

    @TestVisible
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
}