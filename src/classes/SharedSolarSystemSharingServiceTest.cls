/**
 * Created by joeychan on 2020-01-31.
 */

@IsTest
private class SharedSolarSystemSharingServiceTest {
    @TestSetup
    static void setupData() {
        OpportunitiesSelectorTest.testSetup();
        Account parentAccount = new Account(
                Name = 'Parent Account 1'
        );
        Account parentAccount2 = new Account(
                Name = 'Parent Account 2'
        );
        insert new List<Account>{
                parentAccount, parentAccount2
        };

        Contact contact = new Contact(
                FirstName = 'Customer',
                LastName = 'Contact',
                Active_Communities_User__c = true,
                AccountId = parentAccount.Id,
                Email = 'test456@email.com'
        );

        Contact contact2 = new Contact(
                FirstName = 'Customer',
                LastName = 'Contact2',
                Active_Communities_User__c = true,
                AccountId = parentAccount.Id,
                Email = 'test789@email.com'
        );
        insert new List<Contact>{
                contact, contact2
        };
        insertUser(contact);
        insertUser(contact2);


        Account propertyAccount = new Account(
                Name = 'Property Account',
                Product_Line__c = 'Community Solar',
                Parent_Account__c = parentAccount.Id
        );

        insert propertyAccount;

        List<Shared_Solar_System__c> sssList = [SELECT Id, Name FROM Shared_Solar_System__c ORDER BY CreatedDate ASC LIMIT 2];

        Opportunity opp = new Opportunity(
                Name = 'NoAccess TestOpp',
                AccountId = propertyAccount.Id,
                Product_Line__c = 'Community Solar',
                Shared_Solar_System__c = sssList[0].Id,
                CloseDate = System.today(),
                StageName = 'QC in Progress'
        );


        Opportunity opp2 = new Opportunity(
                Name = 'Access TestOpp',
                AccountId = propertyAccount.Id,
                Product_Line__c = 'Community Solar',
                Shared_Solar_System__c = sssList[1].Id,
                CloseDate = System.today(),
                StageName = 'Complete'
        );

        insert new List<Opportunity>{
                opp, opp2
        };

        Account partnerAccount = new Account(
            Name = 'Test Partner Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        insert partnerAccount;

        Contact partnerContact = new Contact(
            AccountId = partnerAccount.Id,
            FirstName = 'Test',
            LastName = 'Partner',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner_Contact').getRecordTypeId()
        );
        insert partnerContact;

        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Partner Portal Community User'].Id,
            ContactId = partnerContact.Id,
            FirstName = 'Partner',
            LastName = 'Test',
            Email = 'test@gearscrm.test',
            Username = 'test@gearscrm.test' + System.currentTimeMillis(),
            CommunityNickname = 'pt',
            CompanyName = 'GearsCRM',
            Title = 'Tester',
            Alias = 'PSSSTest',
            TimeZoneSidKey = 'America/New_York',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert u;

    }

    private static User insertUser(Contact contact) {
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name = 'Community Solar Community User'];

        User userToInsert = new User(
                FirstName = contact.FirstName,
                LastName = contact.LastName,
                Alias = contact.FirstName.left(2) + contact.LastName.right(6),
                Email = contact.Email,
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Country = 'United States',
                IsActive = true,
                ContactId = contact.Id,
                ProfileId = profileRecord.Id,
                TimeZoneSidKey = 'America/New_York',
                Username = contact.Email,
                CommunityNickname = contact.FirstName.left(10) + contact.LastName.left(30)
        );

        Util.insertSObj(userToInsert);
        return userToInsert;
    }
    @IsTest
    private static void testUserActivation() {
        Account parentAccount = [SELECT Id FROM Account WHERE Name = 'Parent Account 1'];
        Contact newContact = new Contact(
                FirstName = 'Customer',
                LastName = 'Contact3',
                Active_Communities_User__c = true,
                AccountId = parentAccount.Id,
                Email = 'newContactTest@email.com'
        );
        insert newContact;

        Test.startTest();
        User newUser = insertUser(newContact);
        Portal_User_Activated__e portalUserActivatedEvent = new Portal_User_Activated__e(
                User_Id__c = newUser.Id
        );
        EventBus.publish(portalUserActivatedEvent);
        Test.stopTest();

        User customerUser = [SELECT Id, AccountId, ContactId FROM User WHERE Email = 'newContactTest@email.com' LIMIT 1];
        List<Shared_Solar_System__Share> sssShares = [
                SELECT Id, UserOrGroupId, ParentId, AccessLevel
                FROM Shared_Solar_System__Share
                WHERE UserOrGroupId = :customerUser.Id AND RowCause = 'Customer_Portal_Access__c'
        ];
        System.assertEquals(1, sssShares.size(), 'There should be one SSS Share for the newly created user');
        System.assertEquals('Read', sssShares[0].AccessLevel, 'Only read access should be added');
    }
    @IsTest
    private static void testEvaluateSharingViaProperties() {
        List<Shared_Solar_System__c> sssList = [SELECT Id, Name FROM Shared_Solar_System__c ORDER BY CreatedDate ASC LIMIT 2];
        Account propertyAccount = [SELECT Id FROM Account WHERE Name = 'Property Account' LIMIT 1];
        User customerUser = [SELECT Id, AccountId FROM User WHERE Email = 'test456@email.com' LIMIT 1];
        Test.startTest();

        SharedSolarSystemSharingService sssService = new SharedSolarSystemSharingService();
        sssService.evaluateSharingViaProperties(new List<Id>{
                propertyAccount.Id
        });
        Test.stopTest();

        List<Shared_Solar_System__Share> sssShares = [
                SELECT Id, UserOrGroupId, ParentId, AccessLevel
                FROM Shared_Solar_System__Share
                WHERE UserOrGroupId = :customerUser.Id AND RowCause = 'Customer_Portal_Access__c'
        ];
        System.assertEquals(1, sssShares.size(), 'There should be only one SSS Share');
        System.assertEquals(sssList[1].Id, sssShares[0].ParentId, 'The SSS Id should match');
        System.assertEquals(customerUser.Id, sssShares[0].UserOrGroupId, 'User Id should match');
        System.assertEquals('Read', sssShares[0].AccessLevel, 'Only read access should be added');
    }

    @IsTest
    private static void testEvaluateSharingViaMultipleUsers() {
        List<Shared_Solar_System__c> sssList = [SELECT Id, Name FROM Shared_Solar_System__c ORDER BY CreatedDate ASC LIMIT 2];
        List<Id> userIdList = new List<Id>();
        for (User user : [SELECT Id, AccountId FROM User WHERE Profile.Name = 'Community Solar Community User']) {
            userIdList.add(user.Id);
        }
        Test.startTest();
        SharedSolarSystemSharingService sssService = new SharedSolarSystemSharingService();
        sssService.evaluateSharingViaUsers(userIdList);
        Test.stopTest();

        List<Shared_Solar_System__Share> sssShares = [
                SELECT Id, UserOrGroupId, ParentId, AccessLevel
                FROM Shared_Solar_System__Share
                WHERE UserOrGroupId IN :userIdList AND RowCause = 'Customer_Portal_Access__c'
        ];
        System.assertEquals(2, sssShares.size(), 'There should be two SSS Shares');
        System.assertEquals(sssList[1].Id, sssShares[0].ParentId, 'The SSS Id should match');
        System.assertEquals('Read', sssShares[0].AccessLevel, 'Only read access should be added');
    }
    @IsTest
    private static void testEvaluateSharingViaOneUser() {
        List<Shared_Solar_System__c> sssList = [SELECT Id, Name FROM Shared_Solar_System__c ORDER BY CreatedDate ASC LIMIT 2];
        User customerUser = [SELECT Id, AccountId FROM User WHERE Email = 'test456@email.com' LIMIT 1];
        Test.startTest();
        SharedSolarSystemSharingService sssService = new SharedSolarSystemSharingService();
        sssService.evaluateSharingViaUsers(new List<Id>{
                customerUser.Id
        });
        Test.stopTest();

        List<Shared_Solar_System__Share> sssShares = [
                SELECT Id, UserOrGroupId, ParentId, AccessLevel
                FROM Shared_Solar_System__Share
                WHERE UserOrGroupId = :customerUser.Id AND RowCause = 'Customer_Portal_Access__c'
        ];

        System.assertEquals(1, sssShares.size(), 'There should be only one SSS Share');
        System.assertEquals(sssList[1].Id, sssShares[0].ParentId, 'The SSS Id should match');
        System.assertEquals(customerUser.Id, sssShares[0].UserOrGroupId, 'User Id should match');
        System.assertEquals('Read', sssShares[0].AccessLevel, 'Only read access should be added');
    }

    @IsTest
    private static void testTriggerAndEvent(){
        Account acct = [
            SELECT Id
            FROM Account
            WHERE Parent_Account__c != null
            LIMIT 1
        ];

        List<Shared_Solar_System__Share> beforeShares  = [
            SELECT Id, UserOrGroupId, ParentId, AccessLevel
            FROM Shared_Solar_System__Share
            WHERE RowCause = 'Customer_Portal_Access__c'
        ];
        System.assertEquals(0, beforeShares.size());

        Test.startTest();
            Subscription_Change_Event__e newEvent = new Subscription_Change_Event__e(
                Property_Account_Id__c = acct.Id
            );
            EventBus.publish(newEvent);
        Test.stopTest();

        List<Shared_Solar_System__Share> afterShares  = [
            SELECT Id, UserOrGroupId, ParentId, AccessLevel
            FROM Shared_Solar_System__Share
            WHERE RowCause = 'Customer_Portal_Access__c'
        ];
        System.assertEquals(2,afterShares.size());
    }

    @IsTest
    private static void testPartnerEligibilityAfterInsertUpdate() {
        Id partnerAccountId = [SELECT Id FROM Account WHERE Name = 'Test Partner Account' LIMIT 1].Id;
        Shared_Solar_System__c sharedSolarSystem = [SELECT Id, Product__c FROM Shared_Solar_System__c LIMIT 1];
        Id userId = [SELECT Id FROM User WHERE Alias = 'PSSSTest' LIMIT 1].Id;

        Commission_Structure__c commissionStructure = new Commission_Structure__c(
            Name = 'Test Commission Structure',
            Cents_kW_DC_First_Bill__c = 0.03,
            Cents_kW_DC_Up_Front__c = 0.08,
            Cents_kW_DC_First_Bill_Paid__c = 0.02,
            Partner_Account__c = partnerAccountId,
            Product__c = sharedSolarSystem.Product__c
        );

        insert commissionStructure;

        Partner_Shared_Solar_System_Eligibility__c partnerEligibility = new Partner_Shared_Solar_System_Eligibility__c (
            Account__c = partnerAccountId,
            Shared_Solar_System__c = sharedSolarSystem.Id,
            Active__c = true,
            Commission_Structure__c = commissionStructure.Id
        );

        insert partnerEligibility;

        List<Shared_Solar_System__Share> shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
        ];
        System.assertEquals(1, shares.size(), 'Expected 1 Shared_Solar_System__share record to be created');
        System.assertEquals(sharedSolarSystem.Id, shares[0].ParentId, 'Expected the Shared_Solar_System__share record to have a ParentId equal to the ID of the test Shared_Solar_System__c record');
        System.assertEquals(userId, shares[0].UserOrGroupId, 'Expected the Shared_Solar_System__share record to have a UserOrGroupId equal to the ID of the test User record');

        partnerEligibility.Active__c = false;
        update partnerEligibility;
        shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
        ];
        System.assertEquals(0, shares.size(), 'Expected to delete the share when active is set to false');

        partnerEligibility.Active__c = true;
        update partnerEligibility;
        shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
        ];
        System.assertEquals(1, shares.size(), 'Expected 1 Shared_Solar_System__share record to be created');
        System.assertEquals(sharedSolarSystem.Id, shares[0].ParentId, 'Expected the Shared_Solar_System__share record to have a ParentId equal to the ID of the test Shared_Solar_System__c record');
        System.assertEquals(userId, shares[0].UserOrGroupId, 'Expected the Shared_Solar_System__share record to have a UserOrGroupId equal to the ID of the test User record');
    }

    @IsTest
    private static void testPartnerEligibilityAfterDelete() {
        Id partnerAccountId = [SELECT Id FROM Account WHERE Name = 'Test Partner Account' LIMIT 1].Id;
        Shared_Solar_System__c sharedSolarSystem = [SELECT Id, Product__c FROM Shared_Solar_System__c LIMIT 1];
        Id userId = [SELECT Id FROM User WHERE Alias = 'PSSSTest' LIMIT 1].Id;

        Commission_Structure__c commissionStructure = new Commission_Structure__c(
            Name = 'Test Commission Structure',
            Cents_kW_DC_First_Bill__c = 0.03,
            Cents_kW_DC_Up_Front__c = 0.08,
            Cents_kW_DC_First_Bill_Paid__c = 0.02,
            Partner_Account__c = partnerAccountId,
            Product__c = sharedSolarSystem.Product__c
        );

        insert commissionStructure;

        Partner_Shared_Solar_System_Eligibility__c partnerEligibility = new Partner_Shared_Solar_System_Eligibility__c (
            Account__c = partnerAccountId,
            Shared_Solar_System__c = sharedSolarSystem.Id,
            Active__c = true,
            Commission_Structure__c = commissionStructure.Id
        );
        insert partnerEligibility;

        List<Shared_Solar_System__Share> shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
        ];
        System.assertEquals(1, shares.size(), 'Expected 1 Shared_Solar_System__share record to be created');
        System.assertEquals(sharedSolarSystem.Id, shares[0].ParentId, 'Expected the Shared_Solar_System__share record to have a ParentId equal to the ID of the test Shared_Solar_System__c record');
        System.assertEquals(userId, shares[0].UserOrGroupId, 'Expected the Shared_Solar_System__share record to have a UserOrGroupId equal to the ID of the test User record');

        Test.startTest();
        delete partnerEligibility;
        Test.stopTest();

        shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
        ];
        System.assertEquals(0, shares.size(), 'Expected no Shared_Solar_System__share records to exist');
    }
}