/**
 * Created by SarahRenfro on 7/7/2020.
 *
 * Description: Called by Subscription Order Creation Flow and Recalculate Subscriptions Flow
 * UALs and UASes are updated with new Rate Classes and Sizing Methods. This method creates
 * subscription Orders to capture the change
 *
 * Tested By: SubscriptionSizingTestclass
 *
 * Limitations:
    Only one method in a class can have the InvocableMethod annotation
    Can have at most one input parameter and its data type must be a List of primitive data types
    https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm
*/

public without sharing class InvocableSizingMethodRecalculation {

    @InvocableMethod(label='Change Sizing Method for Subscriptions')
    public static void recalculateSubscriptionWithSizingMethod(List<List<Utility_Account_Subscription__c>> uasList) {
        try {
            FeatureService featureService = new FeatureService();
            SubscriptionManagementService service = new SubscriptionManagementService();
            List<Subscription_Order__c> soList =  service.createSystemChangeSubscriptionOrders(uasList[0], null);
            if (featureService.isEnabled('Sizing_Method')) {
                insert soList;
            }
        } catch (Exception e) {
            Logger.logNow('InvocableSizingMethodRecalculation', 'recalculateSubscriptionWithSizingMethod', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }
}