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
     *   1. Opps that change Stage
     *   2. Opps that change customer group or customer sub group
     * These situations indicate a possible value change for Pending or Committed capacity SSS rollup field(s))
     * @return Set of Shared_Solar_System__c Ids
     */
    public Set<Id> getSystemsToCheckCapacityRollups() {
        Set<Id> systems = new Set<Id>();
        for (Opportunity newOpp : newList) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            if (newOpp.StageName != oldOpp.StageName) {
                systems.add(newOpp.Shared_Solar_System__c);
            }
            if (newOpp.Customer_Group__c != oldOpp.Customer_Group__c ||
                newOpp.Customer_Sub_Group__c != oldOpp.Customer_Sub_Group__c) {
                systems.add(newOpp.Shared_Solar_System__c);
            }
            if (newOpp.Partner_tag_lookup__c != oldOpp.Partner_tag_lookup__c ||
                newOpp.Partner_Account__c != oldOpp.Partner_Account__c) {
                systems.add(newOpp.Shared_Solar_System__c);
            }
        }
        return systems;
    }
}