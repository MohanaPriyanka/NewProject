/*************************************************************************************
 * Created By: peteryao on 9/12/19  
 * Test: ContentDocumentSelectorTest
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ContentDocumentSelector {
    public List<ContentDocument> selectById(Set<Id> documentIds) {
        return [
            SELECT Id, LatestPublishedVersion.Title, LatestPublishedVersion.VersionData, ContentSize
            FROM ContentDocument
            WHERE Id IN :documentIds
            ORDER BY ContentSize DESC
        ];
    }

    public ContentDocument getMostRecentTransferSheet(Transfer__c transfer) {
        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink docLink : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = : transfer.Id
        ]){
            contentDocIds.add(docLInk.ContentDocumentId);
        } 

        ContentDocument latestTransferSheet = [
            SELECT Id, LatestPublishedVersion.Title, LatestPublishedVersion.VersionData, ContentSize
            FROM ContentDocument
            WHERE Id IN : contentDocIds
            AND LatestPublishedVersion.File_Category__c = 'Transfer Sheet'
            ORDER BY ContentModifiedDate DESC
            LIMIT 1
        ];
        return latestTransferSheet;
    }
}