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
        Test.startTest();
        Util.disableTrigger('Disable_OpportunityTrigger__c');
        Util.disableTrigger('Disable_AccountTrigger__c');
        List<Shared_Solar_System__c> sss = [SELECT Id FROM Shared_Solar_System__c ORDER BY Name ASC ];

        CustomerCommunicationHandlerTest.createBills(System.today() - 88, sss[0].Id); // 67 days late
        List <Account_Bill__c> listaccountBills = [ SELECT Id, Published__c, Parent_Account__r.Id
        FROM Account_Bill__c];

        for (Account_Bill__c acctBill : listaccountBills) {
            acctBill.Published__c = true;
        }
        update listaccountBills;

        CSCancellationScheduler cancellationScheduler = new CSCancellationScheduler();
        cancellationScheduler.execute(null);

        //Check handleOverdueAccounts
        Account testAccount = [
            SELECT Id, Name, Cancellation_Request_Date__c, Cancellation_Reason__c, Cancellation_Comments__c
            FROM Account WHERE Id = :listaccountBills[0].Parent_Account__r.Id
        ];

        System.assertNotEquals(null, testAccount.Cancellation_Request_Date__c);
        System.assertEquals('Automated Cancellation', testAccount.Cancellation_Comments__c);
        System.assertEquals('Lack of Payment', testAccount.Cancellation_Reason__c);

        Test.stopTest();
    }
}