/**
 * Created by mstackhouse on 1/16/2019.
 * Description: 
 * Test: batchAccountBills => LetterStreamServiceTest
 */


global without sharing class AccountBillController {
    webservice static void sendAllReadyBillsToLetterStream() {
        ScheduledAccountBillLetterStreamMailer batchJob = new ScheduledAccountBillLetterStreamMailer();
        if (Test.isRunningTest()) {
            batchJob.makeCallout = false;
        }
        batchJob.batchAccountBillsBySize(AccountBillSelector.getAccountBillsReadyToBeSent(null));
    }

    webService static void sendAccountBillsToLetterStream(List<Id> accountBillIds) {
        ScheduledAccountBillLetterStreamMailer batchJob = new ScheduledAccountBillLetterStreamMailer();
        if (Test.isRunningTest()) {
            batchJob.makeCallout = false;
        }
        List<Account_Bill__c> accountBillsToSend = AccountBillSelector.getAccountBillsReadyToBeSent(new Set<Id>(accountBillIds));
        if (accountBillIds.size() != accountBillsToSend.size()) {
            String message = 'Some of the bills were not ready to be sent. ' +
                'Make sure bills are Published, ' +
                'Ready for Paper Bill Queue ' +
                'and have an attached bill pdf' ;
            throw new Util.BWException(message);
        }
        batchJob.batchAccountBillsBySize(accountBillsToSend);
    }
}