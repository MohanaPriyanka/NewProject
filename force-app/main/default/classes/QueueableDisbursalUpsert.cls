/**
 * Created by abarnes on 12/6/2018.
 */

public class QueueableDisbursalUpsert implements Queueable {

    private Loan__c loan;

    public QueueableDisbursalUpsert(Loan__c newLoan) {
        this.loan = newLoan;
    }

    public void execute(QueueableContext context) {
        Map<String, String> disbursalStatuses = new Map<String, String>();
        Map<String, Decimal> disbursalAmounts = new Map<String, Decimal>();
        List<Disbursal__c> disbursals = new List<Disbursal__c>();
        List<Id> loanIds = new List<Id> {loan.Id};
        List<Loan__c> loanList = new List<Loan__c> {loan};

        Partner__c partner = [SELECT Id, Name FROM Partner__c WHERE Id = :loan.Partner__c];
        Product2 product = [SELECT Id, Disbursal_Terms__c FROM Product2 WHERE Id = :loan.Product__c];

        loan.Product__r = product;
        loan.Partner__r = partner;

        DisbursalHandler dh = new DisbursalHandler();

        loanIds = dh.getLoanIdsFromLoanList(loanList);
        disbursals = dh.getDisbursalsFromLoan(loanIds);
        disbursalStatuses = dh.getDisbursalStatusMap(disbursals);
        disbursalAmounts = dh.getDisbursalAmountMap(disbursals);
        disbursals = dh.createAndTrueUpDisbursals(loanList, disbursalStatuses, disbursalAmounts);
        upsert disbursals Unique_ID__c;
    }

}