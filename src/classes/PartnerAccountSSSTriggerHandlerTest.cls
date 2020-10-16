@IsTest
private without sharing class PartnerAccountSSSTriggerHandlerTest {
    @TestSetup
    private static void setup() {
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

        Shared_Solar_System__c sss = new Shared_Solar_System__c(
            Name = 'Test Shared Solar System'
        );
        insert sss;

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
            Alias = 'test',
            TimeZoneSidKey = 'America/New_York',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert u;
    }

    @IsTest
    private static void afterInsertTest() {
        Id partnerAccountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id sharedSolarSystemId = [SELECT Id FROM Shared_Solar_System__c LIMIT 1].Id;
        Id userId = [SELECT Id FROM User ORDER BY CreatedDate DESC LIMIT 1].Id;    
        Partner_Account_Shared_Solar_System__c passs = new Partner_Account_Shared_Solar_System__c(
            Partner_Account__c = partnerAccountId,
            Shared_Solar_System__c = sharedSolarSystemId
        );
        Test.startTest();
        insert passs;
        Test.stopTest();

        List<Shared_Solar_System__share> shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__share
        ];
        System.assertEquals(1, shares.size(), 'Expected 1 Shared_Solar_System__share record to be created');
        System.assertEquals(sharedSolarSystemId, shares[0].ParentId, 'Expected the Shared_Solar_System__share record to have a ParentId equal to the ID of the test Shared_Solar_System__c record');
        System.assertEquals(userId, shares[0].UserOrGroupId, 'Expected the Shared_Solar_System__share record to have a UserOrGroupId equal to the ID of the test User record');
    }

    @IsTest
    private static void afterDeleteTest() {
        Id partnerAccountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id sharedSolarSystemId = [SELECT Id FROM Shared_Solar_System__c LIMIT 1].Id;
        Id userId = [SELECT Id FROM User ORDER BY CreatedDate DESC LIMIT 1].Id;    
        Partner_Account_Shared_Solar_System__c passs = new Partner_Account_Shared_Solar_System__c(
            Partner_Account__c = partnerAccountId,
            Shared_Solar_System__c = sharedSolarSystemId
        );
        insert passs;

        List<Shared_Solar_System__share> shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__share
        ];
        System.assertEquals(1, shares.size(), 'Expected 1 Shared_Solar_System__share record to be created');
        System.assertEquals(sharedSolarSystemId, shares[0].ParentId, 'Expected the Shared_Solar_System__share record to have a ParentId equal to the ID of the test Shared_Solar_System__c record');
        System.assertEquals(userId, shares[0].UserOrGroupId, 'Expected the Shared_Solar_System__share record to have a UserOrGroupId equal to the ID of the test User record');

        Test.startTest();
        delete passs;
        Test.stopTest();

        shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__share
        ];
        System.assertEquals(0, shares.size(), 'Expected no Shared_Solar_System__share records to exist');
    }
}