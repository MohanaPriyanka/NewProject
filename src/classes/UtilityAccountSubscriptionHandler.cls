/**
 * @description Created by SarahRenfro on 12/2/2019.
 * Tested By: UtilityAccountSubscriptionHandlerTest, PartnerCommissionHandlerTest
 */
public without sharing class UtilityAccountSubscriptionHandler {

    @TestVisible private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    @TestVisible private static PartnerCommissionHandler partnerCommissionHandler = new PartnerCommissionHandler();
    private FeatureService featureService = new FeatureService();
    private SubscriptionManagementService subscriptionManagementService = new SubscriptionManagementService();
    private Map<Id,Utility_Account_Subscription__c> oldMap;
    private List<Utility_Account_Subscription__c> newList;
    private TriggerOperation triggerType;
    private UALSelector ualSelector = new UALSelector();

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
        if (Test.isRunningTest() && featureService.isEnabled('Subscription_Orders')) {
            subscriptionManagementService.insertSubscriptionOrdersForTests(newList);
        }
        new SystemCapacityRollupCalculator(new UASCapacityRollupInitializer(oldMap, newList, triggerType)).performRollup();
    }

    public void beforeUpdate() {
        assignSSSBeforeUpdate();
    }

    public void afterUpdate() {
        CSCancellationProjectRemover.handleOpportunitiesRemovedFromProject(oldMap, constructNewMap());
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

    private Map<Id,Utility_Account_Subscription__c> constructNewMap() {
        Map<Id,Utility_Account_Subscription__c> returnMap = new Map<Id,Utility_Account_Subscription__c>();
        for (Utility_Account_Subscription__c uas : newList) {
            returnMap.put(uas.Id, uas);
        }
        return returnMap;
    }
    
    private void assignSSSBeforeInsert() {
        Set<Id> oppIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : newList) {
            oppIds.add(uas.Opportunity__c);
        }
        Map<Id, Opportunity> uasToOppMap = oppSelector.selectOpportunityMap(oppIds);
        for (Utility_Account_Subscription__c uas : newList) {
            Opportunity opp = uasToOppMap.get(uas.Opportunity__c);
            if (opp != null && uas.Shared_Solar_System__c == null) {
                uas.Shared_Solar_System__c = opp.Shared_Solar_System__c;
            }
        }
    }

    private void verifyUALSubscriptionType() {
        Set<Id> ualIds = new Set<Id>();

        for (Utility_Account_Subscription__c uas : newList) {
            ualIds.add(uas.Utility_Account_Log__c);
        }

        Map<Id,Utility_Account_Log__c> ualMap = ualSelector.selectUALSWithUASMap(ualIds);

        for (Utility_Account_Subscription__c uas : newList) {
            Utility_Account_Log__c ual = ualMap.get(uas.Utility_Account_Log__c);
            List<Utility_Account_Subscription__c> childUASList = ual.Utility_Account_Subscriptions__r;
            if (childUASList.size() == 0) {
                continue;
            }
            if (verifyMultipleSubscriptionsAllowed(childUASList)) {
                continue;
            }
            throw new Util.BWException('A UAS already exists for this UAL and only a single subscription per Utility Account is allowed.');
        }

    }

    private Boolean verifyMultipleSubscriptionsAllowed(List<Utility_Account_Subscription__c> uasList) {
        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Shared_Solar_System__r.Product__r.Utility_Account_Subscription_Type__c == 'Single subscription per Utility Account') {
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