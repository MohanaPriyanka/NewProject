/*
** Trigger: LoanTrigger
** SObject: Loan__c
** Description: Creates Loan Payments after loan insert and update
**
** @see LoanTriggerHandler.cls
*/

trigger LoanTrigger on Loan__c (before insert, before update, after insert, after update) {
    LoanHandler loanHandler = new LoanHandler(Trigger.isExecuting, Trigger.size);
    LoanServicer servicer = new LoanServicer(Trigger.new, Trigger.oldMap, Trigger.IsInsert);
    
    if (Trigger.isInsert && Trigger.isBefore) {
        loanHandler.mapLateCategory();
    }

    if(Trigger.isInsert && Trigger.isAfter){        
        loanHandler.OnAfterInsert(Trigger.new);
        if (Trigger.new.size() > 5) {
            Database.executeBatch(servicer, LoanServicer.getBatchSize(Trigger.new));
        } else {
            servicer.createNewLoanPayments();
        }
    }

    if (Trigger.isUpdate && Trigger.isBefore) {
        loanHandler.mapLateCategory();
        servicer.validateLoanChange();
    }

    if (Trigger.isUpdate && Trigger.isAfter) {
        if (Trigger.new.size() > 5 && servicer.anyLoansToService) {
            Database.executeBatch(servicer, LoanServicer.getBatchSize(Trigger.new));
        } else {
            servicer.createNewLoanPayments();
        }
    }

}