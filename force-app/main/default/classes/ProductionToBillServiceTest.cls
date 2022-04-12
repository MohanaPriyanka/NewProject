@IsTest
@SuppressWarnings('PMD.ApexCRUDViolation,PMD.ExcessivePublicCount,PMD.AvoidHardcodingId')
public with sharing class ProductionToBillServiceTest {
    @TestVisible
    private static Integer returnEntryNumber;

    @IsTest
    public static void testScheduleJob() {
        useMocks();
        List<Error_Log__c> beforeLogs = [
            SELECT Class__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ProductionToBillService'
        ];
        System.assertEquals(0, beforeLogs.size());

        Test.startTest();
        ProductionToBillScheduler prodService = new ProductionToBillScheduler();
        Datetime dt = Datetime.now().addMinutes(2);
        String cronExpress = '0 ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
        System.schedule('P2B', cronExpress, prodService);
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Class__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ProductionToBillService'
        ];
        System.assert(afterLogs.size() > 0);
    }

    @IsTest
    public static void testQueueJob() {
        useMocks();
        List<Error_Log__c> beforeLogs = [
            SELECT Class__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ProductionToBillService'
        ];
        System.assertEquals(0, beforeLogs.size());

        Test.startTest();
        ProductionToBillService prodService = new ProductionToBillService();
        prodService.queueJob(ProductionToBillService.OperationType.BILL);
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ProductionToBillService'
        ];
        System.assert(afterLogs.size() > 0);
    }

    @IsTest
    public static void testUncheckReadyForProductionDetail() {
        Util.disableTrigger('Disable_BillAdjustmentTrigger__c');
        Util.disableTrigger('Disable_UASBTrigger__c');

        Account propAccount1 = new Account(
            Name = 'Property Account');
        insert propAccount1;

        UASB__c billOne = new UASB__c(
            Account__c = propAccount1.Id,
            Externally_Serviced__c = true,
            Ready_For_Production_Detail__c = true
        );
        insert billOne;

        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(
            Account__c = propAccount1.Id,
            Adjustment_Type__c = 'BW Credit',
            Externally_Serviced__c = true,
            Ready_For_Production_Detail__c = true,
            Reason_For_Adjustment__c = 'Some Reason'
        );
        insert adjustOne;

        ProductionToBillService service = new ProductionToBillService();
        service.markUASBsAsComplete(new List<UASB__c>{
            billOne
        });
        service.markAdjustmentsAsComplete(new List<Bill_Adjustment__c>{
            adjustOne
        });

        UASB__c requeriedUASB = [
            SELECT Id, Ready_For_Production_Detail__c
            FROM UASB__c
            WHERE Id = :billOne.Id
            LIMIT 1
        ];
        Bill_Adjustment__c requeriedAdj = [
            SELECT Id, Ready_For_Production_Detail__c
            FROM Bill_Adjustment__c
            WHERE Id = :adjustOne.Id
            LIMIT 1
        ];
        System.assert(!requeriedUASB.Ready_For_Production_Detail__c);
        System.assert(!requeriedAdj.Ready_For_Production_Detail__c);
    }

    @IsTest
    private static void testJobOrder() {
        ProductionToBillService productionService = new ProductionToBillService();
        productionService.opType = ProductionToBillService.OperationType.BILL;
        productionService.execute(null);
        System.assertEquals(ProductionToBillService.OperationType.DEBITMEMO, productionService.nextP2BJob.opType,
            'Expected to generate Production Details for DebitMemos after Invoice Items, since they are needed for Payments and Credit Memos');

        productionService = new ProductionToBillService();
        productionService.opType = ProductionToBillService.OperationType.DEBITMEMO;
        productionService.execute(null);
        System.assertEquals(ProductionToBillService.OperationType.PAYMENT, productionService.nextP2BJob.opType,
            'Expected to generate Production Details for Payments after Debit Memos');

        productionService = new ProductionToBillService();
        productionService.opType = ProductionToBillService.OperationType.PAYMENT;
        productionService.execute(null);
        System.assertEquals(ProductionToBillService.OperationType.CREDITMEMO, productionService.nextP2BJob.opType,
            'Expected to generate Production Details for Credit Memos after Payments');

        productionService = new ProductionToBillService();
        productionService.opType = ProductionToBillService.OperationType.CREDITMEMO;
        productionService.execute(null);
        System.assertEquals(ProductionToBillService.OperationType.UNSERVICED_BILL, productionService.nextP2BJob.opType,
            'Expected to generate Production Details for Unserviced Invoice Items after Credit Memos');

        productionService = new ProductionToBillService();
        productionService.opType = ProductionToBillService.OperationType.UNSERVICED_BILL;
        productionService.execute(null);
        System.assertEquals(ProductionToBillService.OperationType.UNSERVICED_ADJUST, productionService.nextP2BJob.opType,
            'Expected to generate Production Details for Unserviced Adjustments after Unserviced Invoice Items');

        productionService = new ProductionToBillService();
        productionService.opType = ProductionToBillService.OperationType.UNSERVICED_ADJUST;
        productionService.execute(null);
        System.assertEquals(null, productionService.nextP2BJob,
            'Expected no next job after generating Production Details for Unserviced Adjustments (until we add a reconciliation job)');
    }

    /* ********* MOCKS ************ */

    public static void useMocks() {
        ProductionToBillService.journalEntrySelector = (JournalEntrySelector) Test.createStub(JournalEntrySelector.class, new MockGLSelector());
        ProductionToBillService.uasbSelector = (UASBSelector) Test.createStub(UASBSelector.class, new MockUASBSelector());

        ProductionDetailBillService.journalEntrySelector = (JournalEntrySelector) Test.createStub(JournalEntrySelector.class, new MockGLSelector());
        ProductionDetailBillService.productionDetailSelector = (ProductionDetailSelector) Test.createStub(ProductionDetailSelector.class, new MockProductionDetailSelector());
        ProductionDetailBillService.uasbSelector = (UASBSelector) Test.createStub(UASBSelector.class, new MockUASBSelector());
        ProductionDetailBillService.adjustmentSelector = (AdjustmentSelector) Test.createStub(AdjustmentSelector.class, new MockAdjustmentSelector());

        ProductionDetailPaymentService.productionDetailSelector = (ProductionDetailSelector) Test.createStub(ProductionDetailSelector.class, new MockProductionDetailSelector());

        ProductionDetailCreditMemoService.productionDetailSelector = (ProductionDetailSelector) Test.createStub(ProductionDetailSelector.class, new MockProductionDetailSelector());
        ProductionDetailCreditMemoService.adjustmentSelector = (AdjustmentSelector) Test.createStub(AdjustmentSelector.class, new MockAdjustmentSelector());
        ProductionDetailCreditMemoService.insertUOW = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Transfer_Part__c.SObjectType
            },
            new FFLibHelperTest.MockDML()
        );
        ProductionDetailCreditMemoService.deleteUOW = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Transfer_Part__c.SObjectType
            },
            new FFLibHelperTest.MockDML()
        );
        ProductionDetailDebitMemoService.adjustmentSelector = (AdjustmentSelector) Test.createStub(AdjustmentSelector.class, new MockAdjustmentSelector());
        ProductionDetailDebitMemoService.productionDetailSelector = (ProductionDetailSelector) Test.createStub(ProductionDetailSelector.class, new MockProductionDetailSelector());
        ProductionDetailDebitMemoService.journalEntrySelector = (JournalEntrySelector) Test.createStub(JournalEntrySelector.class, new MockGLSelector());
    }

    public class MockGLSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            List<Journal_Entry__c> entries = getInvoiceItemJournalEntries();
            switch on methodCall.stubbedMethodName {
                when 'getSFJournalEntriesFromExternalId' {
                    if (returnEntryNumber != null) {
                        return new List<Journal_Entry__c>{
                            entries[returnEntryNumber]
                        };
                    } else {
                        return entries;
                    }
                }
                when 'getEntriesWithoutProductionDetail' {
                    return entries;
                }
                when 'getEntriesMapByIds' {
                    List<Journal_Entry__c> paymentEntries = getPaymentJournalEntries();
                    Map<String, Journal_Entry__c> entryMap = new Map<String, Journal_Entry__c>();
                    for (Journal_Entry__c entry : paymentEntries) {
                        entryMap.put(entry.External_Id__c, entry);
                    }

                    return entryMap;
                }
            }
            return null;
        }
    }

    public class MockProductionDetailSelector extends MockProvider {
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
            partToTransferMap.put(projectA.Id, new List<Transfer_Part__c>{
                projectAOne
            });
            partToTransferMap.put(projectB.Id, new List<Transfer_Part__c>{
                projectBOne, projectBTwo, projectBThree
            });
            partToTransferMap.put(projectC.Id, new List<Transfer_Part__c>{
                projectCOne, projectCTwo
            });
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
        public override Object handleMethodCall(MethodCall methodCall) {
            String uasbMapAsString = '{' +
                '"2c92c0f96e3aa333016e3cf0482a601d":[' +
                '{"Id":"a1i0a000008yUBfAAM", "Discounted_Bill__c":152.00, "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"},' +
                '{"Id":"a1i0a000009yUBfAAM", "Discounted_Bill__c":100.73, "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"}' +
                '],' +
                '"2c92c0f96e3aa331016e3cd782c2000d":[{"Id":"a1i0a000008yiV4AAI", "Discounted_Bill__c":370.69, "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cd782c2640d":[{"Id":"a1i0a000008yU78AAE", "Discounted_Bill__c":37.23, "Savings__c":10,"Transfer__c":"a900a000000GqNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc670012ab0":[{"Id":"a1i0b000008yiQYAAY", "Discounted_Bill__c":370.69, "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cd782e3640e":[{"Id":"a1i0a000008yiQYAAY", "Discounted_Bill__c":62.55, "Savings__c":10,"Transfer__c":"a900a000000GqNBAA0"}],' +
                '"2c92c0f96e3aa331016e3dd672212ab0":[{"Id":"a1i0b000008yiV4AAI", "Discounted_Bill__c":370.69, "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc6723a2ab1":[{"Id":"a1i0a000008yigvAAA", "Discounted_Bill__c":288.71, "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc672512ab5":[{"Id":"a1i0a000008yiGrAAI", "Discounted_Bill__c":136.64, "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc672702ab6":[{"Id":"a1i0a000008yihFAAQ", "Discounted_Bill__c":425.36, "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc672892ab7":[{"Id":"a1i0a000008yih1AAA", "Discounted_Bill__c":251.25, "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc672a12ab9":[{"Id":"a1i0a000008yigsAAA", "Discounted_Bill__c":692.04, "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc672b92abb":[{"Id":"a1i0a000008yifVAAQ", "Discounted_Bill__c":220.39, "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc672d12abc":[{"Id":"a1i0a000008yifJAAQ", "Discounted_Bill__c":436.18, "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc672ee2abd":[{"Id":"a1i0a000008yihjAAA", "Discounted_Bill__c":639.15, "Savings__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc6715f2aa8":[{"Id":"a1i0a000008yUOIAA2", "Discounted_Bill__c":249.62, "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc6717f2aaa":[{"Id":"a1i0a000008yUM7AAM", "Discounted_Bill__c":50.12, "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc671962aab":[{"Id":"a1i0a000008yULrAAM", "Discounted_Bill__c":45.15, "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc671ac2aac":[{"Id":"a1i0a000008yTxMAAU", "Discounted_Bill__c":248.92, "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc671c62aad":[{"Id":"a1i0a000008yUOdAAM", "Discounted_Bill__c":500.34, "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc671e62aae":[{"Id":"a1i0a000008yUO6AAM", "Discounted_Bill__c":234.45, "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc672022aaf":[{"Id":"a1i0a000008yUNsAAM", "Discounted_Bill__c":123.4, "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"}],' +
                '"2c92c0f96e3aa331016e3cc672212ab0":[{"Id":"a1i0a000008yUNnAAM", "Discounted_Bill__c":545.03, "Savings__c":10,"Transfer__c":"a900a000000GrNBAA0"}]' +
                '}';

            switch on methodCall.stubbedMethodName {
                when 'getUASBMapFromExternalIds' {
                    return (Map<String, List<UASB__c>>) JSON.deserialize(uasbMapAsString, Map<String, List<UASB__c>>.class);
                }
                when 'getUnservicedWithoutProductionDetail' {
                    return getExternallyServicedUASBs();
                }
            }
            return null;
        }
    }

    public class MockAdjustmentSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            String adjustMapAsString = '{' +
                '"2c92c0f86e3a939f016e3ceadda44909":[{"Id":"a0p0a000008ZZBuAAO", "Adjustment_Amount__c":10, "Discount__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f96e3aa333016e3cf0484b601f":[{"Id":"a0p0a000008YSBuAAO", "Adjustment_Amount__c":10, "Discount__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f86e3a939f016e3cebdda44909":[{"Id":"a0p0a000008YSCuAAO", "Adjustment_Amount__c":255.63, "Discount__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92a00a71c95c4a0171dfcaf46f5333":[{"Id":"a0p0a000008CCCuAAO", "Adjustment_Amount__c":221.87,"Zuora_Id__c":"2c92a00a71c95c4a0171dfcaf46f5333", "Discount__c":10,"Transfer__c":"a900a000000GqNBAA0"}],' +
                '"2c92c0f86e3a939g016e3cebdda44909":[{"Id":"a0p0a000008AABuAAO", "Adjustment_Amount__c":10, "Discount__c":10,"Transfer__c":"a900a000000GpNBAA0"}],' +
                '"2c92c0f86e3a939h016e3cebdda44909":[{"Id":"a0p0a000008BBBuAAO", "Adjustment_Amount__c":10, "Discount__c":10,"Transfer__c":"a900a000000GpNBAA0"}]' +
                '}';

            switch on methodCall.stubbedMethodName {
                when 'getAdjustmentMapFromExternalIds' {
                    return (Map<String, List<Bill_Adjustment__c>>) JSON.deserialize(adjustMapAsString, Map<String, List<Bill_Adjustment__c>>.class);
                }
            }
            return null;
        }
    }

    public static List<Journal_Entry__c> getInvoiceItemJournalEntries() {
        Date mayBillDate = Date.newInstance(2019, 05, 20);
        Date juneBillDate = Date.newInstance(2019, 06, 20);

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

    public static List<Journal_Entry__c> getPaymentJournalEntries() {
        Date mayBillDate = Date.newInstance(2019, 05, 20);
        Date juneBillDate = Date.newInstance(2019, 06, 20);

        Journal_Entry__c entryOne = new Journal_Entry__c(
            Id = 'a920a000000HuJoAAA',
            Object_Type__c = 'PaymentPart',
            Query_Type__c = 'PaymentPart_IV',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 121.87,
            Applied_Record_Id__c = '2dd2c0fa6e3a9391016e3df87b1f687a',
            External_Id__c = '2c92a00a71c95c4a0171dfcaf46f5343',
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
            Applied_Record_Id__c = '2dd2c0fa6e3a9391016e3df87b1f687b',
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
            Applied_Record_Id__c = '2dd2c0fa6e3a9391016e3df87b1f687b',
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
            Applied_Record_Id__c = '2dd2c0fb6e3aa322016e3df698ff7e9f',
            Customer_Account__c = 'bw-04202',
            Date__c = mayBillDate
        );
        Journal_Entry__c entrySix = new Journal_Entry__c(
            Id = 'a920a000000HuJoAAE',
            Object_Type__c = 'PaymentPart',
            Query_Type__c = 'PaymentPart_IV',
            Project__c = 'SSS-000002',
            Client__c = 'BW-0009470',
            Amount__c = 62.55,
            Applied_Record_Id__c = '2dd2c0fb6e3aa322016e3df698ff7e9f',
            Customer_Account__c = 'bw-04202',
            Date__c = juneBillDate
        );
        List<Journal_Entry__c> entries = new List<Journal_Entry__c>{
            entryOne, entryTwo, entryThree, entryFive, entrySix
        };
        return entries;
    }

    private static Map<String, List<Transfer_Part__c>> getBillPartByInvoice() {
        Map<String, List<Transfer_Part__c>> mapParts = new Map<String, List<Transfer_Part__c>>();
        // Three invoiceItems, first distributed among 2 production periods
        // second is distributed among 3 production periods
        // last one is distributed among 1 production period

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
        mapParts.put('2dd2c0fa6e3a9391016e3df87b1f687a', new List<Transfer_Part__c>{
            partTwo, partThree
        });
        mapParts.put('2dd2c0fa6e3a9391016e3df87b1f687b', new List<Transfer_Part__c>{
            partFour, partFive, partSix
        });
        mapParts.put('2dd2c0fb6e3aa322016e3df698ff7e9f', new List<Transfer_Part__c>{
            partSeven
        });
        return mapParts;
    }

    private static Map<Id, Decimal> getPaymentsMap() {
        Map<Id, Decimal> paymentMap = new Map<Id, Decimal>();
        paymentMap.put('a8y0a000000Gu3rAAA', 100.00);
        paymentMap.put('a8y0a000000Gu3rDDD', 4.33);
        return paymentMap;
    }

    public static List<UASB__c> getExternallyServicedUASBs() {
        UASB__c uasbOne = new UASB__c(
            Id = 'a1i0a000009PwUaAAK',
            Externally_Serviced__c = true,
            Transfer__c = 'a900a000000GpNBAA0',
            Credits_Allocated__c = 133.34
        );
        UASB__c uasbTwo = new UASB__c(
            Id = 'a1i0a000009PwUbAAK',
            Externally_Serviced__c = true,
            Transfer__c = 'a900a000000GqNBAA0',
            Credits_Allocated__c = 80
        );
        UASB__c uasbThree = new UASB__c(
            Id = 'a1i0a000009PwUcAAK',
            Externally_Serviced__c = true,
            Transfer__c = 'a900a000000GqNBAA0',
            Credits_Allocated__c = 30.34
        );
        return new List<UASB__c>{
            uasbOne, uasbTwo, uasbThree
        };
    }

    public static List<Bill_Adjustment__c> getExternallyServicedAdjustments() {
        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(
            Id = 'a0p3K000000LKaMQAA',
            Externally_Serviced__c = true,
            Transfer__c = 'a900a000000GpNBAA0',
            Credits_Allocated__c = 133.34
        );
        Bill_Adjustment__c adjustTwo = new Bill_Adjustment__c(
            Id = 'a0p3K000001LKaMQAB',
            Externally_Serviced__c = true,
            Transfer__c = 'a900a000000GqNBAA0',
            Credits_Allocated__c = 80
        );
        Bill_Adjustment__c adjustThree = new Bill_Adjustment__c(
            Id = 'a0p3K000002LKaMQAC',
            Externally_Serviced__c = true,
            Transfer__c = 'a900a000000GqNBAA0',
            Credits_Allocated__c = 30.34
        );
        return new List<Bill_Adjustment__c>{
            adjustOne, adjustTwo, adjustThree
        };
    }

}