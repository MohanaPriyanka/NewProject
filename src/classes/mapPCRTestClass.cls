@isTest
private class mapPCRTestClass {

Static testMethod void mapPCRTest(){

Load_U__c newLZU = new Load_U__c ( name = '02052', Load_zone__c= 'NEMA Eversource', LZ__c = 'NEMA', Utility__C = 'Eversource', town__c= 'Medfield');

Insert newLZU;


lead newLead = new lead(firstName = 'Cole', lastName = 'Swain', company = 'BlueWave', status = 'Qualified', annual_income_currency__c = 105000, product_line__c = 'Community Solar', parcel_zip__c = '02052') ;
insert newLead;

LASERCA__Personal_Credit_Report__c newPCR = new LASERCA__Personal_Credit_Report__c (name = 'TestCase' , LASERCA__Total_High_Credit__c = 50000, LASERCA__Credit_Score__c= '715', LASERCA__Lead__c = newLead.id);
Insert newPCR;

update newLead;

}
}