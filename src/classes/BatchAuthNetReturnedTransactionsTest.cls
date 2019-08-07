@IsTest
private class BatchAuthNetReturnedTransactionsTest {
    @IsTest
    static void testBatch() {
        Test.startTest();

        List<AuthNetAPI.MerchantAuthentication> merchantNameAndKeys = new List<AuthNetAPI.MerchantAuthentication>();
        AuthNetAPI.MerchantAuthentication m = new AuthNetAPI.MerchantAuthentication();
        m.Zname = '6BTjZjj34N';
        m.transactionKey = '972e285SyApQ3V7y';
        merchantNameAndKeys.add(m);

        BatchAuthNetReturnedTransactions batchAuthNet = new BatchAuthNetReturnedTransactions(merchantNameAndKeys);
        Test.setMock(System.HttpCalloutMock.class, new AuthNetGetSettledBatchMock());
        batchAuthNet.init();

        //Change the batchIds so that only one batch will be processed in the test
        batchAuthNet.batchIds = new List<String>{
            batchAuthNet.batchIds[0]
        };
        System.assertEquals(batchAuthNet.batchIds.size(), 1);

        Test.setMock(System.HttpCalloutMock.class, new AuthNetGetTransactionMock());
        Database.executeBatch(batchAuthNet, 1);
        Test.stopTest();

    }

    @IsTest
    static void testException() {
        Boolean exceptionThrown = false;
        try {
            BatchAuthNetReturnedTransactions batchAuthNet = new BatchAuthNetReturnedTransactions(null);
        } catch (Util.BWException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Check if exception got thrown');
    }

    @IsTest
    static void testAuthNetGetSettledBatchListRequest() {
        Test.setMock(System.HttpCalloutMock.class, new AuthNetGetSettledBatchMock());
        List<String> batchIdList = AuthNetService.getSettledBatchListRequest('merchantName', 'transKey', Datetime.now().addDays(-30), Datetime.now());
        System.assertEquals(batchIdList.size(), 1);
    }
    @IsTest
    static void testAuthNetGetReturnedTransactions() {
        Test.setMock(System.HttpCalloutMock.class, new AuthNetGetTransactionMock());
        List<AuthNetAPI.Transactions> allTransactionList = AuthNetService.getTransactionListRequest('merchantName', 'transKey', 'batchId', '1', '1000');
        System.assertEquals(4, allTransactionList.size());

        System.assertNotEquals(0, allTransactionList[0].settleAmount);
        System.assertNotEquals(null, allTransactionList[0].transId);

        List<AuthNetAPI.Transactions> returnedTransctionList = AuthNetService.getReturnedTransactions(allTransactionList);
        System.assertEquals(1, returnedTransctionList.size());
    }
}