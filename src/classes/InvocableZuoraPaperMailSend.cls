/* Created by Jordan Pentaleri on 10/9/2019
Tested By: InvocableZuoraActionsTest

Limitations:
    Only one method in a class can have the InvocableMethod annotation
    Can have at most one input parameter and its data type must be a List of primitive data types
    https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm
*/

public class InvocableZuoraPaperMailSend {
    @InvocableMethod(label='ZuoraPaperMailSend')
    public static void paperMailSend(){
        ZuoraInvoiceAsyncService asyncService = new ZuoraInvoiceAsyncService(ZuoraInvoiceAsyncService.OperationType.MAIL);
        asyncService.allInvoicesToMail = ZuoraInvoiceSelector.getInvoicesToMail();
        System.enqueueJob(asyncService);
    }
}