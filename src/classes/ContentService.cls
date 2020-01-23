/*
Created By: Jordan Pentaleri 1/23/20
Service for ContentDocument, ContentVersion and ContentDocumentLink actions
*/
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ContentService {
    public static ContentDocumentSelector documentSelector = new ContentDocumentSelector();

    @AuraEnabled
    public static void setCategoryOnContentVersion(Id contentDocumentId, String category){
        List<ContentDocument> contentDocuments = documentSelector.selectById(new Set<Id>{contentDocumentId});
        ContentVersion versionToUpdate = new ContentVersion(
            Id = contentDocuments[0].LatestPublishedVersionId,
            File_Category__c = category
        );
        update versionToUpdate;
    }
}