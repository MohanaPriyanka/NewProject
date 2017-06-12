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
    public static Lead getLoanInfo() {
        Lead l = new Lead(Firstname = 'Test',
                          Lastname = 'Testcase');
        return l;
    }
}
