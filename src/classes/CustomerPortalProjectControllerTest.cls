/**
 * Created by rebeccanachison on 10/12/21.
 */

@IsTest
public with sharing class CustomerPortalProjectControllerTest {
    @TestSetup public static void testSetup() {
        useMocks();
        Util.disableAllTriggers();
        TestFactory.insertBWAddress();
        Test.loadData(Utility__c.SObjectType, 'TestCSUtility');
        Test.loadData(Utility_NMC_Tariff__c.SObjectType, 'TestCSUtilityNMCTariff');
        Test.loadData(Contact.SObjectType, 'TestCSContact');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Test.loadData(Entity__c.SObjectType, 'TestCSEntity');
        Test.loadData(Shared_Solar_System__c.SObjectType, 'TestCSSharedSolarSystem');
        Test.loadData(Utility_Account_Log__c.SObjectType, 'TestCSUtilityAccountLog');
        Test.loadData(Partner__c.SObjectType, 'TestRLPartner');
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Util.enableAllTriggers();
        Test.loadData(Utility_Account_Subscription__c.SObjectType, 'TestCSUtilityAccountSubscription');

        //relate Opportunity to user
        Contact contact = [
                SELECT Id
                FROM Contact
                LIMIT 1
        ];
        Account parentAccount = [
                SELECT Id
                FROM Account
                WHERE Name != 'Account A'
                AND Type = 'Landowner'
                LIMIT 1
        ];
        Opportunity opportunity = [
                SELECT Id, AccountId
                FROM Opportunity
                WHERE Product_Line__c = 'Community Solar'
                AND StageName = 'Complete'
                LIMIT 1
        ];

        Account propertyAccount = new Account(
                Id = opportunity.AccountId,
                Parent_Account__c = parentAccount.Id
        );
        update propertyAccount;

        contact.AccountId = parentAccount.Id;
        update contact;
    }

    /**** Test CustomerPortalProjectCarouselController ****/

    @IsTest public static void testGetUserSharedSolarSystemsCommunitySolarCommunityUser() {
        Contact contact = [
                SELECT Id
                FROM Contact
                WHERE AccountId != NULL
                LIMIT 1
        ];

        //Create Community Solar Community User with unique username
        String userName = 'commsolarcommuser' + Datetime.now().getTime() + '@test.test';
        Profile profile = [
                SELECT Id
                FROM Profile
                WHERE Name = 'Community Solar Community User'
        ];
        User currentUser = new User(
                Alias = 'commun',
                Email = 'commsolarcommuser@test.test',
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Test First',
                LastName = 'Test Last',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Country = 'United States',
                UserName = userName,
                ContactId = contact.Id,
                IsActive = true
        );
        Util.insertSObj(currentUser);

        System.runAs(currentUser) {
            List<Shared_Solar_System__c> sharedSolarSystems = CustomerPortalProjectCarouselController.getUserSharedSolarSystems();
            System.assertEquals(1, sharedSolarSystems.size(), 'Method should have found 1 SSS with a lookup to TestAccountAOppOne');
        }
    }

    @IsTest public static void testGetUserSharedSolarSystemsCommunitySolarUser() {
        Contact contact = [
                SELECT Id
                FROM Contact
                WHERE AccountId != NULL
                LIMIT 1
        ];

        //Create Community Solar User with unique username
        String userName = 'commsolaruser' + Datetime.now().getTime() + '@test.test';
        Profile profile = [
                SELECT Id
                FROM Profile
                WHERE Name = 'Community Solar User'
        ];
        User currentUser = new User(
                Alias = 'commun',
                Email = 'commsolaruser@test.test',
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Test First',
                LastName = 'Test Last',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Country = 'United States',
                UserName = userName,
                ContactId = contact.Id,
                IsActive = true
        );
        Util.insertSObj(currentUser);

        System.runAs(currentUser) {
            List<Shared_Solar_System__c> sharedSolarSystems = CustomerPortalProjectCarouselController.getUserSharedSolarSystems();
            System.assertEquals(1, sharedSolarSystems.size(), 'Method should have found 1 SSS with a lookup to TestAccountAOppOne');
        }
    }

    @IsTest public static void testGetUserSharedSolarSystemsNoSubscriptions() {
        Contact contact = [
                SELECT Id
                FROM Contact
                WHERE AccountId != NULL
                LIMIT 1
        ];

        Opportunity opportunity = [
                SELECT Id, StageName
                FROM Opportunity
                WHERE Product_Line__c = 'Community Solar'
                AND StageName = 'Complete'
                LIMIT 1
        ];

        opportunity.StageName = 'Cancelled';
        update opportunity;

        //Create Community Solar Community User with unique username
        String userName = 'commsolarcommuser' + Datetime.now().getTime() + '@test.test';
        Profile profile = [
                SELECT Id
                FROM Profile
                WHERE Name = 'Community Solar Community User'
        ];
        User currentUser = new User(
                Alias = 'commun',
                Email = 'commsolarcommuser@test.test',
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Test First',
                LastName = 'Test Last',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Country = 'United States',
                UserName = userName,
                ContactId = contact.Id,
                IsActive = true
        );
        Util.insertSObj(currentUser);



        System.runAs(currentUser) {
            List<Shared_Solar_System__c> sharedSolarSystems = CustomerPortalProjectCarouselController.getUserSharedSolarSystems();
            System.assertEquals(0, sharedSolarSystems.size(), 'Method should have found 0 SSS for user');
        }
    }

    @IsTest public static void testGetUserSharedSolarSystemsNoAccountId() {

        try {
            CustomerPortalProjectCarouselController.getUserSharedSolarSystems();
        } catch (Exception e) {
            System.assertEquals('System.AuraHandledException', e.getTypeName(), 'Method should throw AuraHandledException');
        }
    }

    /**** Test CustomerPortalProjectUASListController ****/

    @IsTest public static void testGetUtilityAccountSubscriptionsCommunitySolarCommunityUser() {
        Contact contact = [
                SELECT Id
                FROM Contact
                WHERE AccountId != NULL
                LIMIT 1
        ];

        //Create Community Solar Community User with unique username
        String userName = 'commsolarcommuser' + Datetime.now().getTime() + '@test.test';
        Profile profile = [
                SELECT Id
                FROM Profile
                WHERE Name = 'Community Solar Community User'
        ];
        User currentUser = new User(
                Alias = 'commun',
                Email = 'commsolarcommuser@test.test',
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Test First',
                LastName = 'Test Last',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Country = 'United States',
                UserName = userName,
                ContactId = contact.Id,
                IsActive = true
        );
        Util.insertSObj(currentUser);

        System.runAs(currentUser) {
            List<Utility_Account_Subscription__c> utilityAccountSubscriptions = CustomerPortalProjectUASListController.getUtilityAccountSubscriptions();
            System.assertEquals(1, utilityAccountSubscriptions.size(), 'Method should have found 1 UAS with a lookup to TestAccountAOppOne');
        }
    }

    @IsTest public static void testGetUtilityAccountSubscriptionsCommunitySolarUser() {
        Contact contact = [
                SELECT Id
                FROM Contact
                WHERE AccountId != NULL
                LIMIT 1
        ];

        //Create Community Solar User with unique username
        String userName = 'commsolaruser' + Datetime.now().getTime() + '@test.test';
        Profile profile = [
                SELECT Id
                FROM Profile
                WHERE Name = 'Community Solar User'
        ];
        User currentUser = new User(
                Alias = 'commun',
                Email = 'commsolaruser@test.test',
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Test First',
                LastName = 'Test Last',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Country = 'United States',
                UserName = userName,
                ContactId = contact.Id,
                IsActive = true
        );
        Util.insertSObj(currentUser);

        System.runAs(currentUser) {
            List<Utility_Account_Subscription__c> utilityAccountSubscriptions = CustomerPortalProjectUASListController.getUtilityAccountSubscriptions();
            System.assertEquals(1, utilityAccountSubscriptions.size(), 'Method should have found 1 UAS with a lookup to TestAccountAOppOne');
        }
    }

    @IsTest public static void testGetUtilityAccountSubscriptionsNoAccountId() {

        try {
            CustomerPortalProjectUASListController.getUtilityAccountSubscriptions();
        } catch (Exception e) {
            System.assertEquals('System.AuraHandledException', e.getTypeName(), 'Method should throw AuraHandledException');
        }
    }

    @IsTest public static void testGetUtilityAccountSubscriptionsNoSubscriptions() {
        Contact contact = [
                SELECT Id
                FROM Contact
                WHERE AccountId != NULL
                LIMIT 1
        ];

        Opportunity opportunity = [
                SELECT Id, StageName
                FROM Opportunity
                WHERE Product_Line__c = 'Community Solar'
                AND StageName = 'Complete'
                LIMIT 1
        ];

        opportunity.StageName = 'Cancelled';
        update opportunity;

        //Create Community Solar Community User with unique username
        String userName = 'commsolarcommuser' + Datetime.now().getTime() + '@test.test';
        Profile profile = [
                SELECT Id
                FROM Profile
                WHERE Name = 'Community Solar Community User'
        ];
        User currentUser = new User(
                Alias = 'commun',
                Email = 'commsolarcommuser@test.test',
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Test First',
                LastName = 'Test Last',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Country = 'United States',
                UserName = userName,
                ContactId = contact.Id,
                IsActive = true
        );
        Util.insertSObj(currentUser);

        System.runAs(currentUser) {
            List<Utility_Account_Subscription__c> utilityAccountSubscriptions = CustomerPortalProjectUASListController.getUtilityAccountSubscriptions();
            System.assertEquals(0, utilityAccountSubscriptions.size(), 'Method should have found 0 UAS');
        }
    }

    private static void useMocks() {
        UtilityAccountSubscriptionHandler.partnerCommissionHandler = (PartnerCommissionHandler) Test.createStub(PartnerCommissionHandler.class, new PartnerCommissionHandlerTest.MockPartnerCommissionHandler());
    }
}