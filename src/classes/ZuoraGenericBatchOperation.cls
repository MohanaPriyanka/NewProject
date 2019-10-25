public without sharing class ZuoraGenericBatchOperation implements Database.Batchable<Object>,Database.Stateful, Database.AllowsCallouts {
    public Set<String> possibleDmlOperation = new Set<String>{'Insert','Update','Delete'};
    public String dmlOperation;
    // For delete calls, jsonObjects = ZuoraAPI.ZuoraDeleteRecord (just Id, no other fields)
    public List<Object> jsonObjects = new List<Object>();
    public String type;
    public List<ZuoraAPI.SaveResult> saveResults;

    public ZuoraGenericBatchOperation(ZuoraAPI.ActionItems actionItem, String dmlOperationPassed) {
        jsonObjects = actionItem.objects;
        type = actionItem.type;
        saveResults = new List<ZuoraAPI.SaveResult>();
        if (possibleDmlOperation.contains(dmlOperationPassed)) {
            dmlOperation = dmlOperationPassed;
        }
    }

    public List<Object> start(Database.BatchableContext bc) {
        return jsonObjects;
    }

    public void execute(Database.BatchableContext batchableContext, List<Object> scope) {
        try {
            List<ZuoraAPI.SaveResult> results;
            if (dmlOperation == 'Insert' || dmlOperation == 'Update') {
                ZuoraAPI.ActionItems item = new ZuoraAPI.ActionItems();
                item.type = type;
                item.objects = scope;
                results = ZuoraAPIHelper.genericAction(item, dmlOperation);
            } else if (dmlOperation == 'Delete') {
                ZuoraAPI.ZuoraDelete item = new ZuoraAPI.ZuoraDelete();
                item.type = type;
                item.Ids = new List<String>();
                for (Object obj : scope) {
                    ZuoraAPI.ZuoraDeleteRecord record = (ZuoraAPI.ZuoraDeleteRecord) obj;
                    item.Ids.add(record.Id);
                }
                results = ZuoraAPIHelper.genericAction(item, dmlOperation);
            }
            saveResults.addAll(results);
        } catch (Exception failureException){
            String errorMessage = failureException.getMessage() + failureException.getStackTraceString();
            errorMessage += String.valueOf(scope);
            Logger.logLater('ZuoraGenericBatchOperation', 'execute', errorMessage, 'ERROR');
        }
        Logger.flushLogs();
    }

    public void finish(Database.BatchableContext batchableContext) {
        Logger.logNow('ZuoraGenericBatchOperation','Finish','Generic Batch Completed', 'INFO');
        Logger.logNow('ZuoraGenericBatchOperation','Finish Results',JSON.serialize(saveResults), 'INFO');
    }
}