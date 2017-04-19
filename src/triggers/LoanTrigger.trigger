/*
** Trigger: LoanTrigger
** SObject: Loan__c
** Description: 
**
** @see LoanTriggerHandler.cls
*/

trigger LoanTrigger on Loan__c (before insert, before update, after insert, after update) {
    LoanHandler handler2 = new LoanHandler(Trigger.isExecuting, Trigger.size);
    
    if(Trigger.isInsert && Trigger.isAfter){        
        handler2.OnAfterInsert(Trigger.new);
    }

    if (Trigger.isUpdate && Trigger.isAfter) {
    }

    if (Trigger.isUpdate && Trigger.isBefore) {
        handler2.mapLateCategory();
    }

    if (Trigger.isInsert && Trigger.isBefore) {
        handler2.mapLateCategory();
    }
}