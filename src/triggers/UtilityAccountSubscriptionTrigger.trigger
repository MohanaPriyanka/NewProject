/**
 * Created by SarahRenfro on 8/6/2019.
 */

trigger UtilityAccountSubscriptionTrigger on Utility_Account_Subscription__c (after insert, after update, before insert, before update, before delete) {
    if (Util.isDisabled('Disable_Client_Objects_Trigger__c')) {
        return;
    }

    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            ClientReportingService.deleteClientUAS(Trigger.old);
        } else if (Trigger.isInsert) {
            UtilityAccountSubscriptionHandler.onBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            UtilityAccountSubscriptionHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isAfter)  {
        if (Trigger.isUpdate) {
        } else if (Trigger.isInsert) {
            ClientReportingService.insertClientUAS(Trigger.new);
        }
    }


}