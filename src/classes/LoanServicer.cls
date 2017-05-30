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
    private Map<Id, Loan__c> triggerOldMap;
    private List<SObject> loansToService = new List<SObject>();
    private Boolean handleInsert;
    private String log = '';

    // handleInsert does two things: if true, doesn't check for params being updated to do the upsert, and
    // sets the first Bill Status to be Current and all others to be Future.
    public LoanServicer(List<Loan__c> loans, Map<Id, Loan__c> triggerOldMap, Boolean handleInsert) {
        this.repo = new LoanPaymentRepo();
        this.triggerOldMap = triggerOldMap;
        // We want to service all inserts, but only those that have params updated on update
        if (handleInsert) {
            this.loansToService = loans;
        } else {
            for (Loan__c loan : loans) {
                if (loanParamsUpdated(loan)) {
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
        upsertLoanPayments((List<Loan__c>) scope, handleInsert);
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
        if (!systemProperties.isEmpty() &&
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

    // Expects to be called after loan insert or update.
    public void upsertLoanPayments() {
        if (loansToService.size() > 5 && anyLoansToService) {
            Database.executeBatch(this, LoanServicer.getBatchSize(loansToService));
        } else {
            upsertLoanPayments(loansToService, handleInsert);
        }
    }

    
    // Expose a method that can be called from a batch to to process loans
    public void upsertLoanPayments(List<Loan__c> loans, Boolean handleInsert) {
        List<Loan__c> loansNeedingTAReapplication = new List<Loan__c>();
        repo.init(loans);

        for (Loan__c loan : loans) {
            if (populatedForLPCreation(loan)) {
                if (handleInsert) {
                    repo.createLoanPayments(loan, handleInsert);
                } else {
                    repo.checkLoanForLPsToDelete(loan);
                    repo.createLoanPayments(loan, handleInsert);
                    loansNeedingTAReapplication.add(loan);
                }
            }
        }

        repo.executeDML();

        // We now have new Loan Payments for a new and updated loan. If there
        // are any transaction applications for updated loans, we need to re-apply them.
        // We need to do this after the LPs are updated 
        if (!loansNeedingTAReapplication.isEmpty()) {
            List<Transaction_Application__c> taList = [SELECT Id, Loan_Payment__c,
                                                       Interest_Applied__c, Principal_Applied__c, Principal_Paydown_Reason__c
                                                       FROM Transaction_Application__c
                                                       WHERE Loan_Payment__r.Loan__r.Id = :loansNeedingTAReapplication];
            TransactionApplicationHandler tah = new TransactionApplicationHandler(taList);
            tah.rollupAndCalculate();
        }
    }

    public static Boolean appliesTo(Date testDate, Loan_Payment__c generatedLP) {
        Date dueDate = generatedLP.Payment_Due_Date2__c;
        if (dueDate == null) {
            return false;
        }
        Date dateOpened = dueDate - 20;
        Date dateClosed = Date.newInstance(dueDate.year(), dueDate.month()+1, dueDate.day()-20);

        return (dateOpened < testDate && testDate <= dateClosed);
    }

    public static Boolean populatedForLPCreation(Loan__c loan) {
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

    private Boolean loanParamsUpdated(Loan__c loan) {
        if (triggerOldMap != null &&
            (loan.Product__c != triggerOldMap.get(loan.Id).Product__c ||
             loan.Financing_Fee__c != triggerOldMap.get(loan.Id).Financing_Fee__c ||
             loan.Principal__c != triggerOldMap.get(loan.Id).Principal__c ||
             loan.Interest_Only_Period_DOER__c != triggerOldMap.get(loan.Id).Interest_Only_Period_DOER__c ||
             loan.First_Payment_Due_Date_Override__c != triggerOldMap.get(loan.Id).First_Payment_Due_Date_Override__c)) {
            return true;
        } else {
            return false;
        }
    }

    private Boolean ioPeriodUpdated(Loan__c loan) {
        if (triggerOldMap != null &&
            loan.Interest_Only_Period_DOER__c != triggerOldMap.get(loan.Id).Interest_Only_Period_DOER__c) {
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

        private void init(List<Loan__c> loans) {
            for (Loan__c loan : loans) {
                if (populatedForLPCreation(loan)) {
                    registerProduct(loan);
                }
            }
            queryProducts();
        }

        public void init(Set<Id> products) {
            productIds = products;
            queryProducts();
        }

        private void executeDML() {
            upsertLoanPayments();
            updateLoanPaymentsWithPrior();
            deleteLoanPayments();
        }

        private void createLoanPayments(Loan__c loan, Boolean isInsert) {
            LoanParams params = new LoanParams(loan, productMap);

            Loan_Payment__c priorLP =null;
            Loan_Payment__c currentLP = null;
            for (Integer period = LoanServicer.STARTINGPERIOD;
                 period < params.loanTerm + LoanServicer.STARTINGPERIOD; 
                 period++) {
                currentLP = createLP(period, loan, params, priorLP, isInsert);
                loanPaymentsToCreate.add(currentLP);
                priorLP = currentLP;
            }
        }

        private Loan_Payment__c createLP(Integer period, Loan__c loan, LoanParams params, Loan_Payment__c priorLP, Boolean setBillStatus) {
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
            if (setBillStatus) {
                if (period == LoanServicer.STARTINGPERIOD) {
                    loanPayment.Bill_Status__c = CURRENT;
                } else {
                    loanPayment.Bill_Status__c = FUTURE;
                }
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
                loanPayment.Interest_Only_Period__c = false;
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

            // Calculate forecasted fields and actual due, which would be the same as the Amort schedule for new LPs.
            loanPayment.Actual_PI_Due__c = loanPayment.Amort_Interest_Due__c + loanPayment.Amort_Principal_Due__c;
            loanPayment.Forecasted_Loan_Balance__c = loanPayment.Funds_Distributed__c - loanPayment.Amort_Cumulative_Principal__c;
            loanPayment.Forecasted_Interest_Due__c = loanPayment.Amort_Interest_Due__c;
            loanPayment.Forecasted_Principal_Due__c = loanPayment.Amort_Principal_Due__c;
            loanPayment.Forecasted_Principal_Interest_Due__c = loanPayment.Amort_Interest_Due__c + loanPayment.Amort_Principal_Due__c;
            loanPayment.Forecasted_Cumulative_Principal__c = loanPayment.Amort_Cumulative_Principal__c;
            
            return loanPayment;
        }

        private void checkLoanForLPsToDelete(Loan__c loan) {
            loanIdsToDeleteLPs.add(loan.Id);
        }

        // Only delete loan payments that weren't manually created and not upserted. This
        // should only be loan payments at the end of a loan that has had the Interest Only
        // period shortened (or if a loan switched products to a shorter term)
        private void deleteLoanPayments() {
            List<Loan_Payment__c> loanPaymentsToDelete = new List<Loan_Payment__c>();
            Map<String, Loan_Payment__c> loanPaymentMap = new Map<String, Loan_Payment__c>();
            for (Loan_Payment__c lp : loanPaymentsToCreate) {
                loanPaymentMap.put(lp.Unique_Id__c, lp);
            }
            if (!loanIdsToDeleteLPs.isEmpty()) {
                List<Loan_Payment__c> loanPayments = [SELECT Id, Unique_Id__c
                                                      FROM Loan_Payment__c
                                                      WHERE Loan__c in :loanIdsToDeleteLPs
                                                      AND Period__c != null];
                for (Loan_Payment__c lp : loanPayments) {
                    if (loanPaymentMap.get(lp.Unique_Id__c) == null) {
                        loanPaymentsToDelete.add(lp);
                    }
                }
                if (!loanPaymentsToDelete.isEmpty()) {
                    delete loanPaymentsToDelete;
                }
            }
        }

        private void upsertLoanPayments() {
            upsert loanPaymentsToCreate Unique_Id__c;
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

            if (!lpsWithPrior.isEmpty()) {
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
        private void registerProduct(Product2 product) {
            productIds.add(product.Id);
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

        public List<Loan_Payment__c> calculateCumulativeAndForecasted(Loan__c loan,
                                                                      List<Loan_Payment__c> loanPaymentList,
                                                                      Map<Id, Loan_Payment__c> updatedPIMap) {
            Boolean addLP = false;
            Loan_Payment__c updatedLP;
            Decimal nextCumulativePrincipal = 0, nextForecastedCumulativePrincipal = 0, nextCumulativePrincipalDuringIO = 0,
                principalPaidForReamort = 0;
            Integer reamortPeriodAdjustment = 0, monthIndex;
            
            LoanParams params = new LoanParams(loan, productMap);
            
            List<Loan_Payment__c> loanPaymentsToUpdate = new List<Loan_Payment__c>();
            for (Loan_Payment__c lp : loanPaymentList) {
                if (updatedPIMap != null) {
                    updatedLP = updatedPIMap.get(lp.Id);
                    if (updatedLP != null) {
                        lp.Interest_Applied__c = updatedLP.Interest_Applied__c;
                        lp.Principal_Applied__c = updatedLP.Principal_Applied__c;
                        lp.Actual_Principal_Paydown__c = updatedLP.Actual_Principal_Paydown__c;
                        addLP = true;
                    }
                }
                addLP |= setIfDifferent(lp, 'Cumulative_Principal_Payments__c', nextCumulativePrincipal, false);
                addLP |= setIfDifferent(lp, 'Cumulative_Principal_During_IO__c', nextCumulativePrincipalDuringIO, false);
                addLP |= setIfDifferent(lp, 'Forecasted_Cumulative_Principal__c', nextForecastedCumulativePrincipal, true);

                if (lp.Actual_Principal_Paydown__c != null && lp.Actual_Principal_Paydown__c > 0) {
                    monthIndex = params.firstDistributionMonth + (Integer) lp.Period__c - LoanServicer.STARTINGPERIOD;
                    reamortPeriodAdjustment = monthIndex;
                    principalPaidForReamort = 
                        nullToZero(lp.Cumulative_Principal_Payments__c) + 
                        nullToZero(lp.Actual_Principal_Paydown__c);
                }

                nextCumulativePrincipal =
                    nullToZero(lp.Cumulative_Principal_Payments__c) +
                    nullToZero(lp.Principal_Applied__c);

                nextCumulativePrincipalDuringIO =
                    nullToZero(lp.Cumulative_Principal_During_IO__c) +
                    (lp.Interest_Only_Period__c?nullToZero(lp.Principal_Applied__c):0);

                // Same as the Amort Total Due, but this takes Principal buy down in the IO period and Principal Paydowns into account
                // We take the max becuase Cumulative Principal During IO includes Principal Paid for Reamort and we don't want
                // to double count
                Decimal adjustedAmortTotal = 
                    -Excel.pmt((Double) (lp.Loan__r.Product__r.Loan_Interest_Rate__c/100)/12,
                               (Integer) lp.Loan__r.Loan_Term__c - reamortPeriodAdjustment,
                               (Double) (lp.Funds_Distributed__c - Math.max(lp.Cumulative_Principal_During_IO__c, 
                                                                            principalPaidForReamort)));

                Decimal actualPIDue = 0;
                if (lp.Interest_Only_Period__c) {
                    actualPIDue = lp.Actual_Interest_Due__c;
                } else {
                    if (lp.Loan_Balance__c <= 0) {
                        actualPIDue = 0;
                    } else {
                        actualPIDue = 
                            Math.min(lp.Loan_Balance__c + nullToZero(lp.Actual_Interest_Due__c), adjustedAmortTotal);
                    }
                }
                addLP |= setIfDifferent(lp, 'Actual_PI_Due__c', actualPIDue, false);

                // The new Principal_Applied__c value set above isn't yet incorporated into the 
                // Forecasted_Loan_Balance__c formula, so we need to calculate that and other forecasted fields here
                Decimal forecastedPrincipalDue = 0, forecastedLoanBalance = 0, 
                    forecastedPrincipalInterestDue = 0, forecastedInterestDue = 0;
                forecastedLoanBalance = Math.max(lp.Funds_Distributed__c - 
                                                 nullToZero(lp.Cumulative_Principal_Payments__c) - 
                                                 nullToZero(lp.Actual_Principal_Paydown__c) -
                                                 nullToZero(lp.Forecasted_Cumulative_Principal__c),
                                                 0);
                addLP |= setIfDifferent(lp, 'Forecasted_Loan_Balance__c', forecastedLoanBalance, true);

                if (lp.Loan_Balance__c <= 0) {
                    forecastedInterestDue = 0;
                } else {
                    forecastedInterestDue = nullToZero(lp.Forecasted_Loan_Balance__c) * 
                        (lp.Loan__r.Product__r.Loan_Interest_Rate__c/100)/12;
                }
                addLP |= setIfDifferent(lp, 'Forecasted_Interest_Due__c', forecastedInterestDue, true);

                if (lp.Interest_Only_Period__c) {
                    forecastedPrincipalInterestDue = forecastedInterestDue;
                } else {
                    // The Min handles the case were a customer has overpaid principal and we don't want them to 
                    // pay the normal amort amount for the last payment.
                    // We can't use Amort_Total_Due__c which is Interest + Principal because that's rounded to 2 decimals
                    // and doesn't take principal buy-down during IO period into account
                    forecastedPrincipalInterestDue = 
                        Math.min(forecastedLoanBalance + forecastedLoanBalance * 
                                 (lp.Loan__r.Product__r.Loan_Interest_Rate__c/100)/12,
                                 adjustedAmortTotal);
                }
                addLP |= setIfDifferent(lp, 'Forecasted_Principal_Interest_Due__c', forecastedPrincipalInterestDue, true);

                if (lp.Loan_Balance__c <= 0 || lp.Interest_Only_Period__c) {
                    forecastedPrincipalDue = 0;
                } else {
                    forecastedPrincipalDue = nullToZero(lp.Forecasted_Principal_Interest_Due__c) - 
                        nullToZero(lp.Forecasted_Interest_Due__c);
                }
                addLP |= setIfDifferent(lp, 'Forecasted_Principal_Due__c', forecastedPrincipalDue, true);

                nextForecastedCumulativePrincipal =
                    nullToZero(lp.Forecasted_Cumulative_Principal__c) +
                    nullToZero(lp.Forecasted_Principal_Due__c);

                if (addLP) {
                    loanPaymentsToUpdate.add(lp);
                    addLP = false;
                }

            }
            return loanPaymentsToUpdate;
        }

        private Boolean setIfDifferent(Loan_Payment__c lp, String field, Decimal value, Boolean nullIfClosedOrPaid) {
            if (nullIfClosedOrPaid &&
                (lp.Bill_Status__c == LoanServicer.CLOSED ||
                 lp.Interest_Applied__c != null ||
                 lp.Principal_Applied__c != null)) {
                if (lp.get(field) != null) {
                    lp.put(field, null);
                    return true;
                } else {
                    return false;
                }
            } else {
                if (lp.get(field) != value) {
                    lp.put(field, value);
                    return true;
                } else {
                    return false;
                }
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

            // The Interest Only period is 12 months by default, but ends with the interconnection
            // and release of second distribution. We'll honor the Interest_Only_Period_DOER__c field
            // on Loan if filled in, and otherwise, use the IO period on the product.
            Decimal ioPeriod = null;
            if (loan.Interest_Only_Period_DOER__c != null) {
                ioPeriod = loan.Interest_Only_Period_DOER__c;
            } else {
                ioPeriod = product.Loan_Interest_Only_Period__c;
            }

            // First Distribution Month is negative because the Second Distribution
            // is 0 and starts the Loan Term
            if (ioPeriod == null || ioPeriod  > 0) {
                firstDistributionMonth = -ioPeriod.intValue();
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
            monthsOfIO = nullToZero(ioPeriod).intValue();
            loanTerm = monthsOfPI + monthsOfIO;
        }

    }

    public static Decimal nullToZero(Decimal value) {
        return (value==null?0:value);
    }

    public class LoanProductException extends Exception{}

}
