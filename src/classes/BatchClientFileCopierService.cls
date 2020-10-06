// Tested by ClientFileCopierServiceTest

public without sharing class BatchClientFileCopierService implements Database.Batchable<Id> {
    public Map<Id,Id> versionIdToLinkedEntityId;
    public Id newFolderId;
    public Map<Id,List<String>> linkedEntityIdToFileNames;

    public BatchClientFileCopierService(Map<Id,Id> versionIdToLinkedEntityId, Id newFolderId, Map<Id,List<String>> linkedEntityIdToFileNames){
        this.versionIdToLinkedEntityId = versionIdToLinkedEntityId;
        this.newFolderId = newFolderId;
        this.linkedEntityIdToFileNames = linkedEntityIdToFileNames;
    }

    public List<Id> start(Database.BatchableContext bc) {
        return new List<Id>(versionIdToLinkedEntityId.keySet());
    }

    public void execute(Database.BatchableContext batchableContext, List<Id> versionIds) {
        try {
            ClientFileCopierService service = new ClientFileCopierService();
            List<ContentVersion> filesToClone = service.cloneFiles(versionIds, versionIdToLinkedEntityId, linkedEntityIdToFileNames);
            insert filesToClone;
            service.linkNewFilesToFolder(filesToClone, newFolderId);
            service.uow.commitWork();
        } catch (Exception excep){
            Logger.logNow('BatchClientFileCopierService','execute',excep,JSON.serialize(versionIds),'ERROR');
        }
    }

    public void finish(Database.BatchableContext batchableContext) {
        // Nothing to do
    }
}