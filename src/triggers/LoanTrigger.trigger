/*
** Trigger: LoanTrigger
** SObject: Loan__c
** Description: Creates Loan Payments after loan insert and update
**
** @see LoanTriggerHandler.cls
*/

trigger LoanTrigger on Loan__c (before insert, before update, after insert, after update) {
    List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
    if (systemProperties.size() > 0 &&
        systemProperties[0].Disable_LoanTrigger__c) {
        // Don't run trigger
    } else {
        LoanHandler loanHandler = new LoanHandler(Trigger.isExecuting, Trigger.size);
        LoanServicer servicer = new LoanServicer(Trigger.new, Trigger.oldMap, Trigger.IsInsert);
    
        if (Trigger.isInsert && Trigger.isBefore) {
            loanHandler.mapLateCategory();
        }

        if (Trigger.isInsert && Trigger.isAfter) {
            loanHandler.OnAfterInsert(Trigger.new);
            servicer.upsertLoanPayments();
        }

        if (Trigger.isUpdate && Trigger.isBefore) {
            loanHandler.mapLateCategory();
            servicer.validateLoanChange();
        }

        if (Trigger.isUpdate && Trigger.isAfter) {
            servicer.upsertLoanPayments();
        }
    }
}