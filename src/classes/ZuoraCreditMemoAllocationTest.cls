@IsTest
public class ZuoraCreditMemoAllocationTest {
    // Don't use actual test setup method because we aren't committing to the database, but still want to reuse:
    public static List<ZuoraOutstandingItemsService.OutstandingItem> testDataSetup() {
        // Oldest to newest, Ids are unique:
        ZuoraOutstandingItemsService.OutstandingItem itemOne = new ZuoraOutstandingItemsService.OutstandingItem();
        itemOne.AmountOutstanding = 5;
        itemOne.AmountToApply = 0;
        itemOne.EffectiveDate = Datetime.newInstance(2019,02,01,12,10,00);
        itemOne.Project = 'SSS-0000012';
        itemOne.Client = 'BW-0000123';
        itemOne.Id = 'itemOne';
        itemOne.ParentId = 'invoiceOne';
        itemOne.IsInvoiceItem = true;

        ZuoraOutstandingItemsService.OutstandingItem itemTwo = new ZuoraOutstandingItemsService.OutstandingItem();
        itemTwo.AmountOutstanding = 50;
        itemOne.AmountToApply = 0;
        itemTwo.EffectiveDate = Datetime.newInstance(2019,02,01,12,10,01);
        itemTwo.Project = 'SSS-0000018';
        itemTwo.Client = 'BW-0000122';
        itemTwo.Id = 'itemTwo';
        itemOne.ParentId = 'debitOne';
        itemTwo.IsInvoiceItem = false;

        ZuoraOutstandingItemsService.OutstandingItem itemThree = new ZuoraOutstandingItemsService.OutstandingItem();
        itemThree.AmountOutstanding = 2;
        itemOne.AmountToApply = 0;
        itemThree.EffectiveDate = Datetime.newInstance(2019,02,01,13,10,00);
        itemThree.Project = 'SSS-0000016';
        itemThree.Client = 'BW-0000122';
        itemThree.Id = 'itemThree';
        itemOne.ParentId = 'invoiceTwo';
        itemThree.IsInvoiceItem = true;

        ZuoraOutstandingItemsService.OutstandingItem itemFour = new ZuoraOutstandingItemsService.OutstandingItem();
        itemFour.AmountOutstanding = 10;
        itemOne.AmountToApply = 0;
        itemFour.EffectiveDate = Datetime.newInstance(2019,02,01,14,10,00);
        itemFour.Project = 'SSS-0000012';
        itemFour.Client = 'BW-0000123';
        itemFour.Id = 'itemFour';
        itemOne.ParentId = 'debitOne';
        itemFour.IsInvoiceItem = false;

        List<ZuoraOutstandingItemsService.OutstandingItem> unsortedItemList = new List<ZuoraOutstandingItemsService.OutstandingItem>{
            itemFour, itemOne, itemThree, itemTwo
        };

        return unsortedItemList;
    }

    @IsTest
    private static void testSortOutstandingItemsByDate() {
        List<ZuoraOutstandingItemsService.OutstandingItem> unsortedItemList = testDataSetup();
        List<ZuoraOutstandingItemsService.OutstandingItem> sortedList = unsortedItemList.clone();

        sortedList.sort();

        System.assertEquals(sortedList[0].Id, unsortedItemList[1].Id); //itemOne
        System.assertEquals(sortedList[1].Id, unsortedItemList[3].Id); //itemTwo
        System.assertEquals(sortedList[2].Id, unsortedItemList[2].Id); //itemThree
        System.assertEquals(sortedList[3].Id, unsortedItemList[0].Id); //itemFour

        // Update itemThree to be the newest:
        sortedList[2].EffectiveDate = sortedList[2].EffectiveDate.addMonths(1);

        sortedList.sort();
        System.assertEquals(sortedList[0].Id, unsortedItemList[1].Id); //itemOne
        System.assertEquals(sortedList[1].Id, unsortedItemList[3].Id); //itemTwo
        System.assertEquals(sortedList[2].Id, unsortedItemList[0].Id); //itemFour
        System.assertEquals(sortedList[3].Id, unsortedItemList[2].Id); //itemThree **
    }

    @IsTest
    private static void testApplicationCreditMoreThanBills(){
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems = testDataSetup();
        outstandingItems.sort();

        List<ZuoraOutstandingItemsService.OutstandingItem> itemsWithAppliedAmount;
        itemsWithAppliedAmount = ZuoraOutstandingItemsService.applyToOutstandingItems(outstandingItems,55.45,'SSS-0000012','BW-0000123');

        System.assertEquals(4,outstandingItems.size());
        System.assertEquals(2,itemsWithAppliedAmount.size());

        for (ZuoraOutstandingItemsService.OutstandingItem item : itemsWithAppliedAmount){
            if (item.Id == 'itemOne'){
                System.assertEquals(5,item.AmountToApply);
            } else if (item.Id == 'itemFour') {
                System.assertEquals(10, item.AmountToApply);
            } else {
                // Do not expect to get any bills other than these 2:
                System.assert(false);
            }
        }
    }

    @IsTest
    private static void testApplicationCreditLessThanBills(){
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItemList = testDataSetup();
        outstandingItemList.sort();

        List<ZuoraOutstandingItemsService.OutstandingItem> itemsWithAppliedAmount;
        itemsWithAppliedAmount = ZuoraOutstandingItemsService.applyToOutstandingItems(outstandingItemList,7.25,'SSS-0000012','BW-0000123');

        System.assertEquals(4,outstandingItemList.size());
        System.assertEquals(2,itemsWithAppliedAmount.size());

        for (ZuoraOutstandingItemsService.OutstandingItem item : itemsWithAppliedAmount){
            if (item.Id == 'itemOne'){
                System.assertEquals(5,item.AmountToApply);
            } else if (item.Id == 'itemFour') {
                System.assertEquals(2.25, item.AmountToApply);
            } else {
                // Do not expect to get any bills other than these 2:
                System.assert(false);
            }
        }
    }

    @IsTest
    private static void testApplicationOnlyMatchesOneBill(){
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItemList = testDataSetup();
        outstandingItemList.sort();

        List<ZuoraOutstandingItemsService.OutstandingItem> itemsWithAppliedAmount;
        itemsWithAppliedAmount = ZuoraOutstandingItemsService.applyToOutstandingItems(outstandingItemList,50,'SSS-0000018','BW-0000122');

        System.assertEquals(4,outstandingItemList.size());
        System.assertEquals(1,itemsWithAppliedAmount.size());

        for (ZuoraOutstandingItemsService.OutstandingItem item : itemsWithAppliedAmount){
            if (item.Id == 'itemTwo'){
                System.assertEquals(50,item.AmountToApply);
            } else {
                // Do not expect to get any bills other than this 1:
                System.assert(false);
            }
        }
    }

    @IsTest
    private static void testInvoiceQuery() {
        String zuoraId = '2c92c0f86ae3a4ad016ae5e247886605';

        List<ZuoraAPI.Invoice> invoices = ZuoraOutstandingItemsService.getOutstandingInvoices(zuoraId);
        System.assertEquals(2,invoices.size());

        ZuoraAPI.InvoiceWithItems invoiceWithItem = ZuoraOutstandingItemsService.getInvoiceItems(invoices[0]);
        System.assertEquals(invoices[0].id, invoiceWithItem.invoice.id);
        System.assertEquals(2, invoiceWithItem.items.size());
    }

    @IsTest
    private static void testDebitMemoQuery() {
        String zuoraId = '2c92c0f86ae3a4ad016ae5e247886605';

        List<ZuoraAPI.ZuoraDebitMemo> debitMemos = ZuoraOutstandingItemsService.getOutstandingDebitMemos(zuoraId);
        System.assertEquals(1,debitMemos.size());

        ZuoraAPI.DebitMemoWithItems debitMemoWithItem = ZuoraOutstandingItemsService.getDebitMemoItems(debitMemos[0]);
        System.assertEquals(debitMemos[0].id, debitMemoWithItem.debitMemo.id);
        System.assertEquals(1, debitMemoWithItem.items.size());
    }

    @IsTest
    private static void testCreditMemoQuery() {
        List<ZuoraAPI.ZuoraCreditMemo> creditMemos;
        creditMemos = (ZuoraCreditMemoAllocationService.getFirstPageCreditMemos(10)).CreditMemos;
        System.assertEquals(2,creditMemos.size());

        ZuoraAPI.CreditMemoWithItem creditMemoWithItem = ZuoraCreditMemoAllocationService.getItemFromCreditMemo(creditMemos[0]);
        System.assertEquals(creditMemos[0].id, creditMemoWithItem.CreditMemo.id);
        System.assertNotEquals(5, creditMemoWithItem.Item.amount);
    }

    @IsTest
    private static void testOutstandingBalance() {
        String zuoraId = '2c92c0f86ae3a4ad016ae5e247886605';
        ZuoraOutstandingItemsAsyncService asyncService = ZuoraOutstandingItemsService.processOutstandingItemsByDate(zuoraId, null);
        asyncService.execute(null);
        List<ZuoraOutstandingItemsService.OutstandingItem> allOutstandingItems = asyncService.processingParameter.allOutstandingItems;

        // 2 invoices, with 2 invoice items each, different SSS same client
        // SSS-000098: ($180 + $710) & SSS-000099: ($90 + $100)
        // 1 debit memo with 1 item (SSS-000098)
        System.assertEquals(5,allOutstandingItems.size());

        Decimal totalOutstanding = 0;
        Decimal invoiceOutstanding = 0;
        Decimal debitMemoOutstanding = 0;
        for (ZuoraOutstandingItemsService.OutstandingItem item : allOutstandingItems) {
            if (item.IsInvoiceItem){
                invoiceOutstanding += item.AmountOutstanding;
            } else {
                debitMemoOutstanding += item.AmountOutstanding;
            }
            totalOutstanding += item.AmountOutstanding;
            System.assertEquals(null,item.AmountToApply);
        }

        System.assertEquals(1100,totalOutstanding);
        System.assertEquals(1080,invoiceOutstanding);
        System.assertEquals(20,debitMemoOutstanding);
    }

    @IsTest
    private static void testApplyLessThanBill() {
        String zuoraId = '2c92c0f86ae3a4ad016ae5e247886605';
        List<ZuoraOutstandingItemsService.OutstandingItem> allOutstandingItems;
        List<ZuoraOutstandingItemsService.OutstandingItem> withAppliedAmount;
        ZuoraOutstandingItemsAsyncService asyncService = ZuoraOutstandingItemsService.processOutstandingItemsByDate(zuoraId, null);
        asyncService.execute(null);
        allOutstandingItems = asyncService.processingParameter.allOutstandingItems;
        // 2 invoices, with 2 invoice items each, different SSS same client
        // SSS-000098: ($180 + $710) & SSS-000099: ($90 + $100)
        // 1 debit memo with 1 item (SSS-000098)
        System.assertEquals(5,allOutstandingItems.size());
        withAppliedAmount = ZuoraOutstandingItemsService.applyToOutstandingItems(
            allOutstandingItems, 20,'SSS-000099','BW-00000385'
        );

        Decimal totalApplied = 0;
        Decimal invoiceApplied = 0;
        Decimal debitMemoApplied = 0;
        for (ZuoraOutstandingItemsService.OutstandingItem item : withAppliedAmount){
            if (item.IsInvoiceItem) {
                invoiceApplied += item.AmountToApply;
            } else {
                debitMemoApplied += item.AmountToApply;
            }
            totalApplied += item.AmountToApply;
        }

        System.assertEquals(20,totalApplied);
        System.assertEquals(20,invoiceApplied);
        System.assertEquals(0,debitMemoApplied);
    }

    @IsTest
    private static void testApplyMoreThanBill() {
        String zuoraId = '2c92c0f86ae3a4ad016ae5e247886605';
        List<ZuoraOutstandingItemsService.OutstandingItem> allOutstandingItems;
        List<ZuoraOutstandingItemsService.OutstandingItem> withAppliedAmountSSS1;
        List<ZuoraOutstandingItemsService.OutstandingItem> withAppliedAmountSSS2;
        ZuoraOutstandingItemsAsyncService asyncService = ZuoraOutstandingItemsService.processOutstandingItemsByDate(zuoraId, null);
        asyncService.execute(null);
        allOutstandingItems = asyncService.processingParameter.allOutstandingItems;

        // 2 invoices, with 2 invoice items each, different SSS same client
        // SSS-000098: ($180 + $710) & SSS-000099: ($90 + $100)
        // 1 debit memo with 1 item (SSS-000098)
        System.assertEquals(5,allOutstandingItems.size());
        withAppliedAmountSSS1 = ZuoraOutstandingItemsService.applyToOutstandingItems(
            allOutstandingItems, 2000,'SSS-000099','BW-00000385'
        );
        Decimal totalApplied = 0;
        Decimal invoiceApplied = 0;
        Decimal debitMemoApplied = 0;
        for (ZuoraOutstandingItemsService.OutstandingItem item : withAppliedAmountSSS1){
            if (item.IsInvoiceItem){
                invoiceApplied += item.AmountToApply;
            } else {
                debitMemoApplied += item.AmountToApply;
            }
            totalApplied += item.AmountToApply;
        }
        System.assertEquals(190,totalApplied);
        System.assertEquals(190,invoiceApplied);
        System.assertEquals(0,debitMemoApplied);

        // Now, test the other SSS:
        withAppliedAmountSSS2 = ZuoraOutstandingItemsService.applyToOutstandingItems(
            allOutstandingItems, 2000,'SSS-000098','BW-00000385'
        );
        totalApplied = 0;
        invoiceApplied = 0;
        debitMemoApplied = 0;
        for (ZuoraOutstandingItemsService.OutstandingItem item : withAppliedAmountSSS2){
            if (item.IsInvoiceItem){
                invoiceApplied += item.AmountToApply;
            } else {
                debitMemoApplied += item.AmountToApply;
            }
            totalApplied += item.AmountToApply;
        }
        System.assertEquals(910,totalApplied);
        System.assertEquals(890,invoiceApplied);
        System.assertEquals(20,debitMemoApplied);
    }

    @IsTest
    private static void testCreditAllocationInvoiceDebitGrouping() {
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems = testDataSetup();
        System.assertEquals(4,outstandingItems.size());

        outstandingItems[0].AmountToApply = 2;
        outstandingItems[1].AmountToApply = 4;
        outstandingItems[2].AmountToApply = 1.7;
        outstandingItems[3].AmountToApply = 1.3;

        // Four items, 2 invoices with 1 item each, 1 debit memo with 2 items:
        System.assertEquals(true, outstandingItems[1].IsInvoiceItem);
        System.assertEquals(true, outstandingItems[2].IsInvoiceItem);
        System.assertEquals(false, outstandingItems[0].IsInvoiceItem);
        System.assertEquals(false, outstandingItems[3].IsInvoiceItem);

        List<ZuoraAPI.ZuoraCreditMemo> creditMemos;
        creditMemos = (ZuoraCreditMemoAllocationService.getFirstPageCreditMemos(10)).CreditMemos;
        ZuoraAPI.CreditMemoWithItem creditMemoWithItem = ZuoraCreditMemoAllocationService.getItemFromCreditMemo(creditMemos[0]);

        Test.startTest();
        ZuoraCreditMemoAllocationService.CreditMemoApplication application;
        application = ZuoraCreditMemoAllocationService.groupByInvoiceAndDebitMemo(creditMemoWithItem, outstandingItems);
        Test.stopTest();

        // Four outstanding items, 2 invoices with 1 item each, 1 debit memo with 2 items:
        System.assertEquals(2,application.invoices.size());
        System.assertEquals(1,application.debitMemos.size());

        System.assertEquals(1,application.invoices[0].items.size());
        System.assertEquals(1,application.invoices[1].items.size());
        System.assertEquals(2,application.debitMemos[0].items.size());

        // Check that invoice/debit memo equal the sum of its parts
        System.assertEquals(
            application.invoices[0].amount,
            application.invoices[0].items[0].amount
        );
        System.assertEquals(
            application.invoices[1].amount,
            application.invoices[1].items[0].amount
        );
        System.assertEquals(
            application.debitMemos[0].amount,
            application.debitMemos[0].items[0].amount + application.debitMemos[0].items[1].amount
        );
        System.assertEquals(
            5.7,
            application.invoices[0].amount + application.invoices[1].amount
        );
        System.assertEquals(
            3.3,
            application.debitMemos[0].amount
        );
    }

    @IsTest
    private static void testBatch() {
        Test.startTest();
        ZuoraMemoBatchApply batchJob = new ZuoraMemoBatchApply();
        batchJob.startApplication();
        System.assertEquals(2, batchJob.creditMemosToApply.size());
        // Because we can only execute one batch in a test, there are two CMs to apply, and runBatch starts with a batch
        // size of 1 because of the chained queueable limit, we need to take one of the credit memos out.
        batchJob.creditMemosToApply.remove(1);
        batchJob.runBatch();
        Test.stopTest();

        List<Error_Log__c> errorLogs = [
            SELECT Id, Class__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraMemoBatchApply'
        ];

        System.assertEquals('ZuoraMemoBatchApply has finished', errorLogs[0].Message__c);
    }

    @IsTest
    private static void testProcessOutstandingItems() {
        // applyToOutstandingItems and groupByInvoiceAndDebitMemo are unit tested above
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems = testDataSetup();
        ZuoraAPI.CreditMemoWithItem creditMemoWithItem = new ZuoraAPI.CreditMemoWithItem();
        ZuoraAPI.ZuoraCreditMemo creditMemo = new ZuoraAPI.ZuoraCreditMemo();
        creditMemo.Project_Zcustom = '';
        creditMemo.ClientOwner_Zcustom = '';
        creditMemoWithItem.CreditMemo = creditMemo;

        ZuoraOutstandingItemsService.ProcessingParameter processingParameter =
            new ZuoraOutstandingItemsService.ProcessingParameter('ZuoraCreditMemoAllocationService', creditMemoWithItem);
        ZuoraCreditMemoAllocationService allocationService = new ZuoraCreditMemoAllocationService();
        allocationService.processOutstandingItems(testDataSetup(), processingParameter);
        System.assertEquals(1, ZuoraAPIHelper.numberCalloutsForZuoraNamespace, 'Should have executed one callout to allocate credit memo');
    }
}