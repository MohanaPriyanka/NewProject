/*************************************************************************************
 * Created By: Jordan Pentaleri on 2019-10-28
 * Description: Takes a list of JSON objects, groups into batches and calls the generic
 * action update calls, described here:
 * https://www.zuora.com/developer/api-reference/#tag/Actions
 *
 * Test: ZuoraGenericBatchOperationTest
 *************************************************************************************/

public without sharing class ZuoraGenericBatchOperation implements Database.Batchable<Object>,Database.Stateful, Database.AllowsCallouts {
    public ZuoraAPIHelper.actionDMLOperations dmlOperation;
    // For delete calls, jsonObjects is just a list of Strings (Zuora Id)
    public List<Object> jsonObjects = new List<Object>();
    public String type;
    public List<ZuoraAPI.SaveResult> saveResults;

    public ZuoraGenericBatchOperation(ZuoraAPI.ActionItems actionItem, ZuoraAPIHelper.actionDMLOperations dmlOperationPassed) {
        jsonObjects = actionItem.objects;
        type = actionItem.type;
        dmlOperation = dmlOperationPassed;
        saveResults = new List<ZuoraAPI.SaveResult>();
    }

    public List<Object> start(Database.BatchableContext bc) {
        return jsonObjects;
    }

    public void execute(Database.BatchableContext batchableContext, List<Object> scope) {
        try {
            ZuoraAPI.ActionItems item = new ZuoraAPI.ActionItems();
            item.type = type;
            if (dmlOperation == ZuoraAPIHelper.actionDMLOperations.DMLINSERT
                || dmlOperation == ZuoraAPIHelper.actionDMLOperations.DMLUPDATE ) {
                    item.objects = scope;
            } else if (dmlOperation == ZuoraAPIHelper.actionDMLOperations.DMLDELETE ) {
                for (Object recordId : scope) {
                    item.ids = new List<String>();
                    item.ids.add((String) recordId);
                }
            }
            saveResults.addAll(ZuoraAPIHelper.genericAction(item, dmlOperation));
        } catch (Exception failureException){
            String errorMessage = failureException.getMessage() + '\n' + failureException.getStackTraceString() + '\n';
            errorMessage += JSON.serialize(scope);
            Logger.logLater('ZuoraGenericBatchOperation', 'execute', errorMessage, 'ERROR');
        }
        Logger.flushLogs();
    }

    public void finish(Database.BatchableContext batchableContext) {
        Logger.logNow('ZuoraGenericBatchOperation','Finish','Generic Batch Completed', 'INFO');
        Logger.logNow('ZuoraGenericBatchOperation','Finish Results',JSON.serialize(saveResults), 'INFO');
    }
}