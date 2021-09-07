/**
 * @description Opportunity trigger, executed by Opportunity record change
 * Tested by: OpportunityTriggerTest, CSCancellationServiceTest, ClientBrandingServiceTest, PartnerCommissionHandlerTest
 */
trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update, after delete) {
    if (Util.isDisabled('Disable_OpportunityTrigger__c')) {
        return;
    }
    OpportunityTriggerHandler handler = new OpportunityTriggerHandler(Trigger.new, Trigger.newMap, Trigger.oldMap);
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.onBeforeInsert();
        } when AFTER_INSERT {
            handler.onAfterInsert();
        } when BEFORE_UPDATE {
            handler.onBeforeUpdate();
        } when AFTER_UPDATE {
            handler.onAfterUpdate();
        } when AFTER_DELETE {
            handler.onAfterDelete();
        }
    }
}