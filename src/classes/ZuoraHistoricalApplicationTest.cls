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