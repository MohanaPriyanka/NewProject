/**
 * Created by Sarah Renfro on 12/6/2018.
 */

@IsTest
private class CSAccountCancellerTest {
    @TestSetup public static void setupTestData() {
        CustomerCommunicationHandlerTest.setupData();
    }

    @IsTest
    static void testOverdueAccounts() {
        //Set up delinquent customers
        Test.startTest();
        List<Shared_Solar_System__c> sss = [SELECT Id FROM Shared_Solar_System__c ORDER BY Name ASC ];

        CustomerCommunicationHandlerTest.createBills(System.today() - 88, sss[0].Id); // 67 days late
        List <Account_Bill__c> listaccountBills = [ SELECT Id, Published__c, Parent_Account__r.Id
        FROM Account_Bill__c];

        for (Account_Bill__c acctBill : listaccountBills) {
            acctBill.Published__c = true;
        }
        update listaccountBills;

        //A: Normal - Cancel
        CSCancellationScheduler cancellationScheduler = new CSCancellationScheduler();
        cancellationScheduler.execute(null);
        Account testAccount = [
            SELECT Id, Name, Cancellation_Request_Date__c, Cancellation_Reason__c, Cancellation_Comments__c
            FROM Account WHERE Id = :listaccountBills[0].Parent_Account__r.Id
        ];
        Opportunity testOpp = [
            SELECT Id, Customer_Group__c FROM Opportunity WHERE AccountId = :testAccount.Id
        ];

        System.assertNotEquals(null, testAccount.Cancellation_Request_Date__c);
        System.assertEquals('Automated Cancellation', testAccount.Cancellation_Comments__c);
        System.assertEquals('Lack of Payment', testAccount.Cancellation_Reason__c);

        //Undo cancel and set Opp.Customer_Group__c to Anchor
        testAccount.Cancellation_Reason__c = null;
        testAccount.Cancellation_Comments__c = '';
        testAccount.Cancellation_Request_Date__c = null;
        testOpp.Customer_Group__c = 'Anchor';
        update testAccount;
        update testOpp;
        System.debug('Comments: ' + testAccount.Cancellation_Comments__c);

        //B: Do not Cancel Anchor/Public Offtake Accounts
        CSAccountCanceller.handleOverdueAccounts();
        Account testAccountB = [
            SELECT Id, Name, Cancellation_Request_Date__c, Cancellation_Reason__c, Cancellation_Comments__c
            FROM Account WHERE Id = :listaccountBills[0].Parent_Account__r.Id
        ];

        System.assertEquals(null, testAccountB.Cancellation_Request_Date__c);
        System.assertEquals(null, testAccountB.Cancellation_Reason__c);

        Test.stopTest();
    }
}