/**
 * Created by joeychan on 2020-01-31.
 */

@IsTest
private class SharedSolarSystemSharingServiceTest {
    @TestSetup
    static void setupData() {
        OpportunitiesSelectorTest.testSetup();

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
            Product__c = sharedSolarSystem.Product__c,
            Type__c = 'Variable by kW'
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
            Product__c = sharedSolarSystems[0].Product__c,
            Type__c = 'Variable by kW'
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
            Product__c = sharedSolarSystems[0].Product__c,
            Type__c = 'Variable by kW'
        );
        Commission_Structure__c commissionStructure2 = new Commission_Structure__c(
            Name = 'Test Commission Structure',
            Cents_kW_DC_First_Bill__c = 0.03,
            Cents_kW_DC_Up_Front__c = 0.08,
            Cents_kW_DC_First_Bill_Paid__c = 0.02,
            Partner_Account__c = partnerAccounts[1].Id,
            Product__c = sharedSolarSystems[1].Product__c,
            Type__c = 'Variable by kW'
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