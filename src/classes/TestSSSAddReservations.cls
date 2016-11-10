@isTest
private class TestSSSAddReservations {

Static testMethod void SSSAddReservations(){

Account myAccount = new Account(name = 'Test Account');
insert myAccount;

Date myDate = Date.newInstance(2015, 2, 17);
shared_solar_system__c myProject = new shared_solar_system__c(name = 'Tester');
insert myProject;

Opportunity newOpportunity = new Opportunity(name = 'Cole', 
account = myAccount, 
project_assignment__c = 'Manual', 
Shared_Solar_System_picklist__c = 'Tester', 
type = 'New Business', 
stageName = 'Complete',
Product_line__c = 'Community Solar',
Customer_group__c = 'Residential',  
waitlist__c = FALSE, 
closeDate = myDate, 
CS_Capacity_Allocated__c = 100, 
shared_solar_system__c = myProject.id ); 

Opportunity newOpportunity3 = new Opportunity(name = 'Cole2', 
account = myAccount, 
project_assignment__c = 'Manual', 
Shared_Solar_System_picklist__c = 'Tester', 
type = 'New Business', 
stageName = 'Complete',
Product_line__c = 'Community Solar',
Customer_group__c = 'Anchor',  
waitlist__c = FALSE, 
closeDate = myDate, 
CS_Capacity_Allocated__c = 100, 
shared_solar_system__c = myProject.id ); 

Opportunity newOpportunity2 = new Opportunity(name = 'Cole3', 
account = myAccount, 
project_assignment__c = 'Manual', 
Shared_Solar_System_picklist__c = 'Tester', 
type = 'New Business', 
stageName = 'Pending BlueWave Signature',
Product_line__c = 'Community Solar',
Customer_group__c = 'Residential', 
waitlist__c = FALSE, 
closeDate = myDate, 
CS_Capacity_Allocated__c = 100, 
shared_solar_system__c = myProject.id ); 

test.startTest();

insert newOpportunity;
insert newOpportunity2;
insert newOpportunity3;
update newOpportunity;
update newOpportunity2;
update newOpportunity3;

update myProject;


test.stopTest();

 
}
}