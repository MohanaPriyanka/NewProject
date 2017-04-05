@isTest
    public class testTaskInsertUpdate {

    @testSetup public static void setupTestData() {
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert r;

        User newuser = new user (ProfileId = [SELECT Id FROM Profile WHERE Name = 'BFG Standard User'].Id, 
                                 FirstName = 'first',
                                 LastName = 'last',
                                 Email = 'namethatsnotused@bluewave-capital.com',
                                 Username = 'namethatsnotused@bluewave-capital.com' + System.currentTimeMillis(),
                                 CompanyName = 'TEST',
                                 Title = 'title',
                                 Alias = 'alias',
                                 TimeZoneSidKey = 'America/Los_Angeles',
                                 EmailEncodingKey = 'UTF-8',
                                 LanguageLocaleKey = 'en_US',
                                 LocaleSidKey = 'en_US',
                                 UserRoleId = r.Id,
                                 IsActive = true);
    
        insert newuser;
    }

    static testMethod void testTaskInsert () {
        User user = [SELECT Id, Email, isActive, FirstName 
                     FROM User 
                     WHERE LastName = 'last'
                     LIMIT 1];

        Task newtask = new Task (Subject = 'This is the subject',
                                 OwnerID = user.Id);
    
        insert newtask;
        update newtask;

        taskreminderhandler.taskreminder(newtask.id);
    }
}