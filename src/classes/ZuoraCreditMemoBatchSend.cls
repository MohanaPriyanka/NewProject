/*
Tested by: ZuoraCreditDebitMemoServiceTest
 */
public without sharing class ZuoraCreditMemoBatchSend implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{
    public Set<Bill_Adjustment__c> adjustToUpdateSet = new Set<Bill_Adjustment__c>();
    public String queryString;
    public Date effectiveDate;
    public enum AdjustmentType {PostWhenApproved, PostNextBill}
    public AdjustmentType mode = AdjustmentType.PostNextBill;

    public void executeBatch(){
        Database.executeBatch(this, 33);
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        if (queryString != null) {
            return Database.getQueryLocator(queryString);
        } else {
            return AdjustmentSelector.getAdjustmentsNotYetInZuora(false, mode);
        }
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){
        try {
            for (SObject scopeLine : scope){
                if (effectiveDate == null){
                    effectiveDate = System.Today();
                }
                Bill_Adjustment__c adjust = ZuoraCreditDebitMemoService.createCreditOrDebitMemo((Bill_Adjustment__c) scopeLine, effectiveDate);
                if (adjust != null && adjust.Id != null) {
                    adjustToUpdateSet.add(adjust);
                }
            }
        } catch (Exception excep){
            Logger.logLater('ZuoraCreditMemoBatchSend', 'execute', excep.getMessage() + '\n' + excep.getStackTraceString());
        }
        Logger.flushLogs();
    }

    public void finish(Database.BatchableContext bc) {
        try {
            if (mode == AdjustmentType.PostWhenApproved){
                ZuoraMemoBatchApply batchApply = new ZuoraMemoBatchApply();
                batchApply.startApplication();
                batchApply.runBatch();
            }
            if (Util.getSystemPropertyCheckbox('Update_Usage_Records_With_ZuoraId__c')) {
                List<Bill_Adjustment__c> adjustmentsToUpdate = new List<Bill_Adjustment__c>();
                adjustmentsToUpdate.addAll(adjustToUpdateSet);
                update adjustmentsToUpdate;
            }
        } catch (Exception excep){
            Logger.logLater('ZuoraCreditMemoBatchSend', 'finish', excep.getMessage() + '\n' + excep.getStackTraceString());
        }
        Logger.flushLogs();
    }
}