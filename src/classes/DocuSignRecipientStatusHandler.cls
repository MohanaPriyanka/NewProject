/*************************************************************************************
 * Created By: peteryao on 10/12/18  
 * Description: 
 * Tested by: DocuSignHelperTest
 *************************************************************************************/

public with sharing class DocuSignRecipientStatusHandler {
    public static void voidChildren(List<dsfs__DocuSign_Recipient_Status__c> updatedRecipientStatuses) {
        Set<Id> voidedIds = getVoidedStatusIds(updatedRecipientStatuses);
        for (dsfs__DocuSign_Recipient_Status__c recipientStatus : updatedRecipientStatuses) {
            if (voidedIds.contains(recipientStatus.dsfs__Parent_Status_Record__c)) {
                recipientStatus.dsfs__Recipient_Status__c = 'Voided';
            }
        }
    }

    private static Set<Id> getVoidedStatusIds(List<dsfs__DocuSign_Recipient_Status__c> updatedRecipientStatuses) {
        List<Id> dsStatusIds = new List<Id>();
        for (dsfs__DocuSign_Recipient_Status__c recipientStatus : updatedRecipientStatuses) {
            dsStatusIds.add(recipientStatus.dsfs__Parent_Status_Record__c);
        }
        List<dsfs__DocuSign_Status__c> dsStatuses = [
            SELECT Id
            FROM dsfs__DocuSign_Status__c
            WHERE Id = :dsStatusIds
            AND dsfs__Envelope_Status__c = 'Voided'
        ];
        Set<Id> voidedIds = new Set<Id>();
        for (dsfs__DocuSign_Status__c status : dsStatuses) {
            voidedIds.add(status.Id);
        }
        return voidedIds;
    }
}