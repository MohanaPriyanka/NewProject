/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Rolls up applied amounts to Loan Payment and forces Loan Payment recalculation
 *              Also prevents TA update or delete
 * Test: LoanServicerTest
 *************************************************************************************/

public with sharing class TransactionApplicationHandler {
    public static final String UPDATE_DELETE_ERROR_MSG =
        'Cannot update or delete a Transaction Application, instead, create an adjusting record';

    private List<Transaction_Application__c> transApps;

    public TransactionApplicationHandler(List<Transaction_Application__c> triggerContext) {
        transApps = triggerContext;
    }

    public static void preventUpdateAndDelete(List<SObject> objectList) {
        for (SObject obj : objectList) {
            obj.addError(UPDATE_DELETE_ERROR_MSG);
        }
    }
}
