/*
 * Created by: Joey Chan
 * Tested by: BatchAuthNetReturnedTransactionsTest
 * Description: Looks through gateway transactions for returned items.
 *
 * This class is initialized by getting all of the Authorize Batch ids looking back 120 days across all gateways (up to 25).
 * This is ~150 batches at this time (Oct 2019). If it runs out of callouts or gets close to the callout time limit, it'll
 * queue itself with the remaining batches to query.
 */

public without sharing virtual class BatchAuthNetReturnedTransactions implements Database.AllowsCallouts, Queueable, ZuoraDataQueryService.Processor {
    public List<String> batchIds;
    public List<AuthNetAPI.Transactions> allReturnedTransactionList;
    public Map<String, AuthNetAPI.MerchantAuthentication> batchIdToMerchantAuthMap;
    @TestVisible
    private static Integer pagingLimit = 1000;
    @TestVisible
    private BatchAuthNetReturnedTransactions nextAsyncJob;
    private ChargentTransactionSelector transactionSelector = new ChargentTransactionSelector();
    private Integer totalTransactions;
    public static final String TOTAL_TRANSACTIONS_LABEL = 'TotalTransactionsFromAuthorize';

    public BatchAuthNetReturnedTransactions(List<String> batchIds, List<AuthNetAPI.Transactions> returnedTransactions,
        Map<String, AuthNetAPI.MerchantAuthentication> batchIdToMerchantAuthMap, Integer totalTransactions) {
        this.batchIds = batchIds;
        this.allReturnedTransactionList = returnedTransactions;
        this.batchIdToMerchantAuthMap = batchIdToMerchantAuthMap;
        this.totalTransactions = totalTransactions;
    }

    public BatchAuthNetReturnedTransactions() {
        this(new List<String>(), new List<AuthNetAPI.Transactions>(), new Map<String, AuthNetAPI.MerchantAuthentication>(), 0);
    }

    public void init(List<AuthNetAPI.MerchantAuthentication> merchantAuthList) {
        if (merchantAuthList != null && merchantAuthList.size() > 25) {
            throw new Util.BWException('Look for returns across fewer than 25 gateways.');
        }

        Datetime today = System.now();
        try {
            for (AuthNetAPI.MerchantAuthentication merchAuth : merchantAuthList) {
                List<String> batchesFromGateway = new List<String>();
                batchesFromGateway.addAll(AuthNetService.getSettledBatchListRequest(merchAuth.Zname, merchAuth.transactionKey, today - 30, today));
                batchesFromGateway.addAll(AuthNetService.getSettledBatchListRequest(merchAuth.Zname, merchAuth.transactionKey, today - 60, today - 30));
                batchesFromGateway.addAll(AuthNetService.getSettledBatchListRequest(merchAuth.Zname, merchAuth.transactionKey, today - 90, today - 60));
                batchesFromGateway.addAll(AuthNetService.getSettledBatchListRequest(merchAuth.Zname, merchAuth.transactionKey, today - 120, today - 90));
                for (String batchId : batchesFromGateway) {
                    batchIdToMerchantAuthMap.put(batchId, merchAuth);
                }
                this.batchIds.addAll(batchesFromGateway);
            }
        } catch (Exception e){
            Logger.logLater(
                'BatchAuthNetReturnedTransactions',
                'init',
                'Exception caught:\n' + e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR
            );
        }
        Logger.flushLogs();
    }

    public void execute(QueueableContext context) {
        startReturnedItemSearch(batchIds);
    }

    @TestVisible
    private void startReturnedItemSearch(List<String> batchIds) {
        try {
            while (!batchIds.isEmpty()) {
                findReturnedItems(batchIds[0], 1);
                batchIds.remove(0);
            }
        } catch (Util.BWException bwe) {
            nextAsyncJob =
                new BatchAuthNetReturnedTransactions(batchIds, allReturnedTransactionList, batchIdToMerchantAuthMap, totalTransactions);
            if (!Test.isRunningTest()) {
                System.enqueueJob(nextAsyncJob);
            }
        } catch (Exception e) {
            Logger.logNow('BatchAuthNetReturnedTransactions', 'startReturnedItemSearch',
                'Exception caught:\n' + e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
        if (nextAsyncJob == null) {
            finishQueueableChain();
        }
    }

    @TestVisible
    private void findReturnedItems(String batchId, Integer offset) {
        AuthNetAPI.MerchantAuthentication merchAuth = batchIdToMerchantAuthMap.get(batchId);
        if (merchAuth == null) {
            throw new Util.FatalBWException('No Merchant Authentication Found for batchId: ' + batchId);
        }

        AuthNetAPI transactionListResponse = AuthNetService.getTransactionListRequest(
            merchAuth.Zname,
            merchAuth.transactionKey,
            batchId,
            String.valueOf(offset),
            String.valueOf(pagingLimit)
        );
        if (transactionListResponse.totalNumInResultSet > 0) {
            if (transactionListResponse.transactions == null) {
                throw new Util.BWException('Expected transactions for batch: ' + batchId + ' offset: ' + offset + ' paging: ' + pagingLimit);
            } else {
                totalTransactions += transactionListResponse.transactions.size();
            }
            this.allReturnedTransactionList.addAll(AuthNetService.getReturnedTransactions(transactionListResponse.transactions));
            if (transactionListResponse.totalNumInResultSet == pagingLimit) {
                findReturnedItems(batchId, offset+1);
            }
        }
    }

    private void finishQueueableChain() {
        String returnedTransactions = '';
        List<String> gatewayTransactionIds = new List<String>();
        for (AuthNetAPI.Transactions trx : allReturnedTransactionList) {
            returnedTransactions += trx.transId + ': ' + trx.settleAmount + '\n';
            gatewayTransactionIds.add(trx.transId);
        }
        Logger.logNow(
            'BatchAuthNetReturnedTransactions',
            'Returned Transaction Results',
            'These transactions were found to be returned out of '+batchIdToMerchantAuthMap.keySet().size() +' batches :\n' + returnedTransactions,
            Logger.INFO);
        if (gatewayTransactionIds.isEmpty()) {
            return;
        }

        ZuoraDataQueryService.ProcessingParameter processingParameter = new ZuoraDataQueryService.ProcessingParameter();
        processingParameter.className = 'BatchAuthNetReturnedTransactions';
        processingParameter.optionalIntegers = new Map<String, Integer>();
        processingParameter.optionalIntegers.put(TOTAL_TRANSACTIONS_LABEL, totalTransactions);

        ZuoraDataQueryService.callFromApex(ZuoraPaymentSelector.selectPaymentsNotMarkedAsReturned(gatewayTransactionIds), processingParameter);

    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter processingParameter, String response) {
        try {
            logReturnedTransactionsNotRecorded(response);
            checkTransactionCounts(processingParameter);
        } catch (Exception e) {
            Logger.logLater('BatchAuthNetReturnedTransactions', 'executePostQueryJob', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    private void logReturnedTransactionsNotRecorded(String response) {
        List<ZuoraAPI.Payment> returnedPayments = (List<ZuoraAPI.Payment>) JSON.deserialize(response, List<ZuoraAPI.Payment>.class);
        String returnedTransactionsNotRecorded = '';
        for (ZuoraAPI.Payment returnedPayment : returnedPayments) {
            returnedTransactionsNotRecorded +=
                returnedPayment.referenceId + ', ' + returnedPayment.id + ', ' + returnedPayment.amount + ', ' + returnedPayment.effectiveDate + '\n';
        }
        if (returnedTransactionsNotRecorded != '') {
            Logger.logLater(
                'BatchAuthNetReturnedTransactions',
                'Returned Transaction Results',
                'These transactions were found to be returned but not marked as such:\n' + returnedTransactionsNotRecorded,
                Logger.ERROR);
        }
    }

    private void checkTransactionCounts(ZuoraDataQueryService.ProcessingParameter param) {
        Datetime lastFourMonths = System.now() - 120;
        String queryResultJSON = getElectronicPaymentsFromDate(lastFourMonths);
        ZuoraAPI.ZuoraQueryResult queryResult = (ZuoraAPI.ZuoraQueryResult) JSON.deserialize(queryResultJSON, ZuoraAPI.ZuoraQueryResult.class);
        Integer totalTransactionsFromAuthorize = param.optionalIntegers.get(TOTAL_TRANSACTIONS_LABEL);
        if (queryResult.size > totalTransactionsFromAuthorize) {
            Logger.logLater(
                'BatchAuthNetReturnedTransactions',
                'Transaction Count Check',
                'Found ' + queryResult.size + ' electronic transactions in Zuora and ' +
                    totalTransactionsFromAuthorize + ' in the gateway. Make sure the AuthNetScheduler is ' +
                    'checking all gateways',
                Logger.WARN);
        }
    }

    protected virtual String getElectronicPaymentsFromDate(Datetime startDate) {
        return(ZuoraAPIHelper.query(ZuoraPaymentSelector.selectElectronicPaymentsFromDate(startDate), false));
    }
}