public without sharing class ZuoraUsageBatchSend implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    public List<UASB__c> uasbToUpdate = new List<UASB__c>();
    public List<Bill_Adjustment__c> adjustToUpdate = new List<Bill_Adjustment__c>();

    public void executeBatch(){
        Database.executeBatch(this, 50);
    }

    public List<SObject> start(Database.BatchableContext bc){
        List<SObject> sObjectList = new List<SObject>();
        sObjectList.addAll(UASBSelector.uasbsNotYetInZuora());
        sObjectList.addAll(AdjustmentSelector.getAdjustmentsNotYetInZuora(true));
        return sObjectList;
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope){
        ZuoraUsageService.ZuoraUsageItems zuoraUsage = ZuoraUsageService.convertSFUsageToZuoraUsage(scope);
        HttpResponse usageUploadResponse = ZuoraUsageService.usageAPICall(zuoraUsage);
        Map<String, List<SObject>> recordsToUpdate = ZuoraUsageService.handleAPIResponse(zuoraUsage.objects, usageUploadResponse);
        List<UASB__c> newUASBToUpdate = recordsToUpdate.get('UASB');
        List<Bill_Adjustment__c> newAdjustToUpdate = recordsToUpdate.get('Bill_Adjustment');
        if (newUASBToUpdate != null){
            uasbToUpdate.addAll(newUASBToUpdate);
        }
        if (newAdjustToUpdate != null) {
            adjustToUpdate.addAll(newAdjustToUpdate);
        }
        Logger.flushLogs();
    }

    public void finish(Database.BatchableContext bc){
        if (uasbToUpdate.size() > 0){
            update uasbToUpdate;
        }
        if (adjustToUpdate.size() > 0){
            update adjustToUpdate;
        }
    }
}