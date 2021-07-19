@isTest
private class nmcCustomIdTriggerTestClass {

static testMethod void nmcCustomIdTrigger(){

Date myDate = Date.newInstance(2015, 2, 17);

Opportunity newOpp = new Opportunity(Name = 'Cole Swain', Custom_ID__c = 'Cole 1',StageName = 'New', CloseDate = myDate) ;
Utility_NMC_Tariff__c newNMC = new Utility_NMC_Tariff__c(Name ='Eversource Class 2');

insert newNMC;

Utility_NMC_Tariff__c NMCQuery = [SELECT Id FROM Utility_NMC_Tariff__c WHERE Name = 'Eversource Class 2'];

test.startTest();
 
insert newOpp;
 
test.stopTest();
 
Opportunity oppQuery = [SELECT Name, NMC_Tariff__c FROM Opportunity WHERE Name = 'Cole Swain'];
 
system.assertEquals(null, oppQuery.NMC_Tariff__c);
 
 
}
}