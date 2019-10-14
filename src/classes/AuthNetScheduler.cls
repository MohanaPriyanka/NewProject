/**
 * Created by PeterYao on 10/9/2019.
  * Tested By: BatchAuthNetReturnedTransactionsTest
 */

public without sharing class AuthNetScheduler implements Schedulable, Database.AllowsCallouts {
    @TestVisible
    public static GatewaySelector gatewaySelector = new GatewaySelector();

    public void execute(SchedulableContext sc) {
        AuthNetScheduler.startJob();
    }

    @Future(Callout=true)
    public static void startJob() {
        List<AuthNetAPI.MerchantAuthentication> merchantAuthentications = new List<AuthNetAPI.MerchantAuthentication>();

        List<ChargentBase__Gateway__c> gateways = gatewaySelector.getGatewaysForAuthentication();

        for (ChargentBase__Gateway__c gateway : gateways){
            AuthNetAPI.MerchantAuthentication m = new AuthNetAPI.MerchantAuthentication();
            m.Zname = gateway.ChargentBase__Merchant_ID__c;
            m.transactionKey = gateway.ChargentBase__Security_Key__c;
            merchantAuthentications.add(m);
        }

        BatchAuthNetReturnedTransactions batchAuthNet = new BatchAuthNetReturnedTransactions();
        batchAuthNet.init(merchantAuthentications);
        System.enqueueJob(batchAuthNet);
    }
}