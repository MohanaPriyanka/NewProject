/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Called from LoanTrigger. 
 *              Creates Loan Payment records based on Loan and Loan Product parameters. 
 *              Loan Payment records would be related to each other through the Prior 
 *              Period Loan Payment lookup.
 * Test: LoanServicerTest
 *************************************************************************************/

public with sharing class LoanServicer {
    private LoanPaymentRepo repo;

    public LoanServicer() {
        repo = new LoanPaymentRepo();
    }

    public void validateLoanChange() {
        for (Loan__c loan : Trigger.new) {
            if (loanLocked(loan)) {
                loan.addError('Cannot update Product, Commencement date, or System Cost ' +
                              'for a Loan that is Complete or Contract Pending');
            }
        }
    }

    // Expects to be called after loan insert or update. If a loan isn't locked down,
    // we're safe to delete and re-create loan payments on loan update.
    public void createNewLoanPayments() {
        for (Loan__c loan : Trigger.new) {
            if (populatedForLPCreation(loan)) {
                if (Trigger.isInsert) {
                    repo.registerProduct(loan);
                } else if (!loanLocked(loan) &&
                           loanParamsUpdated(loan)) {
                    repo.registerProduct(loan);
                }
            }
        }
        repo.queryProducts();

        for (Loan__c loan : Trigger.new) {
            if (populatedForLPCreation(loan)) {
                if (Trigger.isInsert) {
                    repo.createLoanPayments(loan);
                } else if (!loanLocked(loan) &&
                           loanParamsUpdated(loan)) {
                    repo.deleteLoanPaymentsForLoan(loan);
                    repo.createLoanPayments(loan);
                }
            }
        }

        repo.executeDML();
    }

    private Boolean populatedForLPCreation(Loan__c loan) {
        if (loan.Product__c != null &&
            loan.Commencement_Datee__c != null &&
            loan.System_Costt__c > 0) {
            return true;
        } else {
            return false;
        }
    }

    private Boolean loanLocked(Loan__c loan) {
        if (loan.Acquisition_Status__c == 'Complete' ||
            loan.Acquistion_Status__c == 'Contract Pending') {
            return true;
        } else {
            return false;
        }
    }

    private Boolean loanParamsUpdated(Loan__c loan) {
        if (loan.Product__c != Trigger.oldMap.get(loan.Id).Product__c ||
            loan.Commencement_Datee__c != Trigger.oldMap.get(loan.Id).Commencement_Datee__c ||
            loan.System_Costt__c != Trigger.oldMap.get(loan.Id).System_Costt__c) {
            return true;
        } else {
            return false;
        }
    } 

    private Boolean requiresLoanPaymentRecalc(Loan__c loan) {
        if (!loanLocked(loan) &&
            loanParamsUpdated(loan)) {
            return true;
        } else {
            return false;
        }
    }

    // Assumes there are 
    public class LoanPaymentRepo {
        private Set<Id> loanIdstoDeleteLPs;
        private List<Loan_Payment__c> loanPaymentsToCreate;
        private Set<Id> productIds;
        private Map<Id, Product__c> productMap;
        
        public LoanPaymentRepo() {
            loanIdstoDeleteLPs = new Set<Id>();
            loanPaymentsToCreate = new List<Loan_Payment__c>();
            productIds = new Set<Id>();
            productMap = new Map<Id, Product2>();
        }

        public void executeDML() {
            deleteLoanPayments();
            // saveNewLoanPayments();
            // updateNewLoanPayments();
        }

        public void createLoanPayments(Loan__c loan) {
            for (Integer period = 0; period < loanTermPlusIO; period++) {
                loanPaymentsToCreate.add(createLP(period, loan);
            }
        }

        private Loan_Payment__c createLP(Integer period, Loan__c loan) {
            Loan_Payment__c loanPayment = new Loan_Payment__c();
            loanPayment.Unique_Id__c = loan.Loan_Number__c + '|' + period;
            loanPayment.Period__c = period;

        }

        public void deleteLoanPaymentsForLoan(Loan__c loan) {
            loanIdsToDeleteLPs.add(loan.Id);
        }

        public deleteLoanPayments() {
            if (loanIdstoDeleteLPs.size() > 0) {
                List<Loan_Payment__c> loanPayments = [SELECT Id
                                                      FROM Loan_Payment__c
                                                      WHERE Loan__c in :loanIds];
                if (loanPayments.size() > 0) {
                    delete loanPayments;
                }
            }
        }

        public void registerProduct(Loan__c loan) {
            productIds.add(loan.Product__c);
        }

        public void queryProducts() {
            productMap = [SELECT Id, Loan_Interest_Only_Period__c, Loan_Term__c, Loan_Interest_Rate__c
                          FROM Product2
                          WHERE Id in :productIds];
        }
    }

}