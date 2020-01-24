/**
 * Created by SarahRenfro on 8/6/2019.
 */

trigger UtilityAccountSubscriptionTrigger on Utility_Account_Subscription__c (after insert, after update, before delete) {
    if (Util.isDisabled('Disable_Client_Objects_Trigger__c')) {
        return;
    }

    switch on Trigger.operationType {
        when AFTER_INSERT {
            ClientReportingService.insertClientUAS(Trigger.new);
        }
        when BEFORE_DELETE {
            ClientReportingService.deleteClientUAS(Trigger.old);
        }
        when AFTER_UPDATE {
            CSCancellationService.handleOpportunitiesRemovedFromProject(Trigger.oldMap, Trigger.newMap);
        }
    }
}