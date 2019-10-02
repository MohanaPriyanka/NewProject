/*************************************************************************************
 * Created By: Peter Yao
 * Description: Tests actions taken after refreshing a sandbox to load in test data
 *************************************************************************************/
@IsTest
private class PostSandboxRefresherTest {
    private static final String JOBNAME = 'Test Schedule';

    @TestSetup public static void setupTestData() {
        insert new BW_Address__c(
            Name = 'BlueWave', Address_Line_One__c = '137 Newbury Street 4th Floor',
            Address_Line_Two__c = 'Boston, MA 02114'
        );
        TestFactory.setCSBillSettings();
        Test.startTest();
        Test.loadData(Utility__c.SObjectType, 'TestCSUtility');
        Test.loadData(Utility_NMC_Tariff__c.SObjectType, 'TestCSUtilityNMCTariff');
        Test.loadData(Load_U__c.SObjectType, 'TestCSLoadU');
        Test.loadData(ChargentBase__Gateway__c.SObjectType, 'TestCSGateway');
        Test.loadData(Contact.SObjectType, 'TestCSContact');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Test.loadData(Entity__c.SObjectType, 'TestCSEntity');
        Test.loadData(Shared_Solar_System__c.SObjectType, 'TestCSSharedSolarSystem');
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Test.loadData(Account_Bill__c.SObjectType, 'TestCSAccountBill');
        Test.stopTest();
        Test.loadData(ChargentOrders__ChargentOrder__c.SObjectType, 'TestCSChargentOrder');


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

    @IsTest
    static public void testLetterStreamSetup() {
        if (LetterStream_Settings__c.getAll().isEmpty()) {
            insert new LetterStream_Settings__c(
                Name = 'Global Settings',
                API_Endpoint__c = 'https://secure.letterstream.com/apis/',
                API_Id__c = 'production',
                API_Key__c = 'productionKey'
            );
        }

        Test.startTest();
        PostSandboxRefresher.updateLetterStreamToTestConfig();
        Test.stopTest();

        List<LetterStream_Settings__c> letterStreamSettings = [
            SELECT Id, Name, API_Id__c, API_Key__c
            FROM LetterStream_Settings__c
        ];

        System.assertEquals(1, letterStreamSettings.size());
        System.assertNotEquals('production', letterStreamSettings[0].API_Id__c);
        System.assertNotEquals('productionKey', letterStreamSettings[0].API_Key__c);
        System.assert(letterStreamSettings[0].API_Id__c.contains('test'));
        System.assert(letterStreamSettings[0].API_Key__c.contains('test'));
        System.assertEquals('Test Config', letterStreamSettings[0].Name);
    }

    static testMethod void testSandboxRefresh() {
        List<ChargentBase__Gateway__c> gateways = [
            SELECT Id, ChargentBase__Merchant_ID__c
            FROM ChargentBase__Gateway__c
            WHERE Name LIKE 'Test%'
        ];
        System.assertEquals(0, gateways.size(), 'Did not expect to load test gateways');

        List<ChargentOrders__ChargentOrder__c> chargentOrders = [
            SELECT Id
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Card_Type__c = 'American Express'
        ];
        System.assertEquals(0, chargentOrders.size(), 'Did not expect to load Amex orders');

        Test.startTest();
        PostSandboxRefresher.disableEmails();
        PostSandboxRefresher.deleteScheduledJob(JOBNAME);
        PostSandboxRefresher.updateDocusignToDemoConfig();
        PostSandboxRefresher.switchChargentToTestMode();
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

        gateways = [
            SELECT Id, ChargentBase__Merchant_ID__c
            FROM ChargentBase__Gateway__c
            WHERE Name LIKE 'Test%'
        ];
        // The two loaded gateways should be Test
        System.assertEquals(2, gateways.size());

        chargentOrders = [
            SELECT Id, ChargentOrders__Billing_Last_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Card_Type__c != 'American Express'
            AND (NOT ChargentOrders__Billing_Last_Name__c LIKE '%CaseCreation%')
            AND (NOT ChargentOrders__Billing_Last_Name__c LIKE '%AutoEmailer%')
        ];
        // All loaded orders should be Amex now
        System.assertEquals(0, chargentOrders.size());
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
        PostSandboxRefresher.CSDataSetting csDataSetting = new PostSandboxRefresher.CSDataSetting(24);
        PostSandboxRefresher.CSRecordLoader csRecordLoader = new PostSandboxRefresher.CSRecordLoader(csDataSetting);
        csRecordLoader.execute(null);

        PostSandboxRefresher.SolarSystemHelper solarSystemHelper = new PostSandboxRefresher.SolarSystemHelper(csDataSetting);
        solarSystemHelper.execute(null);

        Test.startTest();
        PostSandboxRefresher.FirstAccountHelper firstAccountHelper = new PostSandboxRefresher.FirstAccountHelper(csDataSetting);
        firstAccountHelper.execute(null);
        Test.stopTest();

        List<Opportunity> opportunities = [SELECT Id FROM Opportunity WHERE Product_Line__c != 'Community Solar'];
        System.assert(opportunities.size() > 0, 'There should be opportunities created with Product Line of Community Solar');
    }

    @IsTest
    static void testSecondAccountHelper() {
        PostSandboxRefresher.CSDataSetting csDataSetting = new PostSandboxRefresher.CSDataSetting(24);
        PostSandboxRefresher.CSRecordLoader csRecordLoader = new PostSandboxRefresher.CSRecordLoader(csDataSetting);
        csRecordLoader.execute(null);

        PostSandboxRefresher.SolarSystemHelper solarSystemHelper = new PostSandboxRefresher.SolarSystemHelper(csDataSetting);
        solarSystemHelper.execute(null);

        Test.startTest();
        PostSandboxRefresher.SecondAccountHelper SecondAccountHelper = new PostSandboxRefresher.SecondAccountHelper(csDataSetting);
        SecondAccountHelper.execute(null);
        Test.stopTest();

        List<Opportunity> opportunities = [SELECT Id FROM Opportunity WHERE Product_Line__c != 'Community Solar'];
        System.assert(opportunities.size() > 0, 'There should be opportunities created with Product Line of Community Solar');
    }

    @IsTest
    static void testProductionUpdateHelper() {
        PostSandboxRefresher.CSDataSetting csDataSetting = new PostSandboxRefresher.CSDataSetting(24);
        PostSandboxRefresher.CSRecordLoader csRecordLoader = new PostSandboxRefresher.CSRecordLoader(csDataSetting);
        csRecordLoader.execute(null);

        PostSandboxRefresher.SolarSystemHelper solarSystemHelper = new PostSandboxRefresher.SolarSystemHelper(csDataSetting);
        solarSystemHelper.execute(null);

        Test.startTest();
        PostSandboxRefresher.ProductionUpdateHelper productionUpdateHelper = new PostSandboxRefresher.ProductionUpdateHelper(csDataSetting);
        productionUpdateHelper.execute(null);
        PostSandboxRefresher.ProductionUpdateHelper2 productionUpdateHelper2 = new PostSandboxRefresher.ProductionUpdateHelper2(csDataSetting);
        productionUpdateHelper2.execute(null);
        PostSandboxRefresher.ProductionUpdateHelper3 productionUpdateHelper3 = new PostSandboxRefresher.ProductionUpdateHelper3(csDataSetting);
        productionUpdateHelper3.execute(null);

        Test.stopTest();
    }

    @IsTest
    static void testPaymentHelper() {
        PostSandboxRefresher.CSDataSetting csDataSetting = new PostSandboxRefresher.CSDataSetting(24);
        PostSandboxRefresher.CSRecordLoader csRecordLoader = new PostSandboxRefresher.CSRecordLoader(csDataSetting);
        csRecordLoader.execute(null);

        PostSandboxRefresher.SolarSystemHelper solarSystemHelper = new PostSandboxRefresher.SolarSystemHelper(csDataSetting);
        solarSystemHelper.execute(null);

        PostSandboxRefresher.GatewayHelper gatewayHelper = new PostSandboxRefresher.GatewayHelper(csDataSetting);
        gatewayHelper.execute(null);

        Test.startTest();
        PostSandboxRefresher.paymentHelper paymentHelper = new PostSandboxRefresher.paymentHelper(csDataSetting);
        paymentHelper.execute(null);
        Test.stopTest();
    }

    @IsTest
    static void testDeleteCSRecords() {
        PostSandboxRefresher.deleteCSRecords();
    }

    @IsTest
    static void testPartnerSetup() {
        PostSandboxRefresher.setupBWTestPartner();

        List<Partner__c> partners = [
            SELECT Id, Name
            FROM Partner__c
        ];

        System.assertEquals(1, partners.size());
        System.assertEquals('BlueWave Test Partner', partners[0].Name);

        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        System.assertNotEquals(null, systemProperties[0].Default_CS_Partner__c);

        List<Contact> partnerContacts = [
            SELECT Id, Name
            FROM Contact
            WHERE Partner_Lookup__c = :partners[0].Id
        ];

        System.assertEquals(2, partnerContacts.size());

        List<Account> partnerAccounts = [
            SELECT Id, Name
            FROM Account
            WHERE Partner__c = :partners[0].Id
        ];

        System.assertEquals(1, partnerAccounts.size());
    }
    @IsTest
    static void testDataSetupForReportTest() {
        PostSandboxRefresher.setupDataForReportTest();
        List<Lead> leads = [SELECT Id FROM Lead WHERE LastName = 'TestLightningReports'];
        // Should be one lead set up by the setup method
        System.assertEquals(1, leads.size());
    }

    @IsTest
    static void testGenericBatchDMLTriggerOff() {
        List<Error_Log__c> triggerOffWarning = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'BillingAccountTrigger'
            AND Method__c = 'TriggerDisabled'
        ];

        System.assertEquals(0,triggerOffWarning.size());

        Account newSFAccountOne = new Account(
            Name = 'Account One',
            Recurring_Billing__c = false
        );
        Account newSFAccountTwo = new Account(
            Name = 'Account Two',
            Recurring_Billing__c = false
        );

        insert new List<Account>{newSFAccountOne, newSFAccountTwo};

        Zuora__CustomerAccount__c newZuoraAccountOne = new Zuora__CustomerAccount__c(
            Name = 'Account Name',
            Zuora__Account__c = newSFAccountOne.Id,
            Zuora__Zuora_Id__c = '222222222222222222222',
            Zuora__AutoPay__c = false
        );
        Zuora__CustomerAccount__c newZuoraAccountTwo = new Zuora__CustomerAccount__c(
            Name = 'Account Name',
            Zuora__Account__c = newSFAccountTwo.Id,
            Zuora__Zuora_Id__c = '333333333333333333333',
            Zuora__AutoPay__c = false
        );

        List<Zuora__CustomerAccount__c> zAccounts = new List<Zuora__CustomerAccount__c>{newZuoraAccountOne, newZuoraAccountTwo};
        insert zAccounts;

        newZuoraAccountOne.Zuora__AutoPay__c = true;
        newZuoraAccountTwo.Zuora__AutoPay__c = true;

        Test.startTest();
            GenericBatchDMLOperation batchDML = new GenericBatchDMLOperation(zAccounts, 'Update');
            batchDML.triggersToDisable = new List<String>{
                'Disable_Billing_Account_Trigger__c',
                'Disable_AccountTrigger__c'
            };
            Database.executeBatch(batchDML);
        Test.stopTest();

        List<Zuora__CustomerAccount__c> billingAccounts = [
            SELECT Id, Zuora__AutoPay__c
            FROM Zuora__CustomerAccount__c
            WHERE Id = : newZuoraAccountOne.Id
            OR Id = : newZuoraAccountTwo.Id
        ];

        System.assertEquals(true,billingAccounts[0].Zuora__AutoPay__c);
        System.assertEquals(true,billingAccounts[0].Zuora__AutoPay__c);

        List<Error_Log__c> updatedTriggerOffWarning = [
            SELECT Id, Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraBillingAccountTrigger'
            AND Method__c = 'TriggerDisabled'
        ];
        System.assertEquals(1,updatedTriggerOffWarning.size());
    }
}