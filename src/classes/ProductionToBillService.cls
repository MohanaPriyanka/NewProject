// Tested By: ProductionToBillServiceTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductionToBillService implements Queueable, Database.AllowsCallouts {
    @TestVisible
    private static JournalEntrySelector journalEntrySelector = new JournalEntrySelector();
    @TestVisible
    private static UASBSelector uasbSelector = new UASBSelector();
    @TestVisible
    private static AdjustmentSelector adjustmentSelector = new AdjustmentSelector();

    public enum OperationType {
        BILL, PAYMENT, CREDITMEMO, DEBITMEMO, UNSERVICED_BILL, UNSERVICED_ADJUST
    }
    public OperationType opType;
    public Integer batchSize = 1000;

    public List<Journal_Entry__c> incompleteEntries = new List<Journal_Entry__c>();

    public void execute(QueueableContext context) {
        try {
            if (opType == OperationType.BILL) {
                executeBillJob();
            } else if (opType == OperationType.PAYMENT) {
                executePaymentJob();
            } else if (opType == OperationType.CREDITMEMO) {
                executeCreditMemoJob();
            } else if (opType == OperationType.UNSERVICED_BILL) {
                executeUnservicedBillJob();
            } else if (opType == OperationType.UNSERVICED_ADJUST) {
                executeUnservicedAdjustJob();
            } else if (opType == OperationType.DEBITMEMO) {
                executeDebitMemoJob();
            }
        } catch (Exception e) {
            String message = e.getMessage() + '\n' + e.getStackTraceString();
            Logger.logNow('ProductionToBillService', 'executeBillJob', message);
        }
        Logger.logNow('ProductionToBillService', 'execute limit check', opType.name() + ' batch size ' + batchSize, Logger.FINE);
    }

    private void executeBillJob() {
        List<Journal_Entry__c> invoiceItems;
        invoiceItems = journalEntrySelector.getEntriesWithoutProductionDetail(
            new List<String>{
                'InvoiceItem'
            }, batchSize
        );
        if (invoiceItems.size() > 0) {
            ProductionDetailBillService billService = new ProductionDetailBillService();
            billService.createProductionDetailFromInvoiceItems(invoiceItems, batchSize);
            markJournalEntriesAsComplete(invoiceItems);
            if (invoiceItems.size() == batchSize) {
                queueJob(OperationType.BILL);
            }
        } else {
            queueJob(OperationType.PAYMENT);
        }
    }

    private void executePaymentJob() {
        List<Journal_Entry__c> collectionItems;
        collectionItems = journalEntrySelector.getEntriesWithoutProductionDetail(
            new List<String>{
                'PaymentPart'
            }, batchSize
        );
        if (collectionItems.size() > 0) {
            ProductionDetailPaymentService paymentService = new ProductionDetailPaymentService();
            paymentService.createProductionDetailFromCollectionItem(collectionItems);
            markJournalEntriesAsComplete(collectionItems);
        }
        if (collectionItems.size() == batchSize) {
            queueJob(OperationType.PAYMENT);
        } else {
            queueJob(OperationType.CREDITMEMO);
        }
    }

    private void executeCreditMemoJob() {
        List<Journal_Entry__c> creditMemosToAttempt;
        List<Journal_Entry__c> completedCreditMemos = new List<Journal_Entry__c>();
        /*
            We will use at least 2 callouts per credit memo, but since we don't know how many part items there
            will be for any given CM, we can't know exactly how many callouts calculateProductionDetailFromCreditMemo
            will use. If we come close to the callout limit, we will stop processing credit memos and requeue.
        */
        batchSize = Math.min(batchSize, 50);
        creditMemosToAttempt = journalEntrySelector.getEntriesWithoutProductionDetail(
            new List<String>{
                'CreditMemo'
            }, batchSize
        );

        if (creditMemosToAttempt.size() > 0) {
            ProductionDetailCreditMemoService creditMemoService = new ProductionDetailCreditMemoService();
            creditMemoService.createProductionDetailFromCreditMemo(creditMemosToAttempt);
            incompleteEntries.addAll(creditMemoService.incompleteEntries);
            completedCreditMemos = creditMemoService.completedJEs;
            markJournalEntriesAsComplete(completedCreditMemos);
        }
        if (creditMemosToAttempt.size() == batchSize || completedCreditMemos.size() != creditMemosToAttempt.size()) {
            queueJob(OperationType.CREDITMEMO);
        } else {
            updateJournalEntriesReadyStatus(incompleteEntries, true);
            queueJob(OperationType.UNSERVICED_BILL);
        }
    }

    private void executeUnservicedBillJob() {
        List<UASB__c> externallyServicedUASBs = new List<UASB__c>();
        externallyServicedUASBs = uasbSelector.getUnservicedWithoutProductionDetail(batchSize);
        if (externallyServicedUASBs.size() > 0) {
            ProductionDetailBillService billService = new ProductionDetailBillService();
            billService.createProductionDetailFromUnservicedUASB(externallyServicedUASBs);
            markUASBsAsComplete(externallyServicedUASBs);
        }
        if (externallyServicedUASBs.size() == batchSize) {
            queueJob(OperationType.UNSERVICED_BILL);
        } else {
            queueJob(OperationType.UNSERVICED_ADJUST);
        }
    }

    private void executeUnservicedAdjustJob() {
        List<Bill_Adjustment__c> externallyServicedAdjusts = new List<Bill_Adjustment__c>();
        externallyServicedAdjusts = adjustmentSelector.getUnservicedWithoutProductionDetail(batchSize);
        if (externallyServicedAdjusts.size() > 0) {
            ProductionDetailBillService billService = new ProductionDetailBillService();
            billService.createProductionDetailFromUnservicedAdjustment(externallyServicedAdjusts);
            markAdjustmentsAsComplete(externallyServicedAdjusts);
        }
        if (externallyServicedAdjusts.size() == batchSize) {
            queueJob(OperationType.UNSERVICED_ADJUST);
        } else {
            queueJob(OperationType.DEBITMEMO);
        }
    }

    private void executeDebitMemoJob() {
        List<Journal_Entry__c> debitMemosToAttempt;
        List<Journal_Entry__c> completedDebitMemos;
        batchSize = Math.min(batchSize, 1000);
        debitMemosToAttempt = journalEntrySelector.getEntriesWithoutProductionDetail(new List<String>{
            'DebitMemo'
        }, batchSize);

        if (debitMemosToAttempt.size() > 0) {
            ProductionDetailDebitMemoService debitMemoService = new ProductionDetailDebitMemoService();
            debitMemoService.createProductionDetailFromDebitMemo(debitMemosToAttempt);
            incompleteEntries.addAll(debitMemoService.incompleteEntries);
            completedDebitMemos = debitMemoService.completedJEs;
            markJournalEntriesAsComplete(debitMemosToAttempt);
        }
        if (debitMemosToAttempt.size() == batchSize) {
            queueJob(OperationType.DEBITMEMO);
        } else {
            updateJournalEntriesReadyStatus(incompleteEntries, true);
        }
    }

    @TestVisible
    private void queueJob(OperationType operation) {
        ProductionToBillService billJob = new ProductionToBillService();
        billJob.opType = operation;
        billJob.incompleteEntries = incompleteEntries;
        System.enqueueJob(billJob);
    }

    private void markJournalEntriesAsComplete(List<Journal_Entry__c> entries) {
        updateJournalEntriesReadyStatus(entries, false);
    }

    private void updateJournalEntriesReadyStatus(List<Journal_Entry__c> entries, Boolean readyForDetail) {
        for (Journal_Entry__c entry : entries) {
            if (entry.Object_Type__c == 'CreditMemo') {
                entry.Applied_Record_Id__c = null;
            }
            entry.Ready_for_Production_Detail__c = readyForDetail;
        }
        update entries;
    }

    @TestVisible
    private void markUASBsAsComplete(List<UASB__c> unservicedBills) {
        for (UASB__c uasb : unservicedBills) {
            uasb.Ready_For_Production_Detail__c = false;
        }
        update unservicedBills;
    }

    @TestVisible
    private void markAdjustmentsAsComplete(List<Bill_Adjustment__c> unservicedAdjusts) {
        for (Bill_Adjustment__c adjust : unservicedAdjusts) {
            adjust.Ready_For_Production_Detail__c = false;
        }
        update unservicedAdjusts;
    }
}