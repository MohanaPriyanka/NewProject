public class ZuoraHistoricalPaymentUpdate implements Database.AllowsCallouts, Queueable, ZuoraDataQueryService.Processor {
    @TestVisible
    private ChargentTransactionSelector transactionSelector = new ChargentTransactionSelector();
    public Set<ZuoraAPI.Payment> paymentsToUpdate;
    public Set<ZuoraAPI.Payment> updatedPayments;
    public Boolean isPayment; // false = is debit memo

    public List<String> bwGateways = new List<String>{
        'SREC',
        'NextSun NGrid WCMA',
        'BW Community Solar Payments Account Gateway',
        'BCS Single Gateway'
    };

    public Map<String, String> paymentMethodMap = new Map<String, String>{
        'Check' => 'ACH',
        'Credit Card' => 'CreditCard',
        'Check (Paper)' => 'Check'
    };

    public void execute(QueueableContext context){
        historicalChargentDataMigration();
    }

    public static void queueDataQueryForHistoricPayments() {
        String queryString = 'SELECT Id, TransactionId__c FROM Payment WHERE TransactionId__c != \'\'';
        ZuoraDataQueryService.ProcessingParameter methodToRunWhenComplete = new ZuoraDataQueryService.ProcessingParameter();
        methodToRunWhenComplete.className = 'ZuoraHistoricalPaymentUpdate';
        methodToRunWhenComplete.methodName = 'paymentUpdate';
        ZuoraDataQueryService.callFromApex(queryString,methodToRunWhenComplete);
    }

    public static void queueDataQueryForReturnedPayments() {
        String queryString = 'SELECT Id, CRMID__c FROM DebitMemo WHERE reasoncode = \'Returned Payment\'';
        ZuoraDataQueryService.ProcessingParameter methodToRunWhenComplete = new ZuoraDataQueryService.ProcessingParameter();
        methodToRunWhenComplete.className = 'ZuoraHistoricalPaymentUpdate';
        methodToRunWhenComplete.methodName = 'debitMemoUpdate';
        ZuoraDataQueryService.callFromApex(queryString,methodToRunWhenComplete);
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter parameter, String response){
        // Because the fields are the same between Payment and Debit Memo, use ZuoraAPI.Payment for both DM and Payments
        paymentsToUpdate = (Set<ZuoraAPI.Payment>)JSON.deserialize(response, Set<ZuoraAPI.Payment>.class);
        updatedPayments = new Set<ZuoraAPI.Payment>();
        if (parameter.methodName == 'paymentUpdate'){
            isPayment = true;
            historicalChargentDataMigration();
        } else if (parameter.methodName == 'debitMemoUpdate'){
            isPayment = false;
            historicalChargentDataMigration();
        }
    }

    public void historicalChargentDataMigration() {
        try {
            List<Id> transIdList = new List<Id>();
            for (ZuoraAPI.Payment historicPayment : paymentsToUpdate){
                transIdList.add(historicPayment.TransactionId_Zcustom);
            }
            Map<Id,ChargentOrders__Transaction__c> chTransactionMap = transactionSelector.getTransactionsById(transIdList);

            Integer calloutCount = 0;
            Set<ZuoraAPI.Payment> paymentsThisBatch = new Set<ZuoraAPI.Payment>();
            for (ZuoraAPI.Payment historicPayment : paymentsToUpdate){
                if (calloutCount == 50){
                    ZuoraHistoricalPaymentUpdate nextPayUpdate = new ZuoraHistoricalPaymentUpdate();
                    nextPayUpdate.isPayment = isPayment;
                    System.enqueueJob(nextPayUpdate);
                    return;
                }
                ZuoraAPI.Payment paymentToUpdate;
                paymentToUpdate = matchChargentFieldsToZuora(chTransactionMap.get(historicPayment.TransactionId_Zcustom));
                HttpResponse response;
                if (isPayment){
                    response = ZuoraAPIHelper.callJsonEndpoint('PUT', '/v1/payments/' + historicPayment.id, paymentToUpdate, false);
                } else {
                    response = ZuoraAPIHelper.callJsonEndpoint('PUT', '/v1/debitmemos/' + historicPayment.id, paymentToUpdate, false);
                }
                ZuoraAPI.Payment responsePayment = (ZuoraAPI.Payment)JSON.deserialize(response.getBody(), ZuoraAPI.Payment.class);
                if (responsePayment.success){
                    updatedPayments.add(paymentToUpdate);
                }
                paymentsThisBatch.add(historicPayment);
                calloutCount += 1;
            }
            paymentsToUpdate.removeAll(paymentsThisBatch);
        } catch (Exception excep) {
            Logger.logNow('ZuoraHistoricalPaymentUpdate', 'historicalChargentDataMigration', excep.getMessage() + excep.getStackTraceString(), 'ERROR');
        }
    }

    public ZuoraAPI.Payment matchChargentFieldsToZuora(ChargentOrders__Transaction__c chTransaction) {
        ZuoraAPI.Payment zPayment = new ZuoraAPI.Payment();
        String gatewayName;
        String clientNumber;
        String zuoraPayMethod;
        String chPayMethod = chTransaction.ChargentOrders__Order__r.ChargentOrders__Payment_Method__c;
        if (chPayMethod == 'Check (Paper)') {
            gatewayName = 'BWTrust';
            clientNumber = 'BW-0028241';
        } else if (bwGateways.contains(chTransaction.ChargentOrders__Gateway__r.Name)){
            gatewayName = chTransaction.ChargentOrders__Gateway__r.Name;
            clientNumber = 'BW-0028241';
        } else {
            gatewayName = chTransaction.ChargentOrders__Gateway__r.Name;
            clientNumber = chTransaction.Client__r.Account_Number__c;
        }
        if (paymentMethodMap.containsKey(chPayMethod)){
            zuoraPayMethod = paymentMethodMap.get(chPayMethod);
        } else {
            throw new Util.FatalBWException('Could not match chargent pay method to zuora pay method');
        }
        ZuoraAPI.ArchivedChargentData chRecord = new ZuoraAPI.ArchivedChargentData();
        chRecord.PaymentMethod = zuoraPayMethod;
        chRecord.ClientNumber = clientNumber;
        chRecord.GatewayName = gatewayName;
        chRecord.GatewayRefId = chTransaction.ChargentOrders__Gateway_ID__c;

        String jsonString = JSON.serialize(chRecord);
        zPayment.ArchivedChargentData_Zcustom = jsonString;
        return zPayment;
    }
}