@isTest
private class ChatterAnswersAuthProviderRegTest {
    static testMethod void validateCreateUpdateUser() {
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            Auth.UserData userData = new Auth.UserData('testId', 'testFirst', 'testLast',
            'testFirst testLast', 'no-reply@salesforce.com', null, 'testuserlong', 'en_US', 'facebook',
            null, new Map<String, String>{'language' => 'en_US'});
            ChatterAnswersAuthProviderRegistration reg = new ChatterAnswersAuthProviderRegistration();
            Profile[] p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            User[] adminUser = [SELECT Id, Firstname, Lastname FROM User WHERE IsActive = true and ProfileId =: p[0].Id LIMIT 1];
            reg.setSiteAdminUserId(adminUser[0].Id);
            User newUser = reg.createUser(null, userData);
            System.assert(newUser != null, 'A new user should have been created');
            System.assertEquals(newUser.Firstname, 'testFirst', 'First name should have been same');
            System.assertEquals(newUser.Lastname, 'testLast', 'Last name should have been same');
            System.assertEquals(newUser.Email, 'no-reply@salesforce.com', 'Email should have been same');
            
            Account a = new Account(Name='Test Account Name');
            insert a;
            
            Contact c = new Contact();
       
            c.AccountId = (a.id);
            c.LastName = 'contactLast';
            c.firstName ='Cole';
            insert(c);
            

  newuser.EmailEncodingKey = 'ISO-8859-1';
  newuser.LanguageLocaleKey = 'en_US';
  newuser.TimeZoneSidKey = 'America/New_York';
  newuser.LocaleSidKey = 'en_US';
  newuser.FirstName = 'first';
  newuser.LastName = 'last';
  newuser.Username = 'test@appirio.com';   
  newuser.CommunityNickname = 'testUser123';
  newuser.Alias = 't1';
  newuser.Email = 'no@email.com';
  newuser.IsActive = true;
  newuser.ContactId = c.Id;
            newUser.ContactId = c.Id;
            newUser.ProfileId = [SELECT Id FROM Profile WHERE Name ='Customer Community Plus Login User' LIMIT 1].Id; 
            newUser.UserPermissionsChatterAnswersUser = TRUE;
          
            
            
            Util.insertSObj(newUser);
            
            
            Auth.UserData updateUserData = new Auth.UserData('testId', 'updatedFirst', 'updatedLast',
            'updatedFirst updatedLast', 'no-reply@new.salesforce.com', null, 'testuserlong', 'en_US', 'facebook',
            null, new Map<String, String>{'language' => 'en_US'});
            reg.updateUser(newUser.Id, null, updateUserData);
            
            User dbUser =  [SELECT Id, Firstname, Lastname, Email FROM User WHERE Id = :newUser.Id];
            System.assertEquals(dbUser.Firstname, 'updatedFirst', 'First name should have been updated');
            System.assertEquals(dbUser.Lastname, 'updatedLast', 'Last name should have been updated');
            System.assertEquals(dbUser.Email, 'no-reply@new.salesforce.com', 'Email should have been updated');
        }
    }
}