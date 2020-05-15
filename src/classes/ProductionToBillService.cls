// Tested By: ProductionToBillServiceTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductionToBillService implements Queueable, Database.AllowsCallouts{
    @TestVisible
    private static JournalEntrySelector journalEntrySelector = new JournalEntrySelector();
    @TestVisible
    private static UASBSelector uasbSelector = new UASBSelector();
    @TestVisible
    private static AdjustmentSelector adjustmentSelector = new AdjustmentSelector();

    public enum OperationType {BILL, PAYMENT, CREDITMEMO, UNSERVICED_BILL, UNSERVICED_ADJUST}
    public OperationType opType;
    public Integer batchSize;

    public List<Journal_Entry__c> incompleteEntries = new List<Journal_Entry__c>();

    public void execute(QueueableContext context) {
        genericExecute();
    }

    public void genericExecute(){
        if (batchSize == null){
            batchSize = 1000;
        }
        if (opType == OperationType.BILL){
            executeBillJob();
        } else if (opType == OperationType.PAYMENT){
            executePaymentJob();
        } else if (opType == OperationType.CREDITMEMO){
            executeCreditMemoJob();
        } else if (opType == OperationType.UNSERVICED_BILL){
            executeUnservicedBillJob();
        } else if (opType == OperationType.UNSERVICED_ADJUST){
            executeUnservicedAdjustJob();
        }
    }

    private void executeBillJob(){
        List<Journal_Entry__c> invoiceItems;
        try {
            invoiceItems = journalEntrySelector.getEntriesWithoutProductionDetail(
                new List<String>{'InvoiceItem'}, batchSize
            );
            if (invoiceItems.size() > 0){
                ProductionDetailBillService billService = new ProductionDetailBillService();
                billService.createProductionDetailFromInvoiceItems(invoiceItems, batchSize);
                markJournalEntriesAsComplete(invoiceItems);
            } else {
                queueJob(OperationType.PAYMENT);
            }
        } catch (Exception excep) {
            String message = excep.getMessage() + '_' + excep.getStackTraceString() + '_' + JSON.serialize(invoiceItems);
            Logger.logNow('ProductionToBillService', 'executeBillJob', message);
        }
    }

    private void executePaymentJob(){
        List<Journal_Entry__c> collectionItems;
        try {
            collectionItems = journalEntrySelector.getEntriesWithoutProductionDetail(
                new List<String>{'PaymentPart'}, batchSize
            );
            if (collectionItems.size() > 0){
                ProductionDetailPaymentService paymentService = new ProductionDetailPaymentService();
                paymentService.createProductionDetailFromCollectionItem(collectionItems);
                markJournalEntriesAsComplete(collectionItems);
            }
            if (collectionItems.size() == batchSize){
                queueJob(OperationType.PAYMENT);
            } else {
                queueJob(OperationType.CREDITMEMO);
            }
        } catch (Exception excep) {
            String message = excep.getMessage() + '_' + excep.getStackTraceString() + '_' + JSON.serialize(collectionItems);
            Logger.logNow('ProductionToBillService', 'executePaymentJob', message);
        }
    }

    private void executeCreditMemoJob(){
        List<Journal_Entry__c> creditMemosToAttempt;

        try {
            /*
                We will use at least 2 callouts per credit memo, but since we don't know how many part items there
                will be for any given CM, we can't know exactly how many callouts calculateProductionDetailFromCreditMemo
                will use. If we come close to the callout limit, we will stop processing credit memos and requeue
            */
            batchSize = Math.min(batchSize, 50);
            Boolean requiresRequeue = false;
            creditMemosToAttempt = journalEntrySelector.getEntriesWithoutProductionDetail(
                new List<String>{'CreditMemo'}, batchSize
            );

            if (creditMemosToAttempt.size() > 0){
                ProductionDetailCreditMemoService creditMemoService = new ProductionDetailCreditMemoService();
                requiresRequeue = creditMemoService.createProductionDetailFromCreditMemo(creditMemosToAttempt);
                incompleteEntries.addAll(creditMemoService.incompleteEntries);
                markJournalEntriesAsComplete(creditMemosToAttempt);
            }
            if (creditMemosToAttempt.size() == batchSize || requiresRequeue){
                queueJob(OperationType.CREDITMEMO);
            } else {
                updateJournalEntriesReadyStatus(incompleteEntries, true);
                queueJob(OperationType.UNSERVICED_BILL);
            }
        } catch (Exception excep) {
            String message = excep.getMessage() + '_' + excep.getStackTraceString() + '_' + JSON.serialize(creditMemosToAttempt);
            Logger.logNow('ProductionToBillService', 'executeCreditMemoJob', message);
        }
    }

    private void executeUnservicedBillJob(){
        List<UASB__c> externallyServicedUASBs = new List<UASB__c>();
        try {
            externallyServicedUASBs = uasbSelector.getUnservicedWithoutProductionDetail(batchSize);
            if (externallyServicedUASBs.size() > 0){
                ProductionDetailBillService billService = new ProductionDetailBillService();
                billService.createProductionDetailFromUnservicedUASB(externallyServicedUASBs);
                markUASBsAsComplete(externallyServicedUASBs);
            }
            if (externallyServicedUASBs.size() == batchSize){
                queueJob(OperationType.UNSERVICED_BILL);
            } else {
                queueJob(OperationType.UNSERVICED_ADJUST);
            }
        } catch (Exception excep){
            String message = excep.getMessage() + '_' + excep.getStackTraceString() + '_' + JSON.serialize(externallyServicedUASBs);
            Logger.logNow('ProductionToBillService', 'executeUnservicedBillJob', message);
        }
    }

    private void executeUnservicedAdjustJob(){
        List<Bill_Adjustment__c> externallyServicedAdjusts = new List<Bill_Adjustment__c>();
        try {
            externallyServicedAdjusts = adjustmentSelector.getUnservicedWithoutProductionDetail(batchSize);
            if (externallyServicedAdjusts.size() > 0){
                ProductionDetailBillService billService = new ProductionDetailBillService();
                billService.createProductionDetailFromUnservicedAdjustment(externallyServicedAdjusts);
                markAdjustmentsAsComplete(externallyServicedAdjusts);
            }
            if (externallyServicedAdjusts.size() == batchSize){
                queueJob(OperationType.UNSERVICED_ADJUST);
            }
        } catch (Exception excep){
            String message = excep.getMessage() + '_' + excep.getStackTraceString() + '_' + JSON.serialize(externallyServicedAdjusts);
            Logger.logNow('ProductionToBillService', 'executeUnservicedAdjustJob', message);
        }
    }

    public void queueJob(OperationType operation){
        ProductionToBillService billJob = new ProductionToBillService();
        billJob.opType = operation;
        billJob.incompleteEntries = incompleteEntries;
        System.enqueueJob(billJob);
    }

    private void markJournalEntriesAsComplete(List<Journal_Entry__c> entries){
        updateJournalEntriesReadyStatus(entries, false);
    }

    private void updateJournalEntriesReadyStatus(List<Journal_Entry__c> entries, Boolean readyForDetail){
        for (Journal_Entry__c entry : entries){
            if (entry.Object_Type__c == 'CreditMemo'){
                entry.Applied_Record_Id__c = null;
            }
            entry.Ready_for_Production_Detail__c = readyForDetail;
        }
        update entries;
    }

    @TestVisible
    private void markUASBsAsComplete(List<UASB__c> unservicedBills){
        for (UASB__c uasb : unservicedBills){
            uasb.Ready_for_Production_Detail__c = false;
        }
        update unservicedBills;
    }

    @TestVisible
    private void markAdjustmentsAsComplete(List<Bill_Adjustment__c> unservicedAdjusts){
        for (Bill_Adjustment__c adjust : unservicedAdjusts){
            adjust.Ready_for_Production_Detail__c = false;
        }
        update unservicedAdjusts;
    }
}