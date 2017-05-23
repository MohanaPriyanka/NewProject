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

        // We need another context to rollup the principal applications that are a result of a paydown. The 
        // calculateCumulativeAndForecasted method below will use the Actual_Principal_Paydown field to trigger reamortization.
        LREngine.Context payDownctx =
            new LREngine.Context(Loan_Payment__c.SobjectType,
                                 Transaction_Application__c.SobjectType,
                                 Schema.SObjectType.Transaction_Application__c.fields.Loan_Payment__c,
                                 'Principal_Paydown_Reason__c != null');
        payDownctx.add(new LREngine.RollupSummaryField(Schema.SObjectType.Loan_Payment__c.fields.Actual_Principal_Paydown__c,
                                                Schema.SObjectType.Transaction_Application__c.fields.Principal_Applied__c,
                                                LREngine.RollupOperation.Sum));
        List<Loan_Payment__c> updatedPayDownPIList = (List<Loan_Payment__c>) LREngine.rollUp(payDownctx, transactionApplicationList);
        // We need to merge this list of LPs that are updated with the Actual_Principal_Paydown amount with the first list...
        if (!updatedPayDownPIList.isEmpty()) {
            for (Loan_Payment__c lp : updatedPayDownPIList) {
                updatedPIMap.get(lp.Id).Actual_Principal_Paydown__c = lp.Actual_Principal_Paydown__c;
            }
        }

        // For each loan payment being updated, query all loan payments and updated the cumulative values
        // Instead of being clever and just getting those loan payments that need to be updated (those that
        // come after the loan payments being updated), just get all of them.
        List<Loan_Payment__c> lpsForLoan = [SELECT Id, Loan__c, Loan__r.Product__c
                                            FROM Loan_Payment__c
                                            WHERE Id = :updatedPIMap.keySet()];
        Set<Id> loanIds = new Set<Id>();
        Set<Id> products = new Set<Id>();
        for (Loan_Payment__c lp : lpsForLoan) {
            loanIds.add(lp.Loan__c);
            products.add(lp.Loan__r.Product__c);
        }

        LoanServicer.LoanPaymentRepo repo = new LoanServicer.LoanPaymentRepo();
        repo.init(products);
        repo.queryProducts();

        List<Loan__c> allLoansWithPayments = [SELECT Id, Interest_Only_Period_DOER__c, 
                                              Product__c, Financing_Fee__c, Principal__c,
                                              (SELECT Id, Period__c, Interest_Only_Period__c,
                                               Bill_Status__c,
                                               Amort_Interest_Due__c, Amort_Principal_Due__c,
                                               Funds_Distributed__c, Actual_Interest_Due__c, Actual_PI_Due__c,
                                               Cumulative_Principal_Payments__c,
                                               Cumulative_Principal_During_IO__c,
                                               Interest_Applied__c, Principal_Applied__c, Actual_Principal_Paydown__c,
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
            loanPaymentsToUpdate.addAll(repo.calculateCumulativeAndForecasted(loan, loan.Loan_Payments__r, updatedPIMap));
        }
        update loanPaymentsToUpdate;
    }

    public static void preventDelete(List<SObject> objectList) {
        for (SObject obj : objectList) {
            obj.addError(DELETE_ERROR_MSG);
        }
    }
}
