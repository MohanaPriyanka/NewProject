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

        Opportunity opp3 = new Opportunity(
            Name = 'Access TestOpp',
            AccountId = propertyAccount.Id,
            Product_Line__c = 'Community Solar',
            Shared_Solar_System__c = sssList[1].Id,
            CloseDate = System.today(),
            StageName = 'Complete'
        );


        insert new List<Opportunity>{
                opp, opp2, opp3
        };

        Account partnerAccount = new Account(
            Name = 'Test Partner Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        Account partnerAccount2 = new Account(
            Name = 'Test Partner Account 2',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        insert new List<Account>{partnerAccount, partnerAccount2};

        Contact partnerContact = new Contact(
            AccountId = partnerAccount.Id,
            FirstName = 'Test',
            LastName = 'Partner',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner_Contact').getRecordTypeId()
        );
        Contact partnerContact2 = new Contact(
            AccountId = partnerAccount2.Id,
            FirstName = 'Test',
            LastName = 'Partner',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner_Contact').getRecordTypeId()
        );
        insert new List<Contact>{partnerContact, partnerContact2};

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
            Alias = 'PSSS',
            TimeZoneSidKey = 'America/New_York',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        User u2 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Partner Portal Community User'].Id,
            ContactId = partnerContact2.Id,
            FirstName = 'Partner',
            LastName = 'Test2',
            Email = 'test@gearscrm.test',
            Username = 'test2@gearscrm.test' + System.currentTimeMillis(),
            CommunityNickname = 'pt2',
            CompanyName = 'GearsCRM',
            Title = 'Tester',
            Alias = 'PSSS2',
            TimeZoneSidKey = 'America/New_York',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert new List<User>{u, u2};

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

        List<Error_Log__c> errorLogs = [
            SELECT Class__c, Method__c, Message__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR
        ];
        System.assertEquals(0, errorLogs.size(),
            'Expected no errors when creating shares, but found this: ' + errorLogs);
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
    private static void testPartnerEligibilityAfterInsert() {
        Id partnerAccountId = [SELECT Id FROM Account WHERE Name = 'Test Partner Account' LIMIT 1].Id;
        Shared_Solar_System__c sharedSolarSystem = [SELECT Id, Product__c FROM Shared_Solar_System__c LIMIT 1];
        Id userId = [SELECT Id FROM User WHERE Alias = 'PSSS' LIMIT 1].Id;

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
            Commission_Structure__c = commissionStructure.Id,
            Start_Date__c = Date.newInstance(2020,1,1)
        );

        insert partnerEligibility;

        List<Shared_Solar_System__Share> shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
        ];
        System.assertEquals(1, shares.size(), 'Expected 1 Shared_Solar_System__share record to be created');
        System.assertEquals(sharedSolarSystem.Id, shares[0].ParentId, 'Expected the Shared_Solar_System__share record to have a ParentId equal to the ID of the test Shared_Solar_System__c record');
        System.assertEquals(userId, shares[0].UserOrGroupId, 'Expected the Shared_Solar_System__share record to have a UserOrGroupId equal to the ID of the test User record');
    }

    @IsTest
    private static void testUnsharingPartnerEligibilities() {
        List<Partner_Shared_Solar_System_Eligibility__c> eligibilities = setupTwoAccountsAndTwoSystems(Date.newInstance(2020,1,1), null);
        // To reproduce a previous bug, we should make sure that we delete the shares for the account/system combination,
        // not all shares for all accounts and systems. If, we have shares for:
        // Partner A, System A
        // Partner A, System B
        // Partner B, System A
        // Partner B, System B
        // If Partner A/System A and Partner B/System B become unshared, we shouldn't unshare Partner A/System B and
        // Parnter B/System A.
        System.assertNotEquals(eligibilities[0].Account__c, eligibilities[3].Account__c,
            'The first and last eligibility should have a different account');
        System.assertNotEquals(eligibilities[0].Shared_Solar_System__c, eligibilities[3].Shared_Solar_System__c,
            'The first and last eligibility should have a different system');

        List<Shared_Solar_System__Share> shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
            ORDER BY ParentId
        ];
        System.assertEquals(4, shares.size(), 'Expected to create four Shared_Solar_System__share records, for two accounts and two systems');
        Test.startTest();
        new SharedSolarSystemSharingService().unshareSharedSolarSystems(new List<Partner_Shared_Solar_System_Eligibility__c>{eligibilities[0], eligibilities[3]});
        Test.stopTest();

        shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
        ];
        System.assertEquals(2, shares.size(), 'Expected two Shared_Solar_System__share records left after deleting two eligibilities');
    }

    @IsTest
    private static void sharingSchedulerShouldCreateShares() {
        Util.disableTrigger('Disable_PartnerSSSEligibilityTrigger__c');
        setupTwoAccountsAndTwoSystems(Date.today(), null);
        Util.enableTrigger('Disable_PartnerSSSEligibilityTrigger__c');

        List<Shared_Solar_System__Share> shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
            ORDER BY ParentId
        ];
        System.assertEquals(0, shares.size(), 'Expected no shares because the trigger was off during eligibility creation');

        Test.startTest();
        System.schedule('Test Sharing Schedule', '0 0 13 * * ?', new SharedSolarSystemSharingScheduler());
        Test.stopTest();

        shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
            ORDER BY ParentId
        ];
        System.assertEquals(4, shares.size(), 'Expected four shares after the schedule runs');

    }

    @IsTest
    private static void sharingSchedulerShouldRemoveShares() {
        // We're saying yesterday is really today, so that setup creates shares
        Date yesterday = Date.today();
        List<Partner_Shared_Solar_System_Eligibility__c> eligibilities =
            setupTwoAccountsAndTwoSystems(Date.today()-30, yesterday);

        List<Shared_Solar_System__Share> shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
            ORDER BY ParentId
        ];
        System.assertEquals(4, shares.size(), 'Expected setup to create four shares');

        try {
            delete eligibilities;
            System.assert(false, 'Expected to prevent deleting the active eligibilities');
        } catch (DmlException dmlException) {
            System.assert(dmlException.getMessage().contains('You cannot delete'), dmlException.getMessage());
        }

        Test.startTest();
        // Simulates the scheduler daily.
        new SharedSolarSystemSharingScheduler().changeSharesForRecentEligibilityRecords(yesterday-1, yesterday);
        Test.stopTest();

        shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
            ORDER BY ParentId
        ];
        System.assertEquals(0, shares.size(), 'Expected to remove all shares after the schedule runs');
    }

    @IsTest
    private static void sharingSchedulerShouldRemoveThenAddShares() {
        Date today = Date.today();

        List<Account> partnerAccounts = [SELECT Id FROM Account WHERE Name LIKE 'Test Partner Account%' ORDER BY Name LIMIT 2];
        List<Shared_Solar_System__c> sharedSolarSystems = [
            SELECT Id, Product__c
            FROM Shared_Solar_System__c
            ORDER BY Id
            LIMIT 1
        ];

        Commission_Structure__c commissionStructure = new Commission_Structure__c(
            Name = 'Test Commission Structure',
            Cents_kW_DC_First_Bill__c = 0.03,
            Cents_kW_DC_Up_Front__c = 0.08,
            Cents_kW_DC_First_Bill_Paid__c = 0.02,
            Partner_Account__c = partnerAccounts[0].Id,
            Product__c = sharedSolarSystems[0].Product__c
        );
        insert new List<Commission_Structure__c>{commissionStructure};

        List<Partner_Shared_Solar_System_Eligibility__c> eligibilities = new List<Partner_Shared_Solar_System_Eligibility__c>();
        eligibilities.add(new Partner_Shared_Solar_System_Eligibility__c (
            Account__c = partnerAccounts[0].Id,
            Shared_Solar_System__c = sharedSolarSystems[0].Id,
            Commission_Structure__c = commissionStructure.Id,
            Start_Date__c = Date.newInstance(2020,11,23),
            End_Date__c = today-1
        ));
        eligibilities.add(new Partner_Shared_Solar_System_Eligibility__c (
            Account__c = partnerAccounts[0].Id,
            Shared_Solar_System__c = sharedSolarSystems[0].Id,
            Commission_Structure__c = commissionStructure.Id,
            Start_Date__c = today,
            End_Date__c = today+30
        ));
        insert eligibilities;

        List<Shared_Solar_System__Share> sharesCreatedByTrigger = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
            ORDER BY ParentId
        ];
        System.assertEquals(1, sharesCreatedByTrigger.size(), 'Expected setup to create one share');

        Test.startTest();
        // Simulates the scheduler daily.
        new SharedSolarSystemSharingScheduler().changeSharesForRecentEligibilityRecords(today, today-1);
        Test.stopTest();

        List<Shared_Solar_System__Share> sharesCreatedByScheduledJob = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
            ORDER BY ParentId
        ];
        System.assertEquals(1, sharesCreatedByScheduledJob.size(),
            'Expected to still have a share after the SSSSharingScheduler ran because there is an active PSSSE');
        System.assertNotEquals(sharesCreatedByTrigger[0].Id, sharesCreatedByScheduledJob[0].Id,
            'The scheduled job should delete shares since a PSSE ended yesterday, and should create a new one for the active PSSE');
    }

    private static List<Partner_Shared_Solar_System_Eligibility__c> setupTwoAccountsAndTwoSystems(Date startDate, Date endDate) {
        List<Account> partnerAccounts = [SELECT Id FROM Account WHERE Name LIKE 'Test Partner Account%' ORDER BY Name LIMIT 2];
        List<Shared_Solar_System__c> sharedSolarSystems = [
            SELECT Id, Product__c
            FROM Shared_Solar_System__c
            ORDER BY Id
            LIMIT 2
        ];

        Commission_Structure__c commissionStructure = new Commission_Structure__c(
            Name = 'Test Commission Structure',
            Cents_kW_DC_First_Bill__c = 0.03,
            Cents_kW_DC_Up_Front__c = 0.08,
            Cents_kW_DC_First_Bill_Paid__c = 0.02,
            Partner_Account__c = partnerAccounts[0].Id,
            Product__c = sharedSolarSystems[0].Product__c
        );
        Commission_Structure__c commissionStructure2 = new Commission_Structure__c(
            Name = 'Test Commission Structure',
            Cents_kW_DC_First_Bill__c = 0.03,
            Cents_kW_DC_Up_Front__c = 0.08,
            Cents_kW_DC_First_Bill_Paid__c = 0.02,
            Partner_Account__c = partnerAccounts[1].Id,
            Product__c = sharedSolarSystems[1].Product__c
        );

        insert new List<Commission_Structure__c>{commissionStructure, commissionStructure2};

        List<Partner_Shared_Solar_System_Eligibility__c> eligibilities = new List<Partner_Shared_Solar_System_Eligibility__c>();
        eligibilities.add(new Partner_Shared_Solar_System_Eligibility__c (
            Account__c = partnerAccounts[0].Id,
            Shared_Solar_System__c = sharedSolarSystems[0].Id,
            Commission_Structure__c = commissionStructure.Id,
            Start_Date__c = startDate,
            End_Date__c = endDate
        ));
        eligibilities.add(new Partner_Shared_Solar_System_Eligibility__c (
            Account__c = partnerAccounts[0].Id,
            Shared_Solar_System__c = sharedSolarSystems[1].Id,
            Commission_Structure__c = commissionStructure.Id,
            Start_Date__c = startDate,
            End_Date__c = endDate
        ));
        eligibilities.add(new Partner_Shared_Solar_System_Eligibility__c (
            Account__c = partnerAccounts[1].Id,
            Shared_Solar_System__c = sharedSolarSystems[0].Id,
            Commission_Structure__c = commissionStructure2.Id,
            Start_Date__c = startDate,
            End_Date__c = endDate
        ));
        eligibilities.add(new Partner_Shared_Solar_System_Eligibility__c (
            Account__c = partnerAccounts[1].Id,
            Shared_Solar_System__c = sharedSolarSystems[1].Id,
            Commission_Structure__c = commissionStructure2.Id,
            Start_Date__c = startDate,
            End_Date__c = endDate
        ));
        insert eligibilities;
        return eligibilities;
    }
}