/**
 * @description Created by jeffparlin on 9/10/21.
 * Tested by: SystemCapacityRollupCalculator
 */
trigger UtilityTrigger on Utility__c (after update) {
    if (Util.isDisabled('Disable_UtilityTrigger__c')) {
        return;
    }
    new SystemCapacityRollupCalculator(new UtilityCapacityRollupInitializer(Trigger.oldMap, Trigger.new)).performRollup();
}