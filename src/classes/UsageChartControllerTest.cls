/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class UsageChartControllerTest {
/*
    static testMethod void testUsageChart() {
        Id p = [select id from profile where name='Community Solar Community User'].id;
       
        Account a = new Account(name ='TestDashboard') ;
        insert a; 
       
        Contact c = new Contact(FirstName='test', LastName ='testDashboard',AccountId = a.Id);
        insert c;  
                  
        User u = new User(alias = 'testDash', email='testdash@test.test', emailencodingkey='UTF-8', lastname='testDashboard', languagelocalekey='en_US', localesidkey='en_US', profileid = p, country='United States',IsActive =true, ContactId = c.Id, timezonesidkey='America/New_York', username='testdashboard@test.test');
        insert u;
        Shared_Solar_System__c ss = new Shared_Solar_System__c();
        insert ss; 
        Product_Profile__c pp = new Product_Profile__c(Shared_Solar_System__c = ss.Id, Profile_Type__c = 'Community Solar', My_Current_Balance__c = 100);
        insert pp;
        Consumption_Update__c cu = new Consumption_Update__c(External_System_ID__c = 'abvksjfkjri2j', Date__c = Date.today(), Energy_Consumption__c = 2, My_Savings__c = 100, Product_Profile__c = pp.Id);
        insert cu;
        Energy_Usage_Update__c pu = new Energy_Usage_Update__c(Date__c = Date.today(), Production__c = 2, Product_Profile__c = pp.Id);
        insert pu;
        system.runAs(u) {
            UsageChartController.getTenYears();
            UsageChartController.getFiveYears();
            UsageChartController.getOneYear();
            UsageChartController.getSixMonths();
            UsageChartController.getOneMonth();
            UsageChartController.getOneDay();
            UsageChartController.getAll();
        }
        // TO DO: implement unit test
        
    }*/
}