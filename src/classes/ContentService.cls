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

    public ContentDocumentLink uploadFileToRecordAndShareInternally(String fileBody, Id recordId, String fileName){
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = Blob.valueOf(fileBody),
            Title = fileName,
            PathOnClient = '/' + fileName
        );
        insert cv;

        Id contentDocId = documentSelector.getDocumentIdFromVersionId(cv.Id);

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = recordId;
        cdl.Visibility = 'InternalUsers';
        cdl.ShareType = 'V';
        cdl.ContentDocumentId = contentDocId;
        insert cdl;

        return cdl;
    }

    public void makeContentDocLinksPrivate(List<ContentDocumentLink> linkList) {
        if(!linkList.isEmpty()) {
            for(ContentDocumentLink link : linkList) {
                link.Visibility = 'InternalUsers';
            }

            List<Database.SaveResult> srList = database.update(linkList);
            for(Database.SaveResult sr : srList) {
                if(!sr.isSuccess()) {
                    Logger.logLater('ContentService', 'makeContentDocLinksPrivate', 'Error updating ContentDocumentLink ' + sr.getId() + '. Errors: ' + sr.getErrors());
                }
            }
            Logger.flushLogs();
        }
    }
}