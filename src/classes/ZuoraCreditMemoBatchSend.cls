/*
Tested by: ZuoraCreditDebitMemoServiceTest
 */
public without sharing class ZuoraCreditMemoBatchSend implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{
    public Set<Bill_Adjustment__c> adjustToUpdateSet = new Set<Bill_Adjustment__c>();
    public String queryString;
    public Date effectiveDate;
    public enum AdjustmentType {
        POST_WHEN_APPROVED, POST_NEXT_BILL}
    public AdjustmentType mode = AdjustmentType.POST_NEXT_BILL;
    private Set<Id> billAdjustmentsToSend = new Set<Id>();

    /**
     * @description Used to send specific Bill Adjustments to Zuora. Intended for the Bill Adjustment Trigger to send
     * adjustments after approval (since multiple approvals can create duplicate records in Zuora per W-021849)
     * @param billAdjustmentsToSend List of Bill_Adjustment__c Ids to send to Zuora
     */
    public void setBillAdjustmentsToSend(Set<Id> billAdjustmentsToSend) {
        this.billAdjustmentsToSend = billAdjustmentsToSend;
    }

    public void executeBatch(){
        // 7 callouts to create a debit memo from an invoice, so a max of 14 memos per transaction to stay under 100 callouts
        Database.executeBatch(this, 14);
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        if (queryString != null) {
            return Database.getQueryLocator(queryString);
        } else {
            return AdjustmentSelector.getAdjustmentsNotYetInZuora(false, mode, billAdjustmentsToSend);
        }
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){
        try {
            for (SObject scopeLine : scope){
                if (effectiveDate == null){
                    effectiveDate = System.today();
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
            // No more than one executeBatch can be called from a test method
            if (mode == AdjustmentType.POST_WHEN_APPROVED && !Test.isRunningTest()){
                ZuoraMemoBatchApply batchApply = new ZuoraMemoBatchApply();
                batchApply.startApplication();
                batchApply.runBatch();
            }

            List<Bill_Adjustment__c> adjustmentsToUpdate = new List<Bill_Adjustment__c>();
            stampEffectiveDate();
            adjustmentsToUpdate.addAll(adjustToUpdateSet);
            update adjustmentsToUpdate;
        } catch (Exception excep){
            Logger.logLater('ZuoraCreditMemoBatchSend', 'finish', excep.getMessage() + '\n' + excep.getStackTraceString());
        }
        Logger.flushLogs();
    }

    private void stampEffectiveDate() {
        for (Bill_Adjustment__c adjustment : adjustToUpdateSet){
            if (adjustment.Effective__c == 'Post on Next Bill') {
                //Production Adjustments are always "Post on Next Bill" and should be populated with the Invoice Date (passed by Bill Gen Console)
                adjustment.Effective_Date__c = effectiveDate;
            } else {
                adjustment.Effective_Date__c = System.today();
            }
        }
    }
}