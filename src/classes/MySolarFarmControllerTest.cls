@isTest
private class MySolarFarmControllerTest {

    static testMethod void testSolarFarm() {
        Id p = [select id from profile where name='Community Solar Community User'].id;
       
        Account a = new Account(name ='TestDashboard') ;
        insert a; 
       
        Contact c = new Contact(FirstName='test', LastName ='testDashboard',AccountId = a.Id);
        insert c;  
                  
        User u = new User(alias = 'testDash', email='testdash@test.test', emailencodingkey='UTF-8', lastname='testDashboard', languagelocalekey='en_US', localesidkey='en_US', profileid = p, country='United States',IsActive =true, ContactId = c.Id, timezonesidkey='America/New_York', username='testdashboard@test.test');
        Util.insertSObj(u);
        Shared_Solar_System__c ss = new Shared_Solar_System__c();
        insert ss; 
        Product_Profile__c pp = new Product_Profile__c(Shared_Solar_System__c = ss.Id, Profile_Type__c = 'Community Solar', My_Current_Balance__c = 100);
        insert pp;
        Consumption_Update__c cu = new Consumption_Update__c(External_System_ID__c = 'abvksjfkjri2j', Date__c = Date.today(), Energy_Consumption__c = 2, My_Savings__c = 100, Product_Profile__c = pp.Id);
        insert cu;
        Energy_Usage_Update__c pu = new Energy_Usage_Update__c(Date__c = Date.today(), Production__c = 2, Product_Profile__c = pp.Id);
        insert pu;
        system.runAs(u) {
			MySolarFarmController.getUsers();
			MySolarFarmController.getSolarSystem();
			
        }
        
    }
}