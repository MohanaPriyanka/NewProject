@isTest
private class mapAvailableCapacityTest{

Static testMethod void mapAvailableCapacity(){


Date myDate = Date.newInstance(2015, 2, 17);

load_u__c newServiceTerritory = new load_u__c( name = '02052', Load_Zone__c = 'NEMA Eversource', lz__c = 'NEMA', utility__c = 'Eversource', town__c = 'Medfield');

Insert newServiceTerritory;

shared_solar_system__c newSSS = new shared_solar_system__c( 

name = 'Florence', 
service_territory__c = 'NEMA',
total_system_size_kWh_DC__c = 2000,
Expected_Yield_kWh_kW__c = 1450,
System_Utility__c = 'Eversource',
Total_CS_Capacity__c = 600);

insert newSSS;

shared_solar_system__c newSSS2 = new shared_solar_system__c( 

name = 'Spartanburg', 
service_territory__c = 'NEMA',
total_system_size_kWh_DC__c = 10000,
Expected_Yield_kWh_kW__c = 1450,
System_Utility__c = 'Eversource',
Total_CS_Capacity__c = 500);

insert newSSS2;

lead newLead = new lead(firstName = 'Cole', Product_Line__c = 'Community Solar', lastName = 'Swain', email = 'cswain@bluewave-capital.com', company = 'BlueWave', status = 'contacted', Parcel_Zip__c = '02052');
insert newLead;


 
}
}