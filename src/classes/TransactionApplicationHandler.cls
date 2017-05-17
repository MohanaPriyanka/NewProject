/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Rolls up applied amounts to Loan Payment and forces Loan Payment recalculation
 *              Also prevents TA update or delete
 * Test: LoanServicerTest
 *************************************************************************************/

public without sharing class TransactionApplicationHandler implements Database.Batchable<sObject>, Database.Stateful {
    public static final String DELETE_ERROR_MSG =
        'Cannot delete a Transaction Application, instead, create an adjusting record';
    public static Integer batchSize = 1;

    private List<Transaction_Application__c> fullTAList;

    public TransactionApplicationHandler(List<Transaction_Application__c> triggerContext) {
        this.fullTAList = triggerContext;
    }

    public List<SObject> start(Database.BatchableContext bc) {
        return fullTAList;
    }

    public void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        rollupAndCalculate(scope);
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
        email.setSubject('TransactionApplicationHandler Complete');
        if (fullTAList != null) {
            email.setPlainTextBody(fullTAList.size() + ' transaction applications processed');
        }
        MessagingService.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }

    // With a batch size larger than 1, we were hitting UNABLE_TO_LOCK_ROW on Loan Payment records
    public void rollupAndCalculate() {
        if (fullTAList.size() > batchSize) {
            Database.executeBatch(this, batchSize);
        } else {
            rollupAndCalculate(fullTAList);
        }
    }
    
    public void rollupAndCalculate(List<Transaction_Application__c> transactionApplicationList) {
        LREngine.Context ctx =
            new LREngine.Context(Loan_Payment__c.SobjectType,
                                 Transaction_Application__c.SobjectType,
                                 Schema.SObjectType.Transaction_Application__c.fields.Loan_Payment__c);

        ctx.add(new LREngine.RollupSummaryField(Schema.SObjectType.Loan_Payment__c.fields.Interest_Applied__c,
                                                Schema.SObjectType.Transaction_Application__c.fields.Interest_Applied__c,
                                                LREngine.RollupOperation.Sum)); 
        ctx.add(new LREngine.RollupSummaryField(Schema.SObjectType.Loan_Payment__c.fields.Principal_Applied__c,
                                                Schema.SObjectType.Transaction_Application__c.fields.Principal_Applied__c,
                                                LREngine.RollupOperation.Sum));
        List<Loan_Payment__c> updatedPIList = (List<Loan_Payment__c>) LREngine.rollUp(ctx, transactionApplicationList);
        Map<Id, Loan_Payment__c> updatedPIMap = new Map<Id, Loan_Payment__c>(updatedPIList);

        // For each loan payment being updated, query all loan payments and updated the cumulative values
        // Instead of being clever and just getting those loan payments that need to be updated (those that
        // come after the loan payments being updated), just get all of them.
        List<Loan_Payment__c> lpsForLoan = [SELECT Id, Loan__c
                                            FROM Loan_Payment__c
                                            WHERE Id = :updatedPIMap.keySet()];
        Set<Id> loanIds = new Set<Id>();
        for (Loan_Payment__c lp : lpsForLoan) {
            loanIds.add(lp.Loan__c);
        }
        List<Loan__c> allLoansWithPayments = [SELECT Id, (SELECT Id, Period__c, Interest_Only_Period__c, Bill_Status__c,
                                                          Amort_Interest_Due__c, Amort_Principal_Due__c,
                                                          Funds_Distributed__c, Actual_Interest_Due__c, Actual_PI_Due__c,
                                                          Cumulative_Principal_Payments__c,
                                                          Cumulative_Principal_During_IO__c,
                                                          Interest_Applied__c, Principal_Applied__c, 
                                                          Loan_Balance__c,
                                                          Forecasted_Loan_Balance__c,
                                                          Forecasted_Cumulative_Principal__c,
                                                          Forecasted_Principal_Interest_Due__c, 
                                                          Forecasted_Interest_Due__c,
                                                          Forecasted_Principal_Due__c,
                                                          Loan__r.Product__r.Loan_Interest_Rate__c,
                                                          Loan__r.Loan_Term__c
                                                          FROM Loan_Payments__r
                                                          WHERE Period__c <> null
                                                          ORDER BY Period__c)
                                              FROM Loan__c
                                              WHERE Id = :loanIds];

        List<Loan_Payment__c> loanPaymentsToUpdate = new List<Loan_Payment__c>();
        for (Loan__c loan : allLoansWithPayments) {
            loanPaymentsToUpdate.addAll(calculateCumulativeAndForecasted(loan.Loan_Payments__r, updatedPIMap));
        }
        update loanPaymentsToUpdate;
    }

    public List<Loan_Payment__c> calculateCumulativeAndForecasted(List<Loan_Payment__c> loanPaymentList,
                                                                  Map<Id, Loan_Payment__c> updatedPIMap) {
        Boolean addLP = false;
        Loan_Payment__c updatedLP;
        Decimal nextCumulativePrincipal = 0, nextForecastedCumulativePrincipal = 0, nextCumulativePrincipalDuringIO = 0;
            
        List<Loan_Payment__c> loanPaymentsToUpdate = new List<Loan_Payment__c>();
        for (Loan_Payment__c lp : loanPaymentList) {
            if (updatedPIMap != null) {
                updatedLP = updatedPIMap.get(lp.Id);
                if (updatedLP != null) {
                    lp.Interest_Applied__c = updatedLP.Interest_Applied__c;
                    lp.Principal_Applied__c = updatedLP.Principal_Applied__c;
                    addLP = true;
                }
            }
            addLP |= setIfDifferent(lp, 'Cumulative_Principal_Payments__c', nextCumulativePrincipal, false);
            addLP |= setIfDifferent(lp, 'Cumulative_Principal_During_IO__c', nextCumulativePrincipalDuringIO, false);
            addLP |= setIfDifferent(lp, 'Forecasted_Cumulative_Principal__c', nextForecastedCumulativePrincipal, true);

            nextCumulativePrincipal =
                nullToZero(lp.Cumulative_Principal_Payments__c) +
                nullToZero(lp.Principal_Applied__c);

            nextCumulativePrincipalDuringIO =
                nullToZero(lp.Cumulative_Principal_During_IO__c) +
                (lp.Interest_Only_Period__c?nullToZero(lp.Principal_Applied__c):0);

            // Same as the Amort Total Due, but this takes Principal buy down in the IO period into account
            Decimal adjustedAmortTotal = 
                -Excel.pmt((Double) (lp.Loan__r.Product__r.Loan_Interest_Rate__c/100)/12,
                           (Integer) lp.Loan__r.Loan_Term__c,
                           (Double) (lp.Funds_Distributed__c - lp.Cumulative_Principal_During_IO__c));

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

    private Decimal nullToZero(Decimal value) {
        return (value==null?0:value);
    }

    public static void preventDelete(List<SObject> objectList) {
        for (SObject obj : objectList) {
            obj.addError(DELETE_ERROR_MSG);
        }
    }
}
