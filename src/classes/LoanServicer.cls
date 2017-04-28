/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Called from LoanTrigger. 
 *              Creates Loan Payment records based on Loan and Loan Product parameters. 
 *              Loan Payment records would be related to each other through the Prior 
 *              Period Loan Payment lookup.
 * Test: LoanServicerTest
 *************************************************************************************/

public without sharing class LoanServicer implements Database.Batchable<sObject>, Database.Stateful {
    public static final Integer STARTINGPERIOD = 1;
    public static final String FUTURE = 'Future';
    public static final String CURRENT = 'Current';
    public static final String CLOSED = 'Closed';
    public static final String LATE = 'Late';

    public Boolean anyLoansToService;
    private LoanPaymentRepo repo;
    private List<SObject> loansToService = new List<SObject>();
    private Boolean handleInsert;
    private String log = '';

    public LoanServicer(List<Loan__c> loans, Map<Id, Loan__c> triggerOldMap, Boolean handleInsert) {
        this.repo = new LoanPaymentRepo();
        // We want to service all inserts, but only those that have params updated on update
        if (handleInsert) {
            this.loansToService = loans;
        } else {
            for (Loan__c loan :  loans) {
                if (loanParamsUpdated(loan, triggerOldMap)) {
                    this.loansToService.add(loan);
                }
            }
        }
        anyLoansToService = !loansToService.isEmpty();
        this.handleInsert = handleInsert;
    }

    public List<SObject> start(Database.BatchableContext bc) {
        return loansToService;
    }

    public void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        createNewLoanPayments((List<Loan__c>) scope, handleInsert);
    }

    public void finish(Database.BatchableContext batchableContext) {
        String emailTo;
        List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
        if (systemProperties.isEmpty() ||
            systemProperties[0].Error_Email__c == null) {
            emailTo = 'product@bluewavesolar.com';
        } else {
            emailTo = systemProperties[0].Error_Email__c;
        }            

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String> {emailTo});
        email.setSubject('LoanServicer Complete');
        if (loansToService != null) {
            email.setPlainTextBody(loansToService.size() + ' loans processed');
        }
        MessagingService.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }

    // Expects to be called before update to prevent loan parameters from being changed
    // on Complete or Contract Pending loans.
    // If the loan change is valid, the existing Loan Payments would be deleted and
    // recreated
    public void validateLoanChange() {
        List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
        if (systemProperties.size() > 0 &&
            systemProperties[0].Disable_LoanServicer_Validation__c) {
            // Don't validate
        } else {
            for (Loan__c loan : (List<Loan__c>) loansToService) {
                if (loanLocked(loan)) {
                    loan.addError('Cannot update Product, Financing Fee ' +
                                  ' or System Cost for a Loan that is Complete or Contract Pending');
                }
            }
        }
    }

    // Since the DML Record limit is 10,000 and LoanServicer can process up to three records
    // for each Loan Payment (a delete, insert, and update), we want to calculate the biggest
    // batch size for this list
    public static Integer getBatchSize(List<Loan__c> loanList) {
        Decimal maxTerm = 1;
        for (Loan__c loan : loanList) {
            if (loan.Loan_Term__c > maxterm) {
                maxTerm = loan.Loan_Term__c;
            }
        }
        Decimal dmlRecords = (10000/(maxTerm*3)).setScale(0, System.RoundingMode.FLOOR);
        return Integer.valueOf(dmlRecords);
    }

    // Expects to be called after loan insert or update. If a loan isn't locked down,
    // we're safe to delete and re-create loan payments on loan update.
    public void createNewLoanPayments() {
        if (loansToService.size() > 5 && anyLoansToService) {
            Database.executeBatch(this, LoanServicer.getBatchSize(loansToService));
        } else {
            createNewLoanPayments(loansToService, handleInsert);
        }
    }

    
    // Expose a method that can be called from a batch to to process loans
    public void createNewLoanPayments(List<Loan__c> loans, Boolean handleInsert) {
        repo.init();
        for (Loan__c loan : loans) {
            if (populatedForLPCreation(loan)) {
                if (handleInsert) {
                    repo.registerProduct(loan);
                } else if (!loanLocked(loan)) {
                    repo.registerProduct(loan);
                }
            }
        }
        repo.queryProducts();

        for (Loan__c loan : loans) {
            if (populatedForLPCreation(loan)) {
                if (handleInsert) {
                    repo.createLoanPayments(loan);
                } else if (!loanLocked(loan)) {
                    repo.deleteLoanPaymentsForLoan(loan);
                    repo.createLoanPayments(loan);
                }
            }
        }

        repo.executeDML();
    }

    private Boolean populatedForLPCreation(Loan__c loan) {
        if (loan.Product__c != null &&
            loan.Principal__c > 0) {
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

    private Boolean loanParamsUpdated(Loan__c loan, Map<Id, Loan__c> triggerOldMap) {
        if (triggerOldMap != null &&
            (loan.Product__c != triggerOldMap.get(loan.Id).Product__c ||
             loan.Financing_Fee__c != triggerOldMap.get(loan.Id).Financing_Fee__c ||
             loan.Principal__c != triggerOldMap.get(loan.Id).Principal__c)) {
            return true;
        } else {
            return false;
        }
    } 

    private class LoanPaymentRepo {
        private Set<Id> loanIdstoDeleteLPs;
        private List<Loan_Payment__c> loanPaymentsToCreate;
        private Set<Id> productIds;
        private Map<Id, Product2> productMap;
        
        private LoanPaymentRepo() {
        }

        private void init() {
            loanIdstoDeleteLPs = new Set<Id>();
            loanPaymentsToCreate = new List<Loan_Payment__c>();
            productIds = new Set<Id>();
            productMap = new Map<Id, Product2>();
        }

        private void executeDML() {
            deleteLoanPayments();
            insertLoanPayments();
            updateLoanPaymentsWithPrior();
        }

        private void createLoanPayments(Loan__c loan) {
            LoanParams params = new LoanParams(loan, productMap);

            Loan_Payment__c priorLP =null;
            Loan_Payment__c currentLP = null;
            for (Integer period = LoanServicer.STARTINGPERIOD;
                 period < getLoanTermPlusIO(loan.Product__c) + LoanServicer.STARTINGPERIOD; 
                 period++) {
                currentLP = createLP(period, loan, params, priorLP);
                loanPaymentsToCreate.add(currentLP);
                priorLP = currentLP;
            }
        }

        private Loan_Payment__c createLP(Integer period, Loan__c loan, LoanParams params, Loan_Payment__c priorLP) {
            Integer monthIndex;
            Integer payFirstDistribution, paySecondDistribution;
            Boolean isInterestOnly = false, isLastPeriod = false;

            monthIndex = params.firstDistributionMonth + period - LoanServicer.STARTINGPERIOD;
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
            if (period == LoanServicer.STARTINGPERIOD) {
                loanPayment.Bill_Status__c = CURRENT;
            } else {
                loanPayment.Bill_Status__c = FUTURE;
            }
            loanPayment.Loan__c = loan.Id;
            loanPayment.Unique_Id__c = loan.Loan_Number__c + '|' + period;
            loanPayment.Period__c = period;
            loanPayment.Payment_Due_Date2__c = 
                loan.First_Payment_Due_Date__c == null?null:loan.First_Payment_Due_Date__c.addMonths(period - LoanServicer.STARTINGPERIOD);

            loanPayment.Funds_Distributed__c = 
                (params.loanAmount*params.firstDistribution+params.Fees)*payFirstDistribution+
                params.loanAmount*params.secondDistribution*paySecondDistribution;
            loanPayment.Funds_Distributed__c.setScale(2, RoundingMode.HALF_UP);
            if (isInterestOnly) {
                loanPayment.Interest_Only_Period__c = true;
                loanPayment.Amort_Interest_Due__c = loanPayment.Funds_Distributed__c * params.monthlyRate;
                loanPayment.Amort_Principal_Due__c = 0;
            } else {
                loanPayment.Amort_Interest_Due__c = -Excel.ipmt((Double) params.monthlyRate, 
                                                                monthIndex + 1, 
                                                                params.monthsOfPI, 
                                                                (Double) loanPayment.Funds_Distributed__c);
                loanPayment.Amort_Principal_Due__c = -Excel.ppmt((Double) params.monthlyRate, 
                                                                 monthIndex + 1,
                                                                 params.monthsOfPI, 
                                                                 (Double) loanPayment.Funds_Distributed__c);
            }
            loanPayment.Amort_Cumulative_Principal__c = 
                priorLP==null?0:(priorLP.Amort_Cumulative_Principal__c + priorLP.Amort_Principal_Due__c);
            loanPayment.Amort_Starting_Principal__c = 
                loanPayment.Funds_Distributed__c - loanPayment.Amort_Cumulative_Principal__c;

            // Calculated forecasted fields, which would be the same as the Amort schedule for new LPs.
            loanPayment.Forecasted_Loan_Balance__c = loanPayment.Funds_Distributed__c - loanPayment.Amort_Cumulative_Principal__c;
            loanPayment.Forecasted_Interest_Due__c = loanPayment.Amort_Interest_Due__c;
            loanPayment.Forecasted_Principal_Due__c = loanPayment.Amort_Principal_Due__c;
            loanPayment.Forecasted_Principal_Interest_Due__c = loanPayment.Amort_Interest_Due__c + loanPayment.Amort_Principal_Due__c;
            loanPayment.Forecasted_Cumulative_Principal__c = loanPayment.Amort_Cumulative_Principal__c;
            
            return loanPayment;
        }

        private void deleteLoanPaymentsForLoan(Loan__c loan) {
            loanIdsToDeleteLPs.add(loan.Id);
        }

        // Only delete loan payments that weren't manually created
        private void deleteLoanPayments() {
            if (loanIdsToDeleteLPs.size() > 0) {
                List<Loan_Payment__c> loanPayments = [SELECT Id
                                                      FROM Loan_Payment__c
                                                      WHERE Loan__c in :loanIdsToDeleteLPs
                                                      AND Period__c != null];
                if (loanPayments.size() > 0) {
                    delete loanPayments;
                }
            }
        }

        private void insertLoanPayments() {
            insert loanPaymentsToCreate;
        }

        private void updateLoanPaymentsWithPrior() {
            List<Loan_Payment__c> lpsWithPrior = new List<Loan_Payment__c>();
            for (Loan_Payment__c loanPayment : loanPaymentsToCreate) {
                if (loanPayment.Period__c > LoanServicer.STARTINGPERIOD) {
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

        private String getPriorUniqueID(Loan_Payment__c currentLP) {
            // Unique ID is Loan_Number__c|Period
            String loanNumber = currentLP.Unique_Id__c.substringBefore('|');
            return loanNumber + '|' + (currentLP.Period__c - 1);
        }

        private void registerProduct(Loan__c loan) {
            productIds.add(loan.Product__c);
        }

        private void queryProducts() {
            List<Product2> products = [SELECT Id, Loan_Interest_Only_Period__c, Loan_Interest_Rate__c, 
                                       Loan_Term__c, Disbursal_Terms__c
                                       FROM Product2
                                       WHERE Id in :productIds];
            for (Product2 product : products) {
                productMap.put(product.Id, product);
            }
        }

        private Integer getLoanTermPlusIO(Id productId) {
            Product2 product = productMap.get(productId);
            if (product != null) {
                return (product.Loan_Interest_Only_Period__c.intValue() +
                        product.Loan_Term__c.intValue());
            } else {
                return 0;
            }
        }
    }

    private class LoanParams {
        private Product2 product;
        private Integer firstDistributionMonth, secondDistributionMonth;
        private Integer monthsOfPI, monthsOfIO, loanTerm;
        private Decimal loanAmount, fees, loanAmountPlusFees;
        private Decimal annualRate, monthlyRate;
        private Decimal firstDistribution, secondDistribution;

        private LoanParams(Loan__c loan, Map<Id, Product2> productMap) {
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

            fees = nullToZero(loan.Financing_Fee__c);
            loanAmount = loan.Principal__c - fees;
            loanAmountPlusFees = loanAmount + fees;
            annualRate = nullToZero(product.Loan_Interest_Rate__c)/100;
            monthlyRate = annualRate / 12;
            monthsOfPI = nullToZero(product.Loan_Term__c).intValue();
            monthsOfIO = nullToZero(product.Loan_Interest_Only_Period__c).intValue();
            loanTerm = monthsOfPI + monthsOfIO;
        }

        private Decimal nullToZero(Decimal value) {
            return (value==null?0:value);
        }
    }

    public class LoanProductException extends Exception{}

}