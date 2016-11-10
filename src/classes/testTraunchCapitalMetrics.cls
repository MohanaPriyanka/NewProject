@isTest
private class testTraunchCapitalMetrics {

Static testMethod void deductLoanValue(){

Date myDate = Date.newInstance(2015, 2, 17);

loan_data__c newLoanData = new loan_data__c (name = 'Loan Data', month__c = 'August', year__c = '2015');

insert newLoanData;

Loan_traunch__c newTraunch = new loan_traunch__c(name = 'Avidian 1', Loan_data__c = newLoanData.id);
newTraunch.name = 'Avidian 1';

insert newTraunch;

loan_traunch__c traunchId = [SELECT id FROM loan_traunch__c WHERE name = 'Avidian 1'];

Opportunity newOpportunity = new Opportunity(name = 'Tester', type = 'New Business', closeDate = myDate, stageName='New', capital_expense__c = 10000, loan_traunch__c = traunchId.id); 

newOpportunity.name = 'Tester';
newOpportunity.type = 'New Business';
newOpportunity.closedate = myDate;
newOpportunity.stageName = 'New';
newOpportunity.capital_expense__c = 10000;
newOpportunity.loan_traunch__c = traunchId.id;

test.startTest();
  
insert newOpportunity;
   
test.stopTest();
 
loan_traunch__c traunchQuery = [SELECT name, capital_outflows__c FROM loan_traunch__c WHERE name = 'Avidian 1'];
 
system.assertEquals(0.00, traunchQuery.capital_outflows__c);
 
 
}
}