/**
 * Created by IsraelScottGrogin on 9/23/2020.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseSelector {

    public List<Case> selectOpenNoMatchCasesFromLead(Lead lead) {
        return [
            SELECT Id
            FROM Case
            WHERE Lead_Lookup__c = :lead.Id
            AND IsClosed = FALSE
            AND QC_Case_Subject__c = 'No Credit Match - Provide Additional Background on Guarantor (New Address or DOB)'
        ];
    }
    public List<Case> selectOpenLowMatchCasesFromLead(Lead lead) {
        return [
            SELECT Id
            FROM Case
            WHERE Lead_Lookup__c = :lead.Id
            AND IsClosed = FALSE
            AND QC_Case_Subject__c = 'Low Credit Match - New Guarantor Needs to Apply'
        ];
    }
    public List<Case> selectForPartnerApplicationStatusEvaluation(Set<Id> caseIds) {
        return [
            SELECT Id, Lead_Lookup__c, Related_Opportunity__c, Related_Opportunity__r.Lead__c
            FROM Case
            WHERE Id = :caseIds
        ];
    }
}