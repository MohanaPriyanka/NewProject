/*
Created By: Jordan Pentaleri 1/23/20
Service for ContentDocument, ContentVersion and ContentDocumentLink actions
*/
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ContentService {
    public static ContentDocumentSelector documentSelector = new ContentDocumentSelector();

    @AuraEnabled
    public static void setCategoryOnContentVersion(List<Id> documentIdList, String category){
        Set<Id> documentIdSet = new Set<Id>(documentIdList);
        List<ContentVersion> versionsToUpdate = new List<ContentVersion>();
        List<ContentDocument> contentDocuments = documentSelector.selectById(documentIdSet);
        for (ContentDocument document : contentDocuments){
            ContentVersion versionToUpdate = new ContentVersion(
                Id = document.LatestPublishedVersionId,
                File_Category__c = category
            );
            versionsToUpdate.add(versionToUpdate);
        }
        update versionsToUpdate;
    }
}