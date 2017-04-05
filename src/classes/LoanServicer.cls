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

    // Expects to be called before update to prevent loan parameters from being changed
    // on Complete or Contract Pending loans.
    // If the loan change is valid, the existing Loan Payments would be deleted and
    // recreated
    public void validateLoanChange() {
        for (Loan__c loan : (List<Loan__c>) Trigger.new) {
            if (loanLocked(loan) && loanParamsUpdated(loan)) {
                loan.addError('Cannot update Product, Commencement date, or System Cost ' +
                              'for a Loan that is Complete or Contract Pending');
            }
        }
    }

    // Expects to be called after loan insert or update. If a loan isn't locked down,
    // we're safe to delete and re-create loan payments on loan update.
    public void createNewLoanPayments() {
        for (Loan__c loan : (List<Loan__c>) Trigger.new) {
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

        for (Loan__c loan : (List<Loan__c>) Trigger.new) {
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
            loan.Acquisition_Status__c == 'Contract Pending') {
            return true;
        } else {
            return false;
        }
    }

    private Boolean loanParamsUpdated(Loan__c loan) {
        Map<Id, Loan__c> triggerOldMap = (Map<Id, Loan__c>) Trigger.oldMap;
        if (loan.Product__c != triggerOldMap.get(loan.Id).Product__c ||
            loan.Commencement_Datee__c != triggerOldMap.get(loan.Id).Commencement_Datee__c ||
            loan.System_Costt__c != triggerOldMap.get(loan.Id).System_Costt__c) {
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

    public class LoanPaymentRepo {
        private Set<Id> loanIdstoDeleteLPs;
        private List<Loan_Payment__c> loanPaymentsToCreate;
        private Set<Id> productIds;
        private Map<Id, Product2> productMap;
        
        public LoanPaymentRepo() {
            loanIdstoDeleteLPs = new Set<Id>();
            loanPaymentsToCreate = new List<Loan_Payment__c>();
            productIds = new Set<Id>();
            productMap = new Map<Id, Product2>();
        }

        public void executeDML() {
            deleteLoanPayments();
            insertLoanPayments();
            updateLoanPaymentsWithPrior();
        }

        public void createLoanPayments(Loan__c loan) {
            LoanParams params = new LoanParams(loan, productMap);

            for (Integer period = 0; period < getLoanTermPlusIO(loan.Product__c); period++) {
                loanPaymentsToCreate.add(createLP(period, loan, params));
            }
        }

        private Loan_Payment__c createLP(Integer period, Loan__c loan, LoanParams params) {
            Integer monthIndex;
            Integer payFirstDistribution, paySecondDistribution;
            Boolean isInterestOnly = false, isLastPeriod = false;

            monthIndex = params.firstDistributionMonth + period;
            if (monthIndex < 0) {
                isInterestOnly = true;
            }

            if (monthIndex + 1 == params.monthsOfPI) {
                isLastPeriod = true;
            }

            // We always pay the first distribution
            payFirstDistribution = 1;

            if (monthIndex >= params.secondDistributionMonth) {
                paySecondDistribution = 1;
            } else {
                paySecondDistribution = 0;
            }

            Loan_Payment__c loanPayment = new Loan_Payment__c();
            loanPayment.Loan__c = loan.Id;
            loanPayment.Unique_Id__c = loan.Loan_Number__c + '|' + period;
            loanPayment.Period__c = period;
            loanPayment.Funds_Distributed__c = 
                (params.loanAmount*params.firstDistribution+params.Fees)*payFirstDistribution+
                params.loanAmount*params.secondDistribution*paySecondDistribution;
            loanPayment.Funds_Distributed__c.setScale(2, RoundingMode.HALF_UP);
            if (isInterestOnly) {
                Decimal interestPayment = -loanPayment.Funds_Distributed__c * params.monthlyRate;
                loanPayment.Interest_Due__c = interestPayment.setScale(2, RoundingMode.HALF_UP);
                loanPayment.Principal_Due__c = 0;
            } else {
                loanPayment.Interest_Due__c = Excel.ipmtRounded((Double) params.monthlyRate, 
                                                                monthIndex + 1, 
                                                                params.monthsOfPI, 
                                                                (Double) loanPayment.Funds_Distributed__c);
                loanPayment.Principal_Due__c = Excel.ppmtRounded((Double) params.monthlyRate, 
                                                                 monthIndex + 1,
                                                                 params.monthsOfPI, 
                                                                 (Double) loanPayment.Funds_Distributed__c);
            }
            return loanPayment;
        }

        public void deleteLoanPaymentsForLoan(Loan__c loan) {
            loanIdsToDeleteLPs.add(loan.Id);
        }

        public void deleteLoanPayments() {
            if (loanIdsToDeleteLPs.size() > 0) {
                List<Loan_Payment__c> loanPayments = [SELECT Id
                                                      FROM Loan_Payment__c
                                                      WHERE Loan__c in :loanIdsToDeleteLPs];
                if (loanPayments.size() > 0) {
                    delete loanPayments;
                }
            }
        }

        public void insertLoanPayments() {
            if (loanPaymentsToCreate.size() > 0) {
                insert loanPaymentsToCreate;
            }
        }

        public void updateLoanPaymentsWithPrior() {
            List<Loan_Payment__c> lpsWithPrior = new List<Loan_Payment__c>();
            for (Loan_Payment__c loanPayment : loanPaymentsToCreate) {
                if (loanPayment.Period__c > 0) {
                    Loan_Payment__c lpReference = 
                        new Loan_Payment__c(Unique_Id__c = getPriorUniqueID(loanPayment));
                    loanPayment.Prior_Period_Loan_Payment__r = lpReference;
                    lpsWithPrior.add(loanPayment);
                }
            }

            if (lpsWithPrior.size() > 0) {
                update lpsWithPrior;
            }
        }

        public String getPriorUniqueID(Loan_Payment__c currentLP) {
            // Unique ID is Loan_Number__c|Period
            String loanNumber = currentLP.Unique_Id__c.substringBefore('|');
            return loanNumber + '|' + (currentLP.Period__c - 1);
        }

        public void registerProduct(Loan__c loan) {
            productIds.add(loan.Product__c);
        }

        public void queryProducts() {
            List<Product2> products = [SELECT Id, Loan_Interest_Only_Period__c, Loan_Interest_Rate__c, 
                                       Loan_Term__c, Disbursal_Terms__c
                                       FROM Product2
                                       WHERE Id in :productIds];
            for (Product2 product : products) {
                productMap.put(product.Id, product);
            }
        }

        public Integer getLoanTermPlusIO(Id productId) {
            Product2 product = productMap.get(productId);
            if (product != null) {
                return (product.Loan_Interest_Only_Period__c.intValue() +
                        product.Loan_Term__c.intValue());
            } else {
                return 0;
            }
        }
    }

    public class LoanParams {
        public Product2 product;
        public Integer firstDistributionMonth, secondDistributionMonth;
        public Integer monthsOfPI, monthsOfIO, loanTerm;
        public Decimal loanAmount, fees, loanAmountPlusFees;
        public Decimal annualRate, monthlyRate;
        public Decimal firstDistribution, secondDistribution;

        public LoanParams(Loan__c loan, Map<Id, Product2> productMap) {
            product = productMap.get(loan.Product__c);
            if (product == null) {
                throw new LoanProductException('No product (' + loan.Product__c + 
                                               ') found in repo for this loan (' + loan.Id + ')');
            }

            // First Distribution Month is negative because the Second Distribution
            // is 0 and starts the Loan Term
            if (product.Loan_Interest_Only_Period__c == null ||
                product.Loan_Interest_Only_Period__c > 0) {
                firstDistributionMonth = -product.Loan_Interest_Only_Period__c.intValue();
            } else {
                firstDistributionMonth = 0;
            }
            // Second Distribution is always 0 so that there are as many months
            // in the second distribution as there are in the Loan Term
            secondDistributionMonth = 0;

            if (product.Disbursal_Terms__c == 
                '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection') {
                firstDistribution = 1;
                secondDistribution = 0;
            } else if (product.Disbursal_Terms__c == 
                       '35% Contract Signature, 65% Interconnection') {
                firstDistribution = .35;
                secondDistribution = .65;
            } else {
                throw new LoanProductException('Disbural Terms: ' + product.Disbursal_Terms__c + 
                                               ' is not handled');
            }

            fees = loan.Financing_Fee__c==null?0:loan.Financing_Fee__c;
            loanAmount = loan.System_Costt__c - fees;
            loanAmountPlusFees = loanAmount + fees;
            annualRate = product.Loan_Interest_Rate__c==null?0:product.Loan_Interest_Rate__c/100;
            monthlyRate = annualRate / 12;
            monthsOfPI = product.Loan_Term__c==null?0:product.Loan_Term__c.intValue();
            monthsOfIO = product.Loan_Interest_Only_Period__c==null?0:product.Loan_Interest_Only_Period__c.intValue();
            loanTerm = monthsOfPI + monthsOfIO;
        }
    }

    public class LoanProductException extends Exception{}

}