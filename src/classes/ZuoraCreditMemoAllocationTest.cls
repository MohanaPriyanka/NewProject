@isTest
public class ZuoraCreditMemoAllocationTest {
    // Don't use actual test setup method because we aren't committing to the database, but still want to reuse:
    private static List<ZuoraOutstandingItemsService.OutstandingItem> testDataSetup(){
        // Oldest to newest, Ids are unique:
        ZuoraOutstandingItemsService.OutstandingItem itemOne = new ZuoraOutstandingItemsService.OutstandingItem();
        itemOne.amountOutstanding = 5;
        itemOne.amountToApply = 0;
        itemOne.effectiveDate = Datetime.newInstance(2019,02,01,12,10,00);
        itemOne.project = 'SSS-0000012';
        itemOne.client = 'BW-0000123';
        itemOne.id = 'itemOne';
        itemOne.parentId = 'invoiceOne';
        itemOne.isInvoiceItem = true;

        ZuoraOutstandingItemsService.OutstandingItem itemTwo = new ZuoraOutstandingItemsService.OutstandingItem();
        itemTwo.amountOutstanding = 50;
        itemOne.amountToApply = 0;
        itemTwo.effectiveDate = Datetime.newInstance(2019,02,01,12,10,01);
        itemTwo.project = 'SSS-0000018';
        itemTwo.client = 'BW-0000122';
        itemTwo.id = 'itemTwo';
        itemOne.parentId = 'debitOne';
        itemTwo.isInvoiceItem = false;

        ZuoraOutstandingItemsService.OutstandingItem itemThree = new ZuoraOutstandingItemsService.OutstandingItem();
        itemThree.amountOutstanding = 2;
        itemOne.amountToApply = 0;
        itemThree.effectiveDate = Datetime.newInstance(2019,02,01,13,10,00);
        itemThree.project = 'SSS-0000016';
        itemThree.client = 'BW-0000122';
        itemThree.id = 'itemThree';
        itemOne.parentId = 'invoiceTwo';
        itemThree.isInvoiceItem = true;

        ZuoraOutstandingItemsService.OutstandingItem itemFour = new ZuoraOutstandingItemsService.OutstandingItem();
        itemFour.amountOutstanding = 10;
        itemOne.amountToApply = 0;
        itemFour.effectiveDate = Datetime.newInstance(2019,02,01,14,10,00);
        itemFour.project = 'SSS-0000012';
        itemFour.client = 'BW-0000123';
        itemFour.id = 'itemFour';
        itemOne.parentId = 'debitOne';
        itemFour.isInvoiceItem = false;

        List<ZuoraOutstandingItemsService.OutstandingItem> unsortedItemList = new List<ZuoraOutstandingItemsService.OutstandingItem>{
            itemFour, itemOne, itemThree, itemTwo
        };

        return unsortedItemList;
    }

    @IsTest
    private static void testSortOutstandingItemsByDate() {
        List<ZuoraOutstandingItemsService.OutstandingItem> unsortedItemList = testDataSetup();
        List<ZuoraOutstandingItemsService.OutstandingItem> sortedList;
        List<ZuoraOutstandingItemsService.OutstandingItem> newSortList;

        sortedList = ZuoraOutstandingItemsService.sortItemsByDate(unsortedItemList);

        System.assertEquals(sortedList[0].Id, unsortedItemList[1].Id); //itemOne
        System.assertEquals(sortedList[1].Id, unsortedItemList[3].Id); //itemTwo
        System.assertEquals(sortedList[2].Id, unsortedItemList[2].Id); //itemThree
        System.assertEquals(sortedList[3].Id, unsortedItemList[0].Id); //itemFour

        // Update itemThree to be the newest:
        unsortedItemList[2].effectiveDate = unsortedItemList[2].effectiveDate.addMonths(1);

        newSortList = ZuoraOutstandingItemsService.sortItemsByDate(unsortedItemList);
        System.assertEquals(newSortList[0].Id, unsortedItemList[1].Id); //itemOne
        System.assertEquals(newSortList[1].Id, unsortedItemList[3].Id); //itemTwo
        System.assertEquals(newSortList[2].Id, unsortedItemList[0].Id); //itemFour
        System.assertEquals(newSortList[3].Id, unsortedItemList[2].Id); //itemThree **
    }

    @IsTest
    private static void testApplicationCreditMoreThanBills(){
        List<ZuoraOutstandingItemsService.OutstandingItem> unsortedItemList = testDataSetup();
        List<ZuoraOutstandingItemsService.OutstandingItem> sortedList;
        sortedList = ZuoraOutstandingItemsService.sortItemsByDate(unsortedItemList);

        List<ZuoraOutstandingItemsService.OutstandingItem> itemsWithAppliedAmount;
        itemsWithAppliedAmount = ZuoraOutstandingItemsService.applyToOutstandingItems(sortedList,55.45,'SSS-0000012','BW-0000123');

        System.assertEquals(4,sortedList.size());
        System.assertEquals(2,itemsWithAppliedAmount.size());

        for (ZuoraOutstandingItemsService.OutstandingItem item : itemsWithAppliedAmount){
            if (item.id == 'itemOne'){
                System.assertEquals(5,item.amountToApply);
            } else if (item.id == 'itemFour') {
                System.assertEquals(10, item.amountToApply);
            } else {
                // Do not expect to get any bills other than these 2:
                System.assert(false);
            }
        }
    }

    @IsTest
    private static void testApplicationCreditLessThanBills(){
        List<ZuoraOutstandingItemsService.OutstandingItem> unsortedItemList = testDataSetup();
        List<ZuoraOutstandingItemsService.OutstandingItem> sortedList;
        sortedList = ZuoraOutstandingItemsService.sortItemsByDate(unsortedItemList);

        List<ZuoraOutstandingItemsService.OutstandingItem> itemsWithAppliedAmount;
        itemsWithAppliedAmount = ZuoraOutstandingItemsService.applyToOutstandingItems(sortedList,7.25,'SSS-0000012','BW-0000123');

        System.assertEquals(4,sortedList.size());
        System.assertEquals(2,itemsWithAppliedAmount.size());

        for (ZuoraOutstandingItemsService.OutstandingItem item : itemsWithAppliedAmount){
            if (item.id == 'itemOne'){
                System.assertEquals(5,item.amountToApply);
            } else if (item.id == 'itemFour') {
                System.assertEquals(2.25, item.amountToApply);
            } else {
                // Do not expect to get any bills other than these 2:
                System.assert(false);
            }
        }
    }

    @IsTest
    private static void testApplicationOnlyMatchesOneBill(){
        List<ZuoraOutstandingItemsService.OutstandingItem> unsortedItemList = testDataSetup();
        List<ZuoraOutstandingItemsService.OutstandingItem> sortedList;
        sortedList = ZuoraOutstandingItemsService.sortItemsByDate(unsortedItemList);

        List<ZuoraOutstandingItemsService.OutstandingItem> itemsWithAppliedAmount;
        itemsWithAppliedAmount = ZuoraOutstandingItemsService.applyToOutstandingItems(sortedList,50,'SSS-0000018','BW-0000122');

        System.assertEquals(4,sortedList.size());
        System.assertEquals(1,itemsWithAppliedAmount.size());

        for (ZuoraOutstandingItemsService.OutstandingItem item : itemsWithAppliedAmount){
            if (item.id == 'itemTwo'){
                System.assertEquals(50,item.amountToApply);
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
        System.assertEquals(invoices[0].Id, invoiceWithItem.Invoice.Id);
        System.assertEquals(2, invoiceWithItem.items.size());
    }

    @IsTest
    private static void testDebitMemoQuery() {
        String zuoraId = '2c92c0f86ae3a4ad016ae5e247886605';

        List<ZuoraAPI.DebitMemo> debitMemos = ZuoraOutstandingItemsService.getOutstandingDebitMemos(zuoraId);
        System.assertEquals(1,debitMemos.size());

        ZuoraAPI.DebitMemoWithItems debitMemoWithItem = ZuoraOutstandingItemsService.getDebitMemoItems(debitMemos[0]);
        System.assertEquals(debitMemos[0].Id, debitMemoWithItem.DebitMemo.Id);
        System.assertEquals(1, debitMemoWithItem.items.size());
    }

    @IsTest
    private static void testCreditMemoQuery() {
        List<ZuoraAPI.ZuoraCreditMemo> creditMemos = ZuoraCreditMemoAllocationService.getAllCreditMemos();
        System.assertEquals(2,creditMemos.size());

        ZuoraAPI.CreditMemoWithItem creditMemoWithItem = ZuoraCreditMemoAllocationService.getItemFromCreditMemo(creditMemos[0]);
        System.assertEquals(creditMemos[0].Id, creditMemoWithItem.CreditMemo.Id);
        System.assertNotEquals(5, creditMemoWithItem.item.amount);
    }

    @IsTest
    private static void testCreditMemoSorting() {
        List<ZuoraAPI.CreditMemoWithItem> unsortedItems = new List<ZuoraAPI.CreditMemoWithItem>();
        List<ZuoraAPI.CreditMemoWithItem> sortedItems = new List<ZuoraAPI.CreditMemoWithItem>();
        Date newestDate = Date.newInstance(2019,06,10);
        Date oldestDate = Date.newInstance(2019,06,03);

        List<ZuoraAPI.ZuoraCreditMemo> creditMemos = ZuoraCreditMemoAllocationService.getAllCreditMemos();
        System.assertEquals(2,creditMemos.size());
        unsortedItems.add(ZuoraCreditMemoAllocationService.getItemFromCreditMemo(creditMemos[0]));
        unsortedItems.add(ZuoraCreditMemoAllocationService.getItemFromCreditMemo(creditMemos[1]));

        System.assertEquals(2, unsortedItems.size());
        System.assertEquals(newestDate, unsortedItems[0].creditMemo.creditMemoDate);
        System.assertEquals(oldestDate, unsortedItems[1].creditMemo.creditMemoDate);

        Test.startTest();
        sortedItems = ZuoraCreditMemoAllocationService.sortByDate(unsortedItems);
        Test.stopTest();

        System.assertEquals(oldestDate, sortedItems[0].creditMemo.creditMemoDate);
        System.assertEquals(newestDate, sortedItems[1].creditMemo.creditMemoDate);
    }

    @isTest
    private static void testOutstandingBalance(){
        String zuoraId = '2c92c0f86ae3a4ad016ae5e247886605';
        List<ZuoraOutstandingItemsService.OutstandingItem> allOutstandingItems;
        allOutstandingItems = ZuoraOutstandingItemsService.getOutstandingItemsByDate(zuoraId);

        // 2 invoices, with 2 invoice items each, different SSS same client
        // SSS-000098: ($180 + $710) & SSS-000099: ($90 + $100)
        // 1 debit memo with 1 item (SSS-000098)
        System.assertEquals(5,allOutstandingItems.size());

        Decimal totalOutstanding = 0;
        Decimal invoiceOutstanding = 0;
        Decimal debitMemoOutstanding = 0;
        for (ZuoraOutstandingItemsService.OutstandingItem item : allOutstandingItems){
            if (item.isInvoiceItem){
                invoiceOutstanding += item.amountOutstanding;
            } else {
                debitMemoOutstanding += item.amountOutstanding;
            }
            totalOutstanding += item.amountOutstanding;
            System.assertEquals(null,item.amountToApply);
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
        allOutstandingItems = ZuoraOutstandingItemsService.getOutstandingItemsByDate(zuoraId);
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
            if (item.isInvoiceItem){
                invoiceApplied += item.amountToApply;
            } else {
                debitMemoApplied += item.amountToApply;
            }
            totalApplied += item.amountToApply;
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


        allOutstandingItems = ZuoraOutstandingItemsService.getOutstandingItemsByDate(zuoraId);

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
            if (item.isInvoiceItem){
                invoiceApplied += item.amountToApply;
            } else {
                debitMemoApplied += item.amountToApply;
            }
            totalApplied += item.amountToApply;
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
            if (item.isInvoiceItem){
                invoiceApplied += item.amountToApply;
            } else {
                debitMemoApplied += item.amountToApply;
            }
            totalApplied += item.amountToApply;
        }
        System.assertEquals(910,totalApplied);
        System.assertEquals(890,invoiceApplied);
        System.assertEquals(20,debitMemoApplied);
    }

    @IsTest
    private static void testCreditAllocationInvoiceDebitGrouping() {
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems = testDataSetup();
        System.assertEquals(4,outstandingItems.size());

        outstandingItems[0].amountToApply = 2;
        outstandingItems[1].amountToApply = 4;
        outstandingItems[2].amountToApply = 1.7;
        outstandingItems[3].amountToApply = 1.3;

        // Four items, 2 invoices with 1 item each, 1 debit memo with 2 items:
        System.assertEquals(true, outstandingItems[1].isInvoiceItem);
        System.assertEquals(true, outstandingItems[2].isInvoiceItem);
        System.assertEquals(false, outstandingItems[0].isInvoiceItem);
        System.assertEquals(false, outstandingItems[3].isInvoiceItem);

        List<ZuoraAPI.ZuoraCreditMemo> creditMemos = ZuoraCreditMemoAllocationService.getAllCreditMemos();
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
        batchJob.init();
        batchJob.runBatch(20);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [
            SELECT Id, Class__c, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraMemoBatchApply'
        ];

        System.assertEquals('ZuoraMemoBatchApply has finished', errorLogs[0].Message__c);
    }
}