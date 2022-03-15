@IsTest
private without sharing class UserTriggerHandlerTest {
    @IsTest
    private static void afterInsertTest() {
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

        Commission_Structure__c commissionStructure = new Commission_Structure__c(
            Name = 'Test Commission Structure',
            Cents_kW_DC_First_Bill__c = 0.03,
            Cents_kW_DC_Up_Front__c = 0.08,
            Cents_kW_DC_First_Bill_Paid__c = 0.02,
            Partner_Account__c = partnerAccount.Id,
            Type__c = 'Variable by kW'
        );
        insert commissionStructure;

        Partner_Shared_Solar_System_Eligibility__c eligibility = new Partner_Shared_Solar_System_Eligibility__c(
            Account__c = partnerAccount.Id,
            Shared_Solar_System__c = sss.Id,
            Commission_Structure__c = commissionStructure.Id,
            Start_Date__c = Date.newInstance(2020,1,1)
        );
        insert eligibility;

        Test.startTest();
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
        User u1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            FirstName = 'User',
            LastName = 'Test',
            Email = 'test@perchenergy.com',
            Username = 'test@perchenergy.com' + System.currentTimeMillis(),
            CommunityNickname = 'ptt',
            CompanyName = 'GearsCRM',
            Title = 'Tester',
            Alias = 'test',
            TimeZoneSidKey = 'America/New_York',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        List<User> usersList=new List<User>();
        usersList.add(u);
        usersList.add(u1);
        insert usersList;
        Test.stopTest();

        List<Shared_Solar_System__Share> shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
        ];
        Contact cnt=[SELECT Id FROM Contact WHERE User__c= :u1.Id];
        System.assertNotEquals(null, cnt.Id, 'Expected to create a Contact related to the Perch Energy account after inserting a user with a Standard license type and perchenergy.com in the email');
        System.assertEquals(1, shares.size(), 'Expected 1 Shared_Solar_System__share record to be created');
        System.assertEquals(sss.Id, shares[0].ParentId, 'Expected the Shared_Solar_System__share record to have a ParentId equal to the ID of the test Shared_Solar_System__c record');
        System.assertEquals(u.Id, shares[0].UserOrGroupId, 'Expected the Shared_Solar_System__share record to have a UserOrGroupId equal to the ID of the test User record');
    }
}