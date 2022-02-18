/**
 * @description Created by SarahRenfro on 12/2/2019.
 * Tested By: UtilityAccountSubscriptionHandlerTest, PartnerCommissionHandlerTest
 */
public without sharing class UtilityAccountSubscriptionHandler {

    @TestVisible private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    @TestVisible private static PartnerCommissionHandler partnerCommissionHandler = new PartnerCommissionHandler();
    private SubscriptionManagementService subscriptionManagementService = new SubscriptionManagementService();
    private Map<Id,Utility_Account_Subscription__c> oldMap;
    private List<Utility_Account_Subscription__c> newList;
    private TriggerOperation triggerType;
    @TestVisible private static UALSelector ualSelector = new UALSelector();
    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();


    public UtilityAccountSubscriptionHandler(Map<Id,Utility_Account_Subscription__c> oldMap,
        List<Utility_Account_Subscription__c> newList, TriggerOperation triggerOperation) {
        this.oldMap = oldMap;
        this.newList = newList;
        this.triggerType = triggerOperation;
    }

    public void beforeInsert() {
        assignSSSBeforeInsert();
        verifyUALSubscriptionType();
    }

    public void afterInsert() {
        ClientReportingService.insertClientUAS(newList);
        new SystemCapacityRollupCalculator(new UASCapacityRollupInitializer(oldMap, newList, triggerType)).performRollup();
    }

    public void beforeUpdate() {
        assignSSSBeforeUpdate();
    }

    public void afterUpdate() {
        CSCancellationProjectRemover.handleOpportunitiesRemovedFromProject(oldMap, new Map<Id,Utility_Account_Subscription__c>(newList));
        ClientReportingService.updateClientUAS(newList, oldMap);
        new SystemCapacityRollupCalculator(new UASCapacityRollupInitializer(oldMap, newList, triggerType)).performRollup();
    }

    public void beforeDelete() {
        subscriptionManagementService.publishSubscriptionOrderChangeEventsOnDelete(null, oldMap);
        ClientReportingService.deleteClientUAS(Trigger.old);
    }

    public void afterDelete() {
        new SystemCapacityRollupCalculator(new UASCapacityRollupInitializer(oldMap, newList, triggerType)).performRollup();
    }

    public void afterUndelete() {
        new SystemCapacityRollupCalculator(new UASCapacityRollupInitializer(oldMap, newList, triggerType)).performRollup();
    }

    private void assignSSSBeforeInsert() {
        Set<Id> oppIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : newList) {
            oppIds.add(uas.Opportunity__c);
        }
        Map<Id, Opportunity> uasToOppMap = oppSelector.selectOpportunityMap(oppIds);
        for (Utility_Account_Subscription__c uas : newList) {
            Opportunity opp = uasToOppMap.get(uas.Opportunity__c);
            if (uas.Shared_Solar_System__c == null) {
                uas.Shared_Solar_System__c = opp?.Shared_Solar_System__c;
            }
        }
    }

    @TestVisible
    private void verifyUALSubscriptionType() {
        Set<Id> ualIds = new Set<Id>();
        Set<Id> sssIds = new Set<Id>();

        for (Utility_Account_Subscription__c uas : newList) {
            ualIds.add(uas.Utility_Account_Log__c);
            sssIds.add(uas.Shared_Solar_System__c);
        }

        MultiMap ualIdToUASesMap = CollectionUtil.multiMapByField(newList, Utility_Account_Subscription__c.Utility_Account_Log__c);
        Map<Id,Utility_Account_Log__c> ualMap = ualSelector.selectUALSWithActiveUASMap(ualIds); // map of ual id and ual with all exiting uas records
        Map<Id,Shared_Solar_System__c> sssMap = getSSSMap(sssIds, ualMap); // map of all solar systems related to the uas records (new and existing)

        for (Utility_Account_Subscription__c uas : newList) {
            Utility_Account_Log__c ual = ualMap.get(uas.Utility_Account_Log__c);
            List<Utility_Account_Subscription__c> existingUASList = ual.Utility_Account_Subscriptions__r;
            List<Utility_Account_Subscription__c> newRelatedUAS = (List<Utility_Account_Subscription__c>) CollectionUtil.toTypedList(ualIdToUASesMap.getValues(uas.Utility_Account_Log__c), new List<Utility_Account_Subscription__c>());
            List<Utility_Account_Subscription__c> combinedRelatedUASList = new List<Utility_Account_Subscription__c>();
            combinedRelatedUASList.addAll(existingUASList);
            combinedRelatedUASList.addAll(newRelatedUAS);

            if (uas.Shared_Solar_System__c == null || (existingUASList.size() == 0 && newRelatedUAS.size() == 1) || verifyMultipleSubscriptionsAllowedByRelatedUAS(combinedRelatedUASList, sssMap)) {
                continue;
            }
            uas.addError('Only a single subscription per Utility Account is allowed for UAL: ' + ual.Id);
        }


    }

    private Map<Id,Shared_Solar_System__c> getSSSMap(Set<Id> sssIds, Map<Id,Utility_Account_Log__c> ualMap) {

        for (Utility_Account_Log__c ual : ualMap.values()) {
            List<Utility_Account_Subscription__c> uasList = ual.Utility_Account_Subscriptions__r;

            for (Utility_Account_Subscription__c uas: uasList) {
                sssIds.add(uas.Shared_Solar_System__c);
            }
        }

        Map<Id,Shared_Solar_System__c> sssMap = sssSelector.getSSSMap(sssIds);
        return sssMap;
    }

    private Boolean verifyMultipleSubscriptionsAllowedByRelatedUAS(List<Utility_Account_Subscription__c> uasList, Map<Id,Shared_Solar_System__c> sssMap) {
        for (Utility_Account_Subscription__c uas : uasList) {
            Shared_Solar_System__c sss = sssMap.get(uas.Shared_Solar_System__c);
            if (sss.Product__r.Utility_Account_Subscription_Type__c == 'Single subscription per Utility Account') {
                return false;
            }
        }
        return true;
    }

    public void assignSSSBeforeUpdate() {
        Set<Id> oppIds = new Set<Id>();
        List<Utility_Account_Subscription__c> uasesWithUpdatedOpportunities = new List<Utility_Account_Subscription__c>();
        for (Utility_Account_Subscription__c uas : newList) {
            if (uas.Opportunity__c != null && (
                (uas.Opportunity__c != oldMap.get(uas.Id).Opportunity__c) || oldMap.get(uas.Id).Opportunity__c == null)) {
                uasesWithUpdatedOpportunities.add(uas);
                oppIds.add(uas.Opportunity__c);
            }
        }
        Map<Id, Opportunity> uasToOppMap = oppSelector.selectOpportunityMap(oppIds);
        for (Utility_Account_Subscription__c uas : uasesWithUpdatedOpportunities) {
            Opportunity opp = uasToOppMap.get(uas.Opportunity__c);
            uas.Shared_Solar_System__c = opp.Shared_Solar_System__c;
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static void rollupAnchorUASes() {
        UASBSelector uasbSelector = new UASBSelector();
        List<AggregateResult> anchorAggregateResults = uasbSelector.selectAggregateAnchorUASBs();
        List<Utility_Account_Subscription__c> anchorUASes = new List<Utility_Account_Subscription__c>();
        for (AggregateResult result : anchorAggregateResults) {
            Utility_Account_Subscription__c anchorUAS = new Utility_Account_Subscription__c(
                Id = (Id) result.get('uasId'),
                Annual_Subscription_Production_Summary__c = (Decimal) result.get('productionSummary')
            );
            anchorUASes.add(anchorUAS);
        }
        GenericBatchDMLOperation batchDMLOperation = new GenericBatchDMLOperation(anchorUASes, 'Update');
        Database.executeBatch(batchDMLOperation);
    }
}