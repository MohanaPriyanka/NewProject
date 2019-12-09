/**
 * Created by SarahRenfro on 12/2/2019.
 *
 * Tested By: UtilityAccountSubscriptionHandlerTest
 */

public without sharing class UtilityAccountSubscriptionHandler {

    public static void assignSSSOnInsert(List<Utility_Account_Subscription__c> uasList) {
        Set<Id> oppIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : uasList) {
            oppIds.add(uas.Opportunity__c);
        }

        Map<Id, Opportunity> uasToOppMap = OpportunitiesSelector.selectOpportunityMap(oppIds);

        for (Utility_Account_Subscription__c uas : uasList) {
            Opportunity opp = uasToOppMap.get(uas.Opportunity__c);
            if (opp != null) {
                uas.Shared_Solar_System__c = opp.Shared_Solar_System__c;
            } else {
                Logger.logNow('UtilityAccountSubscriptionHandler', 'onBeforeInsert', JSON.serialize(uas) + '\n' + 'Unable to populate SSS from Opp on UAS because no Opp found for UAS');
            }
        }
    }


    public static void assignSSSOnUpdate(List<Utility_Account_Subscription__c> uasList, Map<Id, Utility_Account_Subscription__c> oldMap) {
        Set<Id> oppIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : uasList) {
            oppIds.add(uas.Opportunity__c);
        }

        Map<Id, Opportunity> uasToOppMap = OpportunitiesSelector.selectOpportunityMap(oppIds);

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Opportunity__c != null && oldMap.get(uas.Id).Opportunity__c == null && uas.Shared_Solar_System__c == null) {
                Opportunity opp = uasToOppMap.get(uas.Opportunity__c);
                uas.Shared_Solar_System__c = opp.Shared_Solar_System__c;
            }
        }



    }
}