/*************************************************************************************
 * Created By:  Joey Chan 
 * Description: Customer Application Portal controller for the public communities
 * Test: CAPControllerTest
 *************************************************************************************/
public without sharing class CAPController {
    @AuraEnabled
    public static Lead getLead(Id leadId, String email) {
        Lead lead;
        List<Lead> leadList  = [SELECT Id, FirstName, LastName, Email, LASERCA__Birthdate__c, Street, City, State, PostalCode, 
                                Requested_Loan_Amount__c, System_Cost__c, LASERCA__SSN__c, Annual_Income_Currency__c, 
                                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c, 
                                LASERCA__Pull_Credit_Report__c, CAP_Stage__c
                                FROM Lead 
                                WHERE Id = :leadId 
                                AND Email = :email LIMIT 1];
        if (leadList.size() > 0) {
            lead = leadList[0];
        }
        return lead;
    }
}