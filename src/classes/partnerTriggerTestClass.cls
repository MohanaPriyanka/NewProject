@isTest
private class partnerTriggerTestClass {/*

Static testMethod void partnerTrigger(){

Date myDate = Date.newInstance(2015, 2, 17);

partner__c partner = new partner__c (name = 'Partner', service_territory__c = 'All');
insert partner;

BSST__c salesRep = new BSST__c (partner__c = partner.id, name = 'Cole Swain', commission_structure__c = 'C', Custom_id__c = 'BWCSWain', a_rate__c = .08, b_rate__c = .1);
insert salesRep;

shared_solar_system__c newSSS = new shared_solar_system__c( 

name = 'System', 
service_territory__c = 'NEMA',
total_system_size_kWh_DC__c = 2000,
Expected_Yield_kWh_kW__c = 1450,
Partner__c = 'Parnter');
insert newSSS;

Opportunity Opportunity = new Opportunity(
name = 'Tester', 
type = 'New Business', 
project_assignment__c = 'Automatic', 
closeDate = myDate, 
stageName='Complete', 
CS_Capacity_Allocated__c = 100,
service_territory__c = 'NEMA',
parcel_zip__c = '02052',
date_of_application__c = '2015-09-09' ,
Annual_Consumption_kWh__c = 100,
subscription__c = 85,
shared_solar_system__c = newSSS.id,
custom_id__c = 'BWCSwain',
product_line__c = 'Community Solar'
); 

insert opportunity;

update partner
}*/
}