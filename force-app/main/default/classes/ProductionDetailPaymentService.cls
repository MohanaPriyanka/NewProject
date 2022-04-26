// Tested By: ProductionDetailPaymentTest, ProductionDetailDebitMemoTest
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

    @TestVisible
    private void distributePaymentAmongInvoicesOrDebitMemos(Journal_Entry__c paymentEntry, List<Transfer_Part__c> invoicePartOrDebitMemos) {
        Decimal paymentAmount = paymentEntry.Amount__c;

        for (Transfer_Part__c invoicePartOrDebitMemo : invoicePartOrDebitMemos) {
            if (paymentAmount <= 0) {
                continue;
            }

            Decimal applicationAmount;
            if (paymentEntry.Object_Type__c == 'DebitMemo') {
                // If the paymentEntry for which we're creating a Production Detail is a Debit Memo, it's a returned payment.
                // invoicePartOrDebitMemo is the PD for the InvoiceItem or DM that the returned payment is applied to - there
                // could be multiple PDs if the invoice item covers multiple production periods, like a920a0000007xuUAAQ.
                // For those cases, we don't want to apply more than the payment amount or the invoicePartOrDebitMemo, but
                // invoicePartOrDebitMemo could be negative (since it could be a Returned Payment Debit Memo like a920a00000080iiAAA).
                // So we need to take the abs of invoicePartOrDebitMemo.
                applicationAmount = Math.min(Math.abs(invoicePartOrDebitMemo.Amount__c), paymentAmount);
            } else {
                Decimal invoicePartPayments = Util.nullToZero(partToPaymentMap.get(invoicePartOrDebitMemo.Id));
                // The Production Details for Debit Memos are negative (they are negative payments), but we need to pay
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
            Type__c = (paymentEntry.Reason_Code__c=='No Longer Billing'?'No Longer Billing':'Payment'),
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