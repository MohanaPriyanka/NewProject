@isTest
private class UtilityTest {

Static testMethod void UtilityTest(){

utility__c newUtility = new utility__c (
name = 'Duke Energy',
service_territory__c = 'Duke Energy Progress (DEP)');

insert newUtility;
update newUtility;
}
}