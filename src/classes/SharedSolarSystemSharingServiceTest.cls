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
}