/**
 * @description Created by jeffparlin on 9/9/21.
 * Aggregates Shared_Solar_System__c records to queue for capacity rollup recalculation based on changes on Utility_Account_Log__c records
 * Intended for use with SystemCapacityRollupCalculator. Included in UtilityAccountLogTriggerHandler.
 * Tested By: SystemCapacityRollupCalculatorTest
 */
public without sharing class UALCapacityRollupInitializer implements SystemCapacityRollupCalculator.Initializer {

    private Map<Id, Utility_Account_Log__c> oldMap;
    private List<Utility_Account_Log__c> newList;

    public UALCapacityRollupInitializer(Map<Id, Utility_Account_Log__c> ualOldMap, List<Utility_Account_Log__c> ualNew) {
        this.oldMap = ualOldMap;
        this.newList = ualNew;
    }

    /**
     * @description Get Shared_Solar_System__c records to queue for capacity rollup recalculation based on scenarios:
     *      1. Any changes to Average_Demand__c (after update context)
     *      2. Any changes to Exclude_from_Demand_Capacity__c (after update context)
     * These situations indicate a value change for Pending or Committed capacity SSS rollup field(s))s
     * @return Set of Shared_Solar_System__c Ids
     */
    public Set<Id> getSystemsToCheckCapacityRollups() {
        Set<Utility_Account_Log__c> targetUals = new Set<Utility_Account_Log__c>();
        for (Utility_Account_Log__c newUal : newList) {
            Utility_Account_Log__c oldUal = oldMap.get(newUal.Id);
            if (oldUal.Exclude_from_Demand_Capacity__c != newUal.Exclude_from_Demand_Capacity__c ||
                oldUal.Average_Demand__c != newUal.Average_Demand__c) {
                targetUals.add(newUal);
            }
        }
        return new SharedSolarSystemsSelector().getSSSByUAL(targetUals);
    }
}