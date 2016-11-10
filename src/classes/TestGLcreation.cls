@isTest
private class TestGLcreation{

Static testMethod void testGLcreation(){

Date myDate = Date.newInstance(2015, 2, 17);

Opportunity newOpportunity = new Opportunity(

name = 'Tester', 
type = 'New Business', 
closeDate = myDate, 
stageName='New', 
CS_Capacity_Allocated__c = 100,
DOER_Solar_Loan__c = TRUE,
IRBD_Interest_Only_Date_Received__c = myDate,
Disbursal_1_Contract_Signature_Checkbox__c = myDate,
Disbursal_2_Mechanical_Install_Checkbox__c = myDate,
Disbursal_3_Full_Install_Checkbox__c = myDate); 

insert newOpportunity;

loan_data__c newLoanData = new loan_data__c (
name = 'Loan Data', 
month__c = 'August', 
year__c = '2015');

insert newLoanData;

loan_traunch__c newLoanTranche = new loan_traunch__c (
loan_data__c = newLoanData.id, 
name = 'Loan Tranche');

insert newLoanTranche;

loan__c newLoan = new loan__c(
name = 'Loan', 
opportunity__c = newOpportunity.id, 
loan_tranche__c = newLoanTranche.id);

insert newLoan;

loan_payment__c newLoanPayment = new loan_payment__c ( 
name = 'Loan Payment', 
loan__c = newLoan.id,
interest_payment__c = 300,
principal_payment__c = 100, 
payment_1__c = myDate, 
payment_number2__c = 1, 
year__c = '2015',
Unique_ID__c = 'abvksjfkjri2j');


test.startTest();
insert newLoanPayment;
test.stopTest();
 
 
 
}
}