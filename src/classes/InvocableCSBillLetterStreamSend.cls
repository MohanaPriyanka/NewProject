/* Created by Jordan Pentaleri on 2/11/19
*/

public class InvocableCSBillLetterStreamSend {

    @InvocableMethod(   label='LetterStreamJob'
                        description='Send bill pdfs to letterstream for ABs marked as Ready_For_Paper_Bill_Queue__c')
    public static void sendLetters(){
        List<Account_Bill__c> abToSendList = AccountBillSelector.getAccountBillsReadyToBeSent(null);
        AccountBillLetterStreamImpl letterStreamJob = new AccountBillLetterStreamImpl();
        if (Test.isRunningTest()) {
            letterStreamJob.makeCallout = false;
        }
        letterStreamJob.queueAccountBillsToSend(abToSendList);
    }
}