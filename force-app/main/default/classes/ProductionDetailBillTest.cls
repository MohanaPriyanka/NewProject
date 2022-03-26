/**
 * @description Created by PeterYao on 8/13/2021.
 */
@IsTest
@SuppressWarnings('PMD.AvoidHardcodingId')
public with sharing class ProductionDetailBillTest {
    @IsTest
    public static void testFromInvoicesGetUsage() {
        /* 4 Customer Accounts, Across 2 Months:
            bw-00524: 1 Subscription to 1 project
            bw-04202: 1 Subscription to 1 project
            bw-05268: 9 Subscriptions to different projects.
            bw-05956: 8 Subscriptions on same project.
        */
        ProductionToBillServiceTest.useMocks();

        Test.startTest();
        ProductionDetailBillService service = new ProductionDetailBillService();
        service.fromInvoicesGetUsage(getMockInvoiceItemIds(), getMockUsageDataQueryResult());
        Test.stopTest();

        Map<String, ProductionDetailBillService.GLInvoiceItem> invoiceMap = service.invoiceIdToUsageMap;
        ProductionDetailBillService.GLInvoiceItem acct04202 = invoiceMap.get('2c92c0fb6e3aa322016e3df698ff7e9f');
        ProductionDetailBillService.GLInvoiceItem acct00524 = invoiceMap.get('2c92c0fa6e3a9391016e3e30d48066d2');
        ProductionDetailBillService.GLInvoiceItem acct05268 = invoiceMap.get('2c92c0fb6e3aa321016e3df574337a9b');
        ProductionDetailBillService.GLInvoiceItem acct05956 = invoiceMap.get('2c92c0fa6e3a938d016e3dfdc93450b2');

        System.assertEquals(1, acct04202.bills.size());
        System.assertEquals(1, acct00524.bills.size());
        // Even though there are 9 subscriptions for bw-05268, they are all on different projects and therefore
        // only 1 usage line for a given invoiceItems
        System.assertEquals(1, acct05268.bills.size());
        // Alternatively, for bw-05956 all 8 subscriptions are on 1 project (all usage under same invoice)
        System.assertEquals(8, acct05956.bills.size());

        System.assertEquals(acct04202.sumOfAmount, acct04202.amount);
        System.assertEquals(acct00524.sumOfAmount, acct00524.amount);
        System.assertEquals(acct05268.sumOfAmount, acct05268.amount);
        System.assertEquals(acct05956.sumOfAmount, acct05956.amount);

        System.assertEquals(37.23, acct04202.sumOfAmount);
        System.assertEquals(135.06, acct00524.sumOfAmount);
        System.assertEquals(255.63, acct05268.sumOfAmount);
        System.assertEquals(1997.03, acct05956.sumOfAmount);

        System.assertEquals('2c92c0f96e3aa331016e3cd782c2640d', acct04202.bills[0].externalId);
        System.assertEquals('2c92c0f96e3aa333016e3cf0484b601f', acct00524.bills[0].externalId);
        System.assertEquals('2c92c0f86e3a939f016e3cebdda44909', acct05268.bills[0].externalId);
    }

    @IsTest
    public static void testFromUsageGetUASBsandAdjust() {
        ProductionToBillServiceTest.useMocks();
        ProductionDetailBillService service = new ProductionDetailBillService();
        service.fromInvoicesGetUsage(getMockInvoiceItemIds(), getMockUsageDataQueryResult());
        Map<String, ProductionDetailBillService.GLInvoiceItem> oldInvoiceMap = service.invoiceIdToUsageMap;

        ProductionDetailBillService.GLInvoiceItem acct04202 = oldInvoiceMap.get('2c92c0fb6e3aa322016e3df698ff7e9f');
        ProductionDetailBillService.GLInvoiceItem acct00524 = oldInvoiceMap.get('2c92c0fa6e3a9391016e3e30d48066d2');
        ProductionDetailBillService.GLInvoiceItem acct05268 = oldInvoiceMap.get('2c92c0fb6e3aa321016e3df574337a9b');
        ProductionDetailBillService.GLInvoiceItem acct05956 = oldInvoiceMap.get('2c92c0fa6e3a938d016e3dfdc93450b2');

        System.assertEquals(null, acct04202.bills[0].sFRecords);
        System.assertEquals(null, acct00524.bills[0].sFRecords);
        System.assertEquals(null, acct05268.bills[0].sFRecords);
        System.assertEquals(null, acct05956.bills[0].sFRecords);

        Test.startTest();
        service.fromUsageGetUASBsAndProductionAdjustments();
        Test.stopTest();

        Map<String, ProductionDetailBillService.GLInvoiceItem> updatedInvoiceMap = service.invoiceIdToUsageMap;
        acct04202 = updatedInvoiceMap.get('2c92c0fb6e3aa322016e3df698ff7e9f');
        acct00524 = updatedInvoiceMap.get('2c92c0fa6e3a9391016e3e30d48066d2');
        acct05268 = updatedInvoiceMap.get('2c92c0fb6e3aa321016e3df574337a9b');
        acct05956 = updatedInvoiceMap.get('2c92c0fa6e3a938d016e3dfdc93450b2');

        System.assertEquals('a1i0a000008yU78AAE', acct04202.bills[0].sFRecords[0].Id);

        System.assertEquals('a0p0a000008YSBuAAO', acct00524.bills[0].sFRecords[0].Id);

        System.assertEquals('a0p0a000008YSCuAAO', acct05268.bills[0].sFRecords[0].Id);

        List<ProductionDetailBillService.UsageRecord> usageList = acct05956.bills;
        System.assertEquals(8, usageList.size());
        for (ProductionDetailBillService.UsageRecord usage : usageList) {
            System.assertNotEquals(null, usage.sFRecords);
            if (usage.externalId == '2c92c0f96e3aa331016e3cc6717f2aaa') {
                System.assertEquals('a1i0a000008yUM7AAM', usage.sFRecords[0].Id);
            } else if (usage.externalId == '2c92c0f96e3aa331016e3cc671ac2aac') {
                System.assertEquals('a1i0a000008yTxMAAU', usage.sFRecords[0].Id);
            } else if (usage.externalId == '2c92c0f96e3aa331016e3cc672022aaf') {
                System.assertEquals('a1i0a000008yUNsAAM', usage.sFRecords[0].Id);
            }
        }
    }

    @IsTest
    public static void testDistributeAmongTransferPartsAllTogether() {
        ProductionToBillServiceTest.useMocks();
        ProductionDetailBillService service = new ProductionDetailBillService();

        Test.startTest();
        service.fromInvoicesGetUsage(getMockInvoiceItemIds(), getMockUsageDataQueryResult());
        service.fromUsageGetUASBsAndProductionAdjustments();
        service.distributeInvoiceItemAmongTransferProductionDetail();
        Test.stopTest();

        System.assertEquals(6, getMockInvoiceItemIds().size());

        /* 4 Customer Accounts, Across 2 Months:
            bw-00524: 2 Invoices, 1 Usage Row each, 1 transfer part each
            bw-04202: 2 Invoices, 1 Usage Row each, 3 transfer parts each
            bw-05268: 1 Invoice, 1 Usage Row, 1 transfer part
            bw-05956: 1 Invoice, 8 Usage Rows each, 2 transfer parts each
          1 bill type and 1 savings type each = 50 Expected Transfer Parts
        */

        List<Transfer_Part__c> parts = service.productionDetailToInsert;
        System.assertEquals(54, parts.size());

        Decimal billSum = 0;
        Integer billCount = 0;
        Decimal savingsSum = 0;
        for (Transfer_Part__c part : parts) {
            if (part.Type__c == 'Bill') {
                billSum += part.Amount__c;
                billCount += 1;
            }
            if (part.Type__c == 'Customer Savings') {
                savingsSum += part.Amount__c;
            }
        }
        System.assertEquals(27, billCount);
        System.assertEquals(2615.17, billSum);
        System.assertEquals(140, savingsSum);
    }

    @IsTest
    public static void testDistributeAmongTransferWithThreeParts() {
        ProductionToBillServiceTest.useMocks();
        ProductionDetailBillService service = new ProductionDetailBillService();
        ProductionToBillServiceTest.returnEntryNumber = 4;

        Test.startTest();
        // 1 Invoice with 1 Subscription on 1 Project, but bill is from a transfer with 3 parts:
        service.fromInvoicesGetUsage(new Set<String>{
            '2c92c0fb6e3aa322016e3df698ff7e9f'
        }, getMockUsageDataQueryResult());
        service.fromUsageGetUASBsAndProductionAdjustments();
        service.distributeInvoiceItemAmongTransferProductionDetail();
        Test.stopTest();

        Map<String, ProductionDetailBillService.GLInvoiceItem> invoiceMap = service.invoiceIdToUsageMap;
        ProductionDetailBillService.GLInvoiceItem acct04202 = invoiceMap.get('2c92c0fb6e3aa322016e3df698ff7e9f');
        System.assertEquals(37.23, acct04202.amount);
        System.assertEquals(37.23, acct04202.sumOfAmount);
        UASB__c uasb = (UASB__c) acct04202.bills[0].sFRecords[0];
        System.assertEquals(10, uasb.Savings__c);
        System.assertEquals('a900a000000GqNBAA0', uasb.Transfer__c);

        List<Transfer_Part__c> parts = service.productionDetailToInsert;
        System.assertEquals(6, parts.size());

        Decimal billSum = 0;
        Decimal savingsSum = 0;
        for (Transfer_Part__c part : parts) {
            System.assertEquals('a900a000000GqNBAA0', part.Transfer__c);
            if (part.Type__c == 'Bill') {
                billSum += part.Amount__c;
            }
            if (part.Type__c == 'Customer Savings') {
                savingsSum += part.Amount__c;
            }
        }
        System.assertEquals(37.23, billSum);
        // SavingsSum is NOT 9.99: In cases of rounding cutoff, put remainder (~0.01 or so on last transfer part)
        // so that the sum of applications always equals the full Invoice Amount
        System.assertEquals(10, savingsSum);
    }

    @IsTest
    public static void testDistributeAmongTransferWithTwoParts() {
        ProductionToBillServiceTest.useMocks();
        ProductionDetailBillService service = new ProductionDetailBillService();
        ProductionToBillServiceTest.returnEntryNumber = 3;

        Test.startTest();
        // 1 Invoice with 8 Subscriptions on 1 Project, but bill is from a transfer with 2 parts:
        service.fromInvoicesGetUsage(new Set<String>{
            '2c92c0fa6e3a938d016e3dfdc93450b2'
        }, getMockUsageDataQueryResult());
        service.fromUsageGetUASBsAndProductionAdjustments();
        service.distributeInvoiceItemAmongTransferProductionDetail();
        Test.stopTest();

        Map<String, ProductionDetailBillService.GLInvoiceItem> invoiceMap = service.invoiceIdToUsageMap;
        ProductionDetailBillService.GLInvoiceItem acct05956 = invoiceMap.get('2c92c0fa6e3a938d016e3dfdc93450b2');
        System.assertEquals(1997.03, acct05956.amount);
        System.assertEquals(1997.03, acct05956.sumOfAmount);
        System.assertEquals(8, acct05956.bills.size());
        UASB__c uasbOne = (UASB__c) acct05956.bills[0].sFRecords[0];
        UASB__c uasbSeven = (UASB__c) acct05956.bills[0].sFRecords[0];

        System.assertEquals('a900a000000GrNBAA0', uasbOne.Transfer__c);
        System.assertEquals('a900a000000GrNBAA0', uasbSeven.Transfer__c);

        // 8 bills * 2 transfers, 1 for bill, 1 for savings:
        List<Transfer_Part__c> parts = service.productionDetailToInsert;
        System.assertEquals(32, parts.size());

        Decimal billSum = 0;
        Decimal savingsSum = 0;
        for (Transfer_Part__c part : parts) {
            System.assertEquals('a900a000000GrNBAA0', part.Transfer__c);
            if (part.Type__c == 'Bill') {
                billSum += part.Amount__c;
            }
            if (part.Type__c == 'Customer Savings') {
                savingsSum += part.Amount__c;
            }
        }
        System.assertEquals(1997.03, billSum);
        System.assertEquals(80, savingsSum);
    }

    @IsTest
    public static void testDistributeAmongTransferWithMultipleUASBs() {
        ProductionToBillServiceTest.useMocks();
        ProductionDetailBillService service = new ProductionDetailBillService();
        ProductionToBillServiceTest.returnEntryNumber = 0;

        Test.startTest();
        // 1 Invoice with 8 Subscriptions on 1 Project, but bill is from a transfer with 2 parts:
        service.fromInvoicesGetUsage(new Set<String>{
            '2c92c0fa6e3a9391016e3df87b1f687a'
        }, getMockUsageDataQueryResult());
        service.fromUsageGetUASBsAndProductionAdjustments();
        service.distributeInvoiceItemAmongTransferProductionDetail();
        Test.stopTest();

        Map<String, ProductionDetailBillService.GLInvoiceItem> invoiceMap = service.invoiceIdToUsageMap;
        ProductionDetailBillService.GLInvoiceItem acct000524 = invoiceMap.get('2c92c0fa6e3a9391016e3df87b1f687a');

        System.assertEquals(252.73, acct000524.amount);
        System.assertEquals(252.73, acct000524.sumOfAmount);
        System.assertEquals(1, acct000524.bills.size());
        System.assertEquals(2, acct000524.bills[0].sFRecords.size());

        // 2 bills, one has 1 transfer parts, other has 2. 1 for bill, 1 for savings:
        List<Transfer_Part__c> parts = service.productionDetailToInsert;
        System.assertEquals(6, parts.size());

        Decimal billSum = 0;
        Decimal savingsSum = 0;
        for (Transfer_Part__c part : parts) {
            if (part.Type__c == 'Bill') {
                billSum += part.Amount__c;
            }
            if (part.Type__c == 'Customer Savings') {
                savingsSum += part.Amount__c;
            }
        }
        System.assertEquals(252.73, billSum);
        System.assertEquals(20, savingsSum);
    }

    @IsTest
    public static void testCreateProductionDetailFromInvoiceItems() {
        List<Journal_Entry__c> entries = ProductionToBillServiceTest.getInvoiceItemJournalEntries();

        List<Zuora_Data_Query__c> beforeQueries = [
            SELECT Id
            FROM Zuora_Data_Query__c
        ];
        System.assertEquals(0, beforeQueries.size());

        Test.startTest();
        ProductionDetailBillService service = new ProductionDetailBillService();
        service.createProductionDetailFromInvoiceItems(entries, 10);
        Test.stopTest();

        List<Zuora_Data_Query__c> afterQueries = [
            SELECT Id
            FROM Zuora_Data_Query__c
        ];
        System.assert(afterQueries.size() > 0);
    }

    @IsTest
    public static void testUnservicedUASBs() {
        ProductionToBillServiceTest.useMocks();
        List<UASB__c> externalUASBs = ProductionToBillServiceTest.getExternallyServicedUASBs();

        Test.startTest();
        ProductionDetailBillService service = new ProductionDetailBillService();
        service.calculateProductionDetailFromUnservicedUASB(externalUASBs);
        Test.stopTest();

        List<Transfer_Part__c> unservicedParts = service.productionDetailToInsert;
        System.assertEquals(7, unservicedParts.size());

        Decimal uasbOneSum = 0;
        Decimal uasbTwoSum = 0;
        Decimal uasbThreeSum = 0;

        for (Transfer_Part__c part : unservicedParts) {
            System.assertEquals('Externally Serviced', part.Type__c);
            if (part.Externally_Serviced_UASB__c == 'a1i0a000009PwUaAAK') {
                uasbOneSum += part.Amount__c;
            } else if (part.Externally_Serviced_UASB__c == 'a1i0a000009PwUbAAK') {
                uasbTwoSum += part.Amount__c;
            } else {
                uasbThreeSum += part.Amount__c;
            }
        }

        System.assertEquals(133.34, uasbOneSum);
        System.assertEquals(80, uasbTwoSum);
        System.assertEquals(30.34, uasbThreeSum);
    }

    @IsTest
    public static void testUnservicedAdjusts() {
        ProductionToBillServiceTest.useMocks();
        List<Bill_Adjustment__c> externalAdjusts = ProductionToBillServiceTest.getExternallyServicedAdjustments();

        Test.startTest();
        ProductionDetailBillService service = new ProductionDetailBillService();
        service.calculateProductionDetailFromUnservicedAdjustment(externalAdjusts);
        Test.stopTest();

        List<Transfer_Part__c> unservicedParts = service.productionDetailToInsert;
        System.assertEquals(7, unservicedParts.size());

        Decimal uasbOneSum = 0;
        Decimal uasbTwoSum = 0;
        Decimal uasbThreeSum = 0;

        for (Transfer_Part__c part : unservicedParts) {
            System.assertEquals('Externally Serviced', part.Type__c);
            if (part.Externally_Serviced_Bill_Adjustment__c == 'a0p3K000000LKaMQAA') {
                uasbOneSum += part.Amount__c;
            } else if (part.Externally_Serviced_Bill_Adjustment__c == 'a0p3K000001LKaMQAB') {
                uasbTwoSum += part.Amount__c;
            } else {
                uasbThreeSum += part.Amount__c;
            }
        }

        System.assertEquals(133.34, uasbOneSum);
        System.assertEquals(80, uasbTwoSum);
        System.assertEquals(30.34, uasbThreeSum);
    }

    @IsTest
    public static void testBillAmounts() {
        sfab_FabricatedSObject fabbedTransfer = getMockTransfer(11130);
        Transfer_Part__c tp1 = getmockTransferPart(fabbedTransfer, 10000, 5324);
        Transfer_Part__c tp2 = getmockTransferPart(fabbedTransfer, 12000, 4211);
        Transfer_Part__c tp3 = getmockTransferPart(fabbedTransfer, 187, 1595);
        List<Transfer_Part__c> transferParts = new List<Transfer_Part__c>{tp1, tp2, tp3};

        Map<Id, List<Transfer_Part__c>> mapParts = new Map<Id, List<Transfer_Part__c>>();
        Id transferId = Util.getFakeId(Transfer__c.SObjectType);
        mapParts.put(transferId, transferParts);

        ProductionDetailBillService service = new ProductionDetailBillService();
        service.transferToDetailMap = mapParts;
        Decimal billAmount = -221.87;
        service.createBillProductionDetail(transferId, billAmount, 'Bill', Util.getFakeId(Journal_Entry__c.SObjectType));

        List<Transfer_Part__c> partsToInsertList = service.productionDetailToInsert;
        System.assertEquals(3, partsToInsertList.size());
        System.assertEquals(
            partsToInsertList[0].Amount__c,
            Util.roundValue(billAmount * (tp1.Amount__c/tp1.Transfer__r.Transfer_Amount__c), 2, 'HALF_UP'),
            'P2BService should insert a PD with an amount based the dollar values of the Transfer and Transfer Parts, not' +
                ' the kWh values, since credit rates may change monthly'
        );
    }

    private static sfab_FabricatedSObject getMockTransfer(Decimal transferAmount) {
        sfab_FabricatedSObject fabbedTransfer = new sfab_FabricatedSObject(Transfer__c.class);
        fabbedTransfer.setField(Transfer__c.Billing_Method__c, 'kWh');
        fabbedTransfer.setField(Transfer__c.Transfer_kWh__c, 22187);
        fabbedTransfer.setField(Transfer__c.Transfer_Amount__c, transferAmount);
        return fabbedTransfer;
    }

    private static Transfer_Part__c getmockTransferPart(sfab_FabricatedSObject fabbedTransfer, Decimal kWhAmount, Decimal amount) {
        sfab_FabricatedSObject fabbedTransferPart = new sfab_FabricatedSObject(Transfer_Part__c.class);
        fabbedTransferPart.setField(Transfer_Part__c.kWh_Amount__c, kWhAmount);
        fabbedTransferPart.setField(Transfer_Part__c.Amount__c, amount);
        fabbedTransferPart.setParent('Transfer__r', fabbedTransfer);
        return (Transfer_Part__c) fabbedTransferPart.toSObject();
    }

    private static Set<String> getMockInvoiceItemIds() {
        return new Set<String>{
            '2c92c0fa6e3a938d016e3e2ed1f832aa', '2c92c0fb6e3aa322016e3df698ff7e9f', '2c92c0fa6e3a9391016e3e30d48066d2',
            '2c92c0fa6e3a9391016e3df87b1f687a', '2c92c0fa6e3a938d016e3dfdc93450b2',
            '2c92c0fb6e3aa321016e3df574337a9b'
        };
    }

    private static String getMockUsageDataQueryResult() {
        String dataAsString = '{"Project":"SSS-000024","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebdd3b4906","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yU9rAAE","CustomerNumber":"bw-05268","Amount":229.320000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc6715f2aa8","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yUOIAA2","CustomerNumber":"bw-05956","Amount":312.340000000}' +
            '{"Project":"SSS-000017","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebdd834908","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yU9pAAE","CustomerNumber":"bw-05268","Amount":185.730000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc6717f2aaa","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yUM7AAM","CustomerNumber":"bw-05956","Amount":161.840000000}' +
            '{"Project":"SSS-000021","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebde86491f","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yU9kAAE","CustomerNumber":"bw-05268","Amount":184.040000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc671962aab","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yULrAAM","CustomerNumber":"bw-05956","Amount":48.540000000}' +
            '{"Project":"SSS-000018","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebddc9490a","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yU9nAAE","CustomerNumber":"bw-05268","Amount":199.460000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc671ac2aac","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yTxMAAU","CustomerNumber":"bw-05956","Amount":100.340000000}' +
            '{"Project":"SSS-000016","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebde1e4915","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yU9lAAE","CustomerNumber":"bw-05268","Amount":190.220000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc671c62aad","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yUOdAAM","CustomerNumber":"bw-05956","Amount":469.320000000}' +
            '{"Project":"SSS-000002","Client":"BW-0009470","ExternalId":"2c92c0f96e3aa331016e3cd782c2640d","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yU78AAE","CustomerNumber":"bw-04202","Amount":37.230000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc671e62aae","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yUO6AAM","CustomerNumber":"bw-05956","Amount":184.490000000}' +
            '{"Project":"SSS-000020","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebdd104905","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yU9jAAE","CustomerNumber":"bw-05268","Amount":187.180000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc672022aaf","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yUNsAAM","CustomerNumber":"bw-05956","Amount":212.000000000}' +
            '{"Project":"SSS-000019","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebddf9490c","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yU9mAAE","CustomerNumber":"bw-05268","Amount":242.880000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc672212ab0","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yUNnAAM","CustomerNumber":"bw-05956","Amount":508.160000000}' +
            '{"Project":"SSS-000023","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebdd5c4907","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yU9qAAE","CustomerNumber":"bw-05268","Amount":255.550000000}' +
            '{"Project":"SSS-000022","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebdda44909","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a0p0a000008YSCuAAO","CustomerNumber":"bw-05268","Amount":255.630000000}' +
            '{"Project":"SSS-000001","Client":"BW-0009470","ExternalId":"2c92c0f96e3aa333016e3cf0482a601d","BillDatetime":"2019-05-01T00:00:00-04:00","InternalId":"a1i0a000008yUBfAAM","CustomerNumber":"bw-00524","Amount":252.730000000}' +
            '{"Project":"SSS-000022","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebdfb6492b","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yiTAAAY","CustomerNumber":"bw-05268","Amount":401.740000000}' +
            '{"Project":"SSS-000023","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebdeee4922","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yiTEAAY","CustomerNumber":"bw-05268","Amount":404.260000000}' +
            '{"Project":"SSS-000021","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebdfdc492c","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yiStAAI","CustomerNumber":"bw-05268","Amount":291.110000000}' +
            '{"Project":"SSS-000019","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebe003492d","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yiSrAAI","CustomerNumber":"bw-05268","Amount":377.800000000}' +
            '{"Project":"SSS-000002","Client":"BW-0009470","ExternalId":"2c92c0f96e3aa331016e3cd782e3640e","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yiQYAAY","CustomerNumber":"bw-04202","Amount":62.550000000}' +
            '{"Project":"SSS-000001","Client":"BW-0009470","ExternalId":"2c92c0f96e3aa333016e3cf0484b601f","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a0p0a000008YSBuAAO","CustomerNumber":"bw-00524","Amount":135.060000000}' +
            '{"Project":"SSS-000016","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebdeac4920","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yiSqAAI","CustomerNumber":"bw-05268","Amount":308.130000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc6723a2ab1","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yigvAAA","CustomerNumber":"bw-05956","Amount":288.710000000}' +
            '{"Project":"SSS-000024","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebdf2d4924","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yiTDAAY","CustomerNumber":"bw-05268","Amount":372.480000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc672512ab5","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yiGrAAI","CustomerNumber":"bw-05956","Amount":136.640000000}' +
            '{"Project":"SSS-000017","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebdf5b4927","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yiTCAAY","CustomerNumber":"bw-05268","Amount":301.390000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc672702ab6","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yihFAAQ","CustomerNumber":"bw-05956","Amount":425.360000000}' +
            '{"Project":"SSS-000018","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebdf884928","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yiTBAAY","CustomerNumber":"bw-05268","Amount":292.650000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc672892ab7","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yih1AAA","CustomerNumber":"bw-05956","Amount":251.250000000}' +
            '{"Project":"SSS-000020","Client":"BW-0009470","ExternalId":"2c92c0f86e3a939f016e3cebe026492e","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yiSsAAI","CustomerNumber":"bw-05268","Amount":287.520000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc672a12ab9","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yigsAAA","CustomerNumber":"bw-05956","Amount":692.040000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc672b92abb","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yifVAAQ","CustomerNumber":"bw-05956","Amount":220.390000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc672d12abc","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yifJAAQ","CustomerNumber":"bw-05956","Amount":66.120000000}' +
            '{"Project":"SSS-000045","Client":"BW-0009186","ExternalId":"2c92c0f96e3aa331016e3cc672ee2abd","BillDatetime":"2019-06-01T00:00:00-04:00","InternalId":"a1i0a000008yihjAAA","CustomerNumber":"bw-05956","Amount":639.150000000}';

        dataAsString = dataAsString.replace('}', '},');
        dataAsString = dataAsString.removeEnd(',');
        dataAsString = '[' + dataAsString + ']';
        dataAsString = dataAsString.replace('__c', '_Zcustom');
        return dataAsString;
    }
}