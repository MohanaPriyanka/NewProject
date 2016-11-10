@isTest
private class leadsLZUTriggerTestClass {

Static testMethod void validateLZUL(){

lead newLead = new lead(firstName = 'Cole', lastName = 'Swain', company = 'BlueWave', status = 'contacted', Parcel_Zip__c = '02052') ;
Load_U__c newLZU = new Load_U__c ( name = '02052', Load_zone__c= 'NEMA Eversource', LZ__c = 'NEMA', Utility__C = 'Eversource', town__c= 'Medfield');

Insert newLZU;

newLead.FirstName = 'Cole';
newLead.LastName = 'Swain';
newLead.Company = 'BlueWave';
newLead.Status = 'contacted';
newLead.Parcel_Zip__C = '02052';

newLZU.name = '02052';
newLZU.Load_Zone__c = 'NEMA Eversource';
newLZU.LZ__C = 'NEMA';
newLZU.Utility__c = 'Eversource';
newLZU.town__c = 'Medfield';

test.startTest();
 
insert newLead;
 
test.stopTest();
 
lead leadQuery = [SELECT firstName, LZU__C FROM lead WHERE firstName = 'Cole'];
 
system.assertEquals('NEMA Eversource', leadQuery.LZU__C);
 
 
}
}