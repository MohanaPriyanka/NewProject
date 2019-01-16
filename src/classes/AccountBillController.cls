/**
 * Created by mstackhouse on 1/16/2019.
 * Description: 
 * Test: batchAccountBills => LetterStreamServiceTest
 */


global without sharing class AccountBillController {
    webService static void sendAllReadyBillsToLetterStream() {
        AccountBillService.sendBillsToLetterStream(AccountBillSelector.getAccountBillsReadyToBeSent(null));
    }
}