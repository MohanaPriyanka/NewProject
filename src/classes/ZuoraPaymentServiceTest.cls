/**
 * Created by PeterYao on 1/7/2020.
 */

@IsTest
public with sharing class ZuoraPaymentServiceTest {
    @IsTest
    public static void testPaymentApplicationDetail(){
        ZuoraOutstandingItemsService.OutstandingItem itemOne = new ZuoraOutstandingItemsService.OutstandingItem();
        itemOne.AmountOutstanding = 5;
        itemOne.AmountToApply = 0;
        itemOne.EffectiveDate = Datetime.newInstance(2019,02,20,0,0,0);
        itemOne.IsInvoiceItem = true;

        ZuoraOutstandingItemsService.OutstandingItem itemTwo = new ZuoraOutstandingItemsService.OutstandingItem();
        itemTwo.AmountOutstanding = 50;
        itemTwo.AmountToApply = 0;
        itemTwo.EffectiveDate = Datetime.newInstance(2019,01,20,0,0,0);
        itemTwo.IsInvoiceItem = false;

        // Don't expect this to have more than 2 decimals,
        // but just to double check that rounding issues won't be duplicated in Zuora:
        ZuoraOutstandingItemsService.OutstandingItem itemThree = new ZuoraOutstandingItemsService.OutstandingItem();
        itemThree.AmountOutstanding = 2.008;
        itemThree.AmountToApply = 0;
        itemThree.EffectiveDate = Datetime.newInstance(2019,03,20,0,0,0);
        itemThree.IsInvoiceItem = true;

        ZuoraOutstandingItemsService.OutstandingItem itemFour = new ZuoraOutstandingItemsService.OutstandingItem();
        itemFour.AmountOutstanding = 10;
        itemFour.AmountToApply = 0;
        itemFour.EffectiveDate = Datetime.newInstance(2017,02,20,0,0,0);
        itemFour.IsInvoiceItem = false;

        List<ZuoraOutstandingItemsService.OutstandingItem> unsortedItemList = new List<ZuoraOutstandingItemsService.OutstandingItem>{
            itemFour, itemOne, itemThree, itemTwo
        };
        unsortedItemList.sort();

        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        payment.amount = 62.12;

        // Test partial payment:
        ZuoraAPI.ZuoraPaymentApplication application;
        ZuoraPaymentService paymentService = new ZuoraPaymentService();
        application = paymentService.applyPaymentToOutstandingItems(unsortedItemList, payment);
        System.assertEquals(1,application.invoices.size());
        System.assertEquals(2,application.debitMemos.size());
        System.assertEquals(10,application.debitMemos[0].amount);
        System.assertEquals(50,application.debitMemos[1].amount);
        System.assertEquals(2.12,application.invoices[0].amount);

        // Test full payment:
        payment.amount = 67;
        ZuoraAPI.ZuoraPaymentApplication secondApplication;
        secondApplication = paymentService.applyPaymentToOutstandingItems(unsortedItemList, payment);
        System.assertEquals(2,secondApplication.invoices.size());
        System.assertEquals(2,secondApplication.debitMemos.size());
        System.assertEquals(10,secondApplication.debitMemos[0].amount);
        System.assertEquals(50,secondApplication.debitMemos[1].amount);
        System.assertEquals(5,secondApplication.invoices[0].amount);
        System.assertEquals(2,secondApplication.invoices[1].amount);
    }

    @IsTest
    public static void testPaymentApplicationInFuture(){
        Datetime futureDate = System.now() + 3;
        ZuoraOutstandingItemsService.OutstandingItem itemOne = new ZuoraOutstandingItemsService.OutstandingItem();
        itemOne.AmountOutstanding = 5;
        itemOne.AmountToApply = 0;
        itemOne.EffectiveDate = Datetime.newInstance(2019,01,20,0,0,0);
        itemOne.IsInvoiceItem = true;

        ZuoraOutstandingItemsService.OutstandingItem itemTwo = new ZuoraOutstandingItemsService.OutstandingItem();
        itemTwo.AmountOutstanding = 50;
        itemTwo.AmountToApply = 0;
        itemTwo.EffectiveDate = futureDate;
        itemTwo.IsInvoiceItem = false;

        ZuoraOutstandingItemsService.OutstandingItem itemThree = new ZuoraOutstandingItemsService.OutstandingItem();
        itemThree.AmountOutstanding = 40;
        itemThree.AmountToApply = 0;
        itemThree.EffectiveDate = futureDate + 3;
        itemThree.IsInvoiceItem = false;

        List<ZuoraOutstandingItemsService.OutstandingItem> itemList = new List<ZuoraOutstandingItemsService.OutstandingItem>{itemOne};

        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        payment.amount = 55;

        ZuoraAPI.ZuoraPaymentApplication application;
        ZuoraPaymentService paymentService = new ZuoraPaymentService();
        application = paymentService.applyPaymentToOutstandingItems(itemList, payment);
        System.assertEquals(1,application.invoices.size());
        System.assertEquals(0,application.debitMemos.size());
        System.assertEquals(DateUtil.convertGmtToDate(System.now()), application.effectiveDate,
            'Expected effective date to be today since outstanding items are effective in the past');

        itemList.add(itemTwo);
        itemList.sort();
        application = paymentService.applyPaymentToOutstandingItems(itemList, payment);
        System.assertEquals(1,application.invoices.size());
        System.assertEquals(1,application.debitMemos.size());
        System.assertEquals(DateUtil.convertGmtToDate(futureDate), application.effectiveDate,
            'Expected effective date to be the latest outstanding item\'s effective date');

        itemList.add(itemThree);
        itemList.sort();
        application = paymentService.applyPaymentToOutstandingItems(itemList, payment);
        System.assertEquals(1,application.invoices.size());
        System.assertEquals(1,application.debitMemos.size());
        System.assertEquals(DateUtil.convertGmtToDate(futureDate), application.effectiveDate,
            'Expected effective date to be the the effective date of the latest outstanding item that is getting applied');
    }

    @IsTest
    public static void testPaymentApplication(){
        // Don't expect this to have more than 2 decimals,
        // but just to double check that rounding issues won't be duplicated in Zuora:
        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        payment.amount = 345.558;
        payment.accountId = '2c92c0f86ae3a4ad016ae5e247886605';
        payment.id = 'XXXXXX';

        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems;
        outstandingItems = ZuoraOutstandingItemsService.getOutstandingItemParentsByDate(payment.accountId);

        System.assertEquals(3,outstandingItems.size());
        System.assertEquals(270,outstandingItems[0].AmountOutstanding);
        System.assertEquals(810,outstandingItems[1].AmountOutstanding);
        System.assertEquals(30,outstandingItems[2].AmountOutstanding);

        System.assert(outstandingItems[0].EffectiveDate < outstandingItems[1].EffectiveDate);
        System.assert(outstandingItems[1].EffectiveDate < outstandingItems[2].EffectiveDate);

        ZuoraAPI.ZuoraPaymentApplication application;
        ZuoraPaymentService paymentService = new ZuoraPaymentService();
        application = paymentService.applyPaymentToOutstandingItems(outstandingItems, payment);

        System.assertEquals(2,application.invoices.size());
        System.assertEquals(270,application.invoices[0].amount);
        System.assertEquals(75.56,application.invoices[1].amount);
    }

    @IsTest
    public static void testDataQueryForUnappliedPayments(){
        List<Zuora_Data_Query__c> beforeQueries = [
            SELECT Id
            FROM Zuora_Data_Query__c
        ];
        System.assertEquals(0,beforeQueries.size());

        Test.startTest();
        ZuoraPaymentService.getAndApplyPaymentsWithUnappliedBalance();
        Test.stopTest();

        List<Zuora_Data_Query__c> afterQueries = [
            SELECT Id
            FROM Zuora_Data_Query__c
        ];
        System.assertEquals(1,afterQueries.size());
    }

    @IsTest
    public static void testPostQueryExecution(){
        String response = '' +
            '[{"Id":"2c92c0fa6e3a9395016e3ea23a912962","accountid":"2c92c0f86e3a939f016e3c9d350e3c6b",' +
            '"unappliedamount":311.930000000,"paymentmethodid":"2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"status":"Processed"},' +
            '{"Id":"2c92c0fb6e3aa322016e3e9c15022235","accountid":"2c92c0f86e3a939f016e3c9d34e33c6a",' +
            '"unappliedamount":152.150000000,"paymentmethodid":"2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"status":"Processed"},' +
            '{"Id":"2c92c0fa6e3a9391016e3e7c5b082795","accountid":"2c92c0f86e3a939c016e3caa3bfc3533",' +
            '"unappliedamount":229.020000000,"paymentmethodid":"2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"status":"Processed"},' +
            '{"Id":"2c92c0fa6e3a9395016e3e802d7b2752","accountid":"2c92c0f86e3a939c016e3ca94c8f2cec",' +
            '"unappliedamount":109.700000000,"paymentmethodid":"2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"status":"Processed"},' +
            '{"Id":"2c92c0fb6e3aa321016e3ea07bfb4d64","accountid":"2c92c0f86e3a939f016e3ca9d2ab17ff",' +
            '"unappliedamount":211.800000000,"paymentmethodid":"2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"status":"Processed"},' +
            '{"Id":"2c92c0fb6e3aa322016e3ea4ab237244","accountid":"2c92c0f96e3aa333016e3ca1efa01cd3",' +
            '"unappliedamount":128.590000000,"paymentmethodid":"2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"status":"Processed"}]';

        List<Error_Log__c> beforeLogs = [
            SELECT Id, Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE Method__c = 'callJsonEndpoint'
        ];
        System.assertEquals(0,beforeLogs.size());

        Test.startTest();
            ZuoraPaymentService service = new ZuoraPaymentService();
            service.executePostQueryJob(null, response);
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id, Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE Method__c = 'callJsonEndpoint'
        ];

        Boolean paymentApp = false;
        for (Error_Log__c log : afterLogs){
            if (log.Message__c != null && log.Message__c.contains('/payments/') && log.Message__c.contains('/apply')){
                paymentApp = true;
            }
        }
        System.assert(paymentApp);
    }
}