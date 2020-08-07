// Tested by ClientFileCopierServiceTest

public without sharing class BatchClientFileCopierService implements Database.Batchable<Id> {
    public Map<Id,Id> versionIdToParentId;
    public Id newFolderId;
    public Map<Id,List<String>> parentIdToFileNames;

    public BatchClientFileCopierService(Map<Id,Id> versionIdToParentId, Id newFolderId, Map<Id,List<String>> parentIdToFileNames){
        this.versionIdToParentId = versionIdToParentId;
        this.newFolderId = newFolderId;
        this.parentIdToFileNames = parentIdToFileNames;
    }

    public List<Id> start(Database.BatchableContext bc) {
        List<Id> keysAsList = new List<Id>();
        keysAsList.addAll(versionIdToParentId.keySet());
        return keysAsList;
    }

    public void execute(Database.BatchableContext batchableContext, List<Id> scope) {
        try {
            ClientFileCopierService service = new ClientFileCopierService();
            List<ContentVersion> filesToClone = service.cloneFiles(scope,versionIdToParentId,parentIdToFileNames);
            insert filesToClone;
            service.linkNewFilesToFolder(filesToClone, newFolderId);
            service.uow.commitWork();
        } catch (Exception excep){
            Logger.logNow('BatchClientFileCopierService','execute',excep,JSON.serialize(scope),'ERROR');
        }
    }

    public void finish(Database.BatchableContext batchableContext) {
        // Nothing to do
    }
}