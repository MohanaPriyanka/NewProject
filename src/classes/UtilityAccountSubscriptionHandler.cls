/**
 * Created by SarahRenfro on 12/2/2019.
 *
 * Tested By: UtilityAccountSubscriptionHandlerTest, PartnerCommissionHandlerTest
 */

public without sharing class UtilityAccountSubscriptionHandler {
    @TestVisible
    private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    @TestVisible
    private static PartnerCommissionHandler partnerCommissionHandler = new PartnerCommissionHandler();

    public static void assignSSSBeforeInsert(List<Utility_Account_Subscription__c> uasList) {
        Set<Id> oppIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : uasList) {
            oppIds.add(uas.Opportunity__c);
        }

        Map<Id, Opportunity> uasToOppMap = oppSelector.selectOpportunityMap(oppIds);

        for (Utility_Account_Subscription__c uas : uasList) {
            Opportunity opp = uasToOppMap.get(uas.Opportunity__c);
            if (opp != null && uas.Shared_Solar_System__c == null) {
                uas.Shared_Solar_System__c = opp.Shared_Solar_System__c;
            }
        }
    }

    public static void assignSSSBeforeUpdate(List<Utility_Account_Subscription__c> uasList, Map<Id, Utility_Account_Subscription__c> oldMap) {
        Set<Id> oppIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : uasList) {
            oppIds.add(uas.Opportunity__c);
        }

        Map<Id, Opportunity> uasToOppMap = oppSelector.selectOpportunityMap(oppIds);

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Opportunity__c != null && oldMap.get(uas.Id).Opportunity__c == null && uas.Shared_Solar_System__c == null) {
                Opportunity opp = uasToOppMap.get(uas.Opportunity__c);
                uas.Shared_Solar_System__c = opp.Shared_Solar_System__c;
            }
        }
    }

    public static void recalculateCommissionOnUpdate(List<Utility_Account_Subscription__c> uasList, Map<Id, Utility_Account_Subscription__c> oldMap){
        Set<Id> oppIds = new Set<Id>();
        for (Utility_Account_Subscription__c newUAS : uasList) {
            Utility_Account_Subscription__c oldUAS = oldMap.get(newUAS.Id);
            //TODO: Uases shouldnt be changing opps when subscription orders are live
            oppIds = checkForOppChange(oldUAS.Opportunity__c, newUAS.Opportunity__c, oppIds);
            if (hasSubscriptionChange(oldUAS,newUAS)){
                oppIds.add(newUAS.Opportunity__c);
            }
        }
        if (oppIds.size() > 0){
            partnerCommissionHandler.queueCalculatePartnerCommission(oppIds);
        }
    }

    private static Boolean hasSubscriptionChange(Utility_Account_Subscription__c oldUAS, Utility_Account_Subscription__c newUAS){
        FeatureService featureService = new FeatureService();
        Decimal oldSize;
        Decimal newSize;
        if (featureService.isEnabled('Subscription_Orders')){
            oldSize = oldUAS.Future_Customer_Subscription_KWDC_Rollup__c;
            newSize = newUAS.Future_Customer_Subscription_KWDC_Rollup__c;
        } else {
            // This doesn't catch everything, like SSS updates on the Opp, NMC tariff changes, yield updates, etc.
            // But will tide us over to the Subscription Order work is live ^
            oldSize = oldUAS.Customer_Subscription_KW_DC__c;
            newSize = newUAS.Customer_Subscription_KW_DC__c;
        }
        return oldSize != newSize;
    }

    private static Set<Id> checkForOppChange(Id oldOpp, Id newOpp, Set<Id> oppIds){
        if (newOpp != oldOpp) {
            if (oldOpp != null) {
                oppIds.add(oldOpp);
            }
            if (newOpp != null) {
                oppIds.add(newOpp);
            }
        }
        return oppIds;
    }

    public static void recalculateCommissionOnInsertOrDelete(List<Utility_Account_Subscription__c> uasList){
        Set<Id> oppIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : uasList){
            if (uas.Opportunity__c != null){
                oppIds.add(uas.Opportunity__c);
            }
        }
        if (oppIds.size() > 0){
            partnerCommissionHandler.queueCalculatePartnerCommission(oppIds);
        }
    }

    public static void rollupAnchorUASes() {
        UASBSelector uasbSelector = new UASBSelector();
        List<AggregateResult> anchorAggregateResults = uasbSelector.selectAggregateAnchorUASBs();
        List<Utility_Account_Subscription__c> anchorUASes = new List<Utility_Account_Subscription__c>();
        for (AggregateResult result : anchorAggregateResults) {
            Utility_Account_Subscription__c anchorUAS = new Utility_Account_Subscription__c(
                Id = (Id)result.get('uasId'),
                Annual_Subscription_Production_Summary__c = (Decimal)result.get('productionSummary')
            );
            anchorUASes.add(anchorUAS);
        }

        update anchorUASes;
    }
}