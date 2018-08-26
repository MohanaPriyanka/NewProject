/**
 * Created By: Peter Yao
 * Description: Tests actions taken after refreshing a sandbox
 **/
@IsTest
private class PostSandboxRefresherTest {
    private static final String JOBNAME = 'Test Schedule';

    @TestSetup public static void setupTestData() {
        if (System_Properties__c.getall().isEmpty()) {
            insert new System_Properties__c(
                Name = 'System',
                DocuSign_Customer_Care_User__c = 'customercare@bluewavesolar.com'
            );
        }

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
        PostSandboxRefresher.updateDocusignToDemoConfig();
        Test.stopTest();
 
        List<Contact> contactList = [SELECT Id, Email
                                     FROM Contact
                                     WHERE Email LIKE '%@email.com'];
        System.assertEquals(contactList.size(), 0);
        List<Lead> leadList = [SELECT Id, Email
                               FROM Lead
                               WHERE Email LIKE '%@email.com'];
        System.assertEquals(leadList.size(), 0);

        List<CronTrigger> crons = [SELECT Id, CronJobDetail.Name, CronExpression 
                                   FROM CronTrigger
                                   WHERE CronJobDetail.Name = :JOBNAME];
        System.assertEquals(crons.size(), 0);

        List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
        System.assertEquals('pyao@bluewavesolar.com', systemProperties[0].DocuSign_Customer_Care_User__c);
    }

    static testMethod void testBatchUpdateFailure() {
        List<Lead> leadList = [SELECT Id, Company
                               FROM Lead
                               WHERE Email LIKE '%@email.com'];

        System.assertEquals(MessagingService.emailsSent, null);

        Test.startTest();
        for (Lead lead : leadList) {
            lead.Company = null;
        }

        Database.executeBatch(new GenericBatchDMLOperation(leadList, 'Upsert'));

        Test.stopTest();

        System.assertEquals(MessagingService.emailsSent.size(), 1);
        System.debug(MessagingService.emailsSent);
    }

    static testMethod void testBatchInsertFailures() {
        List<Lead> leadList = new List<Lead>();
        Lead lead = new Lead(FirstName = 'Test',
                             LastName = 'Tester');
        leadList.add(lead);

        System.assertEquals(null, MessagingService.emailsSent);

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());


        Test.startTest();

        Database.executeBatch(new GenericBatchDMLOperation(leadList, 'Insert'));

        Test.stopTest();

        System.assertEquals(MessagingService.emailsSent.size(), 1);
        System.debug(MessagingService.emailsSent);

        errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size());
    }

    @IsTest
    static void testAccountHelper() {
        PostSandboxRefresher.CSRecordLoader csRecordLoader = new PostSandboxRefresher.CSRecordLoader();
        csRecordLoader.execute(null);

        PostSandboxRefresher.SolarSystemHelper solarSystemHelper = new PostSandboxRefresher.SolarSystemHelper();
        solarSystemHelper.execute(null);

        Test.startTest();
        PostSandboxRefresher.FirstAccountHelper firstAccountHelper = new PostSandboxRefresher.FirstAccountHelper();
        firstAccountHelper.execute(null);

        PostSandboxRefresher.SecondAccountHelper SecondAccountHelper = new PostSandboxRefresher.SecondAccountHelper();
        SecondAccountHelper.execute(null);
        Test.stopTest();
    }

    @IsTest
    static void testProductionUpdateHelper() {
        PostSandboxRefresher.CSRecordLoader csRecordLoader = new PostSandboxRefresher.CSRecordLoader();
        csRecordLoader.execute(null);

        PostSandboxRefresher.SolarSystemHelper solarSystemHelper = new PostSandboxRefresher.SolarSystemHelper();
        solarSystemHelper.execute(null);

        Test.startTest();
        PostSandboxRefresher.ProductionUpdateHelper productionUpdateHelper = new PostSandboxRefresher.ProductionUpdateHelper();
        productionUpdateHelper.execute(null);

        PostSandboxRefresher.accountBillHelper accountBillHelper = new PostSandboxRefresher.accountBillHelper();
        accountBillHelper.execute(null);
        Test.stopTest();
    }

    @IsTest
    static void testPaymentHelper() {
        PostSandboxRefresher.CSRecordLoader csRecordLoader = new PostSandboxRefresher.CSRecordLoader();
        csRecordLoader.execute(null);

        PostSandboxRefresher.SolarSystemHelper solarSystemHelper = new PostSandboxRefresher.SolarSystemHelper();
        solarSystemHelper.execute(null);

        PostSandboxRefresher.GatewayHelper gatewayHelper = new PostSandboxRefresher.GatewayHelper();
        gatewayHelper.execute(null);

        Test.startTest();
        PostSandboxRefresher.paymentHelper paymentHelper = new PostSandboxRefresher.paymentHelper();
        paymentHelper.execute(null);
        Test.stopTest();
    }

    @IsTest
    static void testDeleteCSRecords() {
        PostSandboxRefresher.deleteCSRecords();
    }
}