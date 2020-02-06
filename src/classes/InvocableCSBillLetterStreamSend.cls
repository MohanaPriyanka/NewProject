/* Created by Jordan Pentaleri on 2/11/19
*/

public class InvocableCSBillLetterStreamSend {
    @InvocableMethod(Label='LetterStreamJob' Description='Send bill pdfs to letterstream for ABs marked as Ready_For_Paper_Bill_Queue__c')
    public static void sendLetters() {
        if (ZuoraAPIHelper.getZuoraSetting().Zuora_Is_Live__c) {
            ZuoraInvoiceService.batchInvoicesToMail(ZuoraInvoiceSelector.getInvoicesToMail());
        } else {
            AccountBillService.sendBillsToLetterStream(AccountBillSelector.getAccountBillsReadyToBeSent(null));
        }
    }
}