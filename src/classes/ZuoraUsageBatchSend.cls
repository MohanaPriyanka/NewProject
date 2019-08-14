public without sharing class ZuoraUsageBatchSend implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    public List<UASB__c> uasbToUpdate = new List<UASB__c>();
    public List<Bill_Adjustment__c> adjustToUpdate = new List<Bill_Adjustment__c>();
    public List<SObject> fullScope;

    public void executeBatch(){
        Database.executeBatch(this, 50);
    }

    public void init() {
        fullScope = new List<SObject>();
        fullScope.addAll(UASBSelector.uasbsNotYetInZuora());
        fullScope.addAll(AdjustmentSelector.getAdjustmentsNotYetInZuora(true));
    }

    public List<SObject> start(Database.BatchableContext bc){
        return fullScope;
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            ZuoraUsageService.ZuoraUsageItems zuoraUsage = ZuoraUsageService.convertSFUsageToZuoraUsage(scope);
            Logger.clearLogs();
            HttpResponse usageUploadResponse = ZuoraAPIHelper.callJsonEndpoint('POST','/v1/action/create',zuoraUsage,false);
            Map<String, List<SObject>> recordsToUpdate = ZuoraUsageService.handleAPIResponse(zuoraUsage.objects, usageUploadResponse);
            List<UASB__c> newUASBToUpdate = recordsToUpdate.get('UASB');
            List<Bill_Adjustment__c> newAdjustToUpdate = recordsToUpdate.get('Bill_Adjustment');
            if (newUASBToUpdate != null) {
                uasbToUpdate.addAll(newUASBToUpdate);
            }
            if (newAdjustToUpdate != null) {
                adjustToUpdate.addAll(newAdjustToUpdate);
            }
        } catch(Exception excep) {
            Logger.logLater('ZuoraUsageBatchSend', 'execute', excep.getMessage() + '\n' + excep.getStackTraceString());
        }
        Logger.flushLogs();
    }

    public void finish(Database.BatchableContext bc){
        if (Util.getSystemPropertyCheckbox('Update_Usage_Records_With_ZuoraId__c')) {
            if (uasbToUpdate.size() > 0){
                update uasbToUpdate;
            }
            if (adjustToUpdate.size() > 0){
                update adjustToUpdate;
            }
        }
    }
}