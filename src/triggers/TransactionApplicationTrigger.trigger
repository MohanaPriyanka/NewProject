/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Rolls up applied amounts to Loan Payment and forces Loan Payment recalculation
 *              Also prevents TA update or delete
 * Test: LoanServicerTest
 *************************************************************************************/

trigger TransactionApplicationTrigger on Transaction_Application__c (after insert, before update, before delete) {
    if (Trigger.isInsert && Trigger.isAfter) {
        TransactionApplicationHandler tah = new TransactionApplicationHandler(Trigger.new);
    }

    if (Trigger.isDelete && Trigger.isBefore) {
        TransactionApplicationHandler.preventDelete(Trigger.old);
    }
}
