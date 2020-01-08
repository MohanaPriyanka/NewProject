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


}