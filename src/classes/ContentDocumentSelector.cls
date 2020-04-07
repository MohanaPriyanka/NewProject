/*************************************************************************************
 * Created By: peteryao on 9/12/19  
 * Test: ContentDocumentSelectorTest,SimpleSignupFormControllerTest
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

    public List<ContentDocumentLink> selectByLinkedEntity(Id entityId) {
        return [
            SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersion.Title,
                ContentDocument.LatestPublishedVersion.VersionData
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :entityId
            ORDER BY ContentDocument.ContentSize DESC
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

    public Id getDocumentIdFromVersionId(Id versionId) {
        List<ContentVersion> versionList = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = : versionId
            LIMIT 1
        ];
        return versionList[0].ContentDocumentId;
    }

    public List<ContentDocument> getLeadDocsCreatedWithinRange(Datetime startDate, Datetime endDate) {
        return [
            SELECT
                Id,
                (SELECT
                    Id,
                    Visibility
                FROM
                    ContentDocumentLinks
                WHERE
                    Visibility = 'AllUsers'
                    AND LinkedEntity.Type = 'Lead'
                )
            FROM
                ContentDocument
            WHERE
                CreatedDate >= :startDate
                AND CreatedDate <= :endDate
        ];
    }
}