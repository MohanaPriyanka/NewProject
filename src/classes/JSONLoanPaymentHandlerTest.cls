/* Class:       JSONLoanPaymentHandlerTest
 * Created On:  12/19/2016
 * Created by:  OpFocus Team
 * Description: Unit tests for the JSON Loan Payment Handler
 */
 @IsTest
private class JSONLoanPaymentHandlerTest {
	private static final String jsonData = '[{"yn":-1,"pp":0,"mn":-5,"lp":-26.2,"lb":9673.34,"ip":-26.2,"cy":2016,"ct":1,"cm":3},' +
	'{"yn":-1,"pp":0,"mn":-4,"lp":-26.2,"lb":9673.34,"ip":-26.2,"cy":2016,"ct":1,"cm":4},' +
	'{"yn":-1,"pp":0,"mn":-3,"lp":-26.2,"lb":9673.34,"ip":-26.2,"cy":2016,"ct":1,"cm":5},' +
	'{"yn":-1,"pp":0,"mn":-2,"lp":-26.2,"lb":9673.34,"ip":-26.2,"cy":2016,"ct":1,"cm":6},' +
 	'{"yn":-1,"pp":0,"mn":-1,"lp":-26.2,"lb":27638.1,"ip":-26.2,"cy":2016,"ct":1,"cm":7}]';

	private static final String updatedJsonData = '[{"yn":-1,"pp":0,"mn":-5,"lp":-1000.00,"lb":9673.34,"ip":-1000.00,"cy":2016,"ct":1,"cm":3},' +
	'{"yn":-1,"pp":0,"mn":-4,"lp":-1000.00,"lb":9673.34,"ip":-1000.00,"cy":2016,"ct":1,"cm":4},' +
	'{"yn":-1,"pp":0,"mn":-3,"lp":-1000.00,"lb":9673.34,"ip":-1000.00,"cy":2016,"ct":1,"cm":5},' +
	'{"yn":-1,"pp":0,"mn":-2,"lp":-1000.00,"lb":9673.34,"ip":-1000.00,"cy":2016,"ct":1,"cm":6},' +
 	'{"yn":-1,"pp":0,"mn":-1,"lp":-1000.00,"lb":27638.1,"ip":-1000.00,"cy":2016,"ct":1,"cm":7}]';

	@testSetup static void buildData() {
		Account acct = new Account(Name='Test Account');
		insert acct;

		Opportunity opp = new Opportunity(AccountId=acct.Id, Name='Test Opp', 
				CloseDate=Date.today(), StageName='New');
		insert opp;

		Loan_Data__c capPool = new Loan_Data__c(Name='Test Pool', 
			Pool_Type__c='Revolving Credit Line');
		insert capPool;

		Loan_Traunch__c loanTranche = new Loan_Traunch__c(Loan_Data__c=capPool.Id);
		insert loanTranche;

		Loan__c loan = new Loan__c(Loan_Tranche__c=loanTranche.Id);
		insert loan;
	}

	//test methods
	static testMethod void testCreateLoanPayments() {
		Loan_Traunch__c loanTranche = [select Id from Loan_Traunch__c limit 1];
		Loan__c loan = new Loan__c(Loan_Tranche__c=loanTranche.Id, Name='Test Loan', 
			Amortization_Plan__c=jsonData);

		Test.startTest();
			insert loan;
		Test.stopTest();

		List<Loan_Payment__c> payments = [select Id, Name, Unique_ID__c, 
			Payment_Due_Date2__c from Loan_Payment__c];
		
		// verify that we created the right number of Loan Payment records
		System.assertEquals(5, payments.size(),
			'Failed to create Loan Payment records from JSON data');

		// make sure unique id and loan name are correct
		for (Loan_Payment__c payment : payments) {
			String name = loan.Name + ' ' + 
				(payment.Payment_Due_Date2__c.month() < 9 ? '0' : '') + 
				payment.Payment_Due_Date2__c.month() + ' ' + payment.Payment_Due_Date2__c.year();
			System.assertEquals(name, payment.Name, 'Failed to set Name correctly.');
		}
	}	

	//test methods
	static testMethod void testReplaceLoanPayments() {
		Loan__c loan = [select Id from Loan__c limit 1];
		loan.Amortization_Plan__c = jsonData;
		update loan;

		// now lets mark 1 payment as being paid
		Date firstPaymentDate = Date.newInstance(2016,3,1);
		Loan_Payment__c payment = [select Id, Current_Month_Year__c, Payment_1__c from Loan_Payment__c 
			where Payment_Due_Date2__c=:firstPaymentDate limit 1];
		payment.Payment_1__c = Date.today().addDays(-2);
		update payment;

		loan.Amortization_Plan__c = updatedJsonData;
		// now lets replace the Loan Payments
		Test.startTest();
			update loan;
		Test.stopTest();

		// verify that the payment that was paid remained 
		System.assertEquals(1, [select Id from Loan_Payment__c where Payment_1__c != null].size(),
			'Failed to keep a paid Loan Payment');
	}	

	static testMethod void testLoanPaymentJSON() {
		Test.startTest();
			LoanPaymentJSON lpJSON = new LoanPaymentJSON();
			lpJSON.yn = 1;
			lpJSON.pp = 1.0;
			lpJSON.mn = 1;
			lpJSON.lp = 2.0;
			lpJSON.lb = 1000.00;
			lpJSON.ip = 100.00;
			lpJSON.cy = Date.today().year();
			lpJSON.ct = Date.today().day();
			lpJSON.cm = Date.today().month();

			JSON.serializePretty(lpJSON);
		Test.stopTest();
	}
}