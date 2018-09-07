/**
 * Created by mstackhouse on 9/6/2018.
 * Description: Voids child status records when a docusign envelope is voided
 * Test: DocuSignHelperTest
 */


public without sharing class DocuSignStatusTriggerHandler {
    public static void voidChildren(List<dsfs__DocuSign_Status__c> updatedStatuses) {
        List<Id> voidedStatuses = new List<Id>();
        for (dsfs__DocuSign_Status__c updatedStatus : updatedStatuses) {
            if (updatedStatus.dsfs__Envelope_Status__c == 'Voided') {
                voidedStatuses.add(updatedStatus.Id);
            }
        }

        List<dsfs__DocuSign_Recipient_Status__c> recipientStatuses = [
            SELECT Id, dsfs__Recipient_Status__c
            FROM dsfs__DocuSign_Recipient_Status__c
            WHERE dsfs__Parent_Status_Record__c IN : voidedStatuses
        ];

        for (dsfs__DocuSign_Recipient_Status__c recipientStatus : recipientStatuses) {
            recipientStatus.dsfs__Recipient_Status__c = 'Voided';
        }

        update recipientStatuses;
    }
}