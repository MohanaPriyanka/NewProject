/*
** Trigger: LoanTrigger
** SObject: Loan__c
** Description: Creates Loan Payments after loan insert and update
**
** @see LoanTriggerHandler.cls
*/

trigger LoanTrigger on Loan__c (before insert, before update, after insert, after update) {
    Util.printSOQLLimit('loan trigger start');
    DisbursalHandler disbursalHandler = new DisbursalHandler();
    List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
    if (systemProperties.size() > 0 &&
        systemProperties[0].Disable_LoanTrigger__c) {
        // Don't run trigger
    } else {
        LoanHandler lh = new LoanHandler();
        LoanServicer servicer = new LoanServicer(Trigger.new, Trigger.oldMap, Trigger.IsInsert);
    
        if (Trigger.isInsert && Trigger.isBefore && !LoanHandler.ranBeforeInsert) {
            LoanHandler.ranBeforeInsert = true;
            lh.setDaysPastDue(Trigger.new, null);
        }

        if (Trigger.isInsert && Trigger.isAfter && !LoanHandler.ranAfterInsert) {
            LoanHandler.ranAfterInsert = true;
            lh.OnAfterInsert(Trigger.new);
            servicer.upsertLoanPayments();
        }

        if (Trigger.isUpdate && Trigger.isBefore && !LoanHandler.ranBeforeUpdate) {
            LoanHandler.ranBeforeUpdate = true;
            servicer.validateLoanChange();
            lh.setDaysPastDue(Trigger.new, Trigger.oldMap);
        }

        if (Trigger.isUpdate && Trigger.isAfter && !LoanHandler.ranAfterUpdate) {
            LoanHandler.ranAfterUpdate = true;
            servicer.upsertLoanPayments();
            disbursalHandler.updateDisbursalAmountsOnRLAChange(Trigger.newMap, Trigger.oldMap);
        }
    }
    Util.printSOQLLimit('loan trigger end');
}