/**
 * Created by Sarah Renfro on 12/13/2018.
 */

@IsTest
private class CSCancellationSchedulerTest {
    @TestSetup public static void setupTestData() {
        CustomerCommunicationHandlerTest.setupData();
    }

    @IsTest
    static void testExecute() {
        List<Shared_Solar_System__c> sss = [SELECT Id FROM Shared_Solar_System__c ORDER BY Name ASC ];

        CSCancellationServiceTest.createBills(System.today() - 88, sss[0].Id);

        UASB__c uasb = [
            SELECT Id, Opportunity__r.AccountId
            FROM UASB__c
            LIMIT 1
        ];

        Account acct = [
            SELECT Id,
                Max_Overdue_Due_Date_Zuora__c,
                Total_Outstanding_Balance_Zuora__c,
                Max_Overdue_Due_Date__c,
                Total_Outstanding_Balance__c
            FROM Account
            WHERE Id = : uasb.Opportunity__r.AccountId
            LIMIT 1
        ];
        acct.Max_Overdue_Due_Date_Zuora__c = System.today().addDays(-68);
        acct.Total_Outstanding_Balance_Zuora__c = 12.00;
        update acct;

        Autopay_Schedule__c schedule = new Autopay_Schedule__c(
            Run_Date__c = System.today(),
            Send_Results_To__c = UserInfo.getUserId()
        );
        insert schedule;
        Test.startTest();
        CSCancellationScheduler cancellationScheduler = new CSCancellationScheduler();
        cancellationScheduler.execute(null);
        Test.stopTest();

        // There should be one overdue account, with opps set to cancelled, but not yet removed
        System.assertEquals(1, cancellationScheduler.overdueAccounts.size());
        System.assertEquals(1, cancellationScheduler.cancelledOpportunities.size());
        System.assertEquals(0, cancellationScheduler.accountsRemovedFromAllProjects.size());
        if (UserInfo.getUserEmail() != null) {
            System.assertEquals(1, MessagingService.emailsSent.size(), 'Expected to send an email of the summary');
        }

        schedule = [SELECT Id, Summary__c FROM Autopay_Schedule__c WHERE Id = :schedule.Id];
        System.assert(schedule.Summary__c.contains(CSCancellationScheduler.ACCOUNT_OVERDUE_DESCRIPTION.replace('will get', 'got')),
            'Expected a non-preview summary to be written to the schedule');
    }

    @IsTest
    static void testPreview() {
        CustomerCommunicationHandlerTest.setDaysPastDue(System.today().addDays(-68), 10);

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c WHERE Class__c = 'CSCancellationScheduler'];
        System.assertEquals(0, errorLogs.size(), 'Expected no error logs');

        Autopay_Schedule__c schedule = new Autopay_Schedule__c(
            Run_Date__c = System.today(),
            Preview__c = true
        );
        insert schedule;
        Test.startTest();
        CSCancellationScheduler cancellationScheduler = new CSCancellationScheduler();
        cancellationScheduler.execute(null);
        Test.stopTest();

        schedule = [SELECT Id, Summary__c FROM Autopay_Schedule__c WHERE Id = :schedule.Id];
        System.assert(schedule.Summary__c.contains(CSCancellationScheduler.ACCOUNT_OVERDUE_DESCRIPTION), 'Expected a preview summary to be written');
    }

    @IsTest
    static void testNoSchedule() {
        Test.startTest();
        CSCancellationScheduler cancellationScheduler = new CSCancellationScheduler();
        cancellationScheduler.execute(null);
        Integer queriesAfterScheduler = Limits.getQueries();
        Test.stopTest();

        System.assertEquals(1, queriesAfterScheduler,
            'Expected to only run one query, to find the schedule for the current day');
    }

    @IsTest
    private static void testInvocable() {
        InvocableCSCanceller.CancellationStep step = new InvocableCSCanceller.CancellationStep(true, 'OverdueAccounts');
        List<InvocableCSCanceller.CancellationStep> steps = new List<InvocableCSCanceller.CancellationStep>{step};
        System.assertNotEquals(null, InvocableCSCanceller.cancelCS(steps), 'Expected output when previewing OverdueAccounts');
        step.stepName = 'Opportunities';
        System.assertNotEquals(null, InvocableCSCanceller.cancelCS(steps), 'Expected output when previewing Opportunities');
        step.stepName = 'OverdueAccounts';
        System.assertNotEquals(null, InvocableCSCanceller.cancelCS(steps), 'Expected output when previewing OverdueAccounts');
        step.stepName = 'All';
        System.assertNotEquals(null, InvocableCSCanceller.cancelCS(steps), 'Expected output when previewing all steps');
        step.stepName = 'Foo';
        try {
            InvocableCSCanceller.cancelCS(steps);
            System.assert(false, 'Expected to throw an exception when providing an invalid step name');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Unknown step'), e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
}