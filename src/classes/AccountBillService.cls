/**
 * Created by mstackhouse on 1/16/2019.
 * Description: 
 * Test: sendBillsToLetterStream -> LetterStreamServiceTest
 */


public without sharing class AccountBillService {
    public static void sendBillsToLetterStream(List<Account_Bill__c> accountBills) {
        AccountBillLetterStreamImpl letterStreamJob = new AccountBillLetterStreamImpl();
        if (Test.isRunningTest()) {
            letterStreamJob.makeCallout = false;
        }
        if (accountBills.size() > 50) {
            letterStreamJob.accountBillsToSend = accountBills;
            Database.executeBatch(letterStreamJob, 100);
        } else {
            letterStreamJob.queueAccountBillsToSend(accountBills);
        }
    }
}