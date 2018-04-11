@isTest
private class testCalculatePartnerCommissions {

Static testMethod void calculatePartnerSales(){

Date myDate = Date.newInstance(2015, 2, 17);

partner__c newPartner = new partner__c(name = 'Boston Solar', total_commission__c = 11.6);
Opportunity newOpportunity = new Opportunity(name = 'Tester', type = 'New Business', closeDate = myDate, stageName='New', partner_tag__c = 'Boston Solar'); 
Opportunity newOpportunity2 = new Opportunity(name = 'Tester2', type = 'New Business', closeDate = myDate, stageName='New', partner_tag__c = 'Boston Solar'); 

newPartner.name = 'Boston Solar';
newPartner.total_commission__c = 11.6;

insert newPartner;

newOpportunity.name = 'Tester';
newOpportunity.type = 'New Business';
newOpportunity.closedate = myDate;
newOpportunity.stageName = 'New';
newOpportunity.partner_Tag__c = 'Boston Solar';

newOpportunity2.name = 'Tester2';
newOpportunity2.type = 'New Business';
newOpportunity2.closedate = myDate;
newOpportunity2.stageName = 'New';
newOpportunity2.partner_Tag__c = 'Boston Solar';

test.startTest();
  
insert newOpportunity;
insert newOpportunity2;
   
test.stopTest();
 
partner__c partnerQuery = [SELECT name, total_commission__c FROM partner__c WHERE name = 'Boston Solar'];
 
system.assertEquals(11.6, partnerQuery.total_commission__c);
 
 
}
}