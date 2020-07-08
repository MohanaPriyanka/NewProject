public without sharing class FilesUnitOfWorkHelper implements fflib_SObjectUnitOfWork.IDoWork {
    private List<CDLCreator> cdl_records;
    public FilesUnitOfWorkHelper() {
        cdl_records = new List<CDLCreator>();
    }

    public void registerContentDocumentLinkInsert(Utility_Account_Log__c linkedEntity, ContentVersion contentVersion, String sharing, String visibility) {
        CDLCreator creator = new CDLCreator();
        creator.contentVersion = contentVersion;
        creator.linkedEntity = linkedEntity; 
        creator.sharing = sharing;
        creator.visibility = visibility;
        cdl_records.add(creator);
    }

    public void doWork() {
        if(!cdl_records.isEmpty()) {
            createContentDocLinkRecords();
        }
        
        Logger.flushLogs();
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void createContentDocLinkRecords() {
        Set<Id> contentVersionIdSet = new Set<Id>();
        for(CDLCreator c : cdl_records) {
            contentVersionIdSet.add(c.contentVersion.Id);
        }
        Map<Id, ContentVersion> cvMap = new Map<Id, ContentVersion>([
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersionIdSet
        ]);


        List<ContentDocumentLink> cdlForInsert = new List<ContentDocumentLink>();
        for(CDLCreator c : cdl_records) {
            ContentDocumentLink contentDocLink = new ContentDocumentLink();
            contentDocLink.LinkedEntityId = c.linkedEntity.Id;
            contentDocLink.ContentDocumentId = cvMap.get(c.contentVersion.Id).ContentDocumentId;
            contentDocLink.ShareType = c.sharing;
            contentDocLink.Visibility = c.visibility;
            cdlForInsert.add(contentDocLink);
        }

        insert cdlForInsert;
    }



    public class CDLCreator {
        public sObject linkedEntity;
        public Id linkedEntityId;
        public ContentVersion contentVersion;
        public String sharing;
        public String visibility;

        public CDLCreator() { }
    }
}