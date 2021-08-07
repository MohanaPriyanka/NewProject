// Tested By: ProductionToBillServiceTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductionDetailPaymentService implements Database.AllowsCallouts {
    @TestVisible
    private Map<Id, Decimal> partToPaymentMap = new Map<Id, Decimal>();
    public List<Transfer_Part__c> productionDetailToInsert = new List<Transfer_Part__c>();
    @TestVisible
    private static ProductionDetailSelector productionDetailSelector = new ProductionDetailSelector();

    public void createProductionDetailFromCollectionItem(List<Journal_Entry__c> paymentEntries) {
        calculateProductionDetailFromCollectionItem(paymentEntries);
        insert productionDetailToInsert;
    }

    public void calculateProductionDetailFromCollectionItem(List<Journal_Entry__c> paymentEntries) {
        Set<String> invoiceOrDebitMemoIds = new Set<String>();
        for (Journal_Entry__c entry : paymentEntries) {
            invoiceOrDebitMemoIds.add(entry.Applied_Record_Id__c);
        }

        Map<String, List<Transfer_Part__c>> billPartsOrDebitMemoMap = productionDetailSelector.getInvoicePartMap(invoiceOrDebitMemoIds);
        partToPaymentMap = productionDetailSelector.getPaymentSum(invoiceOrDebitMemoIds);

        for (Journal_Entry__c paymentEntry : paymentEntries) {
            List<Transfer_Part__c> invoicePartOrDebitMemo = billPartsOrDebitMemoMap.get(paymentEntry.Applied_Record_Id__c);
            if (invoicePartOrDebitMemo != null) {
                distributePaymentAmongInvoicesOrDebitMemos(paymentEntry, invoicePartOrDebitMemo);
            }
        }
    }

    private void distributePaymentAmongInvoicesOrDebitMemos(Journal_Entry__c paymentEntry, List<Transfer_Part__c> invoicePartOrDebitMemos) {
        Decimal paymentAmount = paymentEntry.Amount__c;

        for (Transfer_Part__c invoicePartOrDebitMemo : invoicePartOrDebitMemos) {
            if (paymentAmount <= 0) {
                continue;
            }

            Decimal applicationAmount;
            if (paymentEntry.Object_Type__c == 'DebitMemo') {
                applicationAmount = Math.min(invoicePartOrDebitMemo.Amount__c, paymentAmount);
            } else {
                Decimal invoicePartPayments = Util.nullToZero(partToPaymentMap.get(invoicePartOrDebitMemo.Id));
                // The production details for debit memos are negative (they are negative payments), but we need to pay
                // them, so we need to take the abs of that amount.
                Decimal invoicePartBalance = Math.abs(invoicePartOrDebitMemo.Amount__c) - invoicePartPayments;
                if (invoicePartBalance <= 0) {
                    continue;
                }
                applicationAmount = Math.min(invoicePartBalance, paymentAmount);
                invoicePartPayments += applicationAmount;
                partToPaymentMap.put(invoicePartOrDebitMemo.Id, invoicePartPayments);
            }

            productionDetailToInsert.add(createCollectionProductionDetail(paymentEntry, invoicePartOrDebitMemo, applicationAmount));
            paymentAmount -= applicationAmount;
        }
    }

    private Transfer_Part__c createCollectionProductionDetail(Journal_Entry__c paymentEntry, Transfer_Part__c invoicePart, Decimal applicationAmount) {
        Transfer_Part__c payPart = new Transfer_Part__c(
            Name = 'Collection Item',
            Production__c = invoicePart.Production__c,
            Transfer__c = invoicePart.Transfer__c,
            Bill_Part__c = invoicePart.Id,
            Journal_Entry__c = paymentEntry.Id,
            Type__c = 'Payment',
            Amount__c = applicationAmount
        );

        // Returned payments create (-) production details to cancel existing payment record
        if (paymentEntry.Object_Type__c == 'DebitMemo' && paymentEntry.Reason_Code__c == 'Returned Payment') {
            payPart.Name = 'Returned Payment';
            payPart.Amount__c = -applicationAmount;
        }
        return payPart;

    }
}