public without sharing class ZuoraUsageBatchSend implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    public List<UASB__c> uasbToUpdate = new List<UASB__c>();
    public List<Bill_Adjustment__c> adjustToUpdate = new List<Bill_Adjustment__c>();
    public String queryString;
    public enum UsageType {UASBS, ADJUSTMENTS}
    public UsageType type;

    public void executeBatch(){
        Database.executeBatch(this, 50);
    }

    public ZuoraUsageBatchSend(UsageType usageType) {
        this.type = usageType;
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        if (queryString != null) {
            return Database.getQueryLocator(queryString);
        } else {
            if (type == UsageType.UASBS) {
                return UASBSelector.uasbsNotYetInZuora();
            } else if (type == UsageType.ADJUSTMENTS) {
                return AdjustmentSelector.getAdjustmentsNotYetInZuora(true);
            } else {
                throw new Util.BWException('Set type to UASBS or ADJUSTMENTS');
            }
        }
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

            // For historical migration, we want to make sure old data doesn't change when we update UASBs and Adjustments,
            // so we track historical changes and log them:

            Datetime startTime = Datetime.now();
            List<SObject> recordsToUpdate = new List<SObject>();
            if (uasbToUpdate.size() > 0){
                recordsToUpdate.addAll(uasbToUpdate);
            }
            if (adjustToUpdate.size() > 0){
                recordsToUpdate.addAll(adjustToUpdate);
            }
            if (recordsToUpdate.size() > 0){
                GenericBatchDMLOperation batchDML = new GenericBatchDMLOperation(recordsToUpdate, 'Update');
                batchDML.triggersToDisable = new List<String>{
                    'Disable_System_Bill_Trigger__c',
                    'Disable_AccountBillTrigger__c',
                    'Disable_AccountTrigger__c',
                    'Disable_BillAdjustmentTrigger__c'
                };
                Database.executeBatch(batchDML);
            }
            Logger.logNow('ZuoraUsageBatchSend','finish',checkFieldUpdates(startTime),'WARN');
        }
    }

    public String checkFieldUpdates(Datetime startTime){
        String history = 'Field History Tracking: ';
        startTime = startTime.addMinutes(-1);
        List<UASB__History> uasbHistory = [
            SELECT ParentId, CreatedDate, Field, OldValue, NewValue
            FROM UASB__History
            WHERE CreatedDate >= :startTime
            ORDER BY CreatedDate DESC
        ];
        for (UASB__History uasb : uasbHistory) {
            history += '[UASB Updates]' + String.valueOf(uasb);
        }
        List<System_Bill__History> systemBillHistory = [
            SELECT ParentId, CreatedDate, CreatedBy.Name, Field, OldValue, NewValue
            FROM System_Bill__History
            WHERE CreatedDate >= :startTime
            ORDER BY CreatedDate DESC
        ];
        for (System_Bill__History sb : systemBillHistory) {
            history += '[SB Updates]' + String.valueOf(sb);
        }
        List<Account_Bill__History> accountBillHistory = [
            SELECT ParentId, CreatedDate, CreatedBy.Name, Field, OldValue, NewValue
            FROM Account_Bill__History
            WHERE CreatedDate >= :startTime
            ORDER BY CreatedDate DESC
        ];
        for (Account_Bill__History ab : accountBillHistory) {
            history += '[AB Updates]' + String.valueOf(ab);
        }
        return history;
    }
}