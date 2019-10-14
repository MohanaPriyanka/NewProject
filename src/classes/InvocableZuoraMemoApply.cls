/* Created by Jordan Pentaleri on 10/9/2019
Tested By: InvocableZuoraActionsTest

Limitations:
    Only one method in a class can have the InvocableMethod annotation
    Can have at most one input parameter and its data type must be a List of primitive data types
    https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm
*/

public class InvocableZuoraMemoApply {
    @InvocableMethod(label='ZuoraMemoApply')
    public static void memoApply(){
        ZuoraMemoBatchApply batchApply = new ZuoraMemoBatchApply();
        batchApply.startApplication();
        if (Test.isRunningTest()){
            // Because we can only execute one batch in a test, and runBatch starts with a batch
            // size of 1 because of the chained queueable limit, we can't pass through >1 during a test.
            batchApply.creditMemosToApply = new List<ZuoraAPI.CreditMemoWithItem>{batchApply.creditMemosToApply[0]};
            batchApply.runBatch();
        } else {
            batchApply.runBatch();
        }
    }
}