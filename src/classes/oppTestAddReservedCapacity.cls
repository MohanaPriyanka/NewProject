@isTest
private class oppTestAddReservedCapacity {

Static testMethod void addReservedCapacity(){

Date myDate = Date.newInstance(2015, 2, 17);
MPM4_BASE__Milestone1_Project__c myProject = new MPM4_BASE__Milestone1_Project__c();

Opportunity newOpportunity = new Opportunity(name = 'Tester', type = 'New Business', closeDate = myDate, stageName='New', CS_Capacity_Allocated__c = 100, Assigned_CS_Project__c = myProject.name ); 

newOpportunity.name = 'Tester';
newOpportunity.type = 'New Business';
newOpportunity.closedate = myDate;
newOpportunity.stageName = 'New';
newOpportunity.CS_Capacity_Allocated__c = 100;
newOpportunity.Assigned_CS_Project__c = myProject.name;


test.startTest();
 
insert newOpportunity;
 
test.stopTest();
 
Opportunity OpportunityQuery = [SELECT name, cs_reserved_capacity__c FROM Opportunity WHERE name = 'Tester'];
 
system.assertEquals(null, OpportunityQuery.cs_reserved_capacity__c);
 
 
}
}