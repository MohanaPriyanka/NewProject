/**
 * @description Batch inserts new ContentVersions and ContentDocumentLinks based on passed-in metadata from ClientFileCopierService
 * Constructs a 'Supporting Documents Folder' (SObject record) to house copied files which looks up to the parent record
 * Tested by: ClientFileCopierServiceTest
 */
public without sharing class BatchClientFileCopierService implements Database.Batchable<ClientFileCopierService.FileToCopy> {

    @TestVisible private static ContentVersionSelector contentVersionSelector = new ContentVersionSelector();
    public List<ClientFileCopierService.FileToCopy> filesToCopy;
    public fflib_SObjectUnitOfWork uow;

    public BatchClientFileCopierService(List<ClientFileCopierService.FileToCopy> files) {
        this.filesToCopy = files;
    }

    public List<ClientFileCopierService.FileToCopy> start(Database.BatchableContext bc) {
        return filesToCopy;
    }

    public void execute(Database.BatchableContext ctx, List<ClientFileCopierService.FileToCopy> filesToCopy) {
        uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ContentDocumentLink.SObjectType});
        try {
            List<ContentVersion> filesToClone = cloneFiles(filesToCopy);
            insert filesToClone;
            linkNewFilesToFolder(filesToClone, filesToCopy[0].supportingDocumentFolderId);
            uow.commitWork();
        } catch (Exception e) {
            Logger.logNow('ClientFileCopierService.Batch', 'execute', e, JSON.serialize(filesToCopy), 'ERROR');
        }
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(Database.BatchableContext batchableContext) {
    }

    /**
     * @description Creates new copies of ContentVersion records corresponding to inputs
     * @param filesToCopy List of ClientFileCopierService.FileToCopy objects, which store information on the file being copied
     * @return List of ContentVersion records to insert into the database which represent copies of original documents
     */
    private List<ContentVersion> cloneFiles(List<ClientFileCopierService.FileToCopy> filesToCopy) {
        // Retrieve the ContentVersion data in batch context
        Set<Id> contentVersionIds = new Set<Id>();
        for (ClientFileCopierService.FileToCopy fileMetadata : filesToCopy) {
            contentVersionIds.add(fileMetadata.contentVersionId);
        }
        Map<Id,ContentVersion> filesWithData = contentVersionSelector.selectByIdWithData(new Set<Id>(contentVersionIds));

        // Clone the documents now that we have all data and metadata
        List<ContentVersion> clonedFilesToInsert = new List<ContentVersion>();
        for (ClientFileCopierService.FileToCopy fileMetadata : filesToCopy) {
            ContentVersion originalData = filesWithData.get(fileMetadata.contentVersionId);
            if (originalData != null && fileMetadata.newFileName != null) {
                clonedFilesToInsert.addAll(cloneFiles(originalData, fileMetadata));
            }
        }
        return clonedFilesToInsert;
    }

    private List<ContentVersion> cloneFiles(ContentVersion oldFile, ClientFileCopierService.FileToCopy fileMetadata) {
        List<ContentVersion> newFiles = new List<ContentVersion>();
        for (Integer i=0; i < fileMetadata.numberOfCopies; i++) { 
            newFiles.add(new ContentVersion(
                ContentLocation = 'S',
                VersionData = oldFile.VersionData,
                Title = fileMetadata.newFileName,
                PathOnClient = '/' + fileMetadata.newFileName + '.pdf'
            ));
        }
        return newFiles;
    }

    private void linkNewFilesToFolder(List<ContentVersion> clonedFiles, Id newFolderId) {
        Set<Id> versionIds = new Set<Id>();
        for (ContentVersion version : clonedFiles) {
            versionIds.add(version.Id);
        }
        // Query for newly inserted ContentVersions to get ContentDocumentId:
        clonedFiles = contentVersionSelector.selectById(versionIds).values();
        for (ContentVersion content : clonedFiles) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = newFolderId;
            cdl.Visibility = 'InternalUsers';
            cdl.ShareType = 'V';
            cdl.ContentDocumentId = content.ContentDocumentId;
            uow.registerNew(cdl);
        }
    }
}