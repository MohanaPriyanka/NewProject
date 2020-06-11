/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Called from LoanTrigger. 
 *              Creates Loan Payment records based on Loan and Loan Product parameters. 
 *              Loan Payment records would be related to each other through the Prior 
 *              Period Loan Payment lookup.
 * Test: LoanServicerTest
 *************************************************************************************/

public without sharing class LoanServicer implements Database.Batchable<SObject> {
    public static final Integer STARTINGPERIOD = 1;
    public static final String FUTURE = 'Future';
    public static final String CURRENT = 'Current';
    public static final String CLOSED = 'Closed';
    public static Boolean qssAlreadyRun = false;

    public Boolean anyLoansToService;
    private LoanPaymentRepo repo;
    private Map<Id, Loan__c> triggerOldMap;
    private List<SObject> loansToService = new List<SObject>();
    private Boolean handleInsert;

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
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
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
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (!systemProperties.isEmpty() &&
            systemProperties[0].Disable_LoanServicer_Validation__c) {
            // Don't validate
        } else {
            for (Loan__c loan : (List<Loan__c>) loansToService) {
                if (loanLocked(loan) && lockedParamsUpdated(loan)) {
                    loan.addError('Cannot update Product, Financing Fee ' +
                                  ' or System Cost for a Loan that is Complete or Contract Pending');
                }
            }
        }
    }

    // Calculate the biggest batch size for this list of loans, assuming one DML statement per
    // loan payment, a 12 month IO period for each loan, and at most 12 loan payments being deleted
    // off the end of a loan due to an IO period change
    public static Integer getBatchSize(List<Loan__c> loanList) {
        Decimal maxTerm = 1;
        for (Loan__c loan : loanList) {
            if (loan.Loan_Term__c > maxTerm) {
                maxTerm = loan.Loan_Term__c;
            }
        }
        Decimal dmlRecords = (10000/(maxTerm+12+12)).setScale(0, System.RoundingMode.FLOOR);
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
                    repo.createLoanPaymentsAndSetAPR(loan, handleInsert);
                } else {
                    repo.checkLoanForLPsToDelete(loan);
                    repo.createLoanPaymentsAndSetAPR(loan, handleInsert);
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

    // Called before insert or update from QSSTrigger
    public void calcQSSAPR(Quick_Sales_Sheet__c qss) {
        if (!qssAlreadyRun) {
            repo.init(qss);
            repo.calcAdjustableAPRandAverage(qss);
            repo.calcAdjustableMaxPayment(qss);
        }
    }

    // Called after insert or update
    public void calcQSSAverageWithBuydown(Quick_Sales_Sheet__c qss) {
        if (!qssAlreadyRun) {
            LoanServicer.qssAlreadyRun = true;
            repo.init(qss);
            repo.calcAdjustableTCO(qss);
            repo.calcAdjustableAverageWithBuydown(qss);
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

    private Boolean lockedParamsUpdated(Loan__c loan) {
        if (triggerOldMap != null &&
            (loan.Product__c != triggerOldMap.get(loan.Id).Product__c ||
                loan.Financing_Fee__c != triggerOldMap.get(loan.Id).Financing_Fee__c ||
                loan.Principal__c != triggerOldMap.get(loan.Id).Principal__c)) {
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
        private Map<String, Decimal> indexRates;
        private List<Loan__c> loansToUpdate;
        private List<Opportunity> oppsToUpdate;

        public LoanPaymentRepo() {
            loanIdstoDeleteLPs = new Set<Id>();
            loanPaymentsToCreate = new List<Loan_Payment__c>();
            productIds = new Set<Id>();
            productMap = new Map<Id, Product2>();
            indexRates = new Map<String, Decimal>();
            loansToUpdate = new List<Loan__c>();
            oppsToUpdate = new List<Opportunity>();
        }

        private void init(List<Loan__c> loans) {
            for (Loan__c loan : loans) {
                if (populatedForLPCreation(loan)) {
                    registerProduct(loan);
                }
            }
            queryProducts();
            queryIndexRates();
        }

        public void init(Set<Id> products) {
            productIds = products;
            queryProducts();
            queryIndexRates();
        }

        public void init(Quick_Sales_Sheet__c qss) {
            registerProduct(qss);
            queryProducts();
            queryIndexRates();
        }

        private void executeDML() {
            upsertLoanPayments();
            deleteLoanPayments();
            updateLoansAndOpps();
        }

        private void createLoanPaymentsAndSetAPR(Loan__c loan, Boolean isInsert) {
            LoanParams params = new LoanParams(loan, productMap, indexRates);

            Loan_Payment__c priorLP = null;
            Loan_Payment__c currentLP = null;
            for (Integer period = LoanServicer.STARTINGPERIOD;
                 period < params.loanTerm + LoanServicer.STARTINGPERIOD; 
                 period++) {
                currentLP = createLP(period, loan, params, priorLP, isInsert);
                loanPaymentsToCreate.add(currentLP);
                priorLP = currentLP;
            }
            if (params.isAdjustable) {
                setAPRAndSummary(loan, params);
            }
        }

        // Called after insert or update because Applied Tax Credits is a cross-object formula
        private void calcAdjustableTCO(Quick_Sales_Sheet__c qss) {
            Loan__c loan = new Loan__c(
                Product__c = qss.Product__c,
                Requested_Loan_Amount__c = qss.Loan_Amount__c
            );
            LoanParams params = new LoanParams(loan, productMap, indexRates);
            params.loanAmount = qss.Loan_Amount__c;
            Decimal year2Payoff = null, year4Payoff = null, cumulativeInterest = 0;
            if (params.isAdjustable) {
                Loan_Payment__c priorLP = null;
                Loan_Payment__c currentLP = null;
                List<Loan_Payment__c> loanPayments = new List<Loan_Payment__c>();
                for (Integer period = LoanServicer.STARTINGPERIOD;
                    period < params.loanTerm + LoanServicer.STARTINGPERIOD;
                    period++) {
                    if (period == params.monthsOfIO + 1) {
                        params.loanAmount = params.loanAmount - qss.Applied_Tax_Credits__c;
                    }
                    currentLP = createLP(period, loan, params, priorLP, true);
                    loanPayments.add(currentLP);
                    priorLP = currentLP;
                    cumulativeInterest += currentLP.Amort_Interest_Due__c;
                    if (period == 24) {
                        year2Payoff = cumulativeInterest + currentLP.Amort_Cumulative_Principal__c + currentLP.Amort_Starting_Principal__c;
                    } else if (period == 48) {
                        year4Payoff = cumulativeInterest + currentLP.Amort_Cumulative_Principal__c + currentLP.Amort_Starting_Principal__c;
                    }
                }
            }
            Quick_Sales_Sheet__c qssClone = new Quick_Sales_Sheet__c(
                Id = qss.Id,
                Year_2_Payoff__c = year2Payoff==null?null:Math.round(year2Payoff),
                Year_4_Payoff__c = year4Payoff==null?null:Math.round(year4Payoff)
            );
            update qssClone;
        }

        // Called after insert or update because Applied Tax Credits is a cross-object formula
        private void calcAdjustableAverageWithBuydown(Quick_Sales_Sheet__c qss) {
            Loan__c loan = new Loan__c(
                Product__c = qss.Product__c,
                Requested_Loan_Amount__c = qss.Loan_Amount__c - qss.Applied_Tax_Credits__c
            );

            LoanParams params = new LoanParams(loan, productMap, indexRates);
            params.loanAmount = qss.Loan_Amount__c - qss.Applied_Tax_Credits__c;
            Decimal averagePaymentWithBuydown = null;
            if (params.isAdjustable) {
                Loan_Payment__c priorLP = null;
                Loan_Payment__c currentLP = null;
                Decimal totalPIPayments = 0;
                List<Loan_Payment__c> loanPayments = new List<Loan_Payment__c>();
                for (Integer period = LoanServicer.STARTINGPERIOD;
                    period < params.loanTerm + LoanServicer.STARTINGPERIOD;
                    period++) {
                    currentLP = createLP(period, loan, params, priorLP, true);
                    loanPayments.add(currentLP);
                    if (period >= params.firstAdjustment) {
                        totalPIPayments += currentLP.Actual_PI_Due__c;
                    }
                    priorLP = currentLP;
                }
                averagePaymentWithBuydown = totalPIPayments /(params.loanTerm - params.firstAdjustment + 1);
            }
            Quick_Sales_Sheet__c qssClone = new Quick_Sales_Sheet__c(
                Id = qss.Id,
                Average_Adjustable_Payment_With_Buydown__c = averagePaymentWithBuydown
            );
            update qssClone;
        }

        private void calcAdjustableAPRandAverage(Quick_Sales_Sheet__c qss) {
            Loan__c loan = new Loan__c(
                Product__c = qss.Product__c,
                Requested_Loan_Amount__c = qss.Loan_Amount__c
            );
            LoanParams params = new LoanParams(loan, productMap, indexRates);
            params.loanAmount = qss.Loan_Amount__c;
            if (params.isAdjustable) {
                Loan_Payment__c priorLP = null;
                Loan_Payment__c currentLP = null;
                Decimal totalPIPayments = 0;
                List<Loan_Payment__c> loanPayments = new List<Loan_Payment__c>();
                for (Integer period = LoanServicer.STARTINGPERIOD;
                    period < params.loanTerm + LoanServicer.STARTINGPERIOD;
                    period++) {
                    currentLP = createLP(period, loan, params, priorLP, true);
                    loanPayments.add(currentLP);
                    if (period >= params.firstAdjustment) {
                        totalPIPayments += currentLP.Actual_PI_Due__c;
                    }
                    priorLP = currentLP;
                }
                qss.APR__c = getXIRRforAPR(qss, loanPayments).estimateIRR(.15);
                qss.Average_Adjustable_Payment__c = totalPIPayments /(params.loanTerm - params.firstAdjustment + 1);
            } else {
                qss.APR__c = null;
                qss.Average_Adjustable_Payment__c = null;
            }
        }
        private void calcAdjustableMaxPayment(Quick_Sales_Sheet__c qss) {
            Loan__c loan = new Loan__c(
                Product__c = qss.Product__c,
                Requested_Loan_Amount__c = qss.Loan_Amount__c
            );
            LoanParams params = new LoanParams(loan, productMap, indexRates);
            params.loanAmount = qss.Loan_Amount__c;
            // Force amort schedule to go to the ceiling rate to get the max payment
            params.indexRate = 99;
            if (params.isAdjustable) {
                Decimal maxPayment = 0;
                Loan_Payment__c priorLP = null;
                Loan_Payment__c currentLP = null;
                List<Loan_Payment__c> loanPayments = new List<Loan_Payment__c>();
                for (Integer period = LoanServicer.STARTINGPERIOD;
                    period < params.loanTerm + LoanServicer.STARTINGPERIOD;
                    period++) {
                    currentLP = createLP(period, loan, params, priorLP, true);
                    loanPayments.add(currentLP);
                    priorLP = currentLP;
                    if (currentLP.Actual_PI_Due__c > maxPayment) {
                        maxPayment = currentLP.Actual_PI_Due__c;
                    }
                }
                qss.Max_Payment__c = maxPayment;
            } else {
                qss.Max_Payment__c = null;
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
            loanPayment.Unique_ID__c = loan.Loan_Number__c + '|' + period;
            loanPayment.Period__c = period;
            loanPayment.Payment_Due_Date2__c = 
                loan.First_Payment_Due_Date_Override__c == null?null:loan.First_Payment_Due_Date_Override__c.addMonths(period - LoanServicer.STARTINGPERIOD);

            loanPayment.Funds_Distributed__c = 
                (params.loanAmount*params.firstDistribution+params.fees)*payFirstDistribution+
                params.loanAmount*params.secondDistribution*paySecondDistribution;
            loanPayment.Funds_Distributed__c.setScale(2, RoundingMode.HALF_UP);
            Decimal monthlyRate = getAdjustedMonthlyRate(params, period);
            loanPayment.Adjusted_Interest_Rate__c = (monthlyRate * 12 * 100).setScale(13);

            loanPayment.Amort_Cumulative_Principal__c =
                priorLP == null?0:(priorLP.Amort_Cumulative_Principal__c + priorLP.Amort_Principal_Due__c).setScale(16);
            loanPayment.Amort_Starting_Principal__c =
                (loanPayment.Funds_Distributed__c - loanPayment.Amort_Cumulative_Principal__c).setScale(16);

            if (isInterestOnly) {
                loanPayment.Interest_Only_Period__c = true;
                loanPayment.Amort_Interest_Due__c = (loanPayment.Funds_Distributed__c * monthlyRate).setScale(16);
                loanPayment.Amort_Principal_Due__c = 0;
            } else {
                loanPayment.Interest_Only_Period__c = false;
                loanPayment.Amort_Interest_Due__c = (monthlyRate * (loanPayment.Funds_Distributed__c - loanPayment.Amort_Cumulative_Principal__c)).setScale(16);
                loanPayment.Amort_Principal_Due__c =
                    (-Excel.pmt((Double) monthlyRate, params.monthsOfPI-monthIndex, (Double) (loanPayment.Funds_Distributed__c - loanPayment.Amort_Cumulative_Principal__c))
                        - loanPayment.Amort_Interest_Due__c).setScale(16);
            }

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
            loanIdstoDeleteLPs.add(loan.Id);
        }

        // Only delete loan payments that weren't manually created and not upserted. This
        // should only be loan payments at the end of a loan that has had the Interest Only
        // period shortened (or if a loan switched products to a shorter term)
        private void deleteLoanPayments() {
            List<Loan_Payment__c> loanPaymentsToDelete = new List<Loan_Payment__c>();
            Map<String, Loan_Payment__c> loanPaymentMap = new Map<String, Loan_Payment__c>();
            for (Loan_Payment__c lp : loanPaymentsToCreate) {
                loanPaymentMap.put(lp.Unique_ID__c, lp);
            }
            if (!loanIdstoDeleteLPs.isEmpty()) {
                List<Loan_Payment__c> loanPayments = [SELECT Id, Unique_ID__c
                                                      FROM Loan_Payment__c
                                                      WHERE Loan__c IN :loanIdstoDeleteLPs
                                                      AND Period__c != NULL];
                for (Loan_Payment__c lp : loanPayments) {
                    if (loanPaymentMap.get(lp.Unique_ID__c) == null) {
                        loanPaymentsToDelete.add(lp);
                    }
                }
                if (!loanPaymentsToDelete.isEmpty()) {
                    delete loanPaymentsToDelete;
                }
            }
        }

        private void upsertLoanPayments() {
            // We get this error if we try creating loans in @TestSetup AND in a @IsTest
            //   System.DmlException: Upsert failed. First exception on row 0; first error: INVALID_FIELD_FOR_INSERT_UPDATE,
            //   Attempting to update (as part of an upsert) parent field Loan__c with new value a0y1F0000002ergQAA,
            //   current value is a0y1F0000002erfQAA: [Loan__c]
            // "Independent Auto-Number" is turned on:
            // https://releasenotes.docs.salesforce.com/en-us/spring14/release-notes/rn_apex_autonumber_sequence.htm
            // @TestSetup and @IsTest run in different transactions and get the same autonumber, resulting in Unique_ID__c
            // collision. We should create all test data in @TestSetup.
            upsert loanPaymentsToCreate Unique_ID__c;
        }

        private void updateLoansAndOpps() {
            if (!loansToUpdate.isEmpty()) {
                update loansToUpdate;
            }
            if (!oppsToUpdate.isEmpty()) {
                update oppsToUpdate;
            }
        }

        private void registerProduct(Loan__c loan) {
            productIds.add(loan.Product__c);
        }

        private void registerProduct(Quick_Sales_Sheet__c qss) {
            productIds.add(qss.Product__c);
        }

        public void queryProducts() {
            List<Product2> products = [
                SELECT Id, Loan_Interest_Only_Period__c, Loan_Interest_Rate__c,
                    Loan_Term__c, Disbursal_Terms__c, First_Adjustment__c, Months_Between_Adjustment__c,
                    Margin_Over_Index_Rate__c, Index_Rate_for_Adjustment__c, Maximum_Adjustment__c,
                    Floor_Rate__c, Ceiling_Rate__c
                FROM Product2
                WHERE Id IN :productIds
            ];
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
            
            LoanParams params = new LoanParams(loan, productMap, indexRates);

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

                monthIndex = params.firstDistributionMonth + (Integer) lp.Period__c - LoanServicer.STARTINGPERIOD;
                if (lp.Actual_Principal_Paydown__c != null && lp.Actual_Principal_Paydown__c > 0) {
                    reamortPeriodAdjustment = monthIndex;
                    principalPaidForReamort = 
                        Util.nullToZero(lp.Cumulative_Principal_Payments__c) + 
                        Util.nullToZero(lp.Actual_Principal_Paydown__c);
                }

                nextCumulativePrincipal =
                    Util.nullToZero(lp.Cumulative_Principal_Payments__c) +
                    Util.nullToZero(lp.Principal_Applied__c);

                nextCumulativePrincipalDuringIO =
                    Util.nullToZero(lp.Cumulative_Principal_During_IO__c) +
                    (lp.Interest_Only_Period__c?Util.nullToZero(lp.Principal_Applied__c):0);

                Decimal monthlyRate = getAdjustedMonthlyRate(params, (Integer) lp.Period__c);

                // The new Principal_Applied__c value set above isn't yet incorporated into the
                // Forecasted_Loan_Balance__c formula, so we need to calculate that and other forecasted fields here
                Decimal forecastedPrincipalDue = 0, forecastedLoanBalance = 0,
                    forecastedPrincipalInterestDue = 0, forecastedInterestDue = 0;
                forecastedLoanBalance = Math.max(lp.Funds_Distributed__c -
                    Util.nullToZero(lp.Cumulative_Principal_Payments__c) -
                    Util.nullToZero(lp.Actual_Principal_Paydown__c) -
                    Util.nullToZero(lp.Forecasted_Cumulative_Principal__c),
                    0).setScale(16);
                addLP |= setIfDifferent(lp, 'Forecasted_Loan_Balance__c', forecastedLoanBalance, true);

                // Same as the Amort Total Due, but this takes Principal buy down in the IO period and Principal Paydowns into account
                // We take the max because Cumulative Principal During IO includes Principal Paid for Reamort and we don't want
                // to double count
                // We'll treat fixed-rate loans different from adjustable because adjustable rate loans automatically reamortize
                // at each adjustment.
                // TODO: For adjustable loans, don't reamortize at month (period shouldn't be the remaining term), just at
                // each adjustment interval.
                Decimal adjustedAmortTotal;
                if (params.isAdjustable) {
                    adjustedAmortTotal = -Excel.pmt((Double) monthlyRate,
                        (Integer) params.monthsOfPI - monthIndex,
                        (Double) forecastedLoanBalance);
                } else {
                    adjustedAmortTotal = -Excel.pmt((Double) monthlyRate,
                        (Integer) lp.Loan__r.Loan_Term__c - reamortPeriodAdjustment,
                        (Double) (lp.Funds_Distributed__c - Math.max(lp.Cumulative_Principal_During_IO__c,
                            principalPaidForReamort)));
                }

                Decimal actualPIDue = 0;
                if (lp.Interest_Only_Period__c) {
                    actualPIDue = lp.Actual_Interest_Due__c;
                } else {
                    if (lp.Loan_Balance__c <= 0) {
                        actualPIDue = 0;
                    } else {
                        actualPIDue = 
                            Math.min(lp.Loan_Balance__c + Util.nullToZero(lp.Actual_Interest_Due__c), adjustedAmortTotal);
                    }
                }
                addLP |= setIfDifferent(lp, 'Actual_PI_Due__c', actualPIDue, false);

                if (lp.Loan_Balance__c <= 0) {
                    forecastedInterestDue = 0;
                } else {
                    forecastedInterestDue = (Util.nullToZero(lp.Forecasted_Loan_Balance__c) * monthlyRate).setScale(16);
                }
                addLP |= setIfDifferent(lp, 'Forecasted_Interest_Due__c', forecastedInterestDue, true);

                if (lp.Interest_Only_Period__c) {
                    forecastedPrincipalInterestDue = forecastedInterestDue;
                } else {
                    // The Min handles the case were a customer has overpaid principal and we don't want them to 
                    // pay the normal amort amount for the last payment.
                    // We can't use Amort_PI_Due__c which is Interest + Principal because that's rounded to 2 decimals
                    // and doesn't take principal buy-down during IO period into account
                    forecastedPrincipalInterestDue = 
                        Math.min(forecastedLoanBalance + forecastedLoanBalance * monthlyRate,
                                 adjustedAmortTotal).setScale(16);
                }
                addLP |= setIfDifferent(lp, 'Forecasted_Principal_Interest_Due__c', forecastedPrincipalInterestDue, true);

                if (lp.Loan_Balance__c <= 0 || lp.Interest_Only_Period__c) {
                    forecastedPrincipalDue = 0;
                } else {
                    forecastedPrincipalDue = (Util.nullToZero(lp.Forecasted_Principal_Interest_Due__c) -
                        Util.nullToZero(lp.Forecasted_Interest_Due__c)).setScale(16);
                }
                addLP |= setIfDifferent(lp, 'Forecasted_Principal_Due__c', forecastedPrincipalDue, true);

                nextForecastedCumulativePrincipal =
                    Util.nullToZero(lp.Forecasted_Cumulative_Principal__c) +
                    Util.nullToZero(lp.Forecasted_Principal_Due__c);

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

        public void queryIndexRates() {
            List<Index_Rate__c> rates = [
                SELECT Id, Index_Rate__c, Index_Rate_Type__c
                FROM Index_Rate__c
            ];
            for (Index_Rate__c rate : rates) {
                indexRates.put(rate.Index_Rate_Type__c, rate.Index_Rate__c);
            }
        }

        public Excel.XIRR getXIRRAndSummary(Decimal loanAmount, List<Loan_Payment__c> loanPayments, PaymentSummary summary) {
            Date today = Date.newInstance(2018,1,1);
            Excel.XIRR xirr = new Excel.XIRR();
            xirr.addCashflow(new Excel.Cashflow(today.addMonths(1-LoanServicer.STARTINGPERIOD), -loanAmount));
            for (Loan_Payment__c lp : loanPayments) {
                xirr.addCashflow(new Excel.Cashflow(today.addMonths((Integer) lp.Period__c), lp.Amort_Interest_Due__c + lp.Amort_Principal_Due__c));
                if (summary != null) {
                    if (lp.Period__c >= summary.params.firstAdjustment &&
                        Math.mod((Integer) (lp.Period__c - summary.params.firstAdjustment), summary.params.monthsBetweenAdjustment) == 0 &&
                        // We only need 5 adjustments for loans that start at 4.49 and go up to 9.99 at 1% increments
                        (lp.Period__c - summary.params.firstAdjustment)/summary.params.monthsBetweenAdjustment < 6) {
                        summary.adjustedPayments[(Integer) (lp.Period__c - summary.params.firstAdjustment)/summary.params.monthsBetweenAdjustment] =
                            lp.Amort_Principal_Due__c + lp.Amort_Interest_Due__c;
                    }
                    summary.totalPayments += lp.Amort_Interest_Due__c + lp.Amort_Principal_Due__c;
                }
            }
            return xirr;
        }

        public Excel.XIRR getXIRRforAPR(Quick_Sales_Sheet__c qss, List<Loan_Payment__c> loanPayments) {
            return getXIRRAndSummary(qss.Loan_Amount__c, loanPayments, null);
        }

        public void setAPRAndSummary(Loan__c loan, LoanParams params) {
            PaymentSummary summary = new PaymentSummary(params);
            Excel.XIRR xirr = getXIRRAndSummary(loan.Requested_Loan_Amount__c, loanPaymentsToCreate, summary);
            // Because this can be called from an after update, we need to create a new instance of the loan to update
            Loan__c loanForAPR = new Loan__c(
                Id = loan.Id,
                APR__c = xirr.estimateIRR(.15),
                First_Adjustable_Monthly_Payment_Amount__c = summary.adjustedPayments[0],
                Second_Adjustable_Monthly_Payment_Amount__c = summary.adjustedPayments[1],
                Third_Adjustable_Monthly_Payment_Amount__c = summary.adjustedPayments[2],
                Fourth_Adjustable_Monthly_Payment_Amount__c = summary.adjustedPayments[3],
                Fifth_Adjustable_Monthly_Payment_Amount__c = summary.adjustedPayments[4],
                Sixth_Adjustable_Monthly_Payment_Amount__c = summary.adjustedPayments[5],
                Total_Loan_Payments_Override__c = summary.totalPayments
            );
            loansToUpdate.add(loanForAPR);
            if (loan.Opportunity__c != null) {
                Opportunity oppForAPR = new Opportunity(
                    Id = loan.Opportunity__c,
                    APR__c = xirr.estimateIRR(.15),
                    First_Adjustable_Monthly_Payment_Amount__c = summary.adjustedPayments[0],
                    Second_Adjustable_Monthly_Payment_Amount__c = summary.adjustedPayments[1],
                    Third_Adjustable_Monthly_Payment_Amount__c = summary.adjustedPayments[2],
                    Fourth_Adjustable_Monthly_Payment_Amount__c = summary.adjustedPayments[3],
                    Fifth_Adjustable_Monthly_Payment_Amount__c = summary.adjustedPayments[4],
                    Sixth_Adjustable_Monthly_Payment_Amount__c = summary.adjustedPayments[5],
                    Total_Loan_Payments_Override__c = summary.totalPayments
                );
                oppsToUpdate.add(oppForAPR);
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
        private Boolean isAdjustable = false;
        private Integer firstAdjustment, monthsBetweenAdjustment;
        private Decimal indexRate, marginOverIndexRate, maximumAdjustment, floorRate, ceilingRate;

        private LoanParams(Loan__c loan, Map<Id, Product2> productMap, Map<String, Decimal> indexRates) {
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

            // DOER pays out differently than all other loans
            if (product.Disbursal_Terms__c == '35% Contract Signature, 65% Interconnection') {
                firstDistribution = .35;
                secondDistribution = .65;
            } else {
                // e.g. '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection or
                // 30% Building Permit Approved, 60% Mechanical Installation, 10% Interconnection or
                // 30%, 60%, 10%
                firstDistribution = 1;
                secondDistribution = 0;
            }

            fees = Util.nullToZero(loan.Financing_Fee__c);
            loanAmount = Util.nullToZero(loan.Principal__c) - fees;
            loanAmountPlusFees = loanAmount + fees;
            annualRate = Util.nullToZero(product.Loan_Interest_Rate__c)/100;
            monthlyRate = annualRate / 12;
            monthsOfPI = Util.nullToZero(product.Loan_Term__c).intValue();
            monthsOfIO = Util.nullToZero(ioPeriod).intValue();
            loanTerm = monthsOfPI + monthsOfIO;
            if (product.Index_Rate_for_Adjustment__c != null) {
                isAdjustable = true;
                firstAdjustment = (Integer) product.First_Adjustment__c;
                monthsBetweenAdjustment = (Integer) product.Months_Between_Adjustment__c;
                indexRate = indexRates.get(product.Index_Rate_for_Adjustment__c)/100;
                marginOverIndexRate = product.Margin_Over_Index_Rate__c/100;
                maximumAdjustment = product.Maximum_Adjustment__c/100;
                floorRate = product.Floor_Rate__c/100;
                ceilingRate = product.Ceiling_Rate__c/100;
            }
        }
    }

    public static Decimal getAdjustedMonthlyRate(LoanParams params, Integer period) {
        Decimal monthlyRate;
        if (params.isAdjustable) {
            // Excel formula:
            // MAX(FloorRate,
            //     AnnualLoanRate - CEILING(MAX(Period-FirstAdjustment+1,0)/MonthsBetweenAdjustment,1) * MaximumAdjustment,
            //     MIN(CeilingRate,
            //         IndexRate + MarginOverIndex,
            //         AnnualLoanRate + CEILING(MAX(Period-FirstAdjustment+1,0)/MonthsBetweenAdjustment,1) * MaximumAdjustment))
            Decimal adjustUp, adjustDown, adjustment, marginOverIndex;
            Integer adjustmentNumber = (Integer) Math.ceil((Decimal) Math.max(period - params.firstAdjustment + LoanServicer.STARTINGPERIOD, 0)/params.monthsBetweenAdjustment);
            adjustment = adjustmentNumber * params.maximumAdjustment;
            adjustDown = params.annualRate - adjustment;
            adjustUp = params.annualRate + adjustment;
            marginOverIndex = params.indexRate + params.marginOverIndexRate;
            monthlyRate = Util.max(new List<Decimal>{params.floorRate, adjustDown, Util.min(new List<Decimal>{params.ceilingRate, adjustUp, marginOverIndex})})/12;
        } else {
            monthlyRate = params.monthlyRate;
        }
        return monthlyRate;
    }

    private class PaymentSummary {
        List<Decimal> adjustedPayments;
        Decimal totalPayments;
        LoanParams params;

        PaymentSummary(LoanParams params) {
            adjustedPayments = new List<Decimal>{null, null, null, null, null, null};
            totalPayments = 0;
            this.params = params;
        }
    }

    public class LoanProductException extends Exception{}

}