/**
 * Created by SarahRenfro on 12/19/2019.
 *
 * Tested By: SubscriptionManagementServiceTest
 *
 */

trigger SharedSolarSystemOrderTrigger on Shared_Solar_System_Order__c (after insert, after update) {
    if (Util.isDisabled('Disable_SharedSolarSystemOrder_Trigger__c')) {
        return;
    }

    SubscriptionManagementService subscriptionManagementService = new SubscriptionManagementService();

    if(Trigger.isUpdate && Trigger.isAfter) {

        subscriptionManagementService.handleSystemOrderChange(Trigger.new, Trigger.oldMap);
    }

}