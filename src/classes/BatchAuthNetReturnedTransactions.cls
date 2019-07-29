global class BatchAuthNetReturnedTransactions implements
                Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts {

    public List<String> batchIds;

    public List<AuthNetAPI.Transactions> allReturnedTransactionList;
    public List<AuthNetAPI.MerchantAuthentication> merchantAuthList;
    public Map<String, AuthNetAPI.MerchantAuthentication> batchId_MerchNameTransactionKey;

    public BatchAuthNetReturnedTransactions(List<AuthNetAPI.MerchantAuthentication> merchantNameAndKeys) {
        this.batchIds = new List<String>();
        this.batchId_MerchNameTransactionKey = new Map<String, AuthNetAPI.MerchantAuthentication>();
        this.merchantAuthList = new List<AuthNetAPI.MerchantAuthentication>();

        if (merchantNameAndKeys != null && merchantNameAndKeys.size() <= 25) {
            merchantAuthList.addAll(merchantNameAndKeys);
        } else {
            Logger.logNow('BatchAuthNetReturnedTransactions', 'start', 'Merchant ID and Transaction Keys should be less than 25.', Logger.ERROR);
            throw new Util.BWException('Merchant ID and Transaction Keys should be less than 25.');
        }
    }
    public void init() {
        this.allReturnedTransactionList = new List<AuthNetAPI.Transactions>();
        Datetime today = System.now();

        //Get batch IDs for every Merchant
        List<String> batchIdsTemp = new List<String>();
        for (AuthNetAPI.MerchantAuthentication merchAuth : merchantAuthList) {
            //Get Merchant batch IDs for the past 120 days
            try {
                batchIdsTemp.addAll(AuthNetService.getSettledBatchListRequest(merchAuth.name, merchAuth.transactionKey, today - 30, today));
                batchIdsTemp.addAll(AuthNetService.getSettledBatchListRequest(merchAuth.name, merchAuth.transactionKey, today - 60, today - 30));
                batchIdsTemp.addAll(AuthNetService.getSettledBatchListRequest(merchAuth.name, merchAuth.transactionKey, today - 90, today - 60));
                batchIdsTemp.addAll(AuthNetService.getSettledBatchListRequest(merchAuth.name, merchAuth.transactionKey, today - 120, today - 90));
            } catch (Exception e) {
                Logger.logNow('BatchAuthNetReturnedTransactions', 'start',
                        'Authorize.net getSettledBatchListRequest Error ' + e.getMessage() + '\n' + e.getStackTraceString(),
                        Logger.ERROR);
            }

            if (!batchIdsTemp.isEmpty()) {
                for (String batchId : batchIdsTemp) {
                    batchId_MerchNameTransactionKey.put(batchId, merchAuth);
                }
                this.batchIds.addAll(batchIdsTemp);
            }
        }
        Logger.flushLogs();
    }

    global Iterable<String> start(Database.BatchableContext bc) {

        return this.batchIds;
    }

    global void execute(Database.BatchableContext bc, List<String> batchIdList) {
        if (batchIdList.size() > 1) {
            throw new Util.BWException('Batch size should be 1.');
        }
        try {
            executeInternal(batchIdList[0]);
        } catch (Exception e) {
            Logger.logNow('BatchAuthNetReturnedTransactions', 'execute',
                    'Authorize.net getTransactionListRequest Error ' + e.getMessage() + '\n' + e.getStackTraceString(),
                    Logger.ERROR);
        }
        Logger.flushLogs();
    }

    private void executeInternal(String batchId) {

        Boolean getMoreTransactions = true;
        Integer offset = 1;
        Integer pagingLimit = 1000;

        AuthNetAPI.MerchantAuthentication merchAuth = batchId_MerchNameTransactionKey.get(batchId);
        if (merchAuth == null) {
            throw new Util.BWException('No Merchant Authentication Found.');
        }

        while (getMoreTransactions) {
            List<AuthNetAPI.Transactions> allTransactionList = new List<AuthNetAPI.Transactions>();
            //This one should return all transactions and then filter here.
            allTransactionList = AuthNetService.getTransactionListRequest(
                    merchAuth.name,
                    merchAuth.transactionKey,
                    batchId,
                    String.valueOf(offset),
                    String.valueOf(pagingLimit)
            );

            List<AuthNetAPI.Transactions> returnedTransactionForBatchList = AuthNetService.getReturnedTransactions(allTransactionList);
            if (returnedTransactionForBatchList.size() > 0) {
                this.allReturnedTransactionList.addAll(returnedTransactionForBatchList);
            }
            if (allTransactionList.isEmpty()) {
                getMoreTransactions = false;
            }
            offset++;
        }
    }

    global void finish(Database.BatchableContext bc) {
        //TODO - Take action on the list of transactions
        Logger.logNow(
                'BatchAuthNetReturnedTransactions',
                'finish',
                'Returned Transaction List:: ' + allReturnedTransactionList,
                Logger.INFO
        );
    }
}