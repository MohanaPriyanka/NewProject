/**
 * Created by aingram on 9/3/21.
 */

@IsTest
private class BouncedEmailCaseCreationSchedulerTest {

    // Dummy CRON expression: midnight on March 15.
    private static String CRON_EXP = '0 0 0 15 3 ? 2022';

    @TestSetup public static void setupTestData() {

        List<Lead> testLeads = new List<Lead>();

        Lead testLead1 = new Lead(
            FirstName = 'John',
            LastName = 'Testcase',
            Company = 'Company',
            Email = 'emailBounceTest1@email.com'
        );

        Lead testLead2 = new Lead(
            FirstName = 'John',
            LastName = 'Testcase',
            Company = 'Company',
            Email = 'emailBounceTest2@email.com'
        );

        Lead testLead3 = new Lead(
            FirstName = 'John',
            LastName = 'Testcase',
            Company = 'Company',
            Email = 'emailBounceTest3@email.com'
        );

        Lead testLead4 = new Lead(
            FirstName = 'John',
            LastName = 'Testcase',
            Company = 'Company',
            Email = 'emailBounceTest4@email.com'
        );

        testLeads.add(testLead1);
        testLeads.add(testLead2);
        testLeads.add(testLead3);
        testLeads.add(testLead4);
        insert testLeads;

        testLead1.EmailBouncedDate = System.now();
        testLead2.EmailBouncedDate = System.now();
        testLead3.EmailBouncedDate = System.now();
        testLead4.EmailBouncedDate = System.now().addDays(-1);

        update testLeads;

        List<Case> testCases = new List<Case>();

        Case case1 = new Case(
            Subject = '- Other',
            Lead_Lookup__c = testLead2.Id,
            Product_Line__c = 'Community Solar',
            Description = 'email bounced. Please provide new email address.',
            Status = 'New'
        );

        Case case2 = new Case(
            Subject = '- Other',
            Lead_Lookup__c = testLead3.Id,
            Product_Line__c = 'Community Solar',
            Description = 'email bounced. Please provide new email address.',
            Status = 'Closed',
            Resolution__c = 'Data Update'
        );

        testCases.add(case1);
        testCases.add(case2);

        insert testCases;


    }

    @IsTest
    static void testBouncedEmailCaseCreation() {

        Test.startTest();
        System.schedule('ScheduledBouncedEmailTest', CRON_EXP, new BouncedEmailCaseCreationScheduler());
        Test.stopTest();

        List<Lead> leads = [
            SELECT Id, Status, FirstName, LastName, Email,
            (SELECT Id, Description, Status FROM Cases__r)
            FROM Lead
        ];

        System.assertEquals(1, leads[0].Cases__r.size(), 'Lead 1 should only have one new case in the system');
        System.assertEquals(1, leads[1].Cases__r.size(), 'Lead 2 should still only have one in the system');
        System.assertEquals(2, leads[2].Cases__r.size(), 'Lead 3 should have 2 cases in the system');
        System.assertEquals(0, leads[3].Cases__r.size(), 'Lead 4 should have no cases in the system since the bounced date is out of range');

    }
}