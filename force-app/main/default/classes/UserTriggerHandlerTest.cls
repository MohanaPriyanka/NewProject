@IsTest
private without sharing class UserTriggerHandlerTest {

    @IsTest
    private static void afterInsertTest() {
        Account partnerAccount = new Account(
            Name = 'Perch Energy',
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

        Contact partnerContact1 = new Contact(
            AccountId = partnerAccount.Id,
            FirstName = 'Test1',
            LastName = 'Partner1',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner_Contact').getRecordTypeId()
        );
        insert partnerContact1;

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
        User standardUser = new User(
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
        User communitySolarCommunityUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Community Solar Community User'].Id,
            ContactId = partnerContact1.Id,
            FirstName = 'Partnedr',
            LastName = 'Test1',
            Email = 'test3423@perchenergy.com',
            Username = 'test@perchenergy.com' + System.currentTimeMillis(),
            CommunityNickname = 'pt23',
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
        usersList.add(standardUser);
        usersList.add(communitySolarCommunityUser);
        insert usersList;
        Test.stopTest();
        List<Shared_Solar_System__Share> shares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
        ];
        Contact cnt=[SELECT Id,Active_Communities_User__c FROM Contact WHERE User__c = :standardUser.Id];
        System.assertNotEquals(null, cnt.Id, 'Expected to create a Contact related to the Perch Energy account after inserting a user with a Standard license type and perchenergy.com in the email');
        User ur=[SELECT Id,IsPortalEnabled FROM User WHERE Id= :communitySolarCommunityUser.Id];
        System.assertEquals(2, shares.size(), 'Expected 2 Shared_Solar_System__share record to be created');
        System.assertEquals(sss.Id, shares[0].ParentId, 'Expected the Shared_Solar_System__share record to have a ParentId equal to the ID of the test Shared_Solar_System__c record');
        System.assertEquals(u.Id, shares[0].UserOrGroupId, 'Expected the Shared_Solar_System__share record to have a UserOrGroupId equal to the ID of the test User record');
        System.assertEquals(true, ur.IsPortalEnabled, 'Expected the user record to have IsPortalEnabled');
    }
    @IsTest
    private static void afterUpdateTest() {
        Account partnerAccount = new Account(
            Name = 'Perch Energy',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        insert partnerAccount;

        Contact partnerContact = new Contact(
            AccountId = partnerAccount.Id,
            FirstName = 'Partner',
            LastName = 'Test',
            Email = 'test@perchenergy.com',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner_Contact').getRecordTypeId()
        );
        insert partnerContact;

        User communitySolarCommunityUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Community Solar Community User'].Id,
            ContactId = partnerContact.Id,
            FirstName = 'Partnedr',
            LastName = 'Test1',
            Email = 'test567@perchenergy.com',
            Username = 'test@perchenergy.com' + System.currentTimeMillis(),
            CommunityNickname = 'pt23',
            CompanyName = 'GearsCRM',
            Title = 'Tester',
            Alias = 'test',
            TimeZoneSidKey = 'America/New_York',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive=true,
            LocaleSidKey = 'en_US'
        );

        List<User> usersList=new List<User>();
        usersList.add(communitySolarCommunityUser);
        insert usersList;

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
        System.runAs(communitySolarCommunityUser){
            communitySolarCommunityUser.Email='test891@perchenergy.com';
            update communitySolarCommunityUser;
            User u=[SELECT Id,Email FROM User WHERE Id=:communitySolarCommunityUser.Id];
            System.assertEquals(u.Email, 'test891@perchenergy.com', 'User email should be updated');
        }
        Test.stopTest();
    }
    @IsTest
    private static void afterUpdateTestActiveCheckBox() {
        Account partnerAccount = new Account(
            Name = 'Perch Energy',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        insert partnerAccount;

        Contact partnerContact = new Contact(
            AccountId = partnerAccount.Id,
            FirstName = 'Partner',
            LastName = 'Test',
            Email = 'test@perchenergy.com',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner_Contact').getRecordTypeId()
        );
        insert partnerContact;

        User communitySolarCommunityUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Community Solar Community User'].Id,
            ContactId =partnerContact.Id,
            FirstName = 'Partnedr',
            LastName = 'Test1',
            Email = 'test567@perchenergy.com',
            Username = 'test@perchenergy.com' + System.currentTimeMillis(),
            CommunityNickname = 'pt23',
            CompanyName = 'GearsCRM',
            Title = 'Tester',
            Alias = 'test',
            TimeZoneSidKey = 'America/New_York',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive=true,
            LocaleSidKey = 'en_US'
        );

        List<User> usersList=new List<User>();
        usersList.add(communitySolarCommunityUser);
        insert usersList;
        User usr=[SELECT Id,IsPortalEnabled FROM User WHERE Id=:UserInfo.getUserId()];

        Test.startTest();
        System.runAs(usr){
            partnerContact.Active_Communities_User__c=false;
            update partnerContact;
            communitySolarCommunityUser.isActive=true;
            communitySolarCommunityUser.IsPortalEnabled=false;
            update communitySolarCommunityUser;
        }
        Test.stopTest();
        Contact cnt=[SELECT Id,Email,Active_Communities_User__c FROM Contact WHERE Id=:partnerContact.Id];
        System.assertEquals(cnt.Active_Communities_User__c, true, 'Active Communities User value should be true');
        User u = [SELECT Id,IsPortalEnabled from User where id =: communitySolarCommunityUser.id];
        System.assertEquals(true, u.IsPortalEnabled, 'Expected the user record to have IsPortalEnabled');
    }
}