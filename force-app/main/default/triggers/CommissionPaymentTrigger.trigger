/**
 * @description Created by jeffparlin on 5/9/22.
 * Tested By: PartnerCommissionGenerationTest
 */
trigger CommissionPaymentTrigger on Commission_Payment__c (after update) {
    CommissionPaymentTriggerHandler handler = new CommissionPaymentTriggerHandler(Trigger.oldMap, Trigger.new);
    handler.afterUpdate();
}