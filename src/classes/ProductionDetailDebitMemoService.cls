/**
 * Created by SarahRenfro on 8/10/2020.
 * TestedBy: ProductionToBillServiceTest
 */

public without sharing class ProductionDetailDebitMemoService {
    @TestVisible
    private List<Transfer_Part__c> productionDetailToInsert = new List<Transfer_Part__c>();

    public List<Journal_Entry__c> completedJEs = new List<Journal_Entry__c>();
    public List<Journal_Entry__c> incompleteEntries = new List<Journal_Entry__c>();

    @TestVisible
    private static AdjustmentSelector adjustmentSelector = new AdjustmentSelector();
    @TestVisible
    private static JournalEntrySelector journalEntrySelector = new JournalEntrySelector();
    @TestVisible
    private static ProductionDetailSelector productionDetailSelector = new ProductionDetailSelector();

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void createProductionDetailFromDebitMemo(List<Journal_Entry__c> debitMemoEntries) {
        calculateProductionDetailFromDebitMemo(debitMemoEntries);
        insert productionDetailToInsert;
    }

    @TestVisible
    private void calculateProductionDetailFromDebitMemo(List<Journal_Entry__c> debitMemoEntries) {
        Set<String> returnedPaymentIds = new Set<String>();
        Set<String> adjustmentExternalIds = new Set<String>();
        List<Journal_Entry__c> returnedDebitMemos = new List<Journal_Entry__c>();
        List<Journal_Entry__c> adjustmentDebitMemos = new List<Journal_Entry__c>();

        for (Journal_Entry__c entry : debitMemoEntries) {
            // Returned Payments need to create negative payment production detail records for the payment that was returned
            if (entry.Reason_Code__c == 'Returned Payment' && entry.Returned_PaymentPart_Id__c != null) {
                returnedPaymentIds.add(entry.Returned_PaymentPart_Id__c);
                returnedDebitMemos.add(entry);
            } else {
                //Adjustment Debit Memos need to create negative payment production detail records like the related adjustments
                adjustmentDebitMemos.add(entry);
                adjustmentExternalIds.add(entry.External_Id__c);
            }
        }

        if (returnedPaymentIds.size() > 0) {
            createProductionDetailsForReturnedPayments(returnedDebitMemos, returnedPaymentIds);
        }

        if (adjustmentDebitMemos.size() > 0 ) {
            createProductionDetailsForAdjustments(adjustmentDebitMemos, adjustmentExternalIds);
        }
    }

    @TestVisible
    private void createProductionDetailsForReturnedPayments(List<Journal_Entry__c> returnedDebitMemos, Set<String> returnedPaymentIds) {
        Map<String, Journal_Entry__c> returnedPaymentEntries = journalEntrySelector.getEntriesMapByIds(returnedPaymentIds);
        // update the DM's Applied Record Id with the paymentPart's Invoice Id
        // sending the DM to the payment service with an Invoice ID to create PDs just like the paymentPart
        for (Journal_Entry__c entry : returnedDebitMemos) {
            entry.Applied_Record_Id__c = returnedPaymentEntries.get(entry.Returned_PaymentPart_Id__c).Applied_Record_Id__c;
        }

        ProductionDetailPaymentService paymentService = new ProductionDetailPaymentService();
        paymentService.calculateProductionDetailFromCollectionItem(returnedDebitMemos);
        productionDetailToInsert.addAll(paymentService.productionDetailToInsert);
    }


    // Adjustment DebitMemos should be associated with a Bill Adjustment
    // Transfer field on Bill Adjustment will be populated
    // Distribute payment via production details in same way as bill adjustment but with opposite sign (-)
    @TestVisible
    private void createProductionDetailsForAdjustments(List<Journal_Entry__c> adjustmentDebitMemos, Set<String> adjustmentExternalIds) {
        Map<String, List<Bill_Adjustment__c>> adjustMap = adjustmentSelector.getAdjustmentMapFromExternalIds(adjustmentExternalIds);
        Set<Id> transferIds = new Set<Id>();

        for (String entryId : adjustMap.keySet()) {
            for (Bill_Adjustment__c adjust : adjustMap.get(entryId)) {
                transferIds.add(adjust.Transfer__c);
            }
        }

        ProductionDetailBillService billService = new ProductionDetailBillService();
        billService.transferToDetailMap = productionDetailSelector.getTransferPartMap(transferIds);
        for (Journal_Entry__c entry : adjustmentDebitMemos) {
            List<Bill_Adjustment__c> adjustments = adjustMap.get(entry.External_Id__c);
            if (adjustments == null) {
                incompleteEntries.add(entry);
                continue;
            }

            for (Bill_Adjustment__c sfAdjustment : adjustments) {
                if (sfAdjustment.Transfer__c != null) {
                    billService.createBillProductionDetail(sfAdjustment.Transfer__c, -entry.Amount__c, 'Payment', entry.Id);
                }
            }
        }
        productionDetailToInsert.addAll(billService.productionDetailToInsert);
    }
}