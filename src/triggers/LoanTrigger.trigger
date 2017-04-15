/*
** Trigger: LoanTrigger
** SObject: Loan__c
** Description: 
**      ADDED 1/10/2017 by OpFocus: 
**      + after insert and update : Parse the JSON field that contains details
**      details for the related Loan Payments and create a Loan
**      Payment for each entry in JSON array. 
**
** @see LoanTriggerHandler.cls
*/

trigger LoanTrigger on Loan__c (before insert, before update, after insert, after update) {
    LoanHandler loanHandler = new LoanHandler(Trigger.isExecuting, Trigger.size);
    JSONLoanPaymentHandler jsonLoanPaymentHandler = new JSONLoanPaymentHandler();
    LoanServicer loanServicer = new LoanServicer();
    
    if(Trigger.isInsert && Trigger.isAfter){        
        loanHandler.OnAfterInsert(Trigger.new);
        jsonLoanPaymentHandler.OnAfterInsert(Trigger.new);
        if (Trigger.new.size() > 50) {
            Database.executeBatch(new LoanServicer(Trigger.new, Trigger.IsInsert));
        } else {
            loanServicer.createNewLoanPayments();
        }
    }

    if (Trigger.isUpdate && Trigger.isAfter) {
        jsonLoanPaymentHandler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
        if (Trigger.new.size() > 50) {
            Database.executeBatch(new LoanServicer(Trigger.new, Trigger.IsInsert));
        } else {
            loanServicer.createNewLoanPayments();
        }
    }

    if (Trigger.isUpdate && Trigger.isBefore) {
        loanHandler.mapLateCategory();
        loanServicer.validateLoanChange();
    }

    if (Trigger.isInsert && Trigger.isBefore) {
        loanHandler.mapLateCategory();
    }
}