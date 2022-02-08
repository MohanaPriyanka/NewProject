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
        Zuora__CustomerAccount__c billingAccount = [SELECT Id FROM Zuora__CustomerAccount__c WHERE Zuora__Balance__c = 15.00 LIMIT 1];

        CSCancellationServiceTest.createBills(System.today() - 88, sss[0].Id);

        Account propAccount1 = [
            SELECT Id,
                Max_Overdue_Due_Date_Zuora__c,
                Max_Overdue_Due_Date__c,
                Billing_Account__c
            FROM Account
            WHERE Name = 'Prop Account 1'
            LIMIT 1
        ];
        propAccount1.Max_Overdue_Due_Date_Zuora__c = System.today().addDays(-68);
        propAccount1.Billing_Account__c = billingAccount.Id;
        update propAccount1;

        Opportunity oppFor236 = [
            SELECT Id, AccountId, StageName, (SELECT Id, Utility_Account_Log__c FROM Utility_Account_Subscriptions__r)
            FROM Opportunity
            WHERE Name = 'Jordan Jordan 0000236'
            LIMIT 1
        ];

        // Set UAL to Cancelled, which updates the UAS Date Removed from Project and sets it to inactive
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Id = oppFor236.Utility_Account_Subscriptions__r[0].Utility_Account_Log__c
        );
        ual.Date_Utility_Account_Cancelled__c = System.today();
        update ual;

        oppFor236.StageName  = 'Cancelled';
        oppFor236.Date_Removed_from_Project__c = ual.Date_Utility_Account_Cancelled__c;
        update oppFor236;
        List<Account> accountsToRemoveFromLastProject = CSCancellationProjectRemover.getAccountsRemovedFromAllProjectsWithUpdatedDate();
        System.assertEquals(1, accountsToRemoveFromLastProject.size(),
            'Expected one Account to be ready to be marked with a Removed From Project date');
        System.assertEquals(oppFor236.AccountId, accountsToRemoveFromLastProject[0].Id,
            'Expected the Account for the Jordan Jordan 0000236 opp to be ready to be marked with a Removed From Project date');

        Autopay_Schedule__c schedule = new Autopay_Schedule__c(
            Run_Date__c = System.today(),
            Send_Results_To__c = UserInfo.getUserId()
        );
        insert schedule;
        Test.startTest();
        CSCancellationScheduler cancellationScheduler = new CSCancellationScheduler();
        cancellationScheduler.execute(null);
        Test.stopTest();

        System.assertEquals(1, cancellationScheduler.cancellationAccountService.overdueAccounts.size(),
            'There should be one overdue account, with opps set to cancelled, but not yet removed');
        System.assertEquals(1, cancellationScheduler.cancellationOppService.cancelledOpportunities.size(), '' +
            'Expected the cancellation scheduler to find one opp to mark as cancelled');
        System.assertEquals(1, cancellationScheduler.cancellationProjectRemover.accountsRemovedFromAllProjects.size(),
            'Expected the cancellation scheduler to find the account ready to be marked with Removed From Project');
        if (UserInfo.getUserEmail() != null) {
            System.assertEquals(3, MessagingService.emailsSent.size(),
                'Expected to send a Subscription Removal Confirmation, an Account Closed Confirmation, and a CS Cancellation Result summary');
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

        System.assertEquals(2, queriesAfterScheduler,
            'Expected to run two queries, to find the schedule for the current day and CSCancellationAccountService.CANCELLED_BY_ID');
    }

    @IsTest
    static void testInvocableCanceller() {
        InvocableCSCanceller.CancellationStep step = new InvocableCSCanceller.CancellationStep(false, '');
        InvocableCSCanceller.cancelCS(new List<InvocableCSCanceller.CancellationStep>{step});
        System.assert(true, 'Temporary to remove dependency from InvocableCSCanceller before deleting it');
    }
}