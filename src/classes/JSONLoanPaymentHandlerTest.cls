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

        Loan_Data__c capitalPool = new Loan_Data__c(Name = 'Revolving Credit Line',
                                                Total_Capital__c = 10000000,
                                                Investor__c = 'The Bank',
                                                Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

        Date myDate = Date.newInstance(2015, 2, 17);
        Date codDate = Date.newInstance(2015, 4, 17);
        Date codDateTwo = Date.newInstance(2015, 7, 17);

        Loan_Traunch__c loanTrancheMA = new Loan_Traunch__c(
            Name = 'Avidia 1',
            Tranche_Cap__c = 1000000,
            Tranche_Type__c = 'Standard',
            State__c = 'MA',
            Stage__c = 'Open',
            Loan_Data__c = capitalPool.id);
        insert loanTrancheMA;  

        Loan_Traunch__c loanTranchePending = new Loan_Traunch__c(
            Name = 'Tranche Assignment Pending',
            Tranche_Type__c = 'Holding',
            Stage__c = 'Closed',
            Loan_Data__c = capitalPool.id);
        insert loanTranchePending;                  

        partner__c partner = new partner__c(name = 'Partner');
        insert partner;

        bsst__c newSalesId = new BSST__c (name = 'Cole Swain', partner__c = partner.id, custom_id__c = 'Cole 1');
        
        insert NewSalesId;  
             
        bsst__c salesIdQuery = [SELECT id FROM Bsst__c WHERE Name = 'Cole Swain'];

        Lead newLead = new lead(FirstName = 'Retired',
                                    LastName = 'Test',
                                    Loan_Amount__c = 25000,
                                    Company = 'Cole Swain',
                                    Retired__c = true,
                                    LASERCA__Social_Security_Number__c = '000000001',
                                    Product_Line__c = 'Residential Loan',
                                    LASERCA__Home_State__c = 'MA',
                                    System_Cost__c = 25000,
                                    Unfinished_Lead__c = true,
                                    Custom_Id__c = 'test',
                                    Loan_Term__c = 120,
                                    Partner_Lookup__c = partner.Id,
                                    Pre_Approval_Form__c = true,
                                    //Personal_Credit_Report__c = creditReportRecord.Id,
                                    Annual_Income_Currency__c = 150000,
                                    Product__c = null,
                                    Product_Program__c = 'BlueWave Solar Loan',
                                    Automatic_Product_Assignment__c = true,
                                    Status = 'Ready for Credit Check');
        insert newLead;
        newLead.Unfinished_Lead__c = false;
        update newLead;
        newLead.Status = 'Pending Information';
        update newLead;
        newLead.Status = 'Qualified';
        update newLead;
	}

	//test methods
	static testMethod void testCreateLoanPayments() {
		Loan_Traunch__c loanTranche = [select Id from Loan_Traunch__c limit 1];
		Loan__c loan = [SELECT Id FROM Loan__c LIMIT 1];
		loan.Amortization_Plan__c = jsonData;
		loan.Name = 'Test Loan';

		//Loan__c loan = new Loan__c(Loan_Tranche__c=loanTranche.Id, Name='Test Loan', 
			//Amortization_Plan__c=jsonData);

		Test.startTest();
			update loan;
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