/**
 * Created by IsraelScottGrogin on 9/23/2020.
 */

public without sharing class CaseSelector {

    public List<Case> selectOpenNoMatchCasesFromLead(Lead lead) {
        return [SELECT Id FROM Case WHERE Lead_Lookup__c = :lead.Id AND IsClosed = FALSE AND QC_Case_Subject__c = 'No FICO Match'];
    }
    public List<Case> selectOpenLowMatchCasesFromLead(Lead lead) {
        return [SELECT Id FROM Case WHERE Lead_Lookup__c = :lead.Id AND IsClosed = FALSE AND QC_Case_Subject__c = 'Low FICO Match'];
    }
}