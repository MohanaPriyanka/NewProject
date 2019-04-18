public without sharing class ZuoraUsageBatchSend implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    public List<UASB__c> uasbToUpdate = new List<UASB__c>();
    public List<Bill_Adjustment__c> adjustToUpdate = new List<Bill_Adjustment__c>();

    public void executeBatch(){
        Database.executeBatch(this, 50);
    }

    public List<SObject> start(Database.BatchableContext bc){
        List<SObject> sObjectList = new List<SObject>();
        sObjectList.addAll(UASBSelector.getUASBsByMonth());
        sObjectList.addAll(AdjustmentSelector.getAdjustmentsByMonth());
        return sObjectList;
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope){
        List<ZuoraUsageService.ZuoraUsage> zuoraUsage = ZuoraUsageService.convertSFUsageToZuoraUsage(scope);
        String jsonString = ZuoraUsageService.convertZuoraUsageToJSON(zuoraUsage);
        HttpResponse usageUploadResponse = ZuoraUsageService.usageAPICall(jsonString);
        Map<String, List<SObject>> recordsToUpdate = ZuoraUsageService.handleAPIResponse(zuoraUsage, usageUploadResponse);
        List<UASB__c> newUASBToUpdate = recordsToUpdate.get('UASB');
        List<Bill_Adjustment__c> newAdjustToUpdate = recordsToUpdate.get('Bill_Adjustment');
        if (newUASBToUpdate != null){
            uasbToUpdate.addAll(newUASBToUpdate);
        }
        if (newAdjustToUpdate != null) {
            adjustToUpdate.addAll(newAdjustToUpdate);
        }
    }

    public void finish(Database.BatchableContext bc){
        Logger.flushLogs();
        if (uasbToUpdate.size() > 0){
            update uasbToUpdate;
        }
        if (adjustToUpdate.size() > 0){
            update adjustToUpdate;
        }
    }
}