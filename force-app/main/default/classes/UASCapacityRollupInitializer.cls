/**
 * @description Created by jeffparlin on 9/13/21.
 * Aggregates Shared_Solar_System__c records to queue for capacity rollup recalculation based on changes on Utility_Account_Subscription__c records
 * Intended for use with SystemCapacityRollupCalculator. Included in UtilityAccountSubscriptionTriggerHandler.
 * Tested By: SystemCapacityRollupCalculatorTest
 */
public without sharing class UASCapacityRollupInitializer implements SystemCapacityRollupCalculator.Initializer {

    private Map<Id, Utility_Account_Subscription__c> oldMap;
    private List<Utility_Account_Subscription__c> newList;
    private TriggerOperation triggerType;

    public UASCapacityRollupInitializer(Map<Id, Utility_Account_Subscription__c> oldMap,
        List<Utility_Account_Subscription__c> uasNew, TriggerOperation triggerType) {
        this.oldMap = oldMap;
        this.newList = uasNew;
        this.triggerType = triggerType;
    }

    /**
     * @description Get Shared_Solar_System__c records to queue for capacity rollup recalculation based on scenarios:
     *      1. Any changes to Utility_Account_Subscription__c (after insert, after update, after delete, after undelete)
     * These situations indicate a value change for Pending or Committed capacity SSS rollup field(s))
     * @return Set of Shared_Solar_System__c Ids
     */
    public Set<Id> getSystemsToCheckCapacityRollups() {
        Set<Id> systemsToQueueForCapacityRecalculation = new Set<Id>();
        switch on triggerType {
            when AFTER_INSERT {
                getSystemsFromTriggerNew(systemsToQueueForCapacityRecalculation);
            } when AFTER_UPDATE {
                getSystemsFromTriggerNew(systemsToQueueForCapacityRecalculation);
            } when AFTER_DELETE {
                getSystemsFromTriggerOldMap(systemsToQueueForCapacityRecalculation);
            } when AFTER_UNDELETE {
                getSystemsFromTriggerNew(systemsToQueueForCapacityRecalculation);
            }
        }
        return systemsToQueueForCapacityRecalculation;
    }

    private void getSystemsFromTriggerNew(Set<Id> systemIdSet) {
        for (Utility_Account_Subscription__c uas : newList) {
            systemIdSet.add(uas.Shared_Solar_System__c);
        }
    }

    private void getSystemsFromTriggerOldMap(Set<Id> systemIdSet) {
        for (Utility_Account_Subscription__c uas : oldMap.values()) {
            systemIdSet.add(uas.Shared_Solar_System__c);
        }
    }
}