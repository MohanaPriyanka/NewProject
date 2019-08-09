/**
 * Created by SarahRenfro on 8/6/2019.
 */

trigger UtilityAccountSubscriptionTrigger on Utility_Account_Subscription__c (after insert, after update, before delete) {
    if (Util.isDisabled('Disable_Client_Objects_Trigger__c')) {
        return;
    }

    if (Trigger.isInsert && Trigger.isAfter) {
        ClientReportingService.insertClientUAS(Trigger.new);
    }

    if (Trigger.isDelete && Trigger.isBefore) {
        ClientReportingService.deleteClientUAS(Trigger.old);
    }
}