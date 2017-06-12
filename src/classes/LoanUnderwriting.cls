/*************************************************************************************
 * Created By: Peter Yao
 * 
 * Description: Controller for the LoanUnderwriting lightning component to help Avidia
 *              review loans
 *
 Tested By: LoanUnderwritingControllerTest
 *************************************************************************************/

public without sharing class LoanUnderwriting {
    @AuraEnabled 
    public static Lead getLoanInfo(Id leadId) {
        List<Lead> leads = [SELECT FirstName, LastName
                            FROM Lead
                            WHERE ID = :leadId];
        if (!leads.isEmpty()) {
            return leads[0];
        } else {
            return new Lead();
        }
    }
}
