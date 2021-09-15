/**
 * @description Created by jeffparlin on 9/10/21.
 * Tested by: SystemCapacityRollupCalculator
 */
trigger UtilityTrigger on Utility__c (after update) {
    new SystemCapacityRollupCalculator(Trigger.oldMap, Trigger.new).performRollup();
}