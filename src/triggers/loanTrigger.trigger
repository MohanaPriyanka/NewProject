/*
** Trigger: loanTrigger
** SObject: Loan__c
** Description: 
**      ADDED 1/10/2017 by OpFocus: 
**      + after insert and update : Parse the JSON field that contains details
**      details for the related Loan Payments and create a Loan
**      Payment for each entry in JSON array. 
**
** @see LoanTriggerHandler.cls
*/

trigger loanTrigger on loan__c (before insert, before update, after insert, after update) {
    LoanHandler handler2 = new LoanHandler(Trigger.isExecuting, Trigger.size);
    JSONLoanPaymentHandler jsonLoanPaymentHandler = new JSONLoanPaymentHandler();
    
    if(Trigger.isInsert && Trigger.isAfter){        
        handler2.OnAfterInsert(Trigger.new);
        jsonLoanPaymentHandler.OnAfterInsert(Trigger.new);
    }

    if (Trigger.isUpdate && Trigger.isAfter) {
        jsonLoanPaymentHandler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}