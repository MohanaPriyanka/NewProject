/* Created by Jordan Pentaleri on 10/9/2019
Tested By: InvocableZuoraActionsTest

Limitations:
    Only one method in a class can have the InvocableMethod annotation
    Can have at most one input parameter and its data type must be a List of primitive data types
    https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm
*/

public class InvocableZuoraBillRun {
    @InvocableMethod(label='ZuoraBillRun')
    public static List<String> billRun(List<Date> invoiceDates){
        // Assuming only 1 Invoice Date is passed through, only make a list because of invocable limitations:
        String response = ZuoraController.executeBillRun(invoiceDates[0]);
        return new List<String>{response};
    }
}