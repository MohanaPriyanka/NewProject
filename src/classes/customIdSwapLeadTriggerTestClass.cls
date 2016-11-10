@isTest
private class customIdSwapLeadTriggerTestClass {

Static testMethod void customIdSwapLead(){

lead newLead = new lead(firstName = 'Cole', lastName = 'Swain', company = 'BlueWave', status = 'contacted', custom_id__c = 'Cole 1') ;

partner__c newPartner = new partner__c(name = 'Partner');
insert newPartner;

bsst__c newBSST = new BSST__c (name ='Cole Swain', partner__c = newPartner.id, custom_id__c = 'Cole 1');
Insert newBSST;

bsst__c BSSTQuery = [SELECT id FROM BSST__C WHERE name = 'Cole Swain'];

test.startTest();
 
insert newLead;
 
test.stopTest();
 
lead leadQuery = [SELECT firstName, bs_sales_id__c FROM lead WHERE firstName = 'Cole'];
 
system.assertEquals(BSSTQuery.id, leadQuery.bs_sales_id__C);
 
 
}
}