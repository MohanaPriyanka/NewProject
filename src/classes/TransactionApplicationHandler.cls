/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Rolls up applied amounts to Loan Payment and forces Loan Payment recalculation
 *              Also prevents TA update or delete
 * Test: LoanServicerTest
 *************************************************************************************/

public without sharing class TransactionApplicationHandler {
    public static final String DELETE_ERROR_MSG =
        'Cannot delete a Transaction Application, instead, create an adjusting record';
    private List<Transaction_Application__c> transactionApplicationList;

    public TransactionApplicationHandler(List<Transaction_Application__c> triggerContext) {
        this.transactionApplicationList = triggerContext;
    }

    public void rollupAndCalculate() {
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
        List<Loan__c> allLoansWithPayments = [SELECT Id, (SELECT Id, Period__c, Interest_Only_Period__c,
                                                          Amort_Total_Due__c, Funds_Distributed__c,
                                                          Cumulative_Principal_Payments__c,
                                                          Interest_Applied__c, Principal_Applied__c, 
                                                          Loan_Balance__c,
                                                          Forecasted_Loan_Balance__c,
                                                          Forecasted_Cumulative_Principal__c,
                                                          Forecasted_Principal_Interest_Due__c, 
                                                          Forecasted_Interest_Due__c,
                                                          Forecasted_Principal_Due__c,
                                                          Loan__r.Product__r.Loan_Interest_Rate__c
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

    // Assumes that the loanPaymentList is sorted by Period, but don't assume the period is 1
    public List<Loan_Payment__c> calculateCumulativeAndForecasted(List<Loan_Payment__c> loanPaymentList,
                                                                  Map<Id, Loan_Payment__c> updatedPIMap) {
        Boolean addLP = false;
        Loan_Payment__c updatedLP;
        Decimal nextCumulativePrincipal = 0, nextForecastedCumulativePrincipal = 0;
            
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
            addLP |= setIfDifferent(lp, 'Forecasted_Cumulative_Principal__c', nextForecastedCumulativePrincipal, true);

            nextCumulativePrincipal =
                nullToZero(lp.Cumulative_Principal_Payments__c) +
                nullToZero(lp.Principal_Applied__c);

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
                forecastedInterestDue = nullToZero(lp.Forecasted_Loan_Balance__c) * (lp.Loan__r.Product__r.Loan_Interest_Rate__c/100)/12;
            }
            addLP |= setIfDifferent(lp, 'Forecasted_Interest_Due__c', forecastedInterestDue, true);

            if (lp.Interest_Only_Period__c) {
                forecastedPrincipalInterestDue = forecastedInterestDue;
            } else {
                forecastedPrincipalInterestDue = 
                    Math.min(forecastedLoanBalance + forecastedLoanBalance * (lp.Loan__r.Product__r.Loan_Interest_Rate__c/100)/12,
                             lp.Amort_Total_Due__c);
            }
            addLP |= setIfDifferent(lp, 'Forecasted_Principal_Interest_Due__c', forecastedPrincipalInterestDue, true);

            if (lp.Loan_Balance__c <= 0 || lp.Interest_Only_Period__c) {
                forecastedPrincipalDue = 0;
            } else {
                forecastedPrincipalDue = nullToZero(lp.Forecasted_Principal_Interest_Due__c) - nullToZero(lp.Forecasted_Interest_Due__c);
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
