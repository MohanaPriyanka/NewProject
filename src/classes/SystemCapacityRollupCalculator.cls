/**
 * @description Created by jeffparlin on 9/9/21.
 * - Gathers Shared_Solar_System__c records which are in need of capacity (rollup) field recalculation based on related record
 *     changes, and performs the recalculation in realtime (synchronously)
 * - Fields on Shared_Solar_System__c modified: Shared_Solar_System__c.Capacity_Committed_kW_DC__c, etc.
 * - If in the future changes to other object types should result in this same sort of recalculation, create a new class
 *     which implements SystemCapacityRollupCalculator.Initializer
 *
 * Tested By: SystemCapacityRollupCalculatorTest, SharedSolarSystemHandlerTest
 */
public without sharing class SystemCapacityRollupCalculator {

    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    private Initializer initializer;
    private Set<Id> systemIds;
    private List<Shared_Solar_System__c> systems;
    private MultiMap uasesByCapacityType;
    private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
        Shared_Solar_System__c.SObjectType
    });

    /**
     * @description Constructor for use when Shared_Solar_System__c records change
     * @param sharedSolarSystemIds List of Shared_Solar_System__c records to process (typically from SSS Trigger.new)
     */
    public SystemCapacityRollupCalculator(Set<Id> sharedSolarSystemIds) {
        this.systemIds = sharedSolarSystemIds;
    }

    /**
     * @description Constructor for use when other (related) object records change
     * @param init Initializer interface to use with the class to determine systems to inspect
     */
    public SystemCapacityRollupCalculator(Initializer init) {
        this.initializer = init;
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
        if (initializer != null) {
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
     * @param sssTriggerNewMap Trigger.newMap from SharedSolarSystemHandler/SharedSolarSystemTrigger
     */
    public void performRollupBeforeUpdate(Map<Id, Shared_Solar_System__c> sssTriggerNewMap) {
        systems = sssSelector.getSSSWithActiveUASes(systemIds);
        summarizeCapacityBeforeUpdate(sssTriggerNewMap);
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
        uasesByCapacityType = MultiMap.newListInstance();
        for (Utility_Account_Subscription__c uas : sssWithActiveUASes.Utility_Account_Subscriptions__r) {
            addCapacityToCapacityList(uas);
            if (isDemandSubscription(sssWithActiveUASes, uas)) {
                addDemandCapacityToCapacityList(uas);
            }
        }
    }

    private void addDemandCapacityToCapacityList(Utility_Account_Subscription__c uas) {
        if (uas.Opportunity__r.StageName == 'Complete') {
            uasesByCapacityType.putValue('Committed Demand', uas);
        } else if (!isCancelledStatus(uas)) {
            uasesByCapacityType.putValue('Pending Demand', uas);
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
        updateSystemField(sss, Shared_Solar_System__c.Pending_Small_CS_Capacity__c, sumCapacity(uasesByCapacityType.getValues('Pending Perch Small CS')));
        updateSystemField(sss, Shared_Solar_System__c.Capacity_Committed_kW_DC__c, sumCapacity(uasesByCapacityType.getValues('Committed Perch Small CS')));
        updateSystemField(sss, Shared_Solar_System__c.Pending_Anchor_Capacity__c, sumCapacity(uasesByCapacityType.getValues('Pending Perch Anchor')));
        updateSystemField(sss, Shared_Solar_System__c.Anchor_Capacity_Reserved__c, sumCapacity(uasesByCapacityType.getValues('Committed Perch Anchor')));
        updateSystemField(sss, Shared_Solar_System__c.Perch_Acq_Pending_LMI_Capacity__c, sumCapacity(uasesByCapacityType.getValues('Pending Perch LMI')));
        updateSystemField(sss, Shared_Solar_System__c.Perch_Acq_Committed_LMI_Capacity__c, sumCapacity(uasesByCapacityType.getValues('Committed Perch LMI')));

        updateSystemField(sss, Shared_Solar_System__c.Client_Acq_Pending_Small_CS_Capacity__c, sumCapacity(uasesByCapacityType.getValues('Pending Client Small CS')));
        updateSystemField(sss, Shared_Solar_System__c.Client_Acq_Committed_Small_CS_Capacity__c, sumCapacity(uasesByCapacityType.getValues('Committed Client Small CS')));
        updateSystemField(sss, Shared_Solar_System__c.Client_Acq_Pending_Anchor_Capacity__c, sumCapacity(uasesByCapacityType.getValues('Pending Client Anchor')));
        updateSystemField(sss, Shared_Solar_System__c.Client_Acq_Committed_Anchor_Capacity__c, sumCapacity(uasesByCapacityType.getValues('Committed Client Anchor')));
        updateSystemField(sss, Shared_Solar_System__c.Client_Acq_Pending_LMI_Capacity__c, sumCapacity(uasesByCapacityType.getValues('Pending Client LMI')));
        updateSystemField(sss, Shared_Solar_System__c.Client_Acq_Committed_LMI_Capacity__c, sumCapacity(uasesByCapacityType.getValues('Committed Client LMI')));

        updateSystemField(sss, Shared_Solar_System__c.Pending_Demand_Capacity__c, sumCapacity(uasesByCapacityType.getValues('Pending Demand')));
        updateSystemField(sss, Shared_Solar_System__c.Committed_Demand_Capacity__c, sumCapacity(uasesByCapacityType.getValues('Committed Demand')));
    }

    /**
     * @description Determines if a subscription should be in the particular Pending or Committed bucket
     * @param uas Utility_Account_Subscription__c
     */
    private void addCapacityToCapacityList(Utility_Account_Subscription__c uas) {
        String capacityKey = getCapacityKey(uas);
        if (!capacityKey.contains('Cancelled')) {
            uasesByCapacityType.putValue(capacityKey, uas);
        }
    }

    @TestVisible
    private String getCapacityKey(Utility_Account_Subscription__c uas) {
        String stageType;
        String responsibleParty;
        String customerType;
        if (uas.Opportunity__r.StageName == 'Complete') {
            stageType = 'Committed';
        } else if (!isCancelledStatus(uas)) {
            stageType = 'Pending';
        } else {
            stageType = 'Cancelled';
        }
        if (uas.Opportunity__r.Partner_Account__r.RecordType.Name == 'Client Account' ||
            uas.Opportunity__r.Partner_tag_lookup__r.Account__r.RecordType.Name == 'Client Account') {
            responsibleParty = 'Client';
        } else {
            responsibleParty = 'Perch';
        }
        if (uas.Opportunity__r.Customer_Group__c == 'Anchor' || uas.Opportunity__r.Customer_Sub_Group__c == 'Public Offtake') {
            customerType = 'Anchor';
        } else if (uas.Opportunity__r.Customer_Sub_Group__c == 'LMI') {
            customerType = 'LMI';
        } else {
            customerType = 'Small CS';
        }
        return stageType + ' ' + responsibleParty + ' ' + customerType;
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
            if (Request.getCurrent().getQuiddity() == Quiddity.SCHEDULED) { // TODO: Deprecate in the future if realtime updates work as expected
                String message = 'Out of sync field ' + field + ' on system ' + sss.Id + '/' + sss.Name +
                    '. Expected: ' + value + ', Actual: ' + sss.get(field);
                Logger.logLater('SystemCapacityRollupCalculator', 'updateSystemField', message, Logger.ERROR);
            }
            sss.put(field, value);
            uow.registerDirty(sss, new List<SObjectField>{
                field
            });
        }
    }

    /**
     * @description Summarizes capacity based on subscriptions
     * @param untypedUASList List of subscriptions for a particular Shared_Solar_System__c
     * @return Decimal (sum) value of Future_Customer_Subscription_KWDC_Rollup__c for all subscriptions in the list
     */
    private Decimal sumCapacity(List<Object> untypedUASList) {
        List<Utility_Account_Subscription__c> uasList = new List<Utility_Account_Subscription__c>();
        CollectionUtil.toTypedList(untypedUASList, uasList);
        Decimal summarizedCapacity = 0;
        for (Utility_Account_Subscription__c uas : uasList) {
            summarizedCapacity += Util.nullToZero(uas.Future_Customer_Subscription_KWDC_Rollup__c);
        }
        return summarizedCapacity;
    }

    /**
     * @description Determines if a subscription meets criteria for 'Cancelled' based on various opp stages
     * @param uas Utility_Account_Subscription__c
     * @return Bool if subscription is 'Cancelled'
     */
    private Boolean isCancelledStatus(Utility_Account_Subscription__c uas) {
        return (uas.Opportunity__r.StageName == 'Expired'
            || uas.Opportunity__r.StageName == 'Cancelled'
            || uas.Opportunity__r.StageName == 'DUPLICATE'
            || uas.Opportunity__r.StageName == 'Unqualified'
            || uas.Opportunity__r.StageName == 'Rejected Contract'
            || uas.Opportunity__r.StageName == 'Dead'
            || uas.Opportunity__r.StageName == 'Lost'
        );
    }
}