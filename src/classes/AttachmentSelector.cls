// Tested by: AttachmentSelectorTest

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class AttachmentSelector {
    public List<Attachment> getAttachmentsByParentIdAndName(Set<Id> parentIds, String fileName) {
        String fileNameContains = '%'+ fileName +'%';
        return [
            SELECT Id, ParentId, Body, Name
            FROM Attachment
            WHERE ParentId IN : parentIds
            AND Name LIKE : fileNameContains
        ];
    }
}