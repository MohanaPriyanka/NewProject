@isTest 
private class PostSandboxRefresherTest {
    private static final String JOBNAME = 'Test Schedule';

    @testSetup public static void setupTestData() {
        Account testAcct = new Account(Name='Test');
        insert testAcct;
        List<Contact> contactList = new List<Contact>();
        List<Lead> leadList = new List<Lead>();
        for (Integer i=0; i<2; i++) {
            Contact c = new Contact(FirstName = 'test',
                                    LastName = 'testerson',
                                    Email = 'ttesterson'+i+'@email.com',
                                    Account = testAcct);
            contactList.add(c);
            Lead l = new Lead(FirstName = 'test',
                              LastName = 'testerson',
                              Company = 'test',
                              Email = 'ttesterson'+i+'@email.com');
            leadList.add(l);
        }
        insert contactList;
        insert leadList;

        ChargentOrders.sheduledBatchProcessing sbp = new ChargentOrders.sheduledBatchProcessing();
        String sch = '20 30 8 10 2 ?';
        System.schedule(JOBNAME, sch, sbp);
    }    

    static testMethod void testSandboxRefresh() {
        Test.startTest();
        PostSandboxRefresher.disableEmails();
        PostSandboxRefresher.deleteScheduledJob(JOBNAME);
        Test.stopTest();
 
        List<Contact> contactList = [SELECT Id, email
                                     FROM Contact
                                     WHERE Email like '%@email.com'];
        System.assertEquals(contactList.size(), 0);
        List<Lead> leadList = [SELECT Id, email
                               FROM Lead
                               WHERE Email like '%@email.com'];
        System.assertEquals(leadList.size(), 0);

        List<CronTrigger> crons = [SELECT Id, CronJobDetail.Name, CronExpression 
                                   FROM CronTrigger
                                   WHERE CronJobDetail.Name = :JOBNAME];
        System.assertEquals(crons.size(), 0);
    }

    static testMethod void testBatchUpdateFailure() {
        List<Lead> leadList = [SELECT Id, company
                               FROM Lead
                               WHERE Email like '%@email.com'];

        System.assertEquals(MessagingService.emailsSent, null);

        Test.startTest();
        for (Lead lead : leadList) {
            lead.company = null;
        }

        Database.executeBatch(new GenericBatchDMLOperation(leadList, 'Upsert'));

        Test.stopTest();

        System.assertEquals(MessagingService.emailsSent.size(), 1);
        System.debug(MessagingService.emailsSent);
    }
}
