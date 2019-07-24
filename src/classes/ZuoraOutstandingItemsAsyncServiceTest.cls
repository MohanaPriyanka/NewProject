/**
 * Created by PeterYao on 7/23/2019.
 */
@IsTest
public with sharing class ZuoraOutstandingItemsAsyncServiceTest {
    @IsTest
    public static void testRequeueInvoices() {
        List<ZuoraAPI.Invoice> invoices = new List<ZuoraAPI.Invoice>();
        ZuoraAPI.Invoice invoice = new ZuoraAPI.Invoice();
        invoice.id = 'ThrowException';
        invoices.add(invoice);
        ZuoraOutstandingItemsAsyncService asyncService = new ZuoraOutstandingItemsAsyncService(invoices, null, null);
        System.assertEquals(null, asyncService.nextChainedJob, 'A ZuoraOutstandingItemsAsyncService job should not be queued');

        asyncService.execute(null);

        System.assertNotEquals(null, asyncService.nextChainedJob, 'A ZuoraOutstandingItemsAsyncService job should be queued');
        System.assertEquals(asyncService.nextChainedJob.invoices, invoices, 'The next chained job should have the same invoice');
    }

    @IsTest
    public static void testProcessOneRequeueOneDebitMemo() {
        List<ZuoraAPI.ZuoraDebitMemo> debitMemos = new List<ZuoraAPI.ZuoraDebitMemo>();
        ZuoraAPI.ZuoraDebitMemo debitMemoOne = new ZuoraAPI.ZuoraDebitMemo();
        debitMemoOne.id = '2c92c0f96b695c76016b6c860fcf77f5';
        debitMemos.add(debitMemoOne);
        ZuoraAPI.ZuoraDebitMemo debitMemoTwo = new ZuoraAPI.ZuoraDebitMemo();
        debitMemoTwo.id = 'ThrowException';
        debitMemos.add(debitMemoTwo);

        ZuoraOutstandingItemsAsyncService asyncService = new ZuoraOutstandingItemsAsyncService(null, debitMemos, null);
        System.assertEquals(null, asyncService.nextChainedJob, 'A ZuoraOutstandingItemsAsyncService job should not be queued');

        asyncService.execute(null);

        System.assertNotEquals(null, asyncService.nextChainedJob, 'A ZuoraOutstandingItemsAsyncService job should be queued');
        System.assertEquals(1, asyncService.nextChainedJob.debitMemos.size(), 'The next chained job should have just one debit memo');
        System.assertEquals('ThrowException', asyncService.nextChainedJob.debitMemos[0].id, 'The debit memo to be requeued should be ThrowException');
    }

}