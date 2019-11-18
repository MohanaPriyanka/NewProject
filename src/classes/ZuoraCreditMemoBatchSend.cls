/*
Tested by: ZuoraCreditDebitMemoServiceTest
 */
public without sharing class ZuoraCreditMemoBatchSend implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{
    public Set<Bill_Adjustment__c> adjustToUpdateSet = new Set<Bill_Adjustment__c>();
    public String queryString;

    public void executeBatch(){
        Database.executeBatch(this, 33);
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        if (queryString != null) {
            return Database.getQueryLocator(queryString);
        } else {
            return AdjustmentSelector.getAdjustmentsNotYetInZuora(false);
        }
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){
        try {
            for (SObject scopeLine : scope){
                Bill_Adjustment__c adjust = ZuoraCreditDebitMemoService.createCreditOrDebitMemo((Bill_Adjustment__c) scopeLine);
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