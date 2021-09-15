/**
 * @description Created by jeffparlin on 9/9/21.
 * Aggregates Shared_Solar_System__c records to queue for capacity rollup recalculation based on changes on Opportunity records
 * Intended for use with SystemCapacityRollupCalculator. Included in OpportunityTriggerHandler.
 * Tested By: SystemCapacityRollupCalculatorTest
 */
public without sharing class OpportunityCapacityRollupInitializer implements SystemCapacityRollupCalculator.Initializer {

    private Map<Id, Opportunity> oldMap;
    private List<Opportunity> newList;

    public OpportunityCapacityRollupInitializer(Map<Id, Opportunity> oppOldMap, List<Opportunity> oppNew) {
        this.oldMap = oppOldMap;
        this.newList = oppNew;
    }

    /**
     * @description Get Shared_Solar_System__c records to queue for capacity rollup recalculation based on scenarios:
     * 1. Opps that change Stage to 'Complete'
     * 2. Opps that move from 'Complete' to any other Stage
     * These situations indicate a value change for Pending or Committed capacity SSS rollup field(s))
     * @return Set of Shared_Solar_System__c Ids
     */
    public Set<Id> getSystemsToCheckCapacityRollups() {
        Set<Id> systems = new Set<Id>();
        for (Opportunity newOpp : newList) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            if (newOpp.StageName != oldOpp.StageName && (newOpp.StageName == 'Complete' || oldOpp.StageName == 'Complete')) {
                systems.add(newOpp.Shared_Solar_System__c);
            }
        }
        return systems;
    }
}