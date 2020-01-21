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

        CustomerCommunicationHandlerTest.createBills(System.today() - 88, sss[0].Id); // 67 days late

        List <Account_Bill__c> accountBills = [
            SELECT Id, Published__c, Parent_Account__r.Id
            FROM Account_Bill__c
        ];

        for (Account_Bill__c acctBill : accountBills) {
            acctBill.Published__c = true;
        }
        update accountBills;
        CustomerCommunicationHandlerTest.mockZuoraFields();

        Test.startTest();
        CSCancellationScheduler cancellationScheduler = new CSCancellationScheduler();
        cancellationScheduler.execute(null);
        Test.stopTest();

        // There should be one overdue account, with opps set to cancelled, but not yet removed
        System.assertEquals(1, cancellationScheduler.overdueAccounts.size());
        System.assertEquals(1, cancellationScheduler.cancelledOpportunities.size());
        System.assertEquals(0, cancellationScheduler.accountsRemovedFromAllProjects.size());

        // There should be just one error log describing the results
        List<Error_Log__c> errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Class__c = 'CSCancellationScheduler'];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Overdue Accounts set as overdue:'),
            'Expected an error log with a cancellation summary, but got this instead:' + errorLogs[0].Message__c);
        System.assert(errorLogs[0].Message__c.contains('Cancelled Opps:'),
            'Expected an error log with a cancellation summary, but got this instead:' + errorLogs[0].Message__c);
    }

    @IsTest
    static void testPreview() {
        List<Shared_Solar_System__c> sss = [SELECT Id FROM Shared_Solar_System__c ORDER BY Name ASC ];

        CustomerCommunicationHandlerTest.createBills(System.today() - 88, sss[0].Id); // 67 days late

        List <Account_Bill__c> accountBills = [
            SELECT Id, Published__c, Parent_Account__r.Id
            FROM Account_Bill__c
        ];

        for (Account_Bill__c acctBill : accountBills) {
            acctBill.Published__c = true;
        }
        update accountBills;
        CustomerCommunicationHandlerTest.mockZuoraFields();

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size(), 'Expected no error logs');

        Test.startTest();
        CSCancellationScheduler cancellationScheduler = new CSCancellationScheduler(true);
        cancellationScheduler.execute(null);
        Test.stopTest();

        errorLogs = [SELECT Id, Method__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size());
        System.assertEquals('previewCancellation', errorLogs[0].Method__c, 'Expected a previewCancellation error log');
    }
}