/**
 * @description Created by IsraelScottGrogin on 9/23/2020.
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

    public List<Case> openQCCasesForLeads(Set<Id> leadIds) {
        return [
            SELECT Id, Status, Description 
            FROM Case
            WHERE Lead_Lookup__c IN : leadIds AND Category__c = 'QC' AND Status != 'Closed'
        ];
    }

    public List<Case> openCollectionCasesForAccounts(Set<Id> accountIds) {
        return [
            SELECT Id, Subject, Status, Resolution__c
            FROM Case
            WHERE Status != 'Closed' AND Type = 'Collections' AND Subject LIKE 'Collections Call:%' AND AccountId IN :accountIds
        ];
    }
}