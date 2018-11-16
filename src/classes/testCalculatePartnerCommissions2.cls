@isTest
private class testCalculatePartnerCommissions2 {

Static testMethod void CSAcalculatePartnerSales(){

Date myDate = Date.newInstance(2015, 2, 17);

partner__c newPartner = new partner__c(name = 'Boston Solar',a_rate__c =0.08, b_rate__c= 0.1, a_commission__c = 656, b_commission__c = 0, total_commission__c = 656,commission_structure__c ='A', csa_threshold__c = 10);

insert newPartner;

partner__c partnerQueryBS = [SELECT id FROM partner__c WHERE partner__c.name = 'Boston Solar'];

Opportunity newOpportunity = new Opportunity(name = 'Tester', type = 'New Business', closeDate = myDate, stageName='New', partner_tag__c = 'Boston Solar',partner_tag_lookup__c = partnerQueryBS.id); 
Opportunity newOpportunity2 = new Opportunity(name = 'Tester2', type = 'New Business', closeDate = myDate, stageName='New', partner_tag__c = 'Boston Solar', partner_tag_lookup__c = partnerQueryBS.id); 

test.startTest(); 
  
insert newOpportunity;
insert newOpportunity2;
   
test.stopTest();

partner__c partnerQuery = [SELECT name, total_commission__c FROM partner__c WHERE name = 'Boston Solar'];
 
system.assertEquals(656.00, partnerQuery.total_commission__c);
 
}

Static testMethod void CSBcalculatePartnerSales(){

Date myDate = Date.newInstance(2015, 2, 17);

partner__c newPartner2 = new partner__c(name = 'Vivint',a_rate__c =0.16, b_rate__c= 0.18, a_commission__c = 480, b_commission__c = 1440, total_commission__c = 1920,commission_structure__c ='B', rate_key__c = 5);

insert newPartner2; 

partner__c partnerQueryNBS = [SELECT id FROM partner__c WHERE partner__c.name = 'Vivint'];

Opportunity newOpportunity3 = new Opportunity(name = 'Tester3', type = 'New Business', closeDate = myDate, stageName='New', partner_tag__c = 'Vivint', partner_tag_lookup__c = partnerQueryNBS.id); 
Opportunity newOpportunity4 = new Opportunity(name = 'Tester4', type = 'New Business', closeDate = myDate, stageName='New', partner_tag__c = 'Vivint', partner_tag_lookup__c = partnerQueryNBS.id);

test.startTest(); 
  
insert newOpportunity3;
insert newOpportunity4;
   
test.stopTest();

partner__c partnerQuery2 = [SELECT name, total_commission__c FROM partner__c WHERE name = 'Vivint'];
 
system.assertEquals(1920.00, partnerQuery2.total_commission__c);
}
}