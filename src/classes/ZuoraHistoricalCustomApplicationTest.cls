/*************************************************************************************
 * Created By: peteryao on 10/16/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraHistoricalCustomApplicationTest {
    public static ZuoraHistoricalCustomApplicationService customApplicationService = new ZuoraHistoricalCustomApplicationService();
    @IsTest
    public static void testCustomApplication() {
        customApplicationService.staticResourceSelector =
            (StaticResourceSelector) Test.createStub(StaticResourceSelector.class, new MockStaticResourceSelector());
        customApplicationService.init();
        String outstandingItemJSON =
            '{"Project":"SSS-000021","ParentId":"2c92c0fb6daab15c016dae43cee5361d","IsInvoiceItem":false,"Id":"2c92c0fb6daab15c016dae43cefd361e","EffectiveDate":"2019-06-15T00:00:00.000Z","Client":"BW-0021776","AmountToApply":100,"AmountOutstanding":9200.00000}';
        ZuoraOutstandingItemsService.OutstandingItem oi =
            (ZuoraOutstandingItemsService.OutstandingItem) JSON.deserialize(outstandingItemJSON, ZuoraOutstandingItemsService.OutstandingItem.class);

        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems = new List<ZuoraOutstandingItemsService.OutstandingItem>();
        outstandingItems.add(oi);
        List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply = new List<ZuoraOutstandingItemsService.OutstandingItem>();
        itemsToApply.add(oi);

        System.assertEquals(null, Logger.logs);
        customApplicationService.customApplication(
            'a210a00000GkIXgAAN',
            outstandingItems,
            itemsToApply
        );
        System.assertEquals(2, Logger.logs.size(), 'Expected two logs: postapplication and itemsToApply');
    }

    @IsTest
    public static void testCheckAndSetOutstandingItemWithApplyItem() {
        String outstandingItemJSON =
            '{"Project":"SSS-000021","ParentId":"2c92c0fb6daab15c016dae43cee5361d","IsInvoiceItem":false,"Id":"2c92c0fb6daab15c016dae43cefd361e","EffectiveDate":"2019-06-15T00:00:00.000Z","Client":"BW-0021776","AmountToApply":100,"AmountOutstanding":9200.00000}';
        ZuoraOutstandingItemsService.OutstandingItem oi =
            (ZuoraOutstandingItemsService.OutstandingItem) JSON.deserialize(outstandingItemJSON, ZuoraOutstandingItemsService.OutstandingItem.class);
        List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply = new List<ZuoraOutstandingItemsService.OutstandingItem>();

        Decimal newAmountToApply = 90;
        ZuoraHistoricalCustomApplicationService.PaymentApplication pa = new ZuoraHistoricalCustomApplicationService.PaymentApplication();
        pa.type = 'ApplyItem';
        pa.effectiveDate = Date.newInstance(2019, 6, 15);
        pa.projectName = 'SSS-000021';
        pa.clientName = 'BW-0021776';
        pa.isInvoice = false;
        pa.startingAmount = 9200;
        pa.applicationAmount = newAmountToApply;
        pa.expectedAmount = 9200;
        pa.createApplication = true;
        List<ZuoraHistoricalCustomApplicationService.PaymentApplication> paList = new List<ZuoraHistoricalCustomApplicationService.PaymentApplication>{pa};

        customApplicationService.checkAndSetOutstandingItem(oi, paList, itemsToApply);
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
        ZuoraHistoricalCustomApplicationService.PaymentApplication pa = new ZuoraHistoricalCustomApplicationService.PaymentApplication();
        pa.type = 'ApplyItem';
        pa.effectiveDate = Date.newInstance(2019, 6, 15);
        pa.projectName = 'SSS-000021';
        pa.clientName = 'BW-0021776';
        pa.isInvoice = false;
        pa.startingAmount = 9200;
        pa.applicationAmount = newAmountToApply;
        pa.expectedAmount = 9200;
        pa.createApplication = false;
        List<ZuoraHistoricalCustomApplicationService.PaymentApplication> paList = new List<ZuoraHistoricalCustomApplicationService.PaymentApplication>{pa};

        customApplicationService.checkAndSetOutstandingItem(oi, paList, null);
        System.assertEquals(9200 - newAmountToApply, oi.AmountOutstanding, 'Should have updated amount to apply since project and date are the same');

        System.assertEquals(null, Logger.logs, 'Starting with no error logs');
        pa.expectedAmount = 100;
        customApplicationService.checkAndSetOutstandingItem(oi, paList, null);
        System.assertEquals(1, Logger.logs.size());
        System.assertEquals(1, Logger.logs.values().size(), 'Expected a failure because the amount to apply wasn\'t expected');
    }

    @IsTest
    public static void testCheckAndSetApplyItem() {
        String outstandingItemJSON =
            '{"Project":"SSS-000021","ParentId":"2c92c0fb6daab15c016dae43cee5361d","IsInvoiceItem":false,"Id":"2c92c0fb6daab15c016dae43cefd361e","EffectiveDate":"2019-06-15T00:00:00.000Z","Client":"BW-0021776","AmountToApply":100,"AmountOutstanding":9200.00000}';
        ZuoraOutstandingItemsService.OutstandingItem oi =
            (ZuoraOutstandingItemsService.OutstandingItem) JSON.deserialize(outstandingItemJSON, ZuoraOutstandingItemsService.OutstandingItem.class);
        Decimal newAmountToApply = 90;

        ZuoraHistoricalCustomApplicationService.PaymentApplication pa = new ZuoraHistoricalCustomApplicationService.PaymentApplication();
        pa.type = 'ApplyItem';
        pa.effectiveDate = Date.newInstance(2019, 6, 15);
        pa.projectName = 'SSS-000021';
        pa.clientName = 'BW-0021776';
        pa.isInvoice = false;
        pa.applicationAmount = newAmountToApply;
        pa.expectedAmount = 100;
        List<ZuoraHistoricalCustomApplicationService.PaymentApplication> paList = new List<ZuoraHistoricalCustomApplicationService.PaymentApplication>{pa};
        customApplicationService.checkAndSetApplyItem(oi, paList);
        System.assertEquals(newAmountToApply, oi.AmountToApply, 'Should have updated amount to apply since project and date are the same');

        System.assertEquals(null, Logger.logs, 'Starting with no error logs');
        customApplicationService.checkAndSetApplyItem(oi, paList);
        System.assertEquals(1, Logger.logs.size());
        System.assertEquals(1, Logger.logs.values().size(), 'Expected a failure because the amount to apply wasn\'t expected');
    }

    /*************
     *** MOCKS ***
     *************/

    public class MockStaticResourceSelector implements StubProvider {
        public MockStaticResourceSelector(){}
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            StaticResource sr = new StaticResource(
                Id = Util.getFakeId(StaticResource.SObjectType),
                Body = Blob.valueOf('Customer,TransactionId,Type,EffectiveDate,ProjectName,ClientName,StartingAmount,ApplicationAmount,ExpectedAmount,CreateApplication\n' +
                    'Stelios,a210a00000GkIXgAAN,OutstandingItem,4/18/2017,SSS-000019,BW-0021776,203.35,181.19,0,TRUE,FALSE\n' +
                    'WFC,a210a00000a4YVDAA2,ProjectMapping,1/20/2018,SSS-000018,BW-0021776,,,,TRUE,FALSE')
            );
            return sr;
        }
    }
}