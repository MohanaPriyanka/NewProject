// Tested By: ContentVersionSelectorTest

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ContentVersionSelector {
    public Map<Id, ContentVersion> selectById(Set<Id> versionIds) {
        Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>([
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id IN : versionIds
        ]);
        return versionMap;
    }
}