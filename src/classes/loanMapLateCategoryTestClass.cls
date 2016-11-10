@isTest
private class loanMapLateCategoryTestClass {

Static testMethod void MapLateCategory(){

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

loan__c newLoan = new loan__c(name = 'Loan', opportunity__c = newOp.id, loan_tranche__c = newLoanTranche.id);

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
 
loan__c loanQuery = [SELECT late_category__c FROM loan__c WHERE name = 'Loan'];
 
system.assertEquals(null, loanQuery.late_category__c);
 
 
}
}