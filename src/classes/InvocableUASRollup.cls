/**
 * Created by SarahRenfro on 5/28/2020.
 *
 * Description: Called from Zuora Bill Generation Console; Populates rollup fields on UAS from UASBs
 *
 * Tested By: InvocableZuoraActionsTest

Limitations:
    Only one method in a class can have the InvocableMethod annotation
    Can have at most one input parameter and its data type must be a List of primitive data types
    https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm
*/


public class InvocableUASRollup {

    @InvocableMethod(label='UASRollup')
    public static void rollupUAS() {
        UtilityAccountSubscriptionHandler.rollupAnchorUASes();
    }
}