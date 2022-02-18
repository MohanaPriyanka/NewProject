/**
 * Created by PeterYao on 10/9/2019.
  * Tested By: BatchAuthNetReturnedTransactionsTest
 */

public without sharing class AuthNetScheduler implements Schedulable, Database.AllowsCallouts {
    @TestVisible
    public static APICredentialSelector apiCredentialSelector = new APICredentialSelector();

    public void execute(SchedulableContext sc) {
        AuthNetScheduler.startJob();
    }

    @Future(Callout=true)
    public static void startJob() {
        List<AuthNetAPI.MerchantAuthentication> merchantAuthentications = new List<AuthNetAPI.MerchantAuthentication>();

        List<API_Credential__c> credentials = apiCredentialSelector.getApiCredentials('Authorize');

        for (API_Credential__c credential : credentials){
            AuthNetAPI.MerchantAuthentication m = new AuthNetAPI.MerchantAuthentication();
            m.Zname = credential.Credential_Id__c;
            m.transactionKey = credential.Credential_Secret__c;
            merchantAuthentications.add(m);
        }

        BatchAuthNetReturnedTransactions batchAuthNet = new BatchAuthNetReturnedTransactions();
        batchAuthNet.init(merchantAuthentications);
        System.enqueueJob(batchAuthNet);
    }
}