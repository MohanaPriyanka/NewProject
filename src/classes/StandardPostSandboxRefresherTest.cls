/**
 * Created by PeterYao on 5/2/2021.
 */
@IsTest
private class StandardPostSandboxRefresherTest {
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
                DocuSign_Customer_Care_User__c = 'customercare@bluewavesolar.com'
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
            Name = 'BlueWave SMART',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SMART - Community Solar',
            Customer_Subscription_Type__c = 'kWh',
            State__c = 'MA',
            ProductCode = 'CS-MA-7',
            IsActive = true,
            zqu__SKU__c = '1234',
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Credit_Minimum__c = '200',
            Monthly_Late_Fee__c = 1,
            Cancellation_Paragraph_Two__c = '<br>Per Massachusetts utility and state regulations, project capacity ' +
                'allocation forms can only be filed up to two times per year; therefore, it may take up to six ' +
                'months for your subscription to stop receiving solar credits. During this time, you will remain ' +
                'responsible for paying for all solar credits transferred to your account. Once the utility removes ' +
                'your subscription, we will notify you via email.</br>'
        );
        Product2 normalSRECProduct = new Product2(
            Name = 'BlueWave SREC',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            State__c = 'MA',
            ProductCode = 'CS-MA-8',
            IsActive = true,
            zqu__SKU__c = '5678',
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Credit_Minimum__c = '200',
            Monthly_Late_Fee__c = 1,
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
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        systemProperties[0].Last_Lease_Dimensions_File_Processed__c = 'LetterStream';
        update systemProperties;
        Test.startTest();
        new StandardPostSandboxRefresher().runApexClass(null);
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
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        systemProperties[0].Last_Lease_Dimensions_File_Processed__c = 'DocuSign';
        update systemProperties;

        Test.startTest();
        try {
            new StandardPostSandboxRefresher().runApexClass(null);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Don\'t update DocuSign'), 'Do not need to update Docusign Config for test');
        }
        Test.stopTest();
    }

    @IsTest
    static void testPartnerSetup() {
        StandardPostSandboxRefresher.setupBWTestPartner();
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
        Profile bfgStandardUserProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'BFG Standard User'
        ];
        Profile systemAdminProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
        ];
        Profile bwTechnologyProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'BW Technology'
        ];
        List<User> users = new List<User>();
        User bfgStandardUser = new User(
            Alias = 'bfgsu',
            Email = 'testUtil@test.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'testUtil',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = bfgStandardUserProfile.Id,
            Country = 'United States',
            IsActive = true,
            TimeZoneSidKey = 'America/New_York',
            Username = 'bfgstandarduser@test.test'
        );
        users.add(bfgStandardUser);
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
        User bwTechnologyUser = new User(
            Alias = 'bwTech',
            Email = 'testUtil@test.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'testUtil',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = bwTechnologyProfile.Id,
            Country = 'United States',
            IsActive = true,
            TimeZoneSidKey = 'America/New_York',
            Username = 'bwTechnology@test.test'
        );
        users.add(bwTechnologyUser);
        insert users;
        // RunAs to get a new context to avoid
        // MIXED_DML_OPERATION, DML operation on setup object is not permitted after you have updated a non-setup object
        // (or vice versa): User, original object: MPM4_BASE__Milestone1_Resource__c
        User currentUser = [SELECT Id FROM User WHERE Id = :systemAdminUser.Id];
        System.runAs(currentUser) {
            Test.startTest();
            StandardPostSandboxRefresher psr = new StandardPostSandboxRefresher();
            psr.schedulePostSandboxJob();
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
                    System.assertEquals(bfgStandardUserProfile.Id, user.ProfileId, 'Should not have updated a non-BW Technology user');
                } when 'sysAdmin' {
                    System.assertEquals(systemAdminProfile.Id, user.ProfileId, 'Should not have updated a non-BW Technology user');
                } when 'bwTech' {
                    System.assertEquals(systemAdminProfile.Id, user.ProfileId, 'Should have updated BW Technology user to System Admin');
                } when else {
                    System.assert(false, 'Found an unexpected user: ' + user);
                }
            }
        }
        users = [
            SELECT Id, Alias, ProfileId
            FROM User
            WHERE Profile.Name = 'BW Technology'
            AND IsActive = TRUE
        ];
        System.assertEquals(0, users.size(), 'Expected to have updated all BW Technology users to System Admins');
    }
}