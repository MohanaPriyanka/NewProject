@isTest
public class testTaskInsertUpdate {

Static testMethod void testTaskInsertUpdate (){

UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
insert r;

User newuser = new user (
    ProfileId = [SELECT Id FROM Profile WHERE Name = 'BFG Standard User'].Id, 
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
    IsActive = true
    );
    
insert newuser;

}

Static testMethod void testTaskInsert (){

List <User> users = [SELECT Id, Email, isActive, FirstName FROM User WHERE isActive = : True];

Task newtask = new Task (
    Subject = 'This is the subject',
    OwnerID = users.get(1).Id
    );
    
insert newtask;
update newtask;

taskreminderhandler.taskreminder(newtask.id);

}
}