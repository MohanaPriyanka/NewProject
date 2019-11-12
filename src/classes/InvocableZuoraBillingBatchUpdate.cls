/* Created by Jordan Pentaleri on 11/11/2019
Tested By: InvocableZuoraActionsTest

Limitations:
    Only one method in a class can have the InvocableMethod annotation
    Can have at most one input parameter and its data type must be a List of primitive data types
    https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm
*/

public class InvocableZuoraBillingBatchUpdate {
    @InvocableMethod(label='BillingBatchUpdate')
    public static List<String> billingBatchUpdate(List<Date> invoiceDates){
        // Assuming only 1 Invoice Date is passed through, only make a list because of invocable limitations:
        ZuoraBillingBatchService service = new ZuoraBillingBatchService();
        ZuoraAPI.ActionItems item = service.updateAccountBatches(invoiceDates[0]);
        List<String> returnString = new List<String>{JSON.serialize(item.objects)};
        return returnString;
    }
}