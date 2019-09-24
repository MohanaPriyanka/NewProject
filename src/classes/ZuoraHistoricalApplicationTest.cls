/*************************************************************************************
 * Created By: peteryao on 2019-07-30  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraHistoricalApplicationTest {
    private static ZuoraHistoricalBatchApply batchApply = new ZuoraHistoricalBatchApply();

    public static void useMocks(Integer numberOfTransactions) {
        batchApply.transactionSelector = (ChargentTransactionSelector) Test.createStub(ChargentTransactionSelector.class, new MockChargentTransactionSelector(numberOfTransactions));
    }

    @IsTest
    public static void testBatch() {
        Id propertyAccountId =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
        Account account = new Account(
            Name = 'Test Account',
            Zuora_Id__c = '12345',
            RecordTypeId = propertyAccountId
        );
        insert account;

        useMocks(1);
        Test.startTest();
        batchApply.init();
        Database.executeBatch(batchApply, 1);
        Test.stopTest();

        System.assert(ZuoraAPIHelper.endpointsCalled.size() > 4,
            'Should be at least four callouts before queueing the outstanding items async service');

        System.assert(ZuoraAPIHelper.endpointsCalled[0].endpoint.contains('/v1/creditmemos?status=Posted'));

        ZuoraCreditMemoAllocationService.QueryResultCreditMemo queryResultCreditMemo =
            (ZuoraCreditMemoAllocationService.QueryResultCreditMemo) JSON.deserialize(
                ZuoraAPIHelper.cleanJSON(ZuoraAPIHelper.endpointsCalled[0].response),
                ZuoraCreditMemoAllocationService.QueryResultCreditMemo.class
            );
        Integer numberCreditMemos = queryResultCreditMemo.CreditMemos.size();
        for (Integer i = 0; i < numberCreditMemos; i++) {
            System.assert(ZuoraAPIHelper.endpointsCalled[1 + i].endpoint.contains('/v1/creditmemos'));
            System.assert(ZuoraAPIHelper.endpointsCalled[1 + i].endpoint.contains('/items'));
        }

        System.assert(ZuoraAPIHelper.endpointsCalled[numberCreditMemos + 1].endpoint.contains('/v1/action/query'));
        System.assert(ZuoraAPIHelper.endpointsCalled[numberCreditMemos + 1].jsonBody.contains('FROM Invoice'));
        System.assert(ZuoraAPIHelper.endpointsCalled[numberCreditMemos + 2].endpoint.contains('/v1/debitmemos?accountId'));
        System.assertNotEquals(null, ZuoraHistoricalBatchApply.asyncServiceEnqueued);
        System.assertEquals('ZuoraHistoricalApplicationService', ZuoraHistoricalBatchApply.asyncServiceEnqueued.processingParameter.processorClassName);
    }

    @IsTest
    public static void testNothingToApply() {
        Id propertyAccountId =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
        Account account = new Account(
            Name = 'Test Account',
            Zuora_Id__c = 'NOCREDITMEMOS',
            RecordTypeId = propertyAccountId
        );
        insert account;

        useMocks(0);
        Test.startTest();
        batchApply.init();
        Database.executeBatch(batchApply, 1);
        Test.stopTest();

        System.assertEquals(1, ZuoraAPIHelper.endpointsCalled.size(), 'Should have quit after finding no credit memos or transactions');
        System.assertEquals(null, ZuoraHistoricalBatchApply.asyncServiceEnqueued);
    }

    @IsTest
    public static void tooManyCreditMemos() {
        Id propertyAccountId =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
        Account account = new Account(
            Name = 'Test Account',
            Zuora_Id__c = 'LOTSACREDITMEMOS',
            RecordTypeId = propertyAccountId
        );
        insert account;

        useMocks(0);
        Test.startTest();
        batchApply.init();
        Database.executeBatch(batchApply, 1);
        Test.stopTest();

        System.assertEquals(1, ZuoraAPIHelper.endpointsCalled.size(), 'Should have quit after finding more than 40 credit memos');
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Found more than 40 credit memos'));
    }


    @IsTest
    public static void testChargentTransactionSelector() {
        ChargentTransactionSelector transactionSelector = new ChargentTransactionSelector();
        List<ChargentOrders__Transaction__c> transactions = transactionSelector.selectForZuoraHistory('');
        System.assertEquals(0, transactions.size());
    }

    @IsTest
    public static void testChargentTransactionSelectorInsufficientPermissions() {
        ChargentTransactionSelector transactionSelector = new ChargentTransactionSelector();
        User pmStandardUser = [SELECT Id FROM User WHERE Profile.Name = 'PM Force.com user' AND IsActive = TRUE LIMIT 1];
        Boolean exceptionCaught = false;
        // Since an PM User should never have permissions to query transactions
        System.runAs(pmStandardUser) {
            try {
                transactionSelector.selectForZuoraHistory('');
            } catch (Util.FatalBWException bwe) {
                exceptionCaught = true;
                System.assertEquals('Insufficient permissions', bwe.getMessage());
            }
        }
        System.assert(exceptionCaught);
    }

    @IsTest
    public static void testMockProvider() {
        MockChargentTransactionSelector transactionSelector = new MockChargentTransactionSelector(0);
        List<MockProvider.MethodCall> methodCalls = transactionSelector.getMethodCallsByName('selectForZuoraHistory');
        System.assertNotEquals(null, methodCalls);
    }

    @IsTest
    public static void testPaymentApplicationConversion() {
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems = ZuoraCreditMemoAllocationTest.testDataSetup();
        System.assertEquals(4, outstandingItems.size());

        for (ZuoraOutstandingItemsService.OutstandingItem outstandingItem : outstandingItems) {
            outstandingItem.AmountToApply = outstandingItem.AmountOutstanding;
        }
        ZuoraHistoricalApplicationService applicationService = new ZuoraHistoricalApplicationService();
        ZuoraAPI.ZuoraPaymentApplication paymentApplication =
            applicationService.outstandingItemToPaymentApplication(outstandingItems, System.now());

        System.assertEquals(1, paymentApplication.debitMemos.size());
        System.assertEquals(2, paymentApplication.debitMemos[0].items.size());
        System.assertEquals(2, paymentApplication.invoices.size());
        System.assertEquals(1, paymentApplication.invoices[0].items.size());
        System.assertEquals(1, paymentApplication.invoices[1].items.size());
    }

    @IsTest
    public static void testTransferHandling() {
        Test.startTest();
        String serializedProcessingParameter = '{"processorClassName":"ZuoraHistoricalApplicationService","payables":[{"payment":{"attributes":{"type":"ChargentOrders__Transaction__c","url":"/services/data/v46.0/sobjects/ChargentOrders__Transaction__c/a21S00000011rB7IAI"},"Id":"a21S00000011rB7IAI","ChargentOrders__Type__c":"Charge","ChargentOrders__Amount__c":1668.29,"ChargentOrders__Payment_Method__c":"Credit Card","ChargentOrders__Gateway_Date__c":"2019-06-20T04:20:19.000+0000","Client__c":"001S000000yKIOEIA4","ChargentOrders__Order__c":"a1yS0000000tv4wIAA","CreatedDate":"2019-06-20T04:20:19.000+0000","ChargentOrders__Gateway__c":"a1wS0000001GnhpIAC","Client__r":{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/001S000000yKIOEIA4"},"Id":"001S000000yKIOEIA4","Account_Number__c":"BW-0023170"},"ChargentOrders__Order__r":{"attributes":{"type":"ChargentOrders__ChargentOrder__c","url":"/services/data/v46.0/sobjects/ChargentOrders__ChargentOrder__c/a1yS0000000tv4wIAA"},"Id":"a1yS0000000tv4wIAA","Entity__c":"a1IS0000002MNiOMAW","Account_Bill__c":"a1nS0000000VmGJIA0","Entity__r":{"attributes":{"type":"Entity__c","url":"/services/data/v46.0/sobjects/Entity__c/a1IS0000002MNiOMAW"},"Id":"a1IS0000002MNiOMAW","Name":"Project B Main St"},"Account_Bill__r":{"attributes":{"type":"Account_Bill__c","url":"/services/data/v46.0/sobjects/Account_Bill__c/a1nS0000000VmGJIA0"},"Id":"a1nS0000000VmGJIA0","Parent_Account__c":"001S000000yKIbOIAW","Parent_Account__r":{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/001S000000yKIbOIAW"},"Id":"001S000000yKIbOIAW","Zuora_Id__c":"2c92c0f86ae3a4ad016ae5e247886605"}}}}},{"payment":{"attributes":{"type":"ChargentOrders__Transaction__c","url":"/services/data/v46.0/sobjects/ChargentOrders__Transaction__c/a21S000000125x4IAA"},"Id":"a21S000000125x4IAA","ChargentOrders__Type__c":"Transfer","ChargentOrders__Amount__c":7.62,"Client__c":"001S000000yKIOEIA4","ChargentOrders__Order__c":"a1yS0000000uDeyIAE","CreatedDate":"2019-08-13T02:52:54.000+0000","ChargentOrders__Gateway__c":"a1wS0000001GnhpIAC","Client__r":{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/001S000000yKIOEIA4"},"Id":"001S000000yKIOEIA4","Account_Number__c":"BW-0023170"},"ChargentOrders__Order__r":{"attributes":{"type":"ChargentOrders__ChargentOrder__c","url":"/services/data/v46.0/sobjects/ChargentOrders__ChargentOrder__c/a1yS0000000uDeyIAE"},"Id":"a1yS0000000uDeyIAE","Entity__c":"a1IS0000002MNiPMAW","Account_Bill__c":"a1nS0000000VmGJIA0","Entity__r":{"attributes":{"type":"Entity__c","url":"/services/data/v46.0/sobjects/Entity__c/a1IS0000002MNiPMAW"},"Id":"a1IS0000002MNiPMAW","Name":"Project B Main St"},"Account_Bill__r":{"attributes":{"type":"Account_Bill__c","url":"/services/data/v46.0/sobjects/Account_Bill__c/a1nS0000000VmGJIA0"},"Id":"a1nS0000000VmGJIA0","Parent_Account__c":"001S000000yKIbOIAW","Parent_Account__r":{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/001S000000yKIbOIAW"},"Id":"001S000000yKIbOIAW","Zuora_Id__c":"2c92c0f96c8afb5d016c8c5b4d4c7b6e"}}}},"payableDate":"2019-08-13T02:52:54.000Z","creditMemo":null},{"payment":{"attributes":{"type":"ChargentOrders__Transaction__c","url":"/services/data/v46.0/sobjects/ChargentOrders__Transaction__c/a21S000000125x9IAA"},"Id":"a21S000000125x9IAA","ChargentOrders__Type__c":"Transfer","ChargentOrders__Amount__c":-7.62,"Client__c":"001S000000yKIOEIA4","ChargentOrders__Order__c":"a1yS0000000uDf3IAE","CreatedDate":"2019-08-13T02:54:13.000+0000","ChargentOrders__Gateway__c":"a1wS0000001GnhpIAC","Client__r":{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/001S000000yKIOEIA4"},"Id":"001S000000yKIOEIA4","Account_Number__c":"BW-0023170"},"ChargentOrders__Order__r":{"attributes":{"type":"ChargentOrders__ChargentOrder__c","url":"/services/data/v46.0/sobjects/ChargentOrders__ChargentOrder__c/a1yS0000000uDf3IAE"},"Id":"a1yS0000000uDf3IAE","Entity__c":"a1IS0000002MNiOMAW","Account_Bill__c":"a1nS0000000VmGJIA0","Entity__r":{"attributes":{"type":"Entity__c","url":"/services/data/v46.0/sobjects/Entity__c/a1IS0000002MNiOMAW"},"Id":"a1IS0000002MNiOMAW","Name":"Project A Oak Road"},"Account_Bill__r":{"attributes":{"type":"Account_Bill__c","url":"/services/data/v46.0/sobjects/Account_Bill__c/a1nS0000000VmGJIA0"},"Id":"a1nS0000000VmGJIA0","Parent_Account__c":"001S000000yKIbOIAW","Parent_Account__r":{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/001S000000yKIbOIAW"},"Id":"001S000000yKIbOIAW","Zuora_Id__c":"2c92c0f96c8afb5d016c8c5b4d4c7b6e"}}}},"payableDate":"2019-08-13T02:54:13.000Z","creditMemo":null}],"creditMemo":null,"allOutstandingItems":[{"Project":"SSS-000023","ParentId":"2c92c0946c8aedff016c8c5cb0016fe0","IsInvoiceItem":true,"Id":"2c92c0946c8aedff016c8c5cb00f6fe3","EffectiveDate":"2019-03-13T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":8887.230000000},{"Project":"SSS-000023","ParentId":"2c92c0946c8aedff016c8c5cb0016fe0","IsInvoiceItem":true,"Id":"2c92c0946c8aedff016c8c5cb00f6fe2","EffectiveDate":"2019-03-13T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":357.790000000},{"Project":"SSS-000023","ParentId":"2c92c09a6c8af6fd016c8c5d99c05078","IsInvoiceItem":true,"Id":"2c92c09a6c8af6fd016c8c5d99ca507c","EffectiveDate":"2019-06-13T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":105.060000000},{"Project":"SSS-000023","ParentId":"2c92c09a6c8af6fd016c8c5d99c05078","IsInvoiceItem":true,"Id":"2c92c09a6c8af6fd016c8c5d99c9507b","EffectiveDate":"2019-06-13T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":105.060000000},{"Project":"SSS-000023","ParentId":"2c92c09a6c8af6fd016c8c5d99c05078","IsInvoiceItem":true,"Id":"2c92c09a6c8af6fd016c8c5d99c9507a","EffectiveDate":"2019-06-13T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":105.060000000},{"Project":"SSS-000024","ParentId":"2c92c0fb6c8afb4e016c8c82f0e8442c","IsInvoiceItem":false,"Id":"2c92c0fb6c8afb4e016c8c82f0fd4434","EffectiveDate":"2019-08-12T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":0}]}';
        ZuoraOutstandingItemsService.ProcessingParameter processingParameter =
            (ZuoraOutstandingItemsService.ProcessingParameter) JSON.deserialize(serializedProcessingParameter, ZuoraOutstandingItemsService.ProcessingParameter.class);
        String serializedOutstandingItems = '[{"Project":"SSS-000023","ParentId":"2c92c0946c8aedff016c8c5cb0016fe0","IsInvoiceItem":true,"Id":"2c92c0946c8aedff016c8c5cb00f6fe3","EffectiveDate":"2019-03-13T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":8887.230000000},{"Project":"SSS-000023","ParentId":"2c92c0946c8aedff016c8c5cb0016fe0","IsInvoiceItem":true,"Id":"2c92c0946c8aedff016c8c5cb00f6fe2","EffectiveDate":"2019-03-13T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":357.790000000},{"Project":"SSS-000023","ParentId":"2c92c09a6c8af6fd016c8c5d99c05078","IsInvoiceItem":true,"Id":"2c92c09a6c8af6fd016c8c5d99ca507c","EffectiveDate":"2019-06-13T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":105.060000000},{"Project":"SSS-000023","ParentId":"2c92c09a6c8af6fd016c8c5d99c05078","IsInvoiceItem":true,"Id":"2c92c09a6c8af6fd016c8c5d99c9507b","EffectiveDate":"2019-06-13T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":105.060000000},{"Project":"SSS-000023","ParentId":"2c92c09a6c8af6fd016c8c5d99c05078","IsInvoiceItem":true,"Id":"2c92c09a6c8af6fd016c8c5d99c9507a","EffectiveDate":"2019-06-13T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":105.060000000},{"Project":"SSS-000024","ParentId":"2c92c0fb6c8afb4e016c8c82f0e8442c","IsInvoiceItem":false,"Id":"2c92c0fb6c8afb4e016c8c82f0fd4434","EffectiveDate":"2019-08-12T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":100}]';
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems =
            (List<ZuoraOutstandingItemsService.OutstandingItem>) JSON.deserialize(serializedOutstandingItems, List<ZuoraOutstandingItemsService.OutstandingItem>.class);
        ZuoraHistoricalApplicationService historicalApplicationService = new ZuoraHistoricalApplicationService();
        historicalApplicationService.projectUniqueIdToEntityMap = new Map<String, Id>{'SSS-000023'=>'a1IS0000002MNiOMAW', 'SSS-000024'=>'a1IS0000002MNiPMAW'};
        historicalApplicationService.processOutstandingItems(outstandingItems, processingParameter);
        Test.stopTest();

        Integer payments=0, debitmemos=0, creditmemos=0;
        for (ZuoraAPIHelper.EndpointCall endpointCall : ZuoraAPIHelper.endpointsCalled) {
            if (endpointCall.endpoint.contains('payments')) {
                payments++;
            } else if (endpointCall.endpoint.contains('debitmemos')) {
                debitmemos++;
            } else if (endpointCall.endpoint.contains('creditmemos')) {
                creditmemos++;
            }
        }
        System.assertEquals(2, payments, 'Expected 2 payment callouts: one to create and another to apply');
        System.assertEquals(3, debitmemos, 'Expected 3 debit memo callouts: create, post, and get');
        System.assertEquals(4, creditmemos, 'Expected 4 credit memo callouts: create, post, get, and apply');
    }

    @IsTest
    public static void testReturnHandling() {
        Test.startTest();
        String serializedProcessingParameter = '{"processorClassName":"ZuoraHistoricalApplicationService","payables":[{"payment":{"attributes":{"type":"ChargentOrders__Transaction__c","url":"/services/data/v46.0/sobjects/ChargentOrders__Transaction__c/a21S000000126HPIAY"},"Id":"a21S000000126HPIAY","ChargentOrders__Type__c":"Charge","ChargentOrders__Amount__c":-4.90,"ChargentOrders__Payment_Method__c":"Check","Client__c":"001S000000yKIOEIA4","ChargentOrders__Order__c":"a1yS0000000ty3gIAA","CreatedDate":"2019-09-02T13:20:50.000+0000","ChargentOrders__Response_Status__c":"Returned","ChargentOrders__Gateway__c":"a1wS0000001GnhpIAC","Client__r":{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/001S000000yKIOEIA4"},"Id":"001S000000yKIOEIA4","Account_Number__c":"BW-0023170"},"ChargentOrders__Order__r":{"attributes":{"type":"ChargentOrders__ChargentOrder__c","url":"/services/data/v46.0/sobjects/ChargentOrders__ChargentOrder__c/a1yS0000000ty3gIAA"},"Id":"a1yS0000000ty3gIAA","Entity__c":"a1IS0000002MNiPMAW","Account_Bill__c":"a1nS0000000VmGJIA0","Entity__r":{"attributes":{"type":"Entity__c","url":"/services/data/v46.0/sobjects/Entity__c/a1IS0000002MNiPMAW"},"Id":"a1IS0000002MNiPMAW","Name":"Project B Main St"},"Account_Bill__r":{"attributes":{"type":"Account_Bill__c","url":"/services/data/v46.0/sobjects/Account_Bill__c/a1nS0000000VmGJIA0"},"Id":"a1nS0000000VmGJIA0","Parent_Account__c":"001S000000yKIbOIAW","Parent_Account__r":{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/001S000000yKIbOIAW"},"Id":"001S000000yKIbOIAW","Zuora_Id__c":"2c92c0f96c8afb5d016c8c5b4d4c7b6e"}}}},"payableDate":"2019-09-02T13:20:50.000Z","creditMemo":null},{"payment":{"attributes":{"type":"ChargentOrders__Transaction__c","url":"/services/data/v46.0/sobjects/ChargentOrders__Transaction__c/a21S00000011v9uIAA"},"Id":"a21S00000011v9uIAA","ChargentOrders__Type__c":"Charge","ChargentOrders__Amount__c":4.90,"ChargentOrders__Payment_Method__c":"Check","ChargentOrders__Gateway_Date__c":"2019-07-02T13:20:50.000+0000","Client__c":"001S000000yKIOEIA4","ChargentOrders__Order__c":"a1yS0000000ty3gIAA","CreatedDate":"2019-07-02T13:20:50.000+0000","ChargentOrders__Response_Status__c":"Returned","ChargentOrders__Gateway__c":"a1wS0000001GnhpIAC","Client__r":{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/001S000000yKIOEIA4"},"Id":"001S000000yKIOEIA4","Account_Number__c":"BW-0023170"},"ChargentOrders__Order__r":{"attributes":{"type":"ChargentOrders__ChargentOrder__c","url":"/services/data/v46.0/sobjects/ChargentOrders__ChargentOrder__c/a1yS0000000ty3gIAA"},"Id":"a1yS0000000ty3gIAA","Entity__c":"a1IS0000002MNiPMAW","Account_Bill__c":"a1nS0000000VmGJIA0","Entity__r":{"attributes":{"type":"Entity__c","url":"/services/data/v46.0/sobjects/Entity__c/a1IS0000002MNiPMAW"},"Id":"a1IS0000002MNiPMAW","Name":"Project B Main St"},"Account_Bill__r":{"attributes":{"type":"Account_Bill__c","url":"/services/data/v46.0/sobjects/Account_Bill__c/a1nS0000000VmGJIA0"},"Id":"a1nS0000000VmGJIA0","Parent_Account__c":"001S000000yKIbOIAW","Parent_Account__r":{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/001S000000yKIbOIAW"},"Id":"001S000000yKIbOIAW","Zuora_Id__c":"2c92c0f96c8afb5d016c8c5b4d4c7b6e"}}}},"payableDate":"2019-07-02T13:20:50.000Z","creditMemo":null}],"creditMemo":null,"allOutstandingItems":[{"Project":"SSS-000023","ParentId":"2c92c0866c99be24016c9b3e984e1b59","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3e985f1b5c","EffectiveDate":"2019-03-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":117.710000000},{"Project":"SSS-000024","ParentId":"2c92c0866c99be24016c9b3e984e1b59","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3e98611b5f","EffectiveDate":"2019-03-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":120.210000000},{"Project":"SSS-000023","ParentId":"2c92c0866c99be24016c9b3e984e1b59","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3e985f1b5b","EffectiveDate":"2019-03-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":357.790000000},{"Project":"SSS-000024","ParentId":"2c92c0866c99be24016c9b3e984e1b59","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3e98601b5e","EffectiveDate":"2019-03-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":134.700000000},{"Project":"SSS-000023","ParentId":"2c92c0856c99b4d3016c9b3f0fa7237f","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f0fb72382","EffectiveDate":"2019-06-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":105.060000000},{"Project":"SSS-000024","ParentId":"2c92c0856c99b4d3016c9b3f0fa7237f","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f0fb82385","EffectiveDate":"2019-06-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":484.090000000},{"Project":"SSS-000023","ParentId":"2c92c0856c99b4d3016c9b3f0fa7237f","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f0fb62381","EffectiveDate":"2019-06-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":105.060000000},{"Project":"SSS-000024","ParentId":"2c92c0856c99b4d3016c9b3f0fa7237f","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f0fb72384","EffectiveDate":"2019-06-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":363.880000000},{"Project":"SSS-000023","ParentId":"2c92c0856c99b4d3016c9b3f0fa7237f","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f0fb62380","EffectiveDate":"2019-06-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":105.060000000},{"Project":"SSS-000024","ParentId":"2c92c0856c99b4d3016c9b3f0fa7237f","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f0fb72383","EffectiveDate":"2019-06-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":363.880000000},{"Project":"SSS-000024","ParentId":"2c92c0866c99be24016c9b3f56a71b78","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3f56ba1b7e","EffectiveDate":"2019-09-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":363.880000000},{"Project":"SSS-000024","ParentId":"2c92c0866c99be24016c9b3f56a71b78","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3f56b91b7d","EffectiveDate":"2019-09-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":363.880000000},{"Project":"SSS-000024","ParentId":"2c92c0866c99be24016c9b3f56a71b78","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3f56b91b7c","EffectiveDate":"2019-09-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":363.880000000},{"Project":"SSS-000024","ParentId":"2c92c0856c99b4d3016c9b3f7e1623b8","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f7e2423be","EffectiveDate":"2019-12-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":299.700000000},{"Project":"SSS-000024","ParentId":"2c92c0856c99b4d3016c9b3f7e1623b8","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f7e2423bd","EffectiveDate":"2019-12-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":299.700000000},{"Project":"SSS-000024","ParentId":"2c92c0856c99b4d3016c9b3f7e1623b8","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f7e2423bc","EffectiveDate":"2019-12-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":299.700000000}]}';
        ZuoraOutstandingItemsService.ProcessingParameter processingParameter =
            (ZuoraOutstandingItemsService.ProcessingParameter) JSON.deserialize(serializedProcessingParameter, ZuoraOutstandingItemsService.ProcessingParameter.class);
        String serializedOutstandingItems = '[{"Project":"SSS-000023","ParentId":"2c92c0866c99be24016c9b3e984e1b59","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3e985f1b5c","EffectiveDate":"2019-03-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":117.710000000},{"Project":"SSS-000024","ParentId":"2c92c0866c99be24016c9b3e984e1b59","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3e98611b5f","EffectiveDate":"2019-03-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":120.210000000},{"Project":"SSS-000023","ParentId":"2c92c0866c99be24016c9b3e984e1b59","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3e985f1b5b","EffectiveDate":"2019-03-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":357.790000000},{"Project":"SSS-000024","ParentId":"2c92c0866c99be24016c9b3e984e1b59","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3e98601b5e","EffectiveDate":"2019-03-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":134.700000000},{"Project":"SSS-000023","ParentId":"2c92c0856c99b4d3016c9b3f0fa7237f","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f0fb72382","EffectiveDate":"2019-06-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":105.060000000},{"Project":"SSS-000024","ParentId":"2c92c0856c99b4d3016c9b3f0fa7237f","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f0fb82385","EffectiveDate":"2019-06-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":484.090000000},{"Project":"SSS-000023","ParentId":"2c92c0856c99b4d3016c9b3f0fa7237f","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f0fb62381","EffectiveDate":"2019-06-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":105.060000000},{"Project":"SSS-000024","ParentId":"2c92c0856c99b4d3016c9b3f0fa7237f","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f0fb72384","EffectiveDate":"2019-06-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":363.880000000},{"Project":"SSS-000023","ParentId":"2c92c0856c99b4d3016c9b3f0fa7237f","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f0fb62380","EffectiveDate":"2019-06-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":105.060000000},{"Project":"SSS-000024","ParentId":"2c92c0856c99b4d3016c9b3f0fa7237f","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f0fb72383","EffectiveDate":"2019-06-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":363.880000000},{"Project":"SSS-000024","ParentId":"2c92c0866c99be24016c9b3f56a71b78","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3f56ba1b7e","EffectiveDate":"2019-09-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":363.880000000},{"Project":"SSS-000024","ParentId":"2c92c0866c99be24016c9b3f56a71b78","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3f56b91b7d","EffectiveDate":"2019-09-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":363.880000000},{"Project":"SSS-000024","ParentId":"2c92c0866c99be24016c9b3f56a71b78","IsInvoiceItem":true,"Id":"2c92c0866c99be24016c9b3f56b91b7c","EffectiveDate":"2019-09-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":363.880000000},{"Project":"SSS-000024","ParentId":"2c92c0856c99b4d3016c9b3f7e1623b8","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f7e2423be","EffectiveDate":"2019-12-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":299.700000000},{"Project":"SSS-000024","ParentId":"2c92c0856c99b4d3016c9b3f7e1623b8","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f7e2423bd","EffectiveDate":"2019-12-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":299.700000000},{"Project":"SSS-000024","ParentId":"2c92c0856c99b4d3016c9b3f7e1623b8","IsInvoiceItem":true,"Id":"2c92c0856c99b4d3016c9b3f7e2423bc","EffectiveDate":"2019-12-20T00:00:00.000Z","Client":"BW-0023170","AmountToApply":null,"AmountOutstanding":299.700000000}]';
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems =
            (List<ZuoraOutstandingItemsService.OutstandingItem>) JSON.deserialize(serializedOutstandingItems, List<ZuoraOutstandingItemsService.OutstandingItem>.class);
        ZuoraHistoricalApplicationService historicalApplicationService = new ZuoraHistoricalApplicationService();
        historicalApplicationService.projectUniqueIdToEntityMap = new Map<String, Id>{'SSS-000023'=>'a1IS0000002MNiOMAW', 'SSS-000024'=>'a1IS0000002MNiPMAW'};
        historicalApplicationService.processOutstandingItems(outstandingItems, processingParameter);
        Test.stopTest();

        Integer payments=0, debitmemos=0, creditmemos=0;
        for (ZuoraAPIHelper.EndpointCall endpointCall : ZuoraAPIHelper.endpointsCalled) {
            if (endpointCall.endpoint.contains('payments')) {
                payments++;
                if (endpointCall.endpoint.contains('apply')) {
                    ZuoraAPI.ZuoraPaymentApplication paymentApplication =
                        (ZuoraAPI.ZuoraPaymentApplication) JSON.deserialize(endpointCall.jsonBody, ZuoraAPI.ZuoraPaymentApplication.class);
                    System.assertEquals(0, paymentApplication.debitMemos.size());
                    System.assertEquals(1, paymentApplication.invoices.size());
                }
            } else if (endpointCall.endpoint.contains('debitmemos')) {
                debitmemos++;
            } else if (endpointCall.endpoint.contains('creditmemos')) {
                creditmemos++;
            }
        }
        System.assertEquals(2, payments, 'Expected 2 payment callouts: one to create and another to apply');
        System.assertEquals(3, debitmemos, 'Expected 3 debit memo callouts: create, post, and get');
        System.assertEquals(0, creditmemos, 'Expected 0 credit memo callouts');
    }

    @IsTest
    public static void testPayableSorting() {
        List<ZuoraHistoricalApplicationService.Payable> payables = new List<ZuoraHistoricalApplicationService.Payable>();

        ZuoraAPI.CreditMemoWithItem creditMemoWithItem = new ZuoraAPI.CreditMemoWithItem();
        ZuoraAPI.ZuoraCreditMemo creditMemo = new ZuoraAPI.ZuoraCreditMemo();
        creditMemo.creditMemoDate = Date.newInstance(2019, 1, 1);
        creditMemoWithItem.CreditMemo = creditMemo;
        payables.add(new ZuoraHistoricalApplicationService.Payable(creditMemoWithItem));

        ZuoraAPI.CreditMemoWithItem creditMemoWithItem2 = new ZuoraAPI.CreditMemoWithItem();
        ZuoraAPI.ZuoraCreditMemo creditMemo2 = new ZuoraAPI.ZuoraCreditMemo();
        creditMemo2.creditMemoDate = Date.newInstance(2018, 11, 1);
        creditMemoWithItem2.CreditMemo = creditMemo2;
        payables.add(new ZuoraHistoricalApplicationService.Payable(creditMemoWithItem2));

        ChargentOrders__Transaction__c payment = new ChargentOrders__Transaction__c(
            ChargentOrders__Type__c = 'Transfer',
            ChargentOrders__Amount__c = -1,
            CreatedDate = Datetime.newInstance(2019, 2, 1)
        );
        payables.add(new ZuoraHistoricalApplicationService.Payable(payment));
        ChargentOrders__Transaction__c payment2 = new ChargentOrders__Transaction__c(
            ChargentOrders__Type__c = 'Transfer',
            ChargentOrders__Amount__c = 2,
            CreatedDate = Datetime.newInstance(2019, 2, 1)
        );
        payables.add(new ZuoraHistoricalApplicationService.Payable(payment2));
        ChargentOrders__Transaction__c payment3 = new ChargentOrders__Transaction__c(
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Amount__c = 3,
            CreatedDate = Datetime.newInstance(2018, 12, 1)
        );
        payables.add(new ZuoraHistoricalApplicationService.Payable(payment3));
        ChargentOrders__Transaction__c payment4 = new ChargentOrders__Transaction__c(
            ChargentOrders__Type__c = 'Transfer',
            ChargentOrders__Amount__c = 1,
            CreatedDate = Datetime.newInstance(2019, 12, 1)
        );
        payables.add(new ZuoraHistoricalApplicationService.Payable(payment4));
        ChargentOrders__Transaction__c payment5 = new ChargentOrders__Transaction__c(
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Returned',
            ChargentOrders__Amount__c = 5,
            CreatedDate = Datetime.newInstance(2019, 11, 1)
        );
        payables.add(new ZuoraHistoricalApplicationService.Payable(payment5));
        ChargentOrders__Transaction__c payment6 = new ChargentOrders__Transaction__c(
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Returned',
            ChargentOrders__Amount__c = -5,
            CreatedDate = Datetime.newInstance(2019, 12, 1)
        );
        payables.add(new ZuoraHistoricalApplicationService.Payable(payment6));

        ChargentOrders__Transaction__c payment7 = new ChargentOrders__Transaction__c(
            ChargentOrders__Type__c = 'Refund',
            ChargentOrders__Response_Status__c = 'Approved',
            ChargentOrders__Amount__c = -191.23,
            CreatedDate = Datetime.newInstance(2018, 7, 27)
        );
        payables.add(new ZuoraHistoricalApplicationService.Payable(payment7));
        ChargentOrders__Transaction__c payment8 = new ChargentOrders__Transaction__c(
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved',
            ChargentOrders__Amount__c = 191.23,
            CreatedDate = Datetime.newInstance(2018, 7, 23)
        );
        payables.add(new ZuoraHistoricalApplicationService.Payable(payment8));

        payables.sort();

        // The negative parts of the transfers, refunds, and returns should go first
        System.assertEquals(Date.newInstance(2018,7,27), payables[0].payableDate.date());
        System.assertEquals(-191.23, payables[0].payment.ChargentOrders__Amount__c);
        System.assertEquals(Date.newInstance(2019,2,1), payables[1].payableDate.date());
        System.assertEquals(-1, payables[1].payment.ChargentOrders__Amount__c);
        System.assertEquals(Date.newInstance(2019,12,1), payables[2].payableDate.date());
        System.assertEquals(-5, payables[2].payment.ChargentOrders__Amount__c);
        // Then the payments and credit memos
        System.assertEquals(Date.newInstance(2018,7,23), payables[3].payableDate.date());
        System.assertEquals(191.23, payables[3].payment.ChargentOrders__Amount__c);
        System.assertEquals(Date.newInstance(2018,11,1), payables[4].payableDate);
        System.assertEquals(Date.newInstance(2018,12,1), payables[5].payableDate.date());
        System.assertEquals(3, payables[5].payment.ChargentOrders__Amount__c);
        System.assertEquals(Date.newInstance(2019,1,1), payables[6].payableDate);
        System.assertEquals(Date.newInstance(2019,2,1), payables[7].payableDate.date());
        System.assertEquals(2, payables[7].payment.ChargentOrders__Amount__c);
        System.assertEquals(Date.newInstance(2019,11,1), payables[8].payableDate.date());
        System.assertEquals(5, payables[8].payment.ChargentOrders__Amount__c);
        System.assertEquals(Date.newInstance(2019,12,1), payables[9].payableDate.date());
        System.assertEquals(1, payables[9].payment.ChargentOrders__Amount__c);
    }

    /*************
     *** MOCKS ***
     *************/

    public class MockChargentTransactionSelector extends MockProvider {
        private Integer numberOfTransactions;
        public MockChargentTransactionSelector(Integer numberOfTransactions) {
            this.numberOfTransactions = numberOfTransactions;
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectForZuoraHistory' {
                    List<ChargentOrders__Transaction__c> transactions = new List<ChargentOrders__Transaction__c>();
                    for (Integer i = 0; i < numberOfTransactions; i++) {
                        transactions.add(getTransaction());
                    }
                    return transactions;
                }
            }
            return null;
        }

        private ChargentOrders__Transaction__c getTransaction() {
            String serialized = '{' +
                '"attributes" : {' +
                '"type" : "ChargentOrders__Transaction__c",' +
                '"url" : "/services/data/v46.0/sobjects/ChargentOrders__Transaction__c/a21S00000011rB7IAI"' +
                '},' +
                '"Id" : "a21S00000011rB7IAI",' +
                '"ChargentOrders__Amount__c" : 1668.29,' +
                '"ChargentOrders__Order__c" : "a1yS0000000tv4wIAA",' +
                '"Client__c" : "001S000000yKIOEIA4",' +
                '"CreatedDate" : "2019-06-20T04:20:19.000+0000",' +
                '"ChargentOrders__Order__r" : {' +
                '"attributes" : {' +
                '"type" : "ChargentOrders__ChargentOrder__c",' +
                '"url" : "/services/data/v46.0/sobjects/ChargentOrders__ChargentOrder__c/a1yS0000000tv4wIAA"' +
                '},' +
                '"Id" : "a1yS0000000tv4wIAA",' +
                '"Entity__c" : "a1IS0000002MNiPMAW"' +
                '},' +
                '"Client__r" : {' +
                '"attributes" : {' +
                '"type" : "Account",' +
                '"url" : "/services/data/v46.0/sobjects/Account/001S000000yKIOEIA4"' +
                '},' +
                '"Id" : "001S000000yKIOEIA4",' +
                '"Account_Number__c" : "BW-0023170"' +
                '}' +
                '}';
            return (ChargentOrders__Transaction__c) JSON.deserialize(serialized, ChargentOrders__Transaction__c.class);
        }
    }
}