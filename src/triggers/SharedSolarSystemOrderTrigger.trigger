/**
 * Created by SarahRenfro on 12/19/2019.
 */

trigger SharedSolarSystemOrderTrigger on Shared_Solar_System_Order__c (after insert, after update) {

//When marked as Approved (But getting inserted with Approved)
    SubscriptionManagementService subscriptionManagementService = new SubscriptionManagementService();

    if(Trigger.isUpdate && Trigger.isAfter) {
        subscriptionManagementService.handleSystemOrderChange(Trigger.new, Trigger.oldMap);
    }

}