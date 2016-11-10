@isTest
private class testIRBDCalculator {

Static testMethod void IRBDCalculator(){

Date myDate = Date.newInstance(2015, 2, 17);

loan_data__c newLoanData = new loan_data__c (name = 'Loan Data', month__c = 'August', year__c = '2015');

insert newLoanData;

Loan_traunch__c newTraunch = new loan_traunch__c(name = 'Avidian 1', Loan_data__c = newLoanData.id, Tranche_Cap__c = 100000);
newTraunch.name = 'Avidian 1';

insert newTraunch;

Opportunity newOpportunity = new Opportunity(name = 'Tester', Loan_Principle__c = 50000, Loan_Rate__c = 0.0599,IRBD_Rate__c = 0.0325,Interest_Only_Period_DOER__c = 5, Principal_and_Interest_Period_DOER__c = 120,  type = 'New Business', product_line__c = 'DOER Solar Loan', loan_assignment__c = 'Automatic', closeDate = myDate, stageName='New', capital_expense__c = 10000); 
insert newOpportunity;
update newOpportunity;


 
}
}