@isTest
private class DOERCalculatorLoanTest{

Static testMethod void DOERCalculatorLoanTest(){

account newAccount = new Account(name = 'Testcase');
insert newAccount;

Date myDate = Date.newInstance(2015, 8, 30);

loan_data__c newLoanData = new loan_data__c (name = 'Loan Data', month__c = 'August', year__c = '2015');
insert newLoanData;

loan_traunch__c newLoanTranche = new loan_traunch__c (loan_data__c = newLoanData.id, name = 'Loan Tranche');
insert newLoanTranche;

opportunity newOp = new opportunity(name ='Cole Swain', email__c ='cswain@bluewave-capital.com', commencement_date__c = myDate, account = newAccount, Loan_Principle__c = 25000, stageName = 'new', type = 'New Business', closeDate = myDate, loan_traunch__c = newLoanTranche.id ) ;
Insert newOp;

MCEC_Report_Data__c newPipeLine = new MCEC_Report_Data__c(name = 'Test', opportunity__c = newOp.id);
insert newPipeLine;

loan__c newLoan = new loan__c(name = 'Loan', opportunity__c = newOp.id, Principall__c = 37707, loan_tranche__c = newLoanTranche.id, DOER_Loan_Base_Rate__c = 0.0625, BlueWave_Avidia_Rate__c = 0.05, IRBD_Rate__c = 0.0325, Principal_and_Interest_Period_DOER__c = 120, DOER_Solar_loann__c = TRUE);
insert newLoan;

newLoanData.month__c = 'September';
newLoanData.year__c = '2016';

update newLoanData;
update newLoanTranche;
update newLoan;

loan_payment__c newLoanPayment = new loan_payment__c (Unique_ID__c = 'abvksjfkjri2j', name = 'Loan Payment', loan__c = newLoan.id, payment_1__c = myDate, payment_number2__c = 1, year__c = '2015');

test.startTest();

insert newLoanPayment;
 
test.stopTest();
 
 
}
}