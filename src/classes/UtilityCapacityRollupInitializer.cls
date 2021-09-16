/**
 * @description Created by jeffparlin on 9/10/21.
 * Aggregates Shared_Solar_System__c records to queue for capacity rollup recalculation based on changes on Utility__c records
 * Intended for use with SystemCapacityRollupCalculator. Included on UtilityTrigger.
 * Tested By: SystemCapacityRollupCalculatorTest
 */
public without sharing class UtilityCapacityRollupInitializer implements SystemCapacityRollupCalculator.Initializer {

    public Map<Id,Utility__c> oldMap;
    public List<Utility__c> newList;

    public UtilityCapacityRollupInitializer(Map<Id,Utility__c> utilityOldMap, List<Utility__c> utilityNew) {
        this.oldMap = utilityOldMap;
        this.newList = utilityNew;
    }

    /**
     * @description Get Shared_Solar_System__c records to queue for capacity rollup recalculation based on scenarios:
     *      1. Utility records that change Average_Demand_Threshold__c (after update context)
     * This situation indicates a value change for Pending or Committed Demand capacity SSS rollup field
     * @return Set of Shared_Solar_System__c Ids
     */
    public Set<Id> getSystemsToCheckCapacityRollups() {
        Set<Id> targetUtilities = (Set<Id>)
            new SObjectFilter(oldMap, newList, Utility__c.Average_Demand_Threshold__c, SObjectFilter.ANY_VALUE, SObjectFilter.ANY_VALUE)
                .get(SObjectFilter.SOBJECT_ID_SET);
        return getSystemsForUtilities(targetUtilities);
    }

    private Set<Id> getSystemsForUtilities(Set<Id> targetUtilities) {
        if (targetUtilities.isEmpty()) {
            return new Set<Id>();
        }
        return new SharedSolarSystemsSelector().getAllSSSByUtility(targetUtilities).keySet();
    }
}