/*
Tested by: ZuoraCreditDebitMemoServiceTest
 */
public without sharing class ZuoraCreditMemoBatchSend implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{
    public Set<Bill_Adjustment__c> adjustToUpdateSet = new Set<Bill_Adjustment__c>();

    public void executeBatch(){
        Database.executeBatch(this, 33);
    }

    public List<SObject> start(Database.BatchableContext bc){
        List<SObject> sObjectList = new List<SObject>();
        sObjectList.addAll(AdjustmentSelector.getAdjustmentsNotYetInZuora(false));
        return sObjectList;
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){
        try {
            for (SObject scopeLine : scope){
                Bill_Adjustment__c adjust = (Bill_Adjustment__c)scopeLine;
                adjustToUpdateSet.add(ZuoraCreditDebitMemoService.createCreditOrDebitMemo(adjust));
            }
        } catch (Exception excep){
            Logger.logLater('ZuoraCreditMemoBatchSend', 'execute', excep.getMessage() + '\n' + excep.getStackTraceString());
        }
        Logger.flushLogs();
    }

    public void finish(Database.BatchableContext bc){
        if (Util.getSystemPropertyCheckbox('Update_Usage_Records_With_ZuoraId__c')) {
            List<Bill_Adjustment__c> adjustmentsToUpdate = new List<Bill_Adjustment__c>();
            adjustmentsToUpdate.addAll(adjustToUpdateSet);
            update adjustmentsToUpdate;
        }
    }
}