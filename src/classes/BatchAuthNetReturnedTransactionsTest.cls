@IsTest
private class BatchAuthNetReturnedTransactionsTest {
    @IsTest
    public static void testFindReturnedItems() {
        String batchId = 'HasReturnedItems';
        BatchAuthNetReturnedTransactions batchAuthNetReturnedTransactions = getBatchAuthNetReturnedTransactions(batchId);

        Test.startTest();
        Integer numTransactions = 10;
        Test.setMock(System.HttpCalloutMock.class, new TransactionMock(numTransactions));
        batchAuthNetReturnedTransactions.findReturnedItems(batchId, 1);
        System.assertEquals(numTransactions, batchAuthNetReturnedTransactions.allReturnedTransactionList.size());
        Test.stopTest();
    }

    @IsTest
    public static void testFindReturnedItemsMultiplePages() {
        String batchId = 'NoReturnedItems';
        BatchAuthNetReturnedTransactions authNetReturnedTransactions = getBatchAuthNetReturnedTransactions(batchId);

        BatchAuthNetReturnedTransactions.pagingLimit = 5;
        Integer numTransactions = BatchAuthNetReturnedTransactions.pagingLimit*3;

        Test.startTest();
        Test.setMock(System.HttpCalloutMock.class, new TransactionMock(numTransactions));
        authNetReturnedTransactions.findReturnedItems(batchId, 1);
        Test.stopTest();

        System.assertEquals(0, authNetReturnedTransactions.allReturnedTransactionList.size());
        System.assertEquals(4, AuthNetHelper.endpointsCalled.size(), 'Expected 3 batches of 5, and 1 batch of 0');
    }

    @IsTest
    public static void testFindReturnedItemsNoPages() {
        String batchId = 'NoReturnedItems';
        BatchAuthNetReturnedTransactions authNetReturnedTransactions = getBatchAuthNetReturnedTransactions(batchId);

        Integer numTransactions = 0;

        Test.startTest();
        Test.setMock(System.HttpCalloutMock.class, new TransactionMock(numTransactions));
        authNetReturnedTransactions.findReturnedItems(batchId, 1);
        Test.stopTest();

        System.assertEquals(0, authNetReturnedTransactions.allReturnedTransactionList.size());
        System.assertEquals(1, AuthNetHelper.endpointsCalled.size());
    }

    @IsTest
    public static void testStartReturnedItemsSearchSuccess() {
        String batchId = 'HasReturnedItems';
        BatchAuthNetReturnedTransactions batchAuthNetReturnedTransactions = getBatchAuthNetReturnedTransactions(batchId);

        Test.startTest();
        Integer numTransactions = 10;
        Test.setMock(System.HttpCalloutMock.class, new TransactionMock(numTransactions));
        batchAuthNetReturnedTransactions.startReturnedItemSearch(new List<String>{batchId});
        Test.stopTest();

        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Class__c = 'BatchAuthNetReturnedTransactions'
            AND Method__c = 'Returned Transaction Results'
        ];
        System.assertEquals(2, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('40034118357'));
    }

    @IsTest
    public static void testStartReturnedItemsSearchChainedAsync() {
        String batchId = 'HasReturnedItems';
        BatchAuthNetReturnedTransactions authNetReturnedTransactions = getBatchAuthNetReturnedTransactions(batchId);
        // This would have the API return one result at a time
        BatchAuthNetReturnedTransactions.pagingLimit = 1;

        Test.startTest();
        // And 101 transactions would put us over the callout limit, requiring a chained queueable
        Integer numTransactions = 101;
        Test.setMock(System.HttpCalloutMock.class, new TransactionMock(numTransactions));
        authNetReturnedTransactions.startReturnedItemSearch(new List<String>{batchId});
        Test.stopTest();

        System.assertNotEquals(null, authNetReturnedTransactions.nextAsyncJob);
        System.assertEquals(100, authNetReturnedTransactions.nextAsyncJob.allReturnedTransactionList.size());
        System.assertEquals(1, authNetReturnedTransactions.nextAsyncJob.batchIds.size());
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Class__c = 'BatchAuthNetReturnedTransactions'
            AND Method__c = 'Returned Transaction Results'
        ];
        System.assertEquals(0, errorLogs.size());
    }

    @IsTest
    public static void testStartReturnedItemsSearchException() {
        String batchId = 'Exception';
        BatchAuthNetReturnedTransactions batchAuthNetReturnedTransactions = getBatchAuthNetReturnedTransactions(batchId);

        Test.startTest();
        Integer numTransactions = 10;
        Test.setMock(System.HttpCalloutMock.class, new TransactionMock(numTransactions));
        batchAuthNetReturnedTransactions.startReturnedItemSearch(new List<String>{batchId});
        Test.stopTest();

        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Class__c = 'BatchAuthNetReturnedTransactions'
            AND Method__c = 'startReturnedItemSearch'
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Test Exception'));

    }

    @IsTest
    public static void testInit() {
        List<AuthNetAPI.MerchantAuthentication> merchantNameAndKeys = new List<AuthNetAPI.MerchantAuthentication>();
        AuthNetAPI.MerchantAuthentication m = new AuthNetAPI.MerchantAuthentication();
        m.Zname = '6BTjZjj34N';
        m.transactionKey = '972e285SyApQ3V7y';
        merchantNameAndKeys.add(m);

        BatchAuthNetReturnedTransactions batchAuthNet = new BatchAuthNetReturnedTransactions();
        Test.startTest();
        Test.setMock(System.HttpCalloutMock.class, new TransactionMock(1));
        batchAuthNet.init(merchantNameAndKeys);
        Test.stopTest();
        System.assertEquals(4, AuthNetHelper.endpointsCalled.size());
        System.assertEquals(1, batchAuthNet.batchIdToMerchantAuthMap.size());
    }

    @IsTest
    public static void testSchedule() {
        AuthNetScheduler authNetScheduler = new AuthNetScheduler();
        authNetScheduler.gatewaySelector = (GatewaySelector) Test.createStub(GatewaySelector.class, new MockGatewaySelector());
        Test.startTest();
        Test.setMock(System.HttpCalloutMock.class, new TransactionMock(1));
        authNetScheduler.execute(null);
        Test.stopTest();
        System.assertEquals(8, AuthNetHelper.endpointsCalled.size(),
            'Expected four callouts to get batches in init(), each of which return a batch requiring a callout to get transactions');
    }

    private static BatchAuthNetReturnedTransactions getBatchAuthNetReturnedTransactions(String batchId) {
        BatchAuthNetReturnedTransactions batchAuthNetReturnedTransactions = new BatchAuthNetReturnedTransactions();
        Map<String, AuthNetAPI.MerchantAuthentication> batchIdToMerchAuthMap = new Map<String, AuthNetAPI.MerchantAuthentication>();
        AuthNetAPI.MerchantAuthentication merchAuth = new AuthNetAPI.MerchantAuthentication();
        merchAuth.Zname = 'Name';
        merchAuth.transactionKey = 'Key';
        batchIdToMerchAuthMap.put(batchId, merchAuth);
        batchAuthNetReturnedTransactions.batchIdToMerchantAuthMap = batchIdToMerchAuthMap;
        return batchAuthNetReturnedTransactions;
    }

    @IsTest
    public static void testGatewaySelector() {
        GatewaySelector gatewaySelector = new GatewaySelector();
        System.assertEquals(0, gatewaySelector.getGatewaysForAuthentication().size());
    }

    /*************
      *** MOCKS ***
      *************/

    public class TransactionMock implements HttpCalloutMock {
        public Integer numTransactions = 0;

        public TransactionMock(Integer numTransactions) {
            this.numTransactions = numTransactions;
        }

        public HttpResponse respond(HttpRequest req) {
            String responseBody;
            if (req.getBody().contains('getSettledBatchListRequest')) {
                responseBody = '{"batchList":[' +
                    '{"batchId": "HasReturnedItems", ' +
                    '"settlementTimeUTC": "2019-07-03T15:21:40Z", ' +
                    '"settlementTimeLocal": "2019-07-03T08:21:40", ' +
                    '"settlementState": "settledSuccessfully", ' +
                    '"paymentMethod": "eCheck" } ], ' +
                    '"messages": { "resultCode": "Ok", "message": [ { "code": "I00001", "text": "Successful." } ] } }';
            } else {
                Map<String, Object> requestMap = (Map<String, Object>) System.JSON.deserializeUntyped(req.getBody());
                Map<String, Object> transactionListMap = (Map<String, Object>) requestMap.get('getTransactionListRequest');
                Map<String, Object> pagingMap = (Map<String, Object>) transactionListMap.get('paging');
                Integer offset = Integer.valueOf((String) pagingMap.get('offset'));
                Integer pagingLimit = Integer.valueOf((String) pagingMap.get('limit'));
                Integer numAlreadyReturned = Math.max(0, (offset - 1) * pagingLimit);
                Integer numLeft = numTransactions - numAlreadyReturned;
                Integer transactionsToReturn = Math.min(numLeft, pagingLimit);

                if (transactionsToReturn == 0) {
                    responseBody = '{' +
                        '"totalNumInResultSet":0,' +
                        '"messages":{"resultCode":"Ok","message":[{"code":"I00004","text":"No records found."}]}}';
                } else if (req.getBody().contains('HasReturnedItems')) {
                    String transactionList = '';
                    for (Integer i = 0; i < transactionsToReturn; i++) {
                        transactionList += getTransaction(true) + ',';
                    }
                    responseBody = '{ "transactions": ' +
                        '[ ' + transactionList.substring(0, transactionList.length() - 1) + '], ' +
                        '"totalNumInResultSet": ' + transactionsToReturn + ', ' +
                        '"messages": { "resultCode": "Ok", "message": [ { "code": "I00001", "text": "Successful." } ] } }';
                } else if (req.getBody().contains('NoReturnedItems')) {
                    String transactionList = '';
                    for (Integer i = 0; i < transactionsToReturn; i++) {
                        transactionList += getTransaction(false) + ',';
                    }
                    responseBody = '{ "transactions": ' +
                        '[ ' + transactionList.substring(0, transactionList.length() - 1) + '], ' +
                        '"totalNumInResultSet": ' + transactionsToReturn + ', ' +
                        '"messages": { "resultCode": "Ok", "message": [ { "code": "I00001", "text": "Successful." } ] } }';
                } else if (req.getBody().contains('Exception')) {
                    throw new CalloutException('Test Exception');
                }
            }
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }

        private String getTransaction(Boolean hasReturnedItems) {
            return '{ "transId": "40034118357", ' +
                '"submitTimeUTC": "2019-07-02T14:19:03Z", ' +
                '"submitTimeLocal": "2019-07-02T07:19:03", ' +
                '"transactionStatus": "settledSuccessfully", ' +
                '"accountType": "eCheck", ' +
                '"accountNumber": "XXXX1312", ' +
                '"settleAmount": 12.04, ' +
                '"hasReturnedItems": '+hasReturnedItems+'}';

        }
    }

    public class MockGatewaySelector extends MockProvider {
        public MockGatewaySelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getGatewaysForAuthentication' {
                    ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
                        Id = Util.getFakeId(ChargentBase__Gateway__c.SObjectType),
                        ChargentBase__Merchant_ID__c = 'foo',
                        ChargentBase__Security_Key__c = 'bar'
                    );
                    return new List<ChargentBase__Gateway__c>{gateway};
                }
            }
            return null;
        }
    }
}