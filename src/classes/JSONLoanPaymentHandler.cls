/* Class:       JSONLoanPaymentHandler
 * Created On:  12/19/2016
 * Created by:  OpFocus Team
 * Description: Handles Loan trigger events for creating or updating
 *		Loan Payment records when JSON field is updated on Loan record
 */
 
public class JSONLoanPaymentHandler {
	public static Boolean blnInsideAfterUpdate = false;
	private static final String BACKSLASH = '/';
	private static final String SPACE = ' ';
	

	public JSONLoanPaymentHandler() {
	}


	/* 
	 * Handle all after update events. Right now, the only functionality
	 * being handled is to parse the JSON field on the Loan record and to
	 * create or update existing Loan Payment records mapping JSON
	 * fields to Loan Payment fields
	 */
	public void OnAfterInsert(List<Loan__c> loans) {
		List<Loan__c> loansToUpdate = new List<Loan__c>();
		for (Loan__c loan : loans) {
			//// if our JSON representation is not null, create payments
			System.debug('=====> checking Amortization_Plan__c ' +
				loan.Amortization_Plan__c + ' against null.');
			if (loan.Amortization_Plan__c != null) {
				System.debug('=====> Adding loan to loansToUpdate');
				loansToUpdate.add(loan);
			}
		}
		// if there are no loans to update, return now.
		if (loansToUpdate.isEmpty()) {
			return;
		}
		updateLoanPayments(loansToUpdate);
	}

	/* 
	 * Handle all after update events. Right now, the only functionality
	 * being handled is to parse the JSON field on the Loan record and to
	 * create or update existing Loan Payment records mapping JSON
	 * fields to Loan Payment fields
	 */
	public void OnAfterUpdate(List<Loan__c> loans, Map<Id, Loan__c> oldLoans) {
		if (blnInsideAfterUpdate) {
			System.debug('=====> blnInsideAfterUpdate is true.');
			return;
		}
		List<Loan__c> loansToUpdate = new List<Loan__c>();
		for (Loan__c loan : loans) {
			//// if our JSON representation changed, update our payments
			System.debug('=====> checking Amortization_Plan__c ' +
				loan.Amortization_Plan__c + ' against old value ' + 
				oldLoans.get(loan.Id).Amortization_Plan__c);
			if (loan.Amortization_Plan__c != null && !loan.Amortization_Plan__c.equals(oldLoans.get(loan.Id).Amortization_Plan__c)) {
				System.debug('=====> Adding loan to loansToUpdate');
				loansToUpdate.add(loan);
			}
		}
		// if there are no loans to update, return now.
		if (loansToUpdate.isEmpty()) {
			return;
		}
		updateLoanPayments(loansToUpdate);
	}

	// update Loan Payments based on JSON in LoansToUpdate records
	private void updateLoanPayments(List<Loan__c> loansToUpdate) {
		// first get all the Loan Payment records for the given Loans
		Map<Id, List<Loan_Payment__c>> mapPaymentsByLoan = new Map<Id, List<Loan_Payment__c>>();
		for (Loan_Payment__c payment : [select Id, Loan__c, Payment_1__c, 
				Current_Month_Year__c, Unique_ID__c, Payment_Due_Date2__c from Loan_Payment__c 
				where Loan__c in :loansToUpdate order by Loan__c, Year2__c, Month__c]) {
			if (mapPaymentsByLoan.get(payment.Loan__c) == null) {
				mapPaymentsByLoan.put(payment.Loan__c, new List<Loan_Payment__c>());
			}
			mapPaymentsByLoan.get(payment.Loan__c).add(payment);
		}

		List<Loan_Payment__c> paymentsToAdd = new List<Loan_Payment__c>();
		for (Loan__c loan : loansToUpdate) {
			// parse our JSON string into an array of LoanPaymentJSON objects
			Map<String, LoanPaymentJSON> mapJsonDataByUniqueId = new Map<String, LoanPaymentJSON>();
			for (LoanPaymentJSON jsonData : (List<LoanPaymentJSON>)JSON.deserialize(loan.Amortization_Plan__c, List<LoanPaymentJSON>.class)) {
				System.debug('======> putting row in mapJsonDataByUniqueId for jsonData = ' + 
					JSON.serializePretty(jsonData));
				mapJsonDataByUniqueId.put(generateUniqueId(loan, jsonData), jsonData);
			}
			// get our Loan Payments and either insert or update
			// with the Loan Payment JSON data
			if (mapPaymentsByLoan.get(loan.Id) == null) {
				// no Payments exist yet - create new ones for all of our JSON data
				for (LoanPaymentJSON jsonData : mapJsonDataByUniqueId.values()) {
					paymentsToAdd.add(createLoanPayment(loan, jsonData));					
				}
			} else {
				// first lets remove all non-paid payments
				List<Loan_Payment__c> paymentsToDelete = new List<Loan_Payment__c>();
				Map<String, Loan_Payment__c> mapPaymentsToKeep = new Map<String, Loan_Payment__c>();
				for (Loan_Payment__c payment : mapPaymentsByLoan.get(loan.Id)) {
					if (payment.Payment_1__c == null) {
						System.debug('======> Deleting Payment ' + 
							JSON.serializePretty(payment));
						paymentsToDelete.add(payment);
						// remove it from our map
					} else {
						System.debug('======> Keeping Payment ' + 
							JSON.serializePretty(payment) + ' with UniqueId = ' + 
							payment.Unique_ID__c);
						mapPaymentsToKeep.put(payment.Unique_ID__c, payment);
					}
				}

				// now remove all unpaid payments
				blnInsideAfterUpdate = true;
				delete paymentsToDelete;
				blnInsideAfterUpdate = false;
				// now we need to create new Loan Payments for the
				// JSON data values UNLESS a Record already exists
				// for same date in which case leave it and discard
				// JSON data
				for (LoanPaymentJSON jsonData : mapJsonDataByUniqueId.values())  {
					System.debug('======> looking for payment for UniqueId = ' + 
						generateUniqueId(loan, jsonData));
					if (mapPaymentsToKeep.get(generateUniqueId(loan, jsonData)) != null) {
						System.debug('=======> Found an existing Loan Record so skipping JSON data = '  +
							JSON.serializePretty(jsonData));
						continue;
					} else {
						System.debug('=======> Inserting new Loan Payment for jsonData = ' + 
							JSON.serializePretty(jsonData));
						paymentsToAdd.add(createLoanPayment(loan, jsonData));
					}
				}
			}
		}
		if (!paymentsToAdd.isEmpty()) {
			insert paymentsToAdd;
		}
	}

	private Loan_Payment__c createLoanPayment(Loan__c loan, LoanPaymentJSON jsonData) {
		// payment Due Date is always 1st day of the month
		Date paymentDate = Date.newInstance(jsonData.cy, jsonData.cm, 1);
		
		// Set the Loan Payment Name as a concatentation of the following:
		// Loan.Name+space+Month+space+Year. 
		// Put a leading zero in the month if necessary. 
		// If value is longer than 80 characters, then truncate it
		String name = loan.Name + SPACE + (jsonData.cm < 10 ? '0' : '') + jsonData.cm + SPACE + jsonData.cy;
		if (name.length() > 80) {
			name = name.abbreviate(80);
		}
		System.debug('======> Setting Loan Payment Name = ' + name);
		Loan_Payment__c payment = new Loan_Payment__c(Name=name, Loan__c=loan.Id,
			Interest_Payment__c=jsonData.ip, Principal_Payment__c=jsonData.pp,
			Payment__c = jsonData.lp, Remaining_Principal_Balance__c=jsonData.lb, 
			Payment_Due_Date2__c=paymentDate,
			Unique_ID__c=generateUniqueId(loan, jsonData));
		System.debug('=======> Inserting Loan Payment ' + JSON.serializePretty(payment));

		return payment;
	}

	private String generateUniqueId(Loan__c loan, LoanPaymentJSON jsonData) {
		return loan.Id + BACKSLASH + (jsonData.cm < 10 ? '0' : '') + jsonData.cm + 
			BACKSLASH + jsonData.cy;
	}

	private String generateUniqueId(Loan_Payment__c payment) {
		return payment.Payment_Due_Date2__c.year() + '_' + payment.Payment_Due_Date2__c.month();
	}

	private String generateDateKey(LoanPaymentJSON jsonData) {
		String dateKey= jsonData.cy + '_' + jsonData.cm + '';
		System.debug('======> Generating dateKey for ' + 
			JSON.serializePretty(jsonData) + ', dateKey = ' + dateKey);
		return dateKey;
		//return jsonData.cy + '' + jsonData.cm + '';
	}
}