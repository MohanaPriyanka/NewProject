/**
 * @description Created by jeffparlin on 9/9/21.
 * - Gathers Shared_Solar_System__c records which are in need of capacity (rollup) field recalculation based on related record
 *     changes, and performs the recalculation in realtime (synchronously)
 * - Different constructors correspond to the different the objects/records that, when changed in a specified way,
 *     indicate that capacity rollups on Shared_Solar_System__c are due for recalculation.
 * - Fields on Shared_Solar_System__c modified: Shared_Solar_System__c.Capacity_Committed_kW_DC__c, etc.
 * - If in the future changes to other object types should result in this same sort of recalculation, create a new class
 *     constructor here and also a new class which implements SystemCapacityRollupCalculator.Initializer
 *
 * Tested By: SystemCapacityRollupCalculatorTest, SharedSolarSystemHandlerTest
 */
public without sharing class SystemCapacityRollupCalculator {

    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    private Initializer initializer;
    private Boolean bypassInitializer = false;
    private Boolean logChanges = false; // TODO: Deprecate later, used only in SharedSolarSystemHandler.execute() for debugging
    private Set<Id> systemIds;
    private List<Shared_Solar_System__c> systems;
    private List<Utility_Account_Subscription__c> pendingSmallCSCapacityList;
    private List<Utility_Account_Subscription__c> committedSmallCSCapacityList;
    private List<Utility_Account_Subscription__c> pendingAnchorCapacityList;
    private List<Utility_Account_Subscription__c> committedAnchorCapacityList;
    private List<Utility_Account_Subscription__c> pendingDemandCapacityList;
    private List<Utility_Account_Subscription__c> committedDemandCapacityList;
    private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
        Shared_Solar_System__c.SObjectType
    });

    /**
     * @description Constructor for use when Shared_Solar_System__c records change
     * @param sharedSolarSystemIds List of Shared_Solar_System__c records to process (typically from SSS Trigger.new)
     * @param logChanges Log if changes are detected on SSS records (TO BE REMOVED AT DEPRECATION OF SCHEDULED JOB)
     */
    public SystemCapacityRollupCalculator(Set<Id> sharedSolarSystemIds, Boolean logChanges) {
        this.bypassInitializer = true;
        this.systemIds = sharedSolarSystemIds;
        this.logChanges = logChanges; // TODO: Deprecate later, used only in SharedSolarSystemHandler.execute() for debugging
    }

    /**
     * @description Constructor for use when Utility__c records change
     * @param utilityOldMap Trigger.oldMap from UtilityTrigger
     * @param utilityNew Trigger.new from UtilityTrigger
     */
    public SystemCapacityRollupCalculator(Map<Id, Utility__c> utilityOldMap, List<Utility__c> utilityNew) {
        this.initializer = new UtilityCapacityRollupInitializer(utilityOldMap, utilityNew);
    }

    /**
     * @description Constructor for use when Utility_Account_Log__c records change
     * @param ualOldMap Trigger.oldMap from UtilityAccountLogTrigger
     * @param ualNew Trigger.new from UtilityAccountLogTrigger
     */
    public SystemCapacityRollupCalculator(Map<Id, Utility_Account_Log__c> ualOldMap, List<Utility_Account_Log__c> ualNew) {
        this.initializer = new UALCapacityRollupInitializer(ualOldMap, ualNew);
    }

    /**
     * @description Constructor for use when Utility_Account_Subscription__c records change
     * @param uasOldMap Trigger.oldMap from UtilityAccountSubscriptionTrigger
     * @param uasNew Trigger.new from UtilityAccountSubscriptionTrigger
     * @param triggerOperation Trigger operation
     */
    public SystemCapacityRollupCalculator(Map<Id, Utility_Account_Subscription__c> uasOldMap,
        List<Utility_Account_Subscription__c> uasNew, TriggerOperation triggerOperation) {
        this.initializer = new UASCapacityRollupInitializer(uasOldMap, uasNew, triggerOperation);
    }

    /**
     * @description Constructor for use when Opportunity records change
     * @param oppOldMap Trigger.oldMap from OpportunityTrigger
     * @param oppNew Trigger.new from OpportunityTrigger
     */
    public SystemCapacityRollupCalculator(Map<Id, Opportunity> oppOldMap, List<Opportunity> oppNew) {
        this.initializer = new OpportunityCapacityRollupInitializer(oppOldMap, oppNew);
    }

    /**
     * @description Interface to be utilized by other classes when other object changes require this class to recalc
     *      Shared_Solar_System__c rollup fields
     */
    public interface Initializer {
        Set<Id> getSystemsToCheckCapacityRollups();
    }

    /**
     * @description Performs rollup operation for all Shared_Solar_System__c records requested and commits changes to the database
     */
    public void performRollup() {
        if (!bypassInitializer) {
            systemIds = initializer.getSystemsToCheckCapacityRollups();
        }
        if (systemIds.isEmpty()) {
            return;
        }
        systems = sssSelector.getSSSWithActiveUASes(systemIds);
        summarizeCapacity();
        uow.commitWork();
    }

    /**
     * @description Performs rollup operation in a BEFORE_UPDATE context for SharedSolarSystemHandler
     *      Does NOT run uow.commitWork() because this is intended to be called from beforeUpdate
     * @param sssTriggerOldMap Trigger.oldMap from SharedSolarSystemHandler/SharedSolarSystemTrigger
     */
    public void performRollupBeforeUpdate(Map<Id, Shared_Solar_System__c> sssTriggerOldMap) {
        systems = sssSelector.getSSSWithActiveUASes(systemIds);
        summarizeCapacityBeforeUpdate(sssTriggerOldMap);
    }

    private void summarizeCapacity() {
        for (Shared_Solar_System__c sssWithActiveUASes : systems) {
            summarizeCapacityBySubscription(sssWithActiveUASes);
            registerCapacityChanges(sssWithActiveUASes);
        }
    }

    /**
     * @description Processes Shared_Solar_System__c records in a BEFORE_UPDATE trigger context
     *      In order to update the values in Trigger.new, a reference must exist to Trigger.new (thus the parameter)
     * @param triggerNewMap Trigger.newMap
     */
    private void summarizeCapacityBeforeUpdate(Map<Id, Shared_Solar_System__c> triggerNewMap) {
        for (Shared_Solar_System__c sss : systems) {
            Shared_Solar_System__c sssToUpdate = triggerNewMap.get(sss.Id);
            summarizeCapacityBySubscription(sss);
            registerCapacityChanges(sssToUpdate);
        }
    }

    /**
     * @description Determines Pending/Committed Small CS Capacity, Pending/Committed Anchor capacity, and Pending/Committed
     * Demand Capacity based on the individual subscription (UAS)
     * existing subscriptions on the SSS
     * @param sssWithActiveUASes SSS with all necessary fields from selector, including UAS (subscriptions) and UAL fields
     */
    private void summarizeCapacityBySubscription(Shared_Solar_System__c sssWithActiveUASes) {
        pendingSmallCSCapacityList = new List<Utility_Account_Subscription__c>();
        committedSmallCSCapacityList = new List<Utility_Account_Subscription__c>();
        pendingAnchorCapacityList = new List<Utility_Account_Subscription__c>();
        committedAnchorCapacityList = new List<Utility_Account_Subscription__c>();
        pendingDemandCapacityList = new List<Utility_Account_Subscription__c>();
        committedDemandCapacityList = new List<Utility_Account_Subscription__c>();
        for (Utility_Account_Subscription__c uas : sssWithActiveUASes.Utility_Account_Subscriptions__r) {
            if (isAnchorOrPublicOfftake(uas)) {
                addCapacityToCapacityList(uas, committedAnchorCapacityList, pendingAnchorCapacityList);
            } else {
                addCapacityToCapacityList(uas, committedSmallCSCapacityList, pendingSmallCSCapacityList);
            }
            if (isDemandSubscription(sssWithActiveUASes, uas)) {
                addCapacityToCapacityList(uas, committedDemandCapacityList, pendingDemandCapacityList);
            }
        }
    }

    /**
     * @description Checks if the UAL is a "Demand" customer (typically exceeding 25 kW of Average Demand). We track this
     * because some projects have caps as to how much capacity can go to "Demand" customers
     * @param sss SSS with necessary parent Utility fields
     * @param uas UAS with necessary parent UAL fields
     * @return TRUE if a demand subscription, else FALSE
     */
    private Boolean isDemandSubscription(Shared_Solar_System__c sss, Utility_Account_Subscription__c uas) {
        Decimal ualAverageDemand = Util.nullToZero(uas.Utility_Account_Log__r.Average_Demand__c);
        return ualAverageDemand >= sss.Utility__r.Average_Demand_Threshold__c && !uas.Utility_Account_Log__r.Exclude_from_Demand_Capacity__c;
    }

    /**
     * @description Updates all Shared_Solar_System__c capacity rollup fields, if necessary
     * @param sss Shared_Solar_System__c record in question
     */
    private void registerCapacityChanges(Shared_Solar_System__c sss) {
        updateSystemField(sss, Shared_Solar_System__c.Reserved_Capacity_kW_DC__c, String.valueOf(sumCapacity(pendingSmallCSCapacityList)));
        updateSystemField(sss, Shared_Solar_System__c.Capacity_Committed_kW_DC__c, sumCapacity(committedSmallCSCapacityList));
        updateSystemField(sss, Shared_Solar_System__c.Pending_Anchor_Capacity__c, sumCapacity(pendingAnchorCapacityList));
        updateSystemField(sss, Shared_Solar_System__c.Anchor_Capacity_Reserved__c, sumCapacity(committedAnchorCapacityList));
        updateSystemField(sss, Shared_Solar_System__c.Pending_Demand_Capacity__c, sumCapacity(pendingDemandCapacityList));
        updateSystemField(sss, Shared_Solar_System__c.Committed_Demand_Capacity__c, sumCapacity(committedDemandCapacityList));
    }

    /**
     * @description Determines if a subscription should be in the particular Pending or Committed bucket
     * @param uas Utility_Account_Subscription__c
     * @param committedCapacityList Committed capacity list in question (e.g. Demand, Small CS, etc.)
     * @param pendingCapacityList Pending capacity list in question (e.g. Demand, Small CS, etc.)
     */
    private void addCapacityToCapacityList(
        Utility_Account_Subscription__c uas, List<Utility_Account_Subscription__c> committedCapacityList,
        List<Utility_Account_Subscription__c> pendingCapacityList) {
        if (uas.Opportunity_Stage__c == 'Complete') {
            committedCapacityList.add(uas);
        } else if (!isCancelledStatus(uas)) {
            pendingCapacityList.add(uas);
        }
    }

    /**
     * @description Checks if the rollup field calculation differs from the database, updates the respective
     *      SObjectField with the correct data if it needs, and registers the change with fflib_SObjectUnitOfWork
     * @param sss Shared_Solar_System__c record in question
     * @param field SObjectField
     * @param value Field value
     */
    private void updateSystemField(Shared_Solar_System__c sss, SObjectField field, Object value) {
        if (sss.get(field) != value) {
            sss.put(field, value);
            uow.registerDirty(sss, new List<SObjectField>{
                field
            });
            if (logChanges) { // TODO: Deprecate in the future if realtime updates work as expected
                String message = 'Out of sync field ' + field + ' on system ' + sss.Id + '/' + sss.Name +
                    '. Expected: ' + value + ', Actual: ' + sss.get(field);
                Logger.logLater('SystemCapacityRollupCalculator', 'updateSystemField', message, Logger.ERROR);
            }
        }
    }

    /**
     * @description Summarizes capacity based on subscriptions
     * @param uasList List of subscriptions for a particular Shared_Solar_System__c
     * @return Decimal (sum) value of Future_Customer_Subscription_KWDC_Rollup__c for all subscriptions in the list
     */
    private Decimal sumCapacity(List<Utility_Account_Subscription__c> uasList) {
        Decimal summarizedCapacity = 0;
        for (Utility_Account_Subscription__c uas : uasList) {
            summarizedCapacity += Util.nullToZero(uas.Future_Customer_Subscription_KWDC_Rollup__c);
        }
        return summarizedCapacity;
    }

    /**
     * @description Determines if a subscription is for an Anchor or Public Offtake customer
     * @param uas Utility_Account_Subscription__c
     * @return Bool if subscription is Anchor/Public Offtake
     */
    private Boolean isAnchorOrPublicOfftake(Utility_Account_Subscription__c uas) {
        return (uas.Customer_Group__c == 'Anchor' || uas.Opportunity__r.Customer_Sub_Group__c == 'Public Offtake');
    }

    /**
     * @description Determines if a subscription meets criteria for 'Cancelled' based on various opp stages
     * @param uas Utility_Account_Subscription__c
     * @return Bool if subscription is 'Cancelled'
     */
    private Boolean isCancelledStatus(Utility_Account_Subscription__c uas) {
        return (uas.Opportunity_Stage__c == 'Expired'
            || uas.Opportunity_Stage__c == 'Cancelled'
            || uas.Opportunity_Stage__c == 'DUPLICATE'
            || uas.Opportunity_Stage__c == 'Unqualified'
            || uas.Opportunity_Stage__c == 'Rejected Contract'
            || uas.Opportunity_Stage__c == 'Dead'
            || uas.Opportunity_Stage__c == 'Lost'
        );
    }
}