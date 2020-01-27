/*
Created By: Jordan Pentaleri 1/23/20
Service for ContentDocument, ContentVersion and ContentDocumentLink actions
*/
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ContentService {
    public static ContentDocumentSelector documentSelector = new ContentDocumentSelector();

    @AuraEnabled
    public static void setCategoryOnContentVersion(List<Id> documentIdList, String category){
        system.debug(documentIdList);
        Set<Id> documentIdSet = new Set<Id>(documentIdList);
        system.debug(documentIdSet);

        List<ContentVersion> versionsToUpdate = new List<ContentVersion>();
        List<ContentDocument> contentDocuments = documentSelector.selectById(documentIdSet);
        system.debug(contentDocuments);


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