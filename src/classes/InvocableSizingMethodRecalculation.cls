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
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class InvocableSizingMethodRecalculation {
    /**
     * @description Creates Subscription Orders for a UAS after changing the sizing method
     * @param uasList is a list with one UAStoUpdateInfo object 
     * The UAStoUpdateInfo object consists of the UAS to update and comments that should go on the related SO 
     */
    @InvocableMethod(label='Change Sizing Method for Subscriptions')
    public static void recalculateSubscriptionWithSizingMethod(List<UAStoUpdateInfo> uasList) {
        UAStoUpdateInfo infoObject = uasList[0];
        List<List<Utility_Account_Subscription__c>> uasListOfLists = new List<List<Utility_Account_Subscription__c>>();
        uasListOfLists.add(infoObject.getUASListToUpdate());
        String soCommentsToInsert = infoObject.getSOComments();
        try {
            SubscriptionManagementService service = new SubscriptionManagementService();
            List<Subscription_Order__c> soList =  service.createSystemChangeSubscriptionOrders(uasListOfLists[0], null, soCommentsToInsert);
            insert soList;
        } catch (Exception e) {
            Logger.logNow('InvocableSizingMethodRecalculation', 'recalculateSubscriptionWithSizingMethod', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
            throw new Util.BWException('Failed to create a Subscription Order to reflect the change in Sizing Method. Confirm the new Sizing Method has the appropriate size factor populated (Size Ratio or Value of NMC)');
        }
    }
    
    public class UAStoUpdateInfo {
        @InvocableVariable( Label='UAS Collection to Update'
                            description='Collection of UAS\'s to update Sizing Method'
                            required=true)
        public List<Utility_Account_Subscription__c> uasListToUpdate;

        @InvocableVariable( Label ='SO Comment'
                            description='Comments to add to SO\'s that are created')
        public String soComments;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public UAStoUpdateInfo(){
            // Invocable types need a no-arg constructor
        }

        public UAStoUpdateInfo(List<Utility_Account_Subscription__c> uasListToUpdate, String soComments){
            this.uasListToUpdate = uasListToUpdate;
            this.soComments = soComments;
        }

        public List<Utility_Account_Subscription__c> getUASListToUpdate(){
            return this.uasListToUpdate;
        }

        public String getSOComments() {
            return this.soComments;
        }
    }
}