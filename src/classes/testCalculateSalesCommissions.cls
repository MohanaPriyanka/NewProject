@isTest
private class testCalculateSalesCommissions {

Static testMethod void CSAcalculateSalesComm(){

/*Date myDate = Date.newInstance(2015, 2, 17);

loan_data__c newData = new loan_data__c(name = 'Data');
insert newData;

Loan_Traunch__c newTranche = new Loan_Traunch__c (name = 'Avidia 1', loan_data__c = newData.id, Tranche_Cap__c = 1100, Initial_Capital__c = 500, capital_outflows__c = 300);
insert newTranche;

partner__c newPartner = new partner__c(name = 'Boston Solar',a_rate__c =0.08, b_rate__c= 0.1, commission_structure__c ='A');
insert newPartner;

BSST__c newBSST = new BSST__c(name = 'Cole Swain', custom_id__c = 'cole', a_rate__c =0.08, partner__c = newPartner.id, b_rate__c= 0.1, csa_threshold__c = 10, commission_structure__c = 'Vivint');
BSST__c newBSSTResi = new BSST__c(name = 'Tamara', custom_id__c = 'resi', a_rate__c =0.08, partner__c = newPartner.id, b_rate__c= 0.1, Rate__c = 50, commission_cap__c = 350);

insert newBSST;
insert newBSSTResi;

partner__c partnerQueryBS = [SELECT id FROM partner__c WHERE partner__c.name = 'Boston Solar'];
BSST__c salesQueryBS = [SELECT id FROM BSST__c WHERE BSST__c.name = 'Cole Swain'];

Opportunity newOpportunity = new Opportunity(BS_Sales_ID__c = newBSST.id, product_line__c = 'Community Solar', name = 'Tester', type = 'New Business', closeDate = myDate, stageName='Complete', CS_Capacity_Allocated__c = 5, custom_id__c = 'cole'); 
Opportunity newOpportunity2 = new Opportunity(BS_Sales_ID__c = newBSST.id, product_line__c = 'Community Solar',  name = 'Tester2', type = 'New Business', closeDate = myDate, stageName='Complete', CS_Capacity_Allocated__c = 3.2, custom_id__c = 'cole'); 
opportunity newOpportunity7 = new opportunity(loan_assignment__c = 'Automatic' , product_line__c = 'Residential Loan',  loan_traunch__c = newTranche.id, name = 'ResiTester', type = 'New Business', closeDate = myDate, stageName='Complete', system_size__c = 6, custom_id__c = 'resi');

insert newOpportunity;
insert newOpportunity2;
insert newOpportunity7;

test.startTest(); 
  
update newOpportunity;
update newOpportunity2;
update newOpportunity7;
   
test.stopTest();

BSST__c salesQuery = [SELECT name, individual_commission__c FROM BSST__c WHERE name = 'Cole Swain'];
 
system.assertEquals(null, salesQuery.individual_commission__c);
 
}

Static testMethod void CSBcalculateSalesComm(){

Date myDate = Date.newInstance(2015, 2, 17);

partner__c newpartner2 = new partner__c(name = 'Boston Solar',a_rate__c =0.08, b_rate__c= 0.1, commission_structure__c ='B');
insert newPartner2;

BSST__c newBSST2 = new BSST__c(name = 'Cole Swain',partner__c = newPartner2.id, custom_id__c = 'swain', a_rate__c =0.16, b_rate__c= 0.18, CSA_Threshold__c = 100, rate_key__c = 5,commission_structure__c ='B');

insert newBSST2; 


partner__c partnerQueryNBS = [SELECT id FROM partner__c WHERE partner__c.name = 'Boston Solar'];
BSST__c salesQueryNBS = [SELECT id FROM BSST__c WHERE BSST__c.name = 'Cole Swain'];

Opportunity newOpportunity3 = new Opportunity(product_line__c = 'Community Solar', name = 'Tester3', stageName = 'Complete', type = 'New Business', closeDate = myDate , CS_Capacity_Allocated__c = 3, custom_id__c = 'swain'); 
Opportunity newOpportunity4 = new Opportunity(product_line__c = 'Community Solar', name = 'Tester4', stageName = 'Complete', type = 'New Business', closeDate = myDate, CS_Capacity_Allocated__c = 8, custom_id__c = 'swain');


test.startTest(); 
  
insert newOpportunity3;
insert newOpportunity4;
update newOpportunity3;
update newOpportunity4;
   
test.stopTest();

BSST__c salesQuery2 = [SELECT name, individual_commission__c FROM BSST__c WHERE name = 'Cole Swain'];
 

}

Static testMethod void CSCcalculateSalesComm(){

Date myDate = Date.newInstance(2015, 2, 17);

partner__c newpartner3 = new partner__c(name = 'Boston Solar');
insert newPartner3;

BSST__c newBSST3 = new BSST__c(name = 'Cole Swain', partner__c = newPartner3.id, custom_id__c = 'coleswain', a_rate__c = 100, CSA_Threshold__c = 100, b_rate__c= 500, rate_key__c = 5,commission_structure__c ='C');
insert newBSST3; 


partner__c partnerQueryNBS = [SELECT id FROM partner__c WHERE partner__c.name = 'Boston Solar'];
BSST__c salesQueryNBS = [SELECT id FROM BSST__c WHERE BSST__c.name = 'Cole Swain'];


Opportunity newOpportunity5 = new Opportunity(product_line__c = 'Community Solar', name = 'Tester5', stageName = 'Complete', type = 'New Business', closeDate = myDate , CS_Capacity_Allocated__c = 3, custom_id__c ='coleswain' ); 
Opportunity newOpportunity6 = new Opportunity(product_line__c = 'Community Solar', name = 'Tester6', stageName = 'Complete', type = 'New Business', closeDate = myDate, CS_Capacity_Allocated__c = 8, custom_id__c ='coleswain' );

insert newOpportunity5;
insert newOpportunity6;

test.startTest(); 
  
Update newOpportunity5;
Update newOpportunity6;
   
test.stopTest();

BSST__c salesQuery3 = [SELECT name, individual_commission__c FROM BSST__c WHERE name = 'Cole Swain'];
 
*/
return;
}
}