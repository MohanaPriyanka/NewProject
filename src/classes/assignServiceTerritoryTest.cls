@isTest
private class assignServiceTerritoryTest {

Static testMethod void validateAssignServiceTerritory(){

lead newLead = new lead(firstName = 'Cole', lastName = 'Swain', company = 'BlueWave', status = 'contacted', Parcel_Zip__c = '29501') ;
service_territory__c newServiceTerritory = new service_territory__c ( name = '29501', service_territory__c = 'Duke Energy Progress (DEP)', city__c = 'Florence');

Insert newServiceTerritory;

test.startTest();
 
insert newLead;
 
test.stopTest();
 
lead leadQuery = [SELECT firstName, service_territory__c FROM lead WHERE firstName = 'Cole'];
 
system.assertEquals('Duke Energy Progress (DEP)' , leadQuery.service_territory__c);
 
 
}
}