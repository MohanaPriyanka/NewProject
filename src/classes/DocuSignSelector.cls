// Tested By: DocuSignSelectorTest

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DocuSignSelector {
    public Map<Id, dsfs__DocuSign_Status__c> getDocusignStatuses(Set<Id> oppIds) {
        Map<Id, dsfs__DocuSign_Status__c> dsMap = new Map<Id, dsfs__DocuSign_Status__c>([
            SELECT Id, dsfs__Opportunity__c
            FROM dsfs__DocuSign_Status__c
            WHERE dsfs__Opportunity__r.Id IN : oppIds
            AND dsfs__Envelope_Status__c = 'Completed'
        ]);
        return dsMap;
    }
}