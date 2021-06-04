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
        List<Utility_Account_Subscription__c> uasesWithUpdatedOpportunities = new List<Utility_Account_Subscription__c>();
        for (Utility_Account_Subscription__c uas : uasList) {
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
                Id = (Id)result.get('uasId'),
                Annual_Subscription_Production_Summary__c = (Decimal)result.get('productionSummary')
            );
            anchorUASes.add(anchorUAS);
        }
        GenericBatchDMLOperation batchDMLOperation = new GenericBatchDMLOperation(anchorUASes, 'Update');
        Database.executeBatch(batchDMLOperation);
    }
    
    public static void checkScheduleZStatus(Map<Id, Utility_Account_Subscription__c> newUASMap, Map<Id, Utility_Account_Subscription__c> oldUASMap){
        Map<Id,Utility_Account_Subscription__c> uasUpdatedStatusInactiveMap = new Map<Id,Utility_Account_Subscription__c>();
        List<Id> updatedUasOppIdList = new List<Id>();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{Opportunity.SObjectType});
        
        for (Utility_Account_Subscription__c uas : newUASMap.values()){
            if ((uas.Next_Schedule_Z_Status__c == 'Inactive Subscription' && oldUASMap.get(uas.Id).Next_Schedule_Z_Status__c != 'Inactive Subscription') && 
                (uas.Total_Count_of_Schedule_Zs__c == 0 || uas.Total_Count_of_Schedule_Zs__c == null)){
                uasUpdatedStatusInactiveMap.put(uas.Id,uas);
                updatedUasOppIdList.add(uas.Opportunity__c);
            } else if (uas.Next_Schedule_Z_Status__c == 'Inactive Subscription' && 
                ((uas.Total_Count_of_Schedule_Zs__c == 0 || uas.Total_Count_of_Schedule_Zs__c == null) && (oldUASMap.get(uas.Id).Total_Count_of_Schedule_Zs__c > 0))){
                uasUpdatedStatusInactiveMap.put(uas.Id,uas);
                updatedUasOppIdList.add(uas.Opportunity__c);
            }
        }
        List<Opportunity> updatedUasOpportunities = OpportunitiesSelector.selectByIds(updatedUasOppIdList);
        for(Opportunity opp : updatedUasOpportunities){
            opp.StageName = 'Cancelled';
            uow.registerDirty(opp);
        }
        uow.commitWork();
    }
    
}