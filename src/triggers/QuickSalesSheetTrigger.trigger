/**
 * Description: Sets APR for adjustable rate loans
 * Tested by: LoanServicerTest
 */

trigger QuickSalesSheetTrigger on Quick_Sales_Sheet__c (before insert, before update, after insert, after update) {
    LoanServicer loanServicer = new LoanServicer(new List<Loan__c>(), null, true);
    if (Trigger.isBefore && Trigger.isUpdate) {
        loanServicer.calcQSSAPR(Trigger.new[0]);
    } else if (Trigger.isBefore && Trigger.isInsert) {
        loanServicer.calcQSSAPR(Trigger.new[0]);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        loanServicer.calcQSSAverageWithBuydown(Trigger.new[0]);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        loanServicer.calcQSSAverageWithBuydown(Trigger.new[0]);
    }
}