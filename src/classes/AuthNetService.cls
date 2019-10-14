public with sharing class AuthNetService {

    public static List<String> getSettledBatchListRequest(String merchantName, String transKey, Datetime firstSettleDate, Datetime lastSettleDate) {

        AuthNetAPI req = new AuthNetAPI();
        req.getSettledBatchListRequest = new AuthNetAPI.GetSettledBatchListRequest();
        req.getSettledBatchListRequest.merchantAuthentication = new AuthNetAPI.MerchantAuthentication();
        req.getSettledBatchListRequest.merchantAuthentication.Zname = merchantName;
        req.getSettledBatchListRequest.merchantAuthentication.transactionKey = transKey;
        req.getSettledBatchListRequest.MAfirstSettlementDate = firstSettleDate.format('yyyy-MM-dd\'T\'HH:mm:ssZ');
        req.getSettledBatchListRequest.lastSettlementDate = lastSettleDate.format('yyyy-MM-dd\'T\'HH:mm:ssZ');
        HttpResponse res = AuthNetHelper.callJsonEndpoint('POST', JSON.serialize(req, true), false);

        //BOM or "Byte Order Mark". It is usually received as the first few bytes of a file,
        //telling you how to interpret the encoding of the rest of the data. You can simply remove the character to continue.
        String resBody = res.getBody().trim().replace('\uFEFF', '');
        AuthNetAPI authNetSettledBatch;
        try {
            authNetSettledBatch = (AuthNetAPI) JSON.deserialize(resBody, AuthNetAPI.class);
        } catch (JSONException jse) {
            throw new Util.FatalBWException(jse.getMessage() + '\n' + resBody);
        }

        return getBatchIdList(authNetSettledBatch);
    }

    public static List<String> getBatchIdList(AuthNetAPI authNetSettledBatch) {
        List<String> batchIdList = new List<String>();
        if (authNetSettledBatch.batchList != null) {
            for (AuthNetAPI.BatchList batchList : authNetSettledBatch.batchList) {
                if (batchList.paymentMethod == 'eCheck'){
                    batchIdList.add(batchList.batchId);
                }
            }
        }
        return batchIdList;
    }

    public static AuthNetAPI getTransactionListRequest(String merchantName, String transKey, String batchId, String pagingOffset, String pagingLimit) {
        AuthNetAPI req = new AuthNetAPI();
        req.getTransactionListRequest = new AuthNetAPI.GetTransactionListRequest();
        req.getTransactionListRequest.CbatchId = batchId;
        req.getTransactionListRequest.DmerchantAuthentication = new AuthNetAPI.MerchantAuthentication();
        req.getTransactionListRequest.DmerchantAuthentication.Zname = merchantName;
        req.getTransactionListRequest.DmerchantAuthentication.transactionKey = transKey;
        req.getTransactionListRequest.Bsorting = new AuthNetAPI.Sorting();
        req.getTransactionListRequest.Bsorting.ZorderBy = 'submitTimeUTC';
        req.getTransactionListRequest.Bsorting.orderDescending = 'true';
        req.getTransactionListRequest.Apaging = new AuthNetAPI.Paging();
        req.getTransactionListRequest.Apaging.Zlimit_Z = pagingLimit;
        req.getTransactionListRequest.Apaging.offset = pagingOffset;

        HttpResponse res = AuthNetHelper.callJsonEndpoint('POST', JSON.serialize(req, true), false);

        String resBody = res.getBody().trim().replace('\uFEFF', '');
        AuthNetAPI authNetTransaction;
        try {
            authNetTransaction = (AuthNetAPI) JSON.deserialize(resBody, AuthNetAPI.class);
        } catch (JSONException jse) {
            throw new Util.FatalBWException(jse.getMessage() + '\n' + resBody);
        }

        return authNetTransaction;
    }

    public static List<AuthNetAPI.Transactions> getReturnedTransactions(List<AuthNetAPI.Transactions> allTransactions) {
        List<AuthNetAPI.Transactions> returnedTransactionList = new List<AuthNetAPI.Transactions>();
        for (AuthNetAPI.Transactions trans : allTransactions) {
            if (trans.hasReturnedItems != null && trans.hasReturnedItems) {
                returnedTransactionList.add(trans);
            }
        }
        return returnedTransactionList;
    }
}