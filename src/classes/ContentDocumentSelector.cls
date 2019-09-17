/*************************************************************************************
 * Created By: peteryao on 9/12/19  
 * Test: ContentDocumentSelectorTest
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ContentDocumentSelector {
    public List<ContentDocument> selectById(Set<Id> documentIds) {
        return [
            SELECT Id, LatestPublishedVersion.Title, LatestPublishedVersion.VersionData, ContentSize
            FROM ContentDocument
            WHERE Id IN :documentIds
            ORDER BY ContentSize DESC
        ];
    }
}