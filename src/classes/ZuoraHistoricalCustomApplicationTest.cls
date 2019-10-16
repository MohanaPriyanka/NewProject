/*************************************************************************************
 * Created By: peteryao on 10/16/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraHistoricalCustomApplicationTest {
    @IsTest
    public static void testCustomApplication() {
        String outstandingItemJSON =
            '{"Project":"SSS-000021","ParentId":"2c92c0fb6daab15c016dae43cee5361d","IsInvoiceItem":false,"Id":"2c92c0fb6daab15c016dae43cefd361e","EffectiveDate":"2019-06-15T00:00:00.000Z","Client":"BW-0021776","AmountToApply":100,"AmountOutstanding":9200.00000}';
        ZuoraOutstandingItemsService.OutstandingItem oi =
            (ZuoraOutstandingItemsService.OutstandingItem) JSON.deserialize(outstandingItemJSON, ZuoraOutstandingItemsService.OutstandingItem.class);

        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems = new List<ZuoraOutstandingItemsService.OutstandingItem>();
        outstandingItems.add(oi);
        List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply = new List<ZuoraOutstandingItemsService.OutstandingItem>();
        itemsToApply.add(oi);

        System.assertEquals(null, Logger.logs);
        ZuoraHistoricalCustomApplicationService.customApplication(
            'a210a00000GkIXgAAN',
            outstandingItems,
            itemsToApply
        );
        System.assertEquals(null, Logger.logs);
    }

    @IsTest
    public static void testSpecficCustomers() {
        String outstandingItemJSON =
            '{"Project":"SSS-000021","ParentId":"2c92c0fb6daab15c016dae43cee5361d","IsInvoiceItem":false,"Id":"2c92c0fb6daab15c016dae43cefd361e","EffectiveDate":"2019-06-15T00:00:00.000Z","Client":"BW-0021776","AmountToApply":100,"AmountOutstanding":9200.00000}';
        ZuoraOutstandingItemsService.OutstandingItem oi =
            (ZuoraOutstandingItemsService.OutstandingItem) JSON.deserialize(outstandingItemJSON, ZuoraOutstandingItemsService.OutstandingItem.class);

        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems = new List<ZuoraOutstandingItemsService.OutstandingItem>();
        outstandingItems.add(oi);
        List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply = new List<ZuoraOutstandingItemsService.OutstandingItem>();
        itemsToApply.add(oi);

        System.assertEquals(null, Logger.logs);
        ZuoraHistoricalCustomApplicationService.applyStelios(outstandingItems, itemsToApply);
        ZuoraHistoricalCustomApplicationService.applyNNF(outstandingItems, itemsToApply);
        ZuoraHistoricalCustomApplicationService.applyYongShing(outstandingItems, itemsToApply);
        System.debug(LoggingLevel.ERROR, System.JSON.serialize(Logger.logs));
        System.assertEquals(null, Logger.logs);
    }
    @IsTest
    public static void testCheckAndSetOutstandingItemWithApplyItem() {
        String outstandingItemJSON =
            '{"Project":"SSS-000021","ParentId":"2c92c0fb6daab15c016dae43cee5361d","IsInvoiceItem":false,"Id":"2c92c0fb6daab15c016dae43cefd361e","EffectiveDate":"2019-06-15T00:00:00.000Z","Client":"BW-0021776","AmountToApply":100,"AmountOutstanding":9200.00000}';
        ZuoraOutstandingItemsService.OutstandingItem oi =
            (ZuoraOutstandingItemsService.OutstandingItem) JSON.deserialize(outstandingItemJSON, ZuoraOutstandingItemsService.OutstandingItem.class);
        List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply = new List<ZuoraOutstandingItemsService.OutstandingItem>();

        Decimal newAmountToApply = 90;
        ZuoraHistoricalCustomApplicationService.checkAndSetOutstandingItem(oi, Date.newInstance(2019, 6, 15), 'SSS-000021', 9200, newAmountToApply, 9200, itemsToApply);
        System.assertEquals(9200 - newAmountToApply, oi.AmountOutstanding, 'Should have updated amount to apply since project and date are the same');
        System.assertEquals(1, itemsToApply.size());
        System.assertEquals(newAmountToApply, itemsToApply[0].AmountToApply);
    }

    @IsTest
    public static void testCheckAndSetOutstandingItem() {
        String outstandingItemJSON =
            '{"Project":"SSS-000021","ParentId":"2c92c0fb6daab15c016dae43cee5361d","IsInvoiceItem":false,"Id":"2c92c0fb6daab15c016dae43cefd361e","EffectiveDate":"2019-06-15T00:00:00.000Z","Client":"BW-0021776","AmountToApply":100,"AmountOutstanding":9200.00000}';
        ZuoraOutstandingItemsService.OutstandingItem oi =
            (ZuoraOutstandingItemsService.OutstandingItem) JSON.deserialize(outstandingItemJSON, ZuoraOutstandingItemsService.OutstandingItem.class);

        Decimal newAmountToApply = 90;
        ZuoraHistoricalCustomApplicationService.checkAndSetOutstandingItem(oi, Date.newInstance(2019, 6, 15), 'SSS-000021', 9200, newAmountToApply, 9200);
        System.assertEquals(9200 - newAmountToApply, oi.AmountOutstanding, 'Should have updated amount to apply since project and date are the same');

        System.assertEquals(null, Logger.logs, 'Starting with no error logs');
        ZuoraHistoricalCustomApplicationService.checkAndSetOutstandingItem(oi, Date.newInstance(2019, 6, 15), 'SSS-000021', 9200, newAmountToApply, 100);
        System.assertEquals(1, Logger.logs.size());
        System.assertEquals(1, Logger.logs.values().size(), 'Expected a failure because the amount to apply wasn\'t expected');
    }

    @IsTest
    public static void testCheckAndSetApplyItem() {
        String outstandingItemJSON =
            '{"Project":"SSS-000021","ParentId":"2c92c0fb6daab15c016dae43cee5361d","IsInvoiceItem":false,"Id":"2c92c0fb6daab15c016dae43cefd361e","EffectiveDate":"2019-06-15T00:00:00.000Z","Client":"BW-0021776","AmountToApply":100,"AmountOutstanding":0.920000000}';
        ZuoraOutstandingItemsService.OutstandingItem oi =
            (ZuoraOutstandingItemsService.OutstandingItem) JSON.deserialize(outstandingItemJSON, ZuoraOutstandingItemsService.OutstandingItem.class);

        Decimal newAmountToApply = 90;
        ZuoraHistoricalCustomApplicationService.checkAndSetApplyItem(oi, Date.newInstance(2019, 6, 15), 'SSS-000021', newAmountToApply, 100);
        System.assertEquals(newAmountToApply, oi.AmountToApply, 'Should have updated amount to apply since project and date are the same');

        System.assertEquals(null, Logger.logs, 'Starting with no error logs');
        ZuoraHistoricalCustomApplicationService.checkAndSetApplyItem(oi, Date.newInstance(2019, 6, 15), 'SSS-000021', newAmountToApply, 100);
        System.assertEquals(1, Logger.logs.size());
        System.assertEquals(1, Logger.logs.values().size(), 'Expected a failure because the amount to apply wasn\'t expected');
    }
}