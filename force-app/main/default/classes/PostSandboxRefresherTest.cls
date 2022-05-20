/**
 * @description Tests actions taken after refreshing a sandbox to load in test data
 *  Created By: Peter Yao
 **/
@IsTest
private class PostSandboxRefresherTest {
    @TestSetup
    public static void setupTestData() {
        insert new BW_Address__c(
            Name = 'Perch', Address_Line_One__c = '137 Newbury Street 4th Floor',
            Address_Line_Two__c = 'Boston, MA 02114'
        );
        TestFactory.setCSBillSettings();
        Test.startTest();
        Test.loadData(Utility__c.SObjectType, 'TestCSUtility');
        Test.loadData(Utility_NMC_Tariff__c.SObjectType, 'TestCSUtilityNMCTariff');
        Test.loadData(Load_U__c.SObjectType, 'TestCSLoadU');
        Test.loadData(Contact.SObjectType, 'TestCSContact');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Test.loadData(Entity__c.SObjectType, 'TestCSEntity');
        Test.loadData(Shared_Solar_System__c.SObjectType, 'TestCSSharedSolarSystem');
        Test.loadData(Partner__c.SObjectType, 'TestRLPartner');
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Test.stopTest();
        if (System_Properties__c.getall().isEmpty()) {
            insert new System_Properties__c(
                Name = 'System',
                DocuSign_Customer_Care_User__c = 'customercare@perchenergy.com'
            );
        }
        Account testAcct = new Account(Name = 'Test');
        insert testAcct;
        List<Contact> contactList = new List<Contact>();
        List<Lead> leadList = new List<Lead>();
        for (Integer i = 0; i < 2; i++) {
            Contact c = new Contact(FirstName = 'test',
                LastName = 'testerson',
                Email = 'ttesterson' + i + '@email.com',
                Account = testAcct);
            contactList.add(c);
            Lead l = new Lead(FirstName = 'test',
                LastName = 'testerson',
                Company = 'test',
                Email = 'ttesterson' + i + '@email.com');
            leadList.add(l);
        }
        insert contactList;
        insert leadList;
        Product2 normalCSProduct = new Product2(
            Name = 'Perch SMART',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SMART - Community Solar',
            Customer_Subscription_Type__c = 'kWh',
            State__c = 'MA',
            ProductCode = 'CS-MA-7',
            IsActive = true,
            zqu__SKU__c = '1234',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Cancellation_Paragraph_Two__c = '<br>Per Massachusetts utility and state regulations, project capacity ' +
                'allocation forms can only be filed up to two times per year; therefore, it may take up to six ' +
                'months for your subscription to stop receiving solar credits. During this time, you will remain ' +
                'responsible for paying for all solar credits transferred to your account. Once the utility removes ' +
                'your subscription, we will notify you via email.</br>'
        );
        Product2 normalSRECProduct = new Product2(
            Name = 'Perch SREC',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            State__c = 'MA',
            ProductCode = 'CS-MA-8',
            IsActive = true,
            zqu__SKU__c = '5678',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Cancellation_Paragraph_Two__c = '<br>Per Massachusetts utility and state regulations, project capacity ' +
                'allocation forms can only be filed up to two times per year; therefore, it may take up to six ' +
                'months for your subscription to stop receiving solar credits. During this time, you will remain ' +
                'responsible for paying for all solar credits transferred to your account. Once the utility removes ' +
                'your subscription, we will notify you via email.</br>',
            Cancellation_Paragraph_Three__c = '<i><br>Please note, per the terms of your contract, you may be charged ' +
                'an early termination fee to cancel your community solar subscription, unless you provide a replacement ' +
                'customer. Please refer to your contract for more details.</br></i>'
        );
        insert new List<Product2>{
            normalCSProduct,
            normalSRECProduct
        };
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
        CSRecordLoader.updateLetterStreamToTestConfig();
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
    @IsTest
    static void testSandboxRefresh() {
        Test.startTest();
        try {
            CSRecordLoader.updateDocusignToDemoConfig();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Don\'t update DocuSign'), 'Do not need to update Docusign Config for test');
        }
        Test.stopTest();
    }
    @IsTest
    static void testAccountHelper() {
        CSRecordLoader.CSDataSetting csDataSetting = new CSRecordLoader.CSDataSetting(24);
        CSRecordLoader csRecordLoader = new CSRecordLoader(csDataSetting);
        csRecordLoader.execute((QueueableContext) null);
        CSRecordLoader.SolarSystemHelper solarSystemHelper = new CSRecordLoader.SolarSystemHelper(csDataSetting);
        solarSystemHelper.execute((QueueableContext) null);
        Test.startTest();
        CSRecordLoader.FirstAccountHelper firstAccountHelper = new CSRecordLoader.FirstAccountHelper(csDataSetting);
        System.enqueueJob(firstAccountHelper);
        Test.stopTest();
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity WHERE Product_Line__c != 'Community Solar'];
        System.assert(opportunities.size() > 0, 'There should be opportunities created with Product Line of Community Solar');
    }
    @IsTest
    static void testSecondAccountHelper() {
        CSRecordLoader.CSDataSetting csDataSetting = new CSRecordLoader.CSDataSetting(24);
        CSRecordLoader csRecordLoader = new CSRecordLoader(csDataSetting);
        csRecordLoader.execute((QueueableContext) null);
        CSRecordLoader.SolarSystemHelper solarSystemHelper = new CSRecordLoader.SolarSystemHelper(csDataSetting);
        solarSystemHelper.execute((QueueableContext) null);
        Test.startTest();
        CSRecordLoader.SecondAccountHelper secondAccountHelper = new CSRecordLoader.SecondAccountHelper(csDataSetting);
        System.enqueueJob(secondAccountHelper);
        Test.stopTest();
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity WHERE Product_Line__c != 'Community Solar'];
        System.assert(opportunities.size() > 0, 'There should be opportunities created with Product Line of Community Solar');
    }
    @IsTest
    static void testTransferHelper() {
        CSRecordLoader.CSDataSetting csDataSetting = new CSRecordLoader.CSDataSetting(24);
        CSRecordLoader csRecordLoader = new CSRecordLoader(csDataSetting);
        csRecordLoader.execute((QueueableContext) null);
        CSRecordLoader.SolarSystemHelper solarSystemHelper = new CSRecordLoader.SolarSystemHelper(csDataSetting);
        solarSystemHelper.execute((QueueableContext) null);
        Test.startTest();
        try {
            CSRecordLoader.TransferHelper transferHelper = new CSRecordLoader.TransferHelper(csDataSetting);
            transferHelper.execute(null);
        } catch (Exception e) {
            System.assert(false, e.getMessage() + e.getStackTraceString());
        }
        Test.stopTest();
        try {
            CSRecordLoader.TransferHelper2 transferHelper2 = new CSRecordLoader.TransferHelper2(csDataSetting);
            transferHelper2.execute(null);
        } catch (Exception e) {
            System.assert(false, e.getMessage() + e.getStackTraceString());
        }
        try {
            CSRecordLoader.TransferHelper3 transferHelper3 = new CSRecordLoader.TransferHelper3(csDataSetting);
            transferHelper3.execute(null);
        } catch (Exception e) {
            System.assert(false, e.getMessage() + e.getStackTraceString());
        }
    }
    @IsTest
    static void testDeleteCSRecords() {
        CSRecordLoader.CustomerName fooBar = new CSRecordLoader.CustomerName('Foo', 'Bar', 1);
        CSRecordLoader.insertAccountsAndContacts(new List<CSRecordLoader.CustomerName>{
            fooBar
        });
        List<Account> accounts = [SELECT Id FROM Account WHERE CreatedDate = :CSRecordLoader.csDataDate];
        System.assertEquals(2, accounts.size(), 'Expected two accounts to be created, parent and property');
        CSRecordLoader.deleteCSRecords();
        accounts = [SELECT Id FROM Account WHERE CreatedDate = :CSRecordLoader.csDataDate];
        System.assertEquals(0, accounts.size(), 'deleteCSRecords should have deleted the accounts that were created');
    }
    @IsTest
    static void testPartnerSetup() {
        CSRecordLoader.setupBWTestPartner();
        List<Partner__c> partners = [
            SELECT Id, Name
            FROM Partner__c
            WHERE Name = 'Solar Test Partner'
        ];
        System.assertEquals(1, partners.size());
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
    private static void testSetSystemAdmins() {
        Profile perchStandardUserProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Perch Standard'
        ];
        Profile systemAdminProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
        ];
        PermissionSet editAll = [SELECT Id FROM PermissionSet WHERE Name = 'Edit_All'];
        List<User> users = new List<User>();
        User perchStandardUser = new User(
            Alias = 'bfgsu',
            Email = 'testUtil@test.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'testUtil',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = perchStandardUserProfile.Id,
            Country = 'United States',
            IsActive = true,
            TimeZoneSidKey = 'America/New_York',
            Username = 'perchstandarduser@test.test'
        );
        users.add(perchStandardUser);
        User systemAdminUser = new User(
            Alias = 'sysAdmin',
            Email = 'testUtil@test.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'testUtil',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = systemAdminProfile.Id,
            Country = 'United States',
            IsActive = true,
            TimeZoneSidKey = 'America/New_York',
            Username = 'systemadmin@test.test'
        );
        users.add(systemAdminUser);
        User bizAppsUser = new User(
            Alias = 'bwTech',
            Email = 'testUtil@test.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'testUtil',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = perchStandardUserProfile.Id,
            Country = 'United States',
            IsActive = true,
            TimeZoneSidKey = 'America/New_York',
            Username = 'bwTechnology@test.test'
        );
        users.add(bizAppsUser);
        insert users;
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = bizAppsUser.Id,
            PermissionSetId = editAll.Id
        );
        insert psa;
        // RunAs to get a new context to avoid
        // MIXED_DML_OPERATION, DML operation on setup object is not permitted after you have updated a non-setup object
        // (or vice versa): User, original object: MPM4_BASE__Milestone1_Resource__c
        User currentUser = [SELECT Id FROM User WHERE Id = :systemAdminUser.Id];
        System.runAs(currentUser) {
            Test.startTest();
            new PostSandboxRefresher().runApexClass(null);
            Test.stopTest();
        }
        users = [
            SELECT Id, Alias, ProfileId
            FROM User
            WHERE Id IN :users
        ];
        System.assertEquals(3, users.size(), 'Expected to find three users that the test inserted');
        for (User user : users) {
            switch on user.Alias {
                when 'bfgsu' {
                    System.assertEquals(perchStandardUserProfile.Id, user.ProfileId, 'Should not have updated a non-BW Technology user');
                } when 'sysAdmin' {
                    System.assertEquals(systemAdminProfile.Id, user.ProfileId, 'Should not have updated a non-BW Technology user');
                } when 'bwTech' {
                    System.assertEquals(systemAdminProfile.Id, user.ProfileId, 'Should have updated BW Technology user to System Admin');
                } when else {
                    System.assert(false, 'Found an unexpected user: ' + user);
                }
            }
        }
        List<PermissionSetAssignment> permissionSetAssignments = [
            SELECT Id, AssigneeId, Assignee.Profile.Name, Assignee.Name
            FROM PermissionSetAssignment
            WHERE PermissionSet.Name = 'Edit_All'
        ];
        for (PermissionSetAssignment permissionSetAssignment : permissionSetAssignments) {
            System.assertEquals('System Administrator', permissionSetAssignment.Assignee.Profile.Name, permissionSetAssignment.Assignee.Name);
        }
    }
}
