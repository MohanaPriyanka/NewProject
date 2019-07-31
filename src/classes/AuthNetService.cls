public with sharing class AuthNetService {

    public static List<String> getSettledBatchListRequest(String merchantName, String transKey, Datetime firstSettleDate, Datetime lastSettleDate) {

        AuthNetAPI req = new AuthNetAPI();
        req.getSettledBatchListRequest = new AuthNetAPI.GetSettledBatchListRequest();
        req.getSettledBatchListRequest.merchantAuthentication = new AuthNetAPI.MerchantAuthentication();
        req.getSettledBatchListRequest.merchantAuthentication.name = merchantName;
        req.getSettledBatchListRequest.merchantAuthentication.transactionKey = transKey;
        req.getSettledBatchListRequest.firstSettlementDate = firstSettleDate.format('yyyy-MM-dd\'T\'HH:mm:ssZ');
        req.getSettledBatchListRequest.lastSettlementDate = lastSettleDate.format('yyyy-MM-dd\'T\'HH:mm:ssZ');
        HttpResponse res = AuthNetHelper.callJsonEndpoint('POST', JSON.serialize(req), false);

        //BOM or "Byte Order Mark". It is usually received as the first few bytes of a file,
        //telling you how to interpret the encoding of the rest of the data. You can simply remove the character to continue.
        String resBody = res.getBody().trim().replace('\uFEFF', '');
        AuthNetAPI authNetSettledBatch = (AuthNetAPI) JSON.deserialize(resBody, AuthNetAPI.class);
        return getBatchIdList(authNetSettledBatch);
    }

    public static List<String> getBatchIdList(AuthNetAPI authNetSettledBatch) {
        List<String> batchIdList = new List<String>();
        if (authNetSettledBatch.batchList != null) {
            for (AuthNetAPI.BatchList batchList : authNetSettledBatch.batchList) {
                batchIdList.add(batchList.batchId);
            }
        }
        return batchIdList;
    }

    public static List<AuthNetAPI.Transactions> getTransactionListRequest(String merchantName, String transKey, String batchId, String pagingOffset, String pagingLimit) {
        AuthNetAPI req = new AuthNetAPI();
        req.getTransactionListRequest = new AuthNetAPI.GetTransactionListRequest();
        req.getTransactionListRequest.batchId = batchId;
        req.getTransactionListRequest.merchantAuthentication = new AuthNetAPI.MerchantAuthentication();
        req.getTransactionListRequest.merchantAuthentication.name = merchantName;
        req.getTransactionListRequest.merchantAuthentication.transactionKey = transKey;
        req.getTransactionListRequest.sorting = new AuthNetAPI.Sorting();
        req.getTransactionListRequest.sorting.orderBy = 'submitTimeUTC';
        req.getTransactionListRequest.sorting.orderDescending = 'true';
        req.getTransactionListRequest.paging = new AuthNetAPI.Paging();
        req.getTransactionListRequest.paging.limit_Z = pagingLimit;
        req.getTransactionListRequest.paging.offset = pagingOffset;

        HttpResponse res = AuthNetHelper.callJsonEndpoint('POST', JSON.serialize(req), false);

        String resBody = res.getBody().trim().replace('\uFEFF', '');
        AuthNetAPI authNetTransaction = (AuthNetAPI) JSON.deserialize(resBody, AuthNetAPI.class);
        return authNetTransaction.transactions;
    }

    public static List<AuthNetAPI.Transactions> getReturnedTransactions(List<AuthNetAPI.Transactions> allTransactions) {
        List<AuthNetAPI.Transactions> returnedTransactionList = new List<AuthNetAPI.Transactions>();
        for (AuthNetAPI.Transactions trans : allTransactions) {
            if (trans.hasReturnedItems) {
                returnedTransactionList.add(trans);
            }
        }
        return returnedTransactionList;
    }
}