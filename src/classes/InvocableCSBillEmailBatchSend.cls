/* Created by Jordan Pentaleri on 2/11/19
Tested By: BatchCSBillEmailHandlerTest
*/

public class InvocableCSBillEmailBatchSend {

    @InvocableMethod(   label='BatchCSBillEmailHandler'
                        description='Sends bill pdfs through email for ABs marked as Ready_For_Email_Send__c')
    public static void sendEmails(){
        Database.executeBatch(new BatchCSBillEmailHandler(), 10);
    }
}