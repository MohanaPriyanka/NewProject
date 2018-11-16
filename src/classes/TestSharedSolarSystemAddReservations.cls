@isTest
private class TestSharedSolarSystemAddReservations {

Static testMethod void SharedSolarSysteAddReservations (){

Account myAccount = new Account(name = 'Test Account');
insert myAccount;

Date myDate = Date.newInstance(2015, 2, 17);
shared_solar_system__c myProject = new shared_solar_system__c(name = 'Tester');
insert myProject;

Opportunity newOpportunity = new Opportunity(name = 'Tester', account = myAccount, project_assignment__c = 'Manual', Shared_Solar_System_picklist__c = 'Tester', type = 'New Business', stageName = 'Complete', waitlist__c = FALSE, closeDate = myDate, shared_solar_system__c = myProject.id ); 

test.startTest();
 
insert newOpportunity;
 
test.stopTest();
 
shared_solar_system__c ProjectQuery = [SELECT name, Reserved_Capacity_kW_DC__c FROM shared_solar_system__c WHERE name = 'Tester'];

 
 
}
}