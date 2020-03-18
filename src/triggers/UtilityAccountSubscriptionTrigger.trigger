/**
 * Created by SarahRenfro on 8/6/2019.
 *
 * Tested By: UtilityAccountSubscriptionHandlerTest and ClientReportingServiceTest
 */
trigger UtilityAccountSubscriptionTrigger on Utility_Account_Subscription__c (after insert, after update, before insert, before update, before delete) {
    if (Util.isDisabled('Disable_Client_Objects_Trigger__c')) {
        return;
    }
    SubscriptionManagementService subscriptionManagementService = new SubscriptionManagementService();
    FeatureService featureService = new FeatureService();
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            UtilityAccountSubscriptionHandler.assignSSSOnInsert(Trigger.new);
        } when BEFORE_UPDATE {
            UtilityAccountSubscriptionHandler.assignSSSOnUpdate(Trigger.new, Trigger.oldMap);
        } when BEFORE_DELETE {
            ClientReportingService.deleteClientUAS(Trigger.old);
        } when AFTER_INSERT {
            ClientReportingService.insertClientUAS(Trigger.new);
            if (Test.isRunningTest() && featureService.isEnabled('Subscription_Orders')) {
                subscriptionManagementService.createSubscriptionOrdersForTests(Trigger.new);
            }
        } when AFTER_UPDATE {
            CSCancellationService.handleOpportunitiesRemovedFromProject(Trigger.oldMap, Trigger.newMap);
        }
    }
}