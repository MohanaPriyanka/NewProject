@isTest
private class ProjectTestAddReservedCapacity {

Static testMethod void ProjectaddReservedCapacity(){

Account myAccount = new Account(name = 'Test Account');
insert myAccount;

Date myDate = Date.newInstance(2015, 2, 17);
MPM4_BASE__Milestone1_Project__c myProject = new MPM4_BASE__Milestone1_Project__c(name = 'Tester');
insert myProject;

Opportunity newOpportunity = new Opportunity(name = 'Tester', account = myAccount, type = 'New Business', closeDate = myDate, stageName='New', CS_Capacity_Allocated__c = 100, Assigned_CS_Project__c = myProject.id ); 

test.startTest();
 
insert newOpportunity;
 
test.stopTest();
 
MPM4_BASE__Milestone1_Project__c ProjectQuery = [SELECT name, cs_reserved_capacity__c FROM MPM4_BASE__Milestone1_Project__c WHERE name = 'Tester'];
 
system.assertEquals(null, ProjectQuery.cs_reserved_capacity__c);
 
 
}
}