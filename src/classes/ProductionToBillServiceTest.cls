@IsTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ProductionToBillServiceTest {
    @isTest
    public static void testScheduleJob(){
        useMocks();
        List<Error_Log__c> beforeLogs = [
            SELECT Class__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ProductionToBillService'
        ];
        System.assertEquals(0,beforeLogs.size());

        Test.startTest();
            ProductionToBillScheduler prodService = new ProductionToBillScheduler();
            Datetime dt = Datetime.now().addMinutes(2);
            String cronExpress = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
            System.schedule('P2B',cronExpress,prodService);
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Class__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ProductionToBillService'
        ];
        System.assert(afterLogs.size() > 0);
    }

    @isTest
    public static void testQueueBillJob(){
        useMocks();
        List<Error_Log__c> beforeLogs = [
            SELECT Class__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ProductionToBillService'
            AND Method__c = 'executeBillJob'
        ];
        System.assertEquals(0,beforeLogs.size());

        Test.startTest();
        ProductionToBillService prodService = new ProductionToBillService();
        prodService.queueJob(ProductionToBillService.OperationType.BILL);
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ProductionToBillService'
            AND Method__c = 'executeBillJob'
        ];
        System.assert(afterLogs.size() > 0);
    }

    @isTest
    public static void testQueueCollectionsJob(){
        useMocks();
        List<Error_Log__c> beforeLogs = [
            SELECT Class__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ProductionToBillService'
            AND Method__c = 'executeCollectionsJob'
        ];
        System.assertEquals(0,beforeLogs.size());

        Test.startTest();
            ProductionToBillService prodService = new ProductionToBillService();
            prodService.queueJob(ProductionToBillService.OperationType.COLLECTION);
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Class__c, Message__c, Method__c
            FROM Error_Log__c
            WHERE Class__c = 'ProductionToBillService'
            AND Method__c = 'executeCollectionsJob'
        ];
        System.assert(afterLogs.size() > 0);
    }

    @IsTest
    public static void testFromInvoicesGetUsage(){
        /* 4 Customer Accounts, Across 2 Months:
            bw-00524: 1 Subscription to 1 project
            bw-04202: 1 Subscription to 1 project
            bw-05268: 9 Subscriptions to different projects.
            bw-05956: 8 Subscriptions on same project.
        */
        useMocks();

        Test.startTest();
            ProductionToBillService service = new ProductionToBillService();
            service.fromInvoicesGetUsage(getMockInvoiceItemIds(),getMockUsageDataQueryResult());
        Test.stopTest();

        Map<String, ProductionToBillService.GLInvoiceItem> invoiceMap = service.invoiceIdToUsageMap;
        ProductionToBillService.GLInvoiceItem acct04202 = invoiceMap.get('2c92c0fb6e3aa322016e3df698ff7e9f');
        ProductionToBillService.GLInvoiceItem acct00524 = invoiceMap.get('2c92c0fa6e3a9391016e3e30d48066d2');
        ProductionToBillService.GLInvoiceItem acct05268 = invoiceMap.get('2c92c0fb6e3aa321016e3df574337a9b');
        ProductionToBillService.GLInvoiceItem acct05956 = invoiceMap.get('2c92c0fa6e3a938d016e3dfdc93450b2');

        System.assertEquals(1,acct04202.Bills.size());
        System.assertEquals(1,acct00524.Bills.size());
        // Even though there are 9 subscriptions for bw-05268, they are all on different projects and therefore
        // only 1 usage line for a given invoiceItems
        System.assertEquals(1,acct05268.Bills.size());
        // Alternatively, for bw-05956 all 8 subscriptions are on 1 project (all usage under same invoice)
        System.assertEquals(8,acct05956.Bills.size());

        System.assertEquals(acct04202.SumOfAmount,acct04202.Amount);
        System.assertEquals(acct00524.SumOfAmount,acct00524.Amount);
        System.assertEquals(acct05268.SumOfAmount,acct05268.Amount);
        System.assertEquals(acct05956.SumOfAmount,acct05956.Amount);

        System.assertEquals(37.23,acct04202.SumOfAmount);
        System.assertEquals(135.06,acct00524.SumOfAmount);
        System.assertEquals(255.63,acct05268.SumOfAmount);
        System.assertEquals(1997.03,acct05956.SumOfAmount);

        System.assertEquals('2c92c0f96e3aa331016e3cd782c2640d',acct04202.Bills[0].ExternalId);
        System.assertEquals('2c92c0f96e3aa333016e3cf0484b601f',acct00524.Bills[0].ExternalId);
        System.assertEquals('2c92c0f86e3a939f016e3cebdda44909',acct05268.Bills[0].ExternalId);
    }

    @IsTest
    public static void testFromUsageGetUASBsandAdjust(){
        useMocks();
        ProductionToBillService service = new ProductionToBillService();
        service.fromInvoicesGetUsage(getMockInvoiceItemIds(),getMockUsageDataQueryResult());
        Map<String, ProductionToBillService.GLInvoiceItem> oldInvoiceMap = service.invoiceIdToUsageMap;

        ProductionToBillService.GLInvoiceItem acct04202 = oldInvoiceMap.get('2c92c0fb6e3aa322016e3df698ff7e9f');
        ProductionToBillService.GLInvoiceItem acct00524 = oldInvoiceMap.get('2c92c0fa6e3a9391016e3e30d48066d2');
        ProductionToBillService.GLInvoiceItem acct05268 = oldInvoiceMap.get('2c92c0fb6e3aa321016e3df574337a9b');
        ProductionToBillService.GLInvoiceItem acct05956 = oldInvoiceMap.get('2c92c0fa6e3a938d016e3dfdc93450b2');

        System.assertEquals(null,acct04202.Bills[0].UASB);
        System.assertEquals(null,acct00524.Bills[0].UASB);
        System.assertEquals(null,acct05268.Bills[0].UASB);
        System.assertEquals(null,acct05956.Bills[0].UASB);

        Test.startTest();
            service.fromUsageGetUASBsAndProductionAdjustments();
        Test.stopTest();

        Map<String, ProductionToBillService.GLInvoiceItem> updatedInvoiceMap = service.invoiceIdToUsageMap;
        acct04202 = updatedInvoiceMap.get('2c92c0fb6e3aa322016e3df698ff7e9f');
        acct00524 = updatedInvoiceMap.get('2c92c0fa6e3a9391016e3e30d48066d2');
        acct05268 = updatedInvoiceMap.get('2c92c0fb6e3aa321016e3df574337a9b');
        acct05956 = updatedInvoiceMap.get('2c92c0fa6e3a938d016e3dfdc93450b2');

        System.assertEquals('a1i0a000008yU78AAE',acct04202.Bills[0].UASB.Id);
        System.assertEquals(null,acct04202.Bills[0].Adjustment);

        System.assertEquals(null,acct00524.Bills[0].UASB);
        System.assertEquals('a0p0a000008YSBuAAO',acct00524.Bills[0].Adjustment.Id);

        System.assertEquals(null,acct05268.Bills[0].UASB);
        System.assertEquals('a0p0a000008YSCuAAO',acct05268.Bills[0].Adjustment.Id);

        List<ProductionToBillService.UsageRecord> usageList = acct05956.Bills;
        System.assertEquals(8,usageList.size());
        for (ProductionToBillService.UsageRecord usage : usageList){
            System.assertNotEquals(null,usage.UASB);
            if (usage.ExternalId == '2c92c0f96e3aa331016e3cc6717f2aaa'){
                System.assertEquals('a1i0a000008yUM7AAM',usage.UASB.Id);
            } else if (usage.ExternalId == '2c92c0f96e3aa331016e3cc671ac2aac'){
                System.assertEquals('a1i0a000008yTxMAAU',usage.UASB.Id);
            } else if (usage.ExternalId == '2c92c0f96e3aa331016e3cc672022aaf'){
                System.assertEquals('a1i0a000008yUNsAAM',usage.UASB.Id);
            }
        }
    }

    @IsTest
    public static void testDistributeAmongTransferPartsAllTogether(){
        useMocks();
        ProductionToBillService service = new ProductionToBillService();

        Test.startTest();
            service.fromInvoicesGetUsage(getMockInvoiceItemIds(),getMockUsageDataQueryResult());
            service.fromUsageGetUASBsAndProductionAdjustments();
            service.distributeInvoiceItemAmongTransferParts();
        Test.stopTest();

        System.assertEquals(6,getMockInvoiceItemIds().size());

        /* 4 Customer Accounts, Across 2 Months:
            bw-00524: 2 Invoices, 1 Usage Row each, 1 transfer part each
            bw-04202: 2 Invoices, 1 Usage Row each, 3 transfer parts each
            bw-05268: 1 Invoice, 1 Usage Row, 1 transfer part
            bw-05956: 1 Invoice, 8 Usage Rows each, 2 transfer parts each
          1 bill type and 1 savings type each = 50 Expected Transfer Parts
        */

        List<Transfer_Part__c> parts = service.partsToInsert;
        System.assertEquals(50,parts.size());

        Decimal billSum = 0;
        Integer billCount = 0;
        Decimal savingsSum = 0;
        for (Transfer_Part__c part : parts){
            if (part.Type__c == 'Bill'){
                billSum += part.Amount__c;
                billCount += 1;
            }
            if (part.Type__c == 'Customer Savings'){
                savingsSum += part.Amount__c;
            }
        }
        System.assertEquals(25,billCount);
        System.assertEquals(2740.23,billSum);
        System.assertEquals(130,savingsSum);
    }

    @IsTest
    public static void testDistributeAmongTransferWithThreeParts(){
        useMocks();
        ProductionToBillService service = new ProductionToBillService();
        returnEntryNumber = 4;

        Test.startTest();
            // 1 Invoice with 1 Subscription on 1 Project, but bill is from a transfer with 3 parts:
            service.fromInvoicesGetUsage(new Set<String>{'2c92c0fb6e3aa322016e3df698ff7e9f'},getMockUsageDataQueryResult());
            service.fromUsageGetUASBsAndProductionAdjustments();
            service.distributeInvoiceItemAmongTransferParts();
        Test.stopTest();

        Map<String, ProductionToBillService.GLInvoiceItem> invoiceMap = service.invoiceIdToUsageMap;
        ProductionToBillService.GLInvoiceItem acct04202 = invoiceMap.get('2c92c0fb6e3aa322016e3df698ff7e9f');
        System.assertEquals(37.23,acct04202.Amount);
        System.assertEquals(37.23,acct04202.SumOfAmount);
        System.assertEquals(10,acct04202.Bills[0].UASB.Savings__c);
        System.assertEquals('a900a000000GqNBAA0',acct04202.Bills[0].UASB.Transfer__c);

        List<Transfer_Part__c> parts = service.partsToInsert;
        System.assertEquals(6,parts.size());

        Decimal billSum = 0;
        Decimal savingsSum = 0;
        for (Transfer_Part__c part : parts){
            System.assertEquals('a900a000000GqNBAA0',part.Transfer__c);
            if (part.Type__c == 'Bill'){
                billSum += part.Amount__c;
            }
            if (part.Type__c == 'Customer Savings'){
                savingsSum += part.Amount__c;
            }
        }
        System.assertEquals(37.23,billSum);
        // SavingsSum is NOT 9.99: In cases of rounding cutoff, put remainder (~0.01 or so on last transfer part)
        // so that the sum of applications always equals the full Invoice Amount
        System.assertEquals(10,savingsSum);
    }

    @IsTest
    public static void testDistributeAmongTransferWithTwoParts(){
        useMocks();
        ProductionToBillService service = new ProductionToBillService();
        returnEntryNumber = 3;

        Test.startTest();
        // 1 Invoice with 8 Subscriptions on 1 Project, but bill is from a transfer with 2 parts:
        service.fromInvoicesGetUsage(new Set<String>{'2c92c0fa6e3a938d016e3dfdc93450b2'},getMockUsageDataQueryResult());
        service.fromUsageGetUASBsAndProductionAdjustments();
        service.distributeInvoiceItemAmongTransferParts();
        Test.stopTest();

        Map<String, ProductionToBillService.GLInvoiceItem> invoiceMap = service.invoiceIdToUsageMap;
        ProductionToBillService.GLInvoiceItem acct05956 = invoiceMap.get('2c92c0fa6e3a938d016e3dfdc93450b2');
        System.assertEquals(1997.03,acct05956.Amount);
        System.assertEquals(1997.03,acct05956.SumOfAmount);
        System.assertEquals(8,acct05956.Bills.size());
        System.assertEquals('a900a000000GrNBAA0',acct05956.Bills[0].UASB.Transfer__c);
        System.assertEquals('a900a000000GrNBAA0',acct05956.Bills[7].UASB.Transfer__c);

        // 8 bills * 2 transfers, 1 for bill, 1 for savings:
        List<Transfer_Part__c> parts = service.partsToInsert;
        System.assertEquals(32,parts.size());

        Decimal billSum = 0;
        Decimal savingsSum = 0;
        for (Transfer_Part__c part : parts){
            System.assertEquals('a900a000000GrNBAA0',part.Transfer__c);
            if (part.Type__c == 'Bill'){
                billSum += part.Amount__c;
            }
            if (part.Type__c == 'Customer Savings'){
                savingsSum += part.Amount__c;
            }
        }
        System.assertEquals(1997.03,billSum);
        System.assertEquals(80,savingsSum);
    }

    @IsTest
    public static void testCreateProductionDetailFromCollectionItem(){
        useMocks();
        List<Transfer_Part__c> beforeBillParts = [
            SELECT Id
            FROM Transfer_Part__c
            WHERE Type__c = 'Payment'
        ];

        System.assertEquals(0,beforeBillParts.size());

        List<Journal_Entry__c> collectionEntries = getCollectionJournalEntries();
        ProductionToBillService service = new ProductionToBillService();
        service.createProductionDetailFromCollectionItem(collectionEntries);

        List<Transfer_Part__c> paymentParts = service.partsToInsert;

        System.assertEquals(8,paymentParts.size());

        for (Transfer_Part__c part : paymentParts){
            switch on String.valueOf(part.Bill_Part__c) {
                when 'a8y0a000000Gu3rAAA' {
                    // Balance is zero, no part should be made:
                    System.assert(false);
                }
                when 'a8y0a000000Gu3rBBB' {
                    System.assertEquals(120,part.Amount__c);
                }
                when 'a8y0a000000Gu3rCCC' {
                    System.assertEquals(1.87,part.Amount__c);
                }
                when 'a8y0a000000Gu3rDDD' {
                    System.assertEquals(29,part.Amount__c);
                }
                when 'a8y0a000000Gu3rEEE' {
                    if (part.Journal_Entry__c == 'a920a000000HuJoAAC'){
                        System.assertEquals(30.61,part.Amount__c);
                    } else {
                        System.assertEquals(2.72,part.Amount__c);
                    }
                }
                when 'a8y0a000000Gu3rFFF' {
                    System.assertEquals(29.39,part.Amount__c);
                }
                when 'a8y0a000000Gu3rGGG' {
                    if (part.Journal_Entry__c == 'a920a000000HuJoAAD'){
                        System.assertEquals(37.23,part.Amount__c);
                    } else {
                        System.assertEquals(62.55,part.Amount__c);
                    }
                }
                when else {
                    System.assert(false);
                }
            }
        }

    }

    @IsTest
    public static void testCreateProductionDetailFromInvoiceItems(){
        List<Journal_Entry__c> entries = getInvoiceItemJournalEntries();

        List<Zuora_Data_Query__c> beforeQueries = [
            SELECT Id FROM Zuora_Data_Query__c
        ];
        System.assertEquals(0,beforeQueries.size());

        Test.startTest();
            ProductionToBillService service = new ProductionToBillService();
            service.createProductionDetailFromInvoiceItems(entries);
        Test.stopTest();

        List<Zuora_Data_Query__c> afterQueries = [
            SELECT Id FROM Zuora_Data_Query__c
        ];
        System.assert(afterQueries.size() > 0);
    }


    /* ********* MOCKS ************ */

    private static Integer returnEntryNumber;

    private static void useMocks() {
        ProductionToBillService.glSelector = (JournalEntrySelector) Test.createStub(JournalEntrySelector.class, new MockGLSelector());
        ProductionToBillService.transferPartsSelector = (ProductionDetailSelector) Test.createStub(ProductionDetailSelector.class, new MockProductionDetailSelector());
        ProductionToBillService.uasbSelector = (UASBSelector) Test.createStub(UASBSelector.class, new MockUASBSelector());
        ProductionToBillService.adjustmentSelector = (AdjustmentSelector) Test.createStub(AdjustmentSelector.class, new MockAdjustmentSelector());
    }

    public class MockGLSelector extends MockProvider {
        public MockGLSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            List<Journal_Entry__c> entries = getInvoiceItemJournalEntries();
            switch on methodCall.stubbedMethodName {
                when 'getSFJournalEntriesFromExternalId' {
                    if (returnEntryNumber != null){
                        return new List<Journal_Entry__c>{entries[returnEntryNumber]};
                    } else {
                        return entries;
                    }
                }
                when 'getEntriesWithoutProductionDetail' {
                    return entries;
                }
            }
            return null;
        }
    }

    public class MockProductionDetailSelector extends MockProvider {
        public MockProductionDetailSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            Map<Id, List<Transfer_Part__c>> partToTransferMap = new Map<Id, List<Transfer_Part__c>>();
            Production__c projectAProd = new Production__c(
                Id = 'a8u8A0000000DFlQAM',
                Name = 'Production A'
            );
            Production__c projectBProd = new Production__c(
                Id = 'a8u8A0000000EFlQAM',
                Name = 'Production B'
            );
            Production__c projectCProd = new Production__c(
                Id = 'a8u8A0000000FFlQAM',
                Name = 'Production C'
            );
            Transfer__c projectA = new Transfer__c(
                Id = 'a900a000000GpNBAA0',
                Transfer_Amount__c = 1000
            );
            Transfer__c projectB = new Transfer__c(
                Id = 'a900a000000GqNBAA0',
                Transfer_Amount__c = 1000
            );
            Transfer__c projectC = new Transfer__c(
                Id = 'a900a000000GrNBAA0',
                Transfer_Amount__c = 2000
            );
            Transfer_Part__c projectAOne = new Transfer_Part__c(
                Id = 'a8y0a000000GqxxAAC',
                Transfer__c = projectA.Id,
                Transfer__r = projectA,
                Production__c = projectAProd.Id,
                Production__r = projectAProd,
                Amount__c = 1000
            );
            Transfer_Part__c projectBOne = new Transfer_Part__c(
                Id = 'a8y0a000000GqxxABC',
                Transfer__c = projectB.Id,
                Transfer__r = projectB,
                Production__c = projectBProd.Id,
                Production__r = projectBProd,
                Amount__c = 333.33
            );
            Transfer_Part__c projectBTwo = new Transfer_Part__c(
                Id = 'a8y0a000000GqxxACC',
                Transfer__c = projectB.Id,
                Transfer__r = projectB,
                Production__c = projectBProd.Id,
                Production__r = projectBProd,
                Amount__c = 333.33
            );
            Transfer_Part__c projectBThree = new Transfer_Part__c(
                Id = 'a8y0a000000GqxxADC',
                Transfer__c = projectB.Id,
                Transfer__r = projectB,
                Production__c = projectBProd.Id,
                Production__r = projectBProd,
                Amount__c = 333.34
            );
            Transfer_Part__c projectCOne = new Transfer_Part__c(
                Id = 'a8y0a000000GqxxAEC',
                Transfer__c = projectC.Id,
                Transfer__r = projectC,
                Production__c = projectCProd.Id,
                Production__r = projectCProd,
                Amount__c = 1999.93
            );
            Transfer_Part__c projectCTwo = new Transfer_Part__c(
                Id = 'a8y0a000000GqxxAFC',
                Transfer__c = projectC.Id,
                Transfer__r = projectC,
                Production__c = projectCProd.Id,
                Production__r = projectCProd,
                Amount__c = 0.07
            );
            partToTransferMap.put(projectA.Id, new List<Transfer_Part__c>{projectAOne});
            partToTransferMap.put(projectB.Id, new List<Transfer_Part__c>{projectBOne, projectBTwo, projectBThree});
            partToTransferMap.put(projectC.Id, new List<Transfer_Part__c>{projectCOne, projectCTwo});
            switch on methodCall.stubbedMethodName {
                when 'getTransferPartMap' {
                    return partToTransferMap;
                }
                when 'getInvoicePartMap' {
                    return getBillPartByInvoice();
                }
                when 'getPaymentSum' {
                    return getPaymentsMap();
                }
            }
            return null;
        }
    }

    public class MockUASBSelector extends MockProvider {
      MockUASBSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String uasbMapAsString = '{' +
                '"a1i0a000008yUBfAAM":{"Id":"a1i0a000008yUBfAAM", "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a1i0a000008yiV4AAI":{"Id":"a1i0a000008yiV4AAI", "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a1i0a000008yU78AAE":{"Id":"a1i0a000008yU78AAE", "Savings__c":10,"Transfer__c":"a900a000000GqNBAA0"},' +
                '"a1i0b000008yiQYAAY":{"Id":"a1i0b000008yiQYAAY", "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a1i0a000008yiQYAAY":{"Id":"a1i0a000008yiQYAAY", "Savings__c":10,"Transfer__c":"a900a000000GqNBAA0"},' +
                '"a1i0b000008yiV4AAI":{"Id":"a1i0b000008yiV4AAI", "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a1i0a000008yigvAAA":{"Id":"a1i0a000008yigvAAA", "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a1i0a000008yiGrAAI":{"Id":"a1i0a000008yiGrAAI", "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a1i0a000008yihFAAQ":{"Id":"a1i0a000008yihFAAQ", "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a1i0a000008yih1AAA":{"Id":"a1i0a000008yih1AAA", "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a1i0a000008yigsAAA":{"Id":"a1i0a000008yigsAAA", "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a1i0a000008yifVAAQ":{"Id":"a1i0a000008yifVAAQ", "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a1i0a000008yifJAAQ":{"Id":"a1i0a000008yifJAAQ", "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a1i0a000008yihjAAA":{"Id":"a1i0a000008yihjAAA", "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a1i0a000008yUOIAA2":{"Id":"a1i0a000008yUOIAA2", "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"},' +
                '"a1i0a000008yUM7AAM":{"Id":"a1i0a000008yUM7AAM", "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"},' +
                '"a1i0a000008yULrAAM":{"Id":"a1i0a000008yULrAAM", "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"},' +
                '"a1i0a000008yTxMAAU":{"Id":"a1i0a000008yTxMAAU", "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"},' +
                '"a1i0a000008yUOdAAM":{"Id":"a1i0a000008yUOdAAM", "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"},' +
                '"a1i0a000008yUO6AAM":{"Id":"a1i0a000008yUO6AAM", "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"},' +
                '"a1i0a000008yUNsAAM":{"Id":"a1i0a000008yUNsAAM", "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"},' +
                '"a1i0a000008yUNnAAM":{"Id":"a1i0a000008yUNnAAM", "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"}' +
                '}';

            switch on methodCall.stubbedMethodName {
                when 'getUASBsFromIds' {
                    return (Map<Id, UASB__c>)JSON.deserialize(uasbMapAsString, Map<Id, UASB__c>.class);
                }
            }
            return null;
        }
    }

    public class MockAdjustmentSelector extends MockProvider {
        public MockAdjustmentSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String adjustMapAsString = '{' +
                '"a0p0a000008ZZBuAAO":{"Id":"a0p0a000008ZZBuAAO", "Discount__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a0p0a000008YSBuAAO":{"Id":"a0p0a000008YSBuAAO", "Discount__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a0p0a000008YSCuAAO":{"Id":"a0p0a000008YSCuAAO", "Discount__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a0p0a000008AABuAAO":{"Id":"a0p0a000008AABuAAO", "Discount__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '"a0p0a000008BBBuAAO":{"Id":"a0p0a000008BBBuAAO", "Discount__c":10,"Transfer__c":"a900a000000GpNBAA0"}' +
                '}';

            switch on methodCall.stubbedMethodName {
                when 'getAdjustmentsFromIds' {
                    return (Map<Id, Bill_Adjustment__c>)JSON.deserialize(adjustMapAsString, Map<Id, Bill_Adjustment__c>.class);
                }
            }
            return null;
        }
    }

    private static Set<String> getMockInvoiceItemIds(){
        return new Set<String>{
            '2c92c0fa6e3a938d016e3e2ed1f832aa', '2c92c0fb6e3aa322016e3df698ff7e9f', '2c92c0fa6e3a9391016e3e30d48066d2',
            '2c92c0fa6e3a9391016e3df87b1f687a', '2c92c0fa6e3a938d016e3dfdc93450b2',
            '2c92c0fb6e3aa321016e3df574337a9b'};
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

        dataAsString = dataAsString.replace('}','},');
        dataAsString = dataAsString.removeEnd(',');
        dataAsString = '[' + dataAsString + ']';
        dataAsString = dataAsString.replace('__c','_Zcustom');
        return dataAsString;
    }

    private static List<Journal_Entry__c> getInvoiceItemJournalEntries(){
        Date mayBillDate = Date.newInstance(2019,05,20);
        Date juneBillDate = Date.newInstance(2019,06,20);

        Journal_Entry__c entryOne = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 252.73,
            External_Id__c = '2c92c0fa6e3a9391016e3df87b1f687a',
            Customer_Account__c = 'bw-00524',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryTwo = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 135.06,
            External_Id__c = '2c92c0fa6e3a9391016e3e30d48066d2',
            Customer_Account__c = 'bw-00524',
            Date__c = juneBillDate
        );
        Journal_Entry__c entryThree = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000022',
            Client__c = 'BW-0009470',
            Amount__c = 255.63,
            External_Id__c = '2c92c0fb6e3aa321016e3df574337a9b',
            Customer_Account__c = 'bw-05268',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryFour = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000045',
            Client__c = 'BW-0009186',
            Amount__c = 1997.03,
            External_Id__c = '2c92c0fa6e3a938d016e3dfdc93450b2',
            Customer_Account__c = 'bw-05956',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryFive = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000002',
            Client__c = 'BW-0009470',
            Amount__c = 37.23,
            External_Id__c = '2c92c0fb6e3aa322016e3df698ff7e9f',
            Customer_Account__c = 'bw-04202',
            Date__c = mayBillDate
        );
        Journal_Entry__c entrySix = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000002',
            Client__c = 'BW-0009470',
            Amount__c = 62.55,
            External_Id__c = '2c92c0fa6e3a938d016e3e2ed1f832aa',
            Customer_Account__c = 'bw-04202',
            Date__c = juneBillDate
        );
        List<Journal_Entry__c> entries = new List<Journal_Entry__c>{
            entryOne, entryTwo, entryThree, entryFour, entryFive, entrySix
        };
        return entries;
    }

    private static List<Journal_Entry__c> getCollectionJournalEntries(){
        Date mayBillDate = Date.newInstance(2019,05,20);
        Date juneBillDate = Date.newInstance(2019,06,20);

        Journal_Entry__c entryOne = new Journal_Entry__c(
            Id = 'a920a000000HuJoAAA',
            Object_Type__c = 'PaymentPart',
            Query_Type__c = 'PaymentPart_IV',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 121.87,
            External_Id__c = '2dd2c0fa6e3a9391016e3df87b1f687a',
            Applied_Record_Id__c = 'a920a000000HSfsAAG',
            Customer_Account__c = 'bw-00524',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryTwo = new Journal_Entry__c(
            Id = 'a920a000000HuJoAAB',
            Object_Type__c = 'PaymentPart',
            Query_Type__c = 'PaymentPart_IV',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 31.72,
            External_Id__c = '2dd2c0fa6e3a9391016e3df87b1f687a',
            Applied_Record_Id__c = 'a920a000000HSfsAAH',
            Customer_Account__c = 'bw-00524',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryThree = new Journal_Entry__c(
            Id = 'a920a000000HuJoAAC',
            Object_Type__c = 'PaymentPart',
            Query_Type__c = 'PaymentPart_IV',
            Project__c = 'SSS-000022',
            Client__c = 'BW-0009470',
            Amount__c = 60.00,
            External_Id__c = '2dd2c0fb6e3aa321016e3df574337a9b',
            Applied_Record_Id__c = 'a920a000000HSfsAAH',
            Customer_Account__c = 'bw-05268',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryFive = new Journal_Entry__c(
            Id = 'a920a000000HuJoAAD',
            Object_Type__c = 'PaymentPart',
            Query_Type__c = 'PaymentPart_IV',
            Project__c = 'SSS-000002',
            Client__c = 'BW-0009470',
            Amount__c = 37.23,
            External_Id__c = '2dd2c0fb6e3aa322016e3df698ff7e9f',
            Applied_Record_Id__c = 'a920a000000HSfsAAI',
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
            External_Id__c = '2dd2c0fa6e3a938d016e3e2ed1f832aa',
            Applied_Record_Id__c = 'a920a000000HSfsAAI',
            Customer_Account__c = 'bw-04202',
            Date__c = juneBillDate
        );
        List<Journal_Entry__c> entries = new List<Journal_Entry__c>{
            entryOne, entryTwo, entryThree, entryFive, entrySix
        };
        return entries;
    }

    private static Map<Id,List<Transfer_Part__c>> getBillPartByInvoice(){
        Map<Id,List<Transfer_Part__c>> mapParts = new Map<Id,List<Transfer_Part__c>>();
        // Three invoiceItems, first two are distributed among 3 production periods
        // last one is distributed among 1 production period
        Transfer_Part__c partOne = new Transfer_Part__c(
            Id = 'a8y0a000000Gu3rAAA',
            Name = 'InvoiceOne_ProductionOne',
            Production__c = 'a8u0a000000I4ETAA0',
            Transfer__c = 'a900a000000GsOyAAK',
            Journal_Entry__c = 'a920a000000HSfsAAG',
            Amount__c = 100,
            Type__c = 'Bill'
        );
        Transfer_Part__c partTwo = new Transfer_Part__c(
            Id = 'a8y0a000000Gu3rBBB',
            Name = 'InvoiceOne_ProductionTwo',
            Production__c = 'a8u0a000000I4ETAA1',
            Transfer__c = 'a900a000000GsOyAAK',
            Journal_Entry__c = 'a920a000000HSfsAAG',
            Amount__c = 120,
            Type__c = 'Bill'
        );
        Transfer_Part__c partThree = new Transfer_Part__c(
            Id = 'a8y0a000000Gu3rCCC',
            Name = 'InvoiceOne_ProductionThree',
            Production__c = 'a8u0a000000I4ETAA2',
            Transfer__c = 'a900a000000GsOyAAK',
            Journal_Entry__c = 'a920a000000HSfsAAG',
            Amount__c = 1.87,
            Type__c = 'Bill'
        );
        Transfer_Part__c partFour = new Transfer_Part__c(
            Id = 'a8y0a000000Gu3rDDD',
            Name = 'InvoiceTwo_ProductionOne',
            Production__c = 'a8u0a000000I4ETAA0',
            Transfer__c = 'a900a000000GsOyAAK',
            Journal_Entry__c = 'a920a000000HSfsAAH',
            Amount__c = 33.33,
            Type__c = 'Bill'
        );
        Transfer_Part__c partFive = new Transfer_Part__c(
            Id = 'a8y0a000000Gu3rEEE',
            Name = 'InvoiceTwo_ProductionTwo',
            Production__c = 'a8u0a000000I4ETAA1',
            Transfer__c = 'a900a000000GsOyAAK',
            Journal_Entry__c = 'a920a000000HSfsAAH',
            Amount__c = 33.33,
            Type__c = 'Bill'
        );
        Transfer_Part__c partSix = new Transfer_Part__c(
            Id = 'a8y0a000000Gu3rFFF',
            Name = 'InvoiceTwo_ProductionThree',
            Production__c = 'a8u0a000000I4ETAA2',
            Transfer__c = 'a900a000000GsOyAAK',
            Journal_Entry__c = 'a920a000000HSfsAAH',
            Amount__c = 33.34,
            Type__c = 'Bill'
        );
        Transfer_Part__c partSeven = new Transfer_Part__c(
            Id = 'a8y0a000000Gu3rGGG',
            Name = 'InvoiceThree_ProductionTwo',
            Production__c = 'a8u0a000000I4ETAA1',
            Transfer__c = 'a900a000000GsOyAAK',
            Journal_Entry__c = 'a920a000000HSfsAAI',
            Amount__c = 123.34,
            Type__c = 'Bill'
        );
        mapParts.put(partOne.Journal_Entry__c, new List<Transfer_Part__c>{partOne, partTwo, partThree});
        mapParts.put(partFour.Journal_Entry__c,new List<Transfer_Part__c>{partFour, partFive, partSix});
        mapParts.put(partSeven.Journal_Entry__c,new List<Transfer_Part__c>{partSeven});
        return mapParts;
    }

    private static Map<Id,Decimal> getPaymentsMap(){
        Map<Id,Decimal> paymentMap = new Map<Id,Decimal>();
        paymentMap.put('a8y0a000000Gu3rAAA', 100.00);
        paymentMap.put('a8y0a000000Gu3rDDD', 4.33);
        return paymentMap;
    }
}