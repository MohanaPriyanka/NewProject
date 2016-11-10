@isTest
private class nmcCustomIdTriggerTestClass {

Static testMethod void nmcCustomIdTrigger(){

Date myDate = Date.newInstance(2015, 2, 17);

MPM4_BASE__Milestone1_Project__c newProject = new MPM4_BASE__Milestone1_Project__c( name = 'tester', Total_MWDC__c = 500);

insert newProject;

opportunity newOpp = new opportunity(name = 'Cole Swain', custom_id__c = 'Cole 1',StageName = 'New', closeDate = myDate) ;
Utility_NMC_Tariff__c newNMC = new Utility_NMC_Tariff__c(name ='Eversource Class 2');

Insert newNMC;

Utility_NMC_Tariff__c NMCQuery = [SELECT id FROM Utility_NMC_Tariff__c WHERE name = 'Eversource Class 2'];

test.startTest();
 
insert newOpp;
 
test.stopTest();
 
opportunity oppQuery = [SELECT name, NMC_Tariff__c FROM opportunity WHERE name = 'Cole Swain'];
 
system.assertEquals(null, oppQuery.NMC_Tariff__c);
 
 
}
}