/**
 * @description Created by PeterYao on 8/13/2021.
 */
@IsTest
public with sharing class ProductionDetailDebitMemoTest {
    @IsTest
    public static void testCreateProductionDetailFromDebitMemos() {
        ProductionToBillServiceTest.useMocks();
        List<Transfer_Part__c> beforeDebitMemos = [
            SELECT Id
            FROM Transfer_Part__c
            WHERE Type__c = 'Payment'
        ];

        System.assertEquals(0, beforeDebitMemos.size());

        List<Journal_Entry__c> debitMemoEntries = getDebitMemoJournalEntries();
        ProductionDetailDebitMemoService service = new ProductionDetailDebitMemoService();
        service.calculateProductionDetailFromDebitMemo(debitMemoEntries);

        List<Transfer_Part__c> paymentParts = service.productionDetailToInsert;

        System.assertEquals(5, paymentParts.size());

        for (Transfer_Part__c part : paymentParts) {
            switch on String.valueOf(part.Bill_Part__c) {
                when 'a8y0a000000Gu3rBBB' {
                    System.assertEquals(-120, part.Amount__c);
                }
                when 'a8y0a000000Gu3rCCC' {
                    System.assertEquals(-1.87, part.Amount__c);
                }
                when else {
                    //other debit memos are for adjustments - tested below in testAdjustmentPaymentFromDebitMemo
                    continue;
                }
            }
        }
    }

    @IsTest
    public static void testAdjustmentPaymentFromDebitMemo() {
        ProductionToBillServiceTest.useMocks();
        List<Transfer_Part__c> beforeDebitMemos = [
            SELECT Id
            FROM Transfer_Part__c
            WHERE Type__c = 'Payment'
        ];

        System.assertEquals(0, beforeDebitMemos.size());

        List<Journal_Entry__c> debitMemoEntries = getDebitMemoJournalEntries();
        Set<String> adjustmentExternalIds = new Set<String>();
        List<Journal_Entry__c> otherDebitMemos = new List<Journal_Entry__c>();

        for (Journal_Entry__c entry : debitMemoEntries) {
            if (entry.Reason_Code__c == 'BW Credit') {
                adjustmentExternalIds.add(entry.External_Id__c);
                otherDebitMemos.add(entry);
            }
        }

        ProductionDetailDebitMemoService dmService = new ProductionDetailDebitMemoService();
        dmService.createProductionDetailsForAdjustments(otherDebitMemos, adjustmentExternalIds);

        List<Transfer_Part__c> paymentParts = dmService.productionDetailToInsert;
        System.assertEquals(3, paymentParts.size());
    }

    @IsTest
    public static void testNoLongerBillingDebitMemo() {
        ProductionToBillServiceTest.useMocks();
        List<Journal_Entry__c> debitMemoEntries = getDebitMemoJournalEntries();
        Set<String> adjustmentExternalIds = new Set<String>();
        List<Journal_Entry__c> otherDebitMemos = new List<Journal_Entry__c>();
        debitMemoEntries[1].Reason_Code__c = 'No Longer Billing';
        adjustmentExternalIds.add(debitMemoEntries[1].External_Id__c);
        otherDebitMemos.add(debitMemoEntries[1]);
        Map<Id, Journal_Entry__c> debitMemoMap = new Map<Id, Journal_Entry__c>(debitMemoEntries);

        ProductionDetailDebitMemoService dmService = new ProductionDetailDebitMemoService();
        dmService.createProductionDetailsForAdjustments(otherDebitMemos, adjustmentExternalIds);

        List<Transfer_Part__c> noLongerBillingParts = dmService.productionDetailToInsert;
        for (Transfer_Part__c transferPart : noLongerBillingParts) {
            if (debitMemoMap.get(transferPart.Journal_Entry__c).Reason_Code__c == 'No Longer Billing') {
                System.assertEquals('No Longer Billing', transferPart.Type__c, 'No Longer Billing JEs should get No Longer Billing PDs');
            } else {
                System.assertNotEquals('No Longer Billing', transferPart.Type__c, 'No Longer Billing PDs should only be for No Longer Billing JEs');
            }
        }
        System.assertEquals(3, noLongerBillingParts.size());
    }

    @IsTest
    private static void testProductionDetailsForReturnedPayments() {
        // Production Details for Returned Payment Debit Memos are treated like payments, but with a negative amount.
        // Instead of testing ProductionDetailDebitMemoService.createProductionDetailsForReturnedPayments, this avoids
        // the selectors and just tests the DebitMemo branch of ProductionDetailPaymentService.distributePaymentAmongInvoicesOrDebitMemos
        // (we'd mock those selectors anyways).
        // A paymentEntry is actually a Debit Memo from ProductionDetailDebitMemoService, e.g. a920a000000Hz1cAAC
        Journal_Entry__c paymentEntry = new Journal_Entry__c(
            Id = Util.getFakeId(Journal_Entry__c.SObjectType),
            External_Id__c = 'DebitMemo1',
            Amount__c = 210.47,
            Applied_Record_Id__c = 'InvoiceItem1',
            Reason_Code__c = 'Returned Payment',
            Object_Type__c = 'DebitMemo',
            Returned_PaymentPart_Id__c = 'PaymentPart1'
        );
        // Transfer Parts for Applied Record Id of the Debit Memo. This could be an Invoice Item or another Debit Memo, in
        // this case we'll make it an Invoice with "Bill" Production Details, e.g. the PD for a920a000000HxKqAAK
        List<Transfer_Part__c> invoicePartOrDebitMemos = new List<Transfer_Part__c>();
        invoicePartOrDebitMemos.add(new Transfer_Part__c(
            Id = Util.getFakeId(Transfer_Part__c.SObjectType),
            Amount__c = 210.47,
            Journal_Entry__c = Util.getFakeId(Journal_Entry__c.SObjectType)
        ));
        ProductionDetailPaymentService paymentService = new ProductionDetailPaymentService();
        paymentService.distributePaymentAmongInvoicesOrDebitMemos(paymentEntry, invoicePartOrDebitMemos);
        System.assertEquals(1, paymentService.productionDetailToInsert.size(),
            'Expected one PD to be created for the Returned Payment Debit Memo');
        System.assertEquals(-210.47, paymentService.productionDetailToInsert[0].Amount__c,
            'All Debit Memos should have a negative PD');

        // Now let's say the customer paid this debit memo, but that payment was returned and a new debit memo was created, like this:
        paymentEntry = new Journal_Entry__c(
            Id = Util.getFakeId(Journal_Entry__c.SObjectType),
            External_Id__c = 'DebitMemo2',
            Amount__c = 210.47,
            Applied_Record_Id__c = 'DebitMemo1',
            Reason_Code__c = 'Returned Payment',
            Object_Type__c = 'DebitMemo',
            Returned_PaymentPart_Id__c = 'PaymentPart2'
        );
        // And the Production Detail for the Debit Memo that it is applied to is now negative:
        invoicePartOrDebitMemos = new List<Transfer_Part__c>();
        invoicePartOrDebitMemos.add(new Transfer_Part__c(
            Id = Util.getFakeId(Transfer_Part__c.SObjectType),
            Amount__c = -210.47,
            Journal_Entry__c = Util.getFakeId(Journal_Entry__c.SObjectType)
        ));
        paymentService = new ProductionDetailPaymentService();
        paymentService.distributePaymentAmongInvoicesOrDebitMemos(paymentEntry, invoicePartOrDebitMemos);
        System.assertEquals(1, paymentService.productionDetailToInsert.size(),
            'Expected one PD to be created for the Returned Payment Debit Memo');
        System.assertEquals(-210.47, paymentService.productionDetailToInsert[0].Amount__c,
            'All Debit Memos, even those applied to another debit memo should have a negative PD');
    }

    @IsTest
    private static void testNoLongerBillingCreditMemo() {
        Journal_Entry__c paymentEntry = new Journal_Entry__c(
            Id = Util.getFakeId(Journal_Entry__c.SObjectType),
            External_Id__c = 'CreditMemo1',
            Amount__c = 210.47,
            Reason_Code__c = 'No Longer Billing',
            Object_Type__c = 'CreditMemo'
        );
        List<Transfer_Part__c> invoicePartOrDebitMemos = new List<Transfer_Part__c>();
        invoicePartOrDebitMemos.add(new Transfer_Part__c(
            Id = Util.getFakeId(Transfer_Part__c.SObjectType),
            Amount__c = 210.47,
            Journal_Entry__c = Util.getFakeId(Journal_Entry__c.SObjectType)
        ));
        ProductionDetailPaymentService paymentService = new ProductionDetailPaymentService();
        paymentService.distributePaymentAmongInvoicesOrDebitMemos(paymentEntry, invoicePartOrDebitMemos);
        System.assertEquals(1, paymentService.productionDetailToInsert.size(),
            'Expected one PD to be created for the No Longer Billing Credit Memo');
        System.assertEquals(210.47, paymentService.productionDetailToInsert[0].Amount__c,
            'Credit Memos should have a positive PD');
        System.assertEquals('No Longer Billing', paymentService.productionDetailToInsert[0].Type__c,
            'No Longer Billing Credit Memos should get that type so they are not conflated with Payments');
    }

    private static List<Journal_Entry__c> getDebitMemoJournalEntries() {
        Date mayBillDate = Date.newInstance(2019, 05, 20);

        //Returned Payment -- should track to Invoice
        Journal_Entry__c entryOne = new Journal_Entry__c(
            Id = 'a920a000000HuJoAAA',
            Object_Type__c = 'DebitMemo',
            Query_Type__c = 'DebitMemo',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 121.87,
            Applied_Record_Id__c = null,
            Reason_Code__c = 'Returned Payment',
            Returned_PaymentPart_Id__c = '2c92a00a71c95c4a0171dfcaf46f5343',
            Customer_Account__c = 'bw-00524',
            Date__c = mayBillDate
        );

        //Adjustment --- should track to Bill Adjustment
        Journal_Entry__c entryTwo = new Journal_Entry__c(
            Id = 'a920a000000HuJoBBB',
            Object_Type__c = 'DebitMemo',
            Query_Type__c = 'DebitMemo',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 221.87,
            Applied_Record_Id__c = null,
            Reason_Code__c = 'BW Credit',
            Customer_Account__c = 'bw-00524',
            External_Id__c = '2c92a00a71c95c4a0171dfcaf46f5333',
            Date__c = mayBillDate
        );

        List<Journal_Entry__c> entries = new List<Journal_Entry__c>{
            entryOne, entryTwo
        };
        return entries;
    }
}