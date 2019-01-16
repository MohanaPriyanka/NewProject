/**
 * Created by mstackhouse on 1/16/2019.
 * Description: 
 * Test: 
 */


public without sharing class AccountBillService {
    public static void sendBillsToLetterStream(List<Account_Bill__c> accountBills) {
        AccountBillLetterStreamImpl batchJob = new AccountBillLetterStreamImpl();
        if (Test.isRunningTest()) {
            batchJob.makeCallout = false;
        }
        batchJob.batchAccountBillsBySize(accountBills);
    }
}