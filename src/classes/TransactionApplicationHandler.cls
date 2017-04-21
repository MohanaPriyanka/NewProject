/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Rolls up applied amounts to Loan Payment and forces Loan Payment recalculation
 *              Also prevents TA update or delete
 * Test: LoanServicerTest
 *************************************************************************************/

public without sharing class TransactionApplicationHandler {
    public static final String DELETE_ERROR_MSG =
        'Cannot delete a Transaction Application, instead, create an adjusting record';

    public TransactionApplicationHandler(List<Transaction_Application__c> triggerContext) {
        rollupAndCalculate(triggerContext);
    }

    private void rollupAndCalculate(List<Transaction_Application__c> transactionApplicationList) {
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
        List<Loan__c> allLoansWithPayments = [SELECT Id, (SELECT Id, Period__c, Cumulative_Principal_Payments__c,
                                                          Interest_Applied__c, Principal_Applied__c
                                                          FROM Loan_Payments__r
                                                          WHERE Period__c <> null
                                                          ORDER BY Period__c)
                                              FROM Loan__c
                                              WHERE Id = :loanIds];

        List<Loan_Payment__c> loanPaymentsToUpdate = new List<Loan_Payment__c>();
        for (Loan__c loan : allLoansWithPayments) {
            loanPaymentsToUpdate.addAll(calculateCumulativePrincipalApplied(loan.Loan_Payments__r, updatedPIMap));
        }
        update loanPaymentsToUpdate;
    }

    // Assumes that the loanPaymentList is sorted by Period, but don't assume the period is 1
    public List<Loan_Payment__c> calculateCumulativePrincipalApplied(List<Loan_Payment__c> loanPaymentList,
                                                                     Map<Id, Loan_Payment__c> updatedPIMap) {
        Loan_Payment__c updatedLP;
        Decimal nextCumulativePrincipal = 0;
        Set<Loan_Payment__c> loanPaymentSet = new Set<Loan_Payment__c>();
        for (Loan_Payment__c lp : loanPaymentList) {
            updatedLP = updatedPIMap.get(lp.Id);
            if (updatedLP != null) {
                lp.Interest_Applied__c = updatedLP.Interest_Applied__c;
                lp.Principal_Applied__c = updatedLP.Principal_Applied__c;
                loanPaymentSet.add(lp);
            }
            if  (lp.Cumulative_Principal_Payments__c != nextCumulativePrincipal &&
                 nextCumulativePrincipal != 0) {
                lp.Cumulative_Principal_Payments__c = nextCumulativePrincipal;
                loanPaymentSet.add(lp);
            }
            nextCumulativePrincipal =
                nullToZero(lp.Cumulative_Principal_Payments__c) +
                nullToZero(lp.Principal_Applied__c);
        }
        return new List<Loan_Payment__c>(loanPaymentSet);
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
