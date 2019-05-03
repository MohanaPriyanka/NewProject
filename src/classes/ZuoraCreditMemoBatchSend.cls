public without sharing class ZuoraCreditMemoBatchSend implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    public Set<Bill_Adjustment__c> adjustToUpdateSet = new Set<Bill_Adjustment__c>();

    public void executeBatch(){
        Database.executeBatch(this, 100);
    }

    public List<SObject> start(Database.BatchableContext bc){
        List<SObject> sObjectList = new List<SObject>();
        sObjectList.addAll(AdjustmentSelector.getAdjustmentsNotYetInZuora(false));
        return sObjectList;
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope){
        try {
            for (sObject scopeLine : scope){
                Bill_Adjustment__c adjust = (Bill_Adjustment__c)scopeLine;
                ZuoraAPI.CreditMemo memo;
                memo = ZuoraCreditDebitMemoService.convertSFAdjustToCreditMemo(adjust);
                HttpResponse response = ZuoraCreditDebitMemoService.creditMemoAPICall(memo);
                Bill_Adjustment__c adjustmentToUpdate = ZuoraCreditDebitMemoService.handleAPIResponse(memo,response);
                if (adjustmentToUpdate != null){
                    adjustToUpdateSet.add(adjustmentToUpdate);
                }
            }
        } catch (Exception excep){
            Logger.logLater('ZuoraCreditMemoBatchSend', 'execute', excep.getMessage() + '\n' + excep.getStackTraceString());
        }
        Logger.flushLogs();
    }

    public void finish(Database.BatchableContext bc){
        List<Bill_Adjustment__c> adjustmentsToUpdate = new List<Bill_Adjustment__c>();
        adjustmentsToUpdate.addAll(adjustToUpdateSet);
        update adjustmentsToUpdate;
    }
}