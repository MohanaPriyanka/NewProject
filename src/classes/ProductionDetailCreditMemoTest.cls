/**
 * @description Created by PeterYao on 8/13/2021.
 */
@IsTest
public with sharing class ProductionDetailCreditMemoTest {
    @IsTest
    public static void testCreateProductionDetailFromCreditMemos() {
        ProductionToBillServiceTest.useMocks();
        // 5 Credit Memos Total
        // 2 of which have Reason Code = 'Production' so should
        // create 4 records each: 1 Bill, 1 Savings and 1 Payment in the first production period, and 1 Payment in the second
        // the remaining 3 should only create 'Collection' Production Detail records
        List<Journal_Entry__c> creditMemoEntries = getCreditMemoJournalEntries();
        System.assertEquals(5, creditMemoEntries.size());

        ProductionDetailCreditMemoService service = new ProductionDetailCreditMemoService();
        service.calculateProductionDetailFromCreditMemo(creditMemoEntries);

        List<Transfer_Part__c> productionDetailList = service.productionDetailToInsert;
        System.assertEquals(0, service.productionDetailToDelete.size());
        List<Journal_Entry__c> entryList = service.completedJEs;
        System.assertEquals(5, entryList.size());

        Integer countOfBills = 0;
        Integer countOfSavings = 0;
        Integer countOfPayments = 0;
        for (Transfer_Part__c prodDetail : productionDetailList) {
            if (prodDetail.Type__c == 'Bill') {
                countOfBills += 1;
            } else if (prodDetail.Type__c == 'Customer Savings') {
                countOfSavings += 1;
            } else if (prodDetail.Type__c == 'Payment') {
                countOfPayments += 1;
            }
        }

        // 2 'Bill' Credit Memos create a bill production detail, a savings production detail
        // and 4 payment records each (2 production periods, 2 parts each)
        // 3 'Payment' Credit Memos have 2 credit memo part items each, so 6 total Production Detail records:
        System.assertEquals(2, countOfBills);
        System.assertEquals(2, countOfSavings);
        System.assertEquals(12, countOfPayments);
    }

    @IsTest
    public static void testCreditMemoCalloutCount() {
        ProductionToBillServiceTest.useMocks();
        // 5 Credit Memos, 2 of which have Reason Code = 'Production' so should make 'Bill' Production Detail records
        // the remaining 3 should create 'Collection' Production Detail records
        List<Journal_Entry__c> creditMemoEntries = getCreditMemoJournalEntries();
        System.assertEquals(5, creditMemoEntries.size());

        ZuoraAPIHelper.numberCalloutsForZuoraNamespace = 88;

        ProductionDetailCreditMemoService service = new ProductionDetailCreditMemoService();
        service.calculateProductionDetailFromCreditMemo(creditMemoEntries);

        List<Transfer_Part__c> productionDetailList = service.productionDetailToInsert;
        List<Journal_Entry__c> completedEntries = service.completedJEs;

        Integer countOfBills = 0;
        Integer countOfSavings = 0;
        Integer countOfPayments = 0;
        for (Transfer_Part__c prodDetail : productionDetailList) {
            if (prodDetail.Type__c == 'Bill') {
                countOfBills += 1;
            } else if (prodDetail.Type__c == 'Customer Savings') {
                countOfSavings += 1;
            } else if (prodDetail.Type__c == 'Payment') {
                countOfPayments += 1;
            }
        }

        // 2 'Bill' Credit Memos create both a bill production detail and savings production detail:
        System.assertEquals(2, countOfBills);
        System.assertEquals(2, countOfSavings);

        // 2 Payments are inserted as a part of the 'production' credit memo logic,
        // which don't use callouts so we aren't testing here:
        countOfPayments -= 2;

        // 3 'Payment' Credit Memos have 2 credit memo part items each, so 6 total Production Detail records,
        // HOWEVER, because the callouts were already at 88, only 1 payment record will be made before re-queueing
        System.assertEquals(2, countOfPayments);
        // Only 1 of the 5 JE will be marked as complete:
        System.assertEquals(1, completedEntries.size());
    }

    @IsTest
    public static void testCreditMemoPreexistingRecordDeletion() {
        String jeListAsJSON = '[' +
            '{"attributes":{"type":"Journal_Entry__c"},"Id":"a920a000000HuJoAAA", "Object_Type__c" : "CreditMemo", "Query_Type__c":"CreditMemo", ' +
            '"Transfer_Parts__r":{"totalSize":1,"done":true,"records":[' +
            '{"attributes":{"type":"Transfer_Part__c"},"Journal_Entry__c":"a920a000000HuJoAAA","Id":"a8y3K0000009ougQAA"}]}' +
            '}, ' +
            '{"attributes":{"type":"Journal_Entry__c"},"Id":"a920a000000HuJoAAB", "Object_Type__c" : "CreditMemo", "Query_Type__c":"CreditMemo", ' +
            '"Transfer_Parts__r":{"totalSize":2,"done":true,"records":[' +
            '{"attributes":{"type":"Transfer_Part__c"},"Journal_Entry__c":"a920a000000HuJoAAB","Id":"a8y3K0000009ougQCC"},' +
            '{"attributes":{"type":"Transfer_Part__c"},"Journal_Entry__c":"a920a000000HuJoAAB","Id":"a8y3K0000009ougQDD"}]}' +
            '}, ' +
            '{"attributes":{"type":"Journal_Entry__c"},"Id":"a920a000000HuJoAAC", "Object_Type__c" : "CreditMemo", "Query_Type__c":"CreditMemo"}, ' +
            '{"attributes":{"type":"Journal_Entry__c"},"Id":"a920a000000HuJoAAD", "Object_Type__c" : "CreditMemo", "Query_Type__c":"CreditMemo", ' +
            '"Transfer_Parts__r":{"totalSize":1,"done":true,"records":[' +
            '{"attributes":{"type":"Transfer_Part__c"},"Journal_Entry__c":"a920a000000HuJoAAD","Id":"a8y3K0000009ougQBB"}]}' +
            '}, ' +
            '{"attributes":{"type":"Journal_Entry__c"},"Id":"a920a000000HuJoAAE", "Object_Type__c" : "CreditMemo", "Query_Type__c":"CreditMemo"} ' +
            ']';
        List<Journal_Entry__c> entryList = (List<Journal_Entry__c>) JSON.deserialize(jeListAsJSON, List<Journal_Entry__c>.class);
        System.assertEquals(5, entryList.size());

        ProductionDetailCreditMemoService service = new ProductionDetailCreditMemoService();
        service.calculateProductionDetailFromCreditMemo(entryList);

        System.assertEquals(4, service.productionDetailToDelete.size());
    }

    private static List<Journal_Entry__c> getCreditMemoJournalEntries() {
        Date mayBillDate = Date.newInstance(2019, 05, 20);
        Date juneBillDate = Date.newInstance(2019, 06, 20);

        Journal_Entry__c entryOne = new Journal_Entry__c(
            Id = 'a920a000000HuJoAAA',
            Object_Type__c = 'CreditMemo',
            Query_Type__c = 'CreditMemo',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 121.87,
            Applied_Record_Id__c = null,
            External_Id__c = '2c92c0f86e3a939h016e3cebdda44909',
            Reason_Code__c = 'Production',
            Customer_Account__c = 'bw-00524',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryTwo = new Journal_Entry__c(
            Id = 'a920a000000HuJoAAB',
            Object_Type__c = 'CreditMemo',
            Query_Type__c = 'CreditMemo',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 31.72,
            Applied_Record_Id__c = null,
            External_Id__c = '2c92c0f86e3a939g016e3cebdda44909',
            Reason_Code__c = 'Client Credit',
            Customer_Account__c = 'bw-00524',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryThree = new Journal_Entry__c(
            Id = 'a920a000000HuJoAAC',
            Object_Type__c = 'CreditMemo',
            Query_Type__c = 'CreditMemo',
            Project__c = 'SSS-000022',
            Client__c = 'BW-0009470',
            Amount__c = 60.00,
            Applied_Record_Id__c = null,
            External_Id__c = '2c92c0f86e3a939f016e3cebdda44909',
            Reason_Code__c = 'BW Credit',
            Customer_Account__c = 'bw-05268',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryFive = new Journal_Entry__c(
            Id = 'a920a000000HuJoAAD',
            Object_Type__c = 'CreditMemo',
            Query_Type__c = 'CreditMemo',
            Project__c = 'SSS-000002',
            Client__c = 'BW-0009470',
            Amount__c = 37.23,
            Applied_Record_Id__c = null,
            External_Id__c = '2c92c0f96e3aa333016e3cf0484b601f',
            Reason_Code__c = 'Production',
            Customer_Account__c = 'bw-04202',
            Date__c = mayBillDate
        );
        Journal_Entry__c entrySix = new Journal_Entry__c(
            Id = 'a920a000000HuJoAAE',
            Object_Type__c = 'CreditMemo',
            Query_Type__c = 'CreditMemo',
            Project__c = 'SSS-000002',
            Client__c = 'BW-0009470',
            Amount__c = 62.55,
            Applied_Record_Id__c = null,
            External_Id__c = '2c92c0f86e3a939f016e3ceadda44909',
            Reason_Code__c = 'Client Credit',
            Customer_Account__c = 'bw-04202',
            Date__c = juneBillDate
        );

        List<Journal_Entry__c> entries = new List<Journal_Entry__c>{
            entryOne, entryTwo, entryThree, entryFive, entrySix
        };
        return entries;
    }
}