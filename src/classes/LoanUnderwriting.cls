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
        List<Lead> leads = [SELECT FirstName, LastName, Name, 
                            Product__r.Name, Product__r.Credit_Minimum__c, Product__r.Debt_To_Income_Maximum__c,
                            Annual_Income_Currency__c,
                            (SELECT Id, Name, LASERCA__Credit_Score_TransUnion__c, 
                             Adverse_Credit_Notice_1__c, Adverse_Credit_Notice_2__c, Adverse_Credit_Notice_3__c,
                             LASERCA__Code__c, LASERCA__Code_2__c, LASERCA__Code_3__c, LASERCA__Code_4__c,
                             LASERCA__Detail_1__c, LASERCA__Detail_2__c, LASERCA__Detail_3__c, LASERCA__Detail_4__c
                             FROM LASERCA__Personal_Credit_Reports__r ORDER BY CreatedDate DESC LIMIT 1),
                            (SELECT Id, Name from Attachments)
                            FROM Lead
                            WHERE ID = :leadId];
        if (!leads.isEmpty()) {
            System.debug(LoggingLevel.ERROR, leads);
            return leads[0];
        } else {
            return new Lead();
        }
    }
}
