/**
 * Created by SarahRenfro on 12/2/2019.
 *
 * Tested By: UtilityAccountSubscriptionHandlerTest
 */

public without sharing class UtilityAccountSubscriptionHandler {

    public static void assignSSS(List<Utility_Account_Subscription__c> uasList) {
        Set<Id> oppIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : uasList) {
            oppIds.add(uas.Opportunity__c);
        }

        Map<Id, Opportunity> uasToOppMap = OpportunitiesSelector.selectOpportunityMap(oppIds);

        for (Utility_Account_Subscription__c uas : uasList) {
            Opportunity opp = uasToOppMap.get(uas.Opportunity__c);
            try {
                uas.Shared_Solar_System__c = opp.Shared_Solar_System__c;
            } catch (Exception e) {
                Logger.logNow('UtilityAccountSubscriptionHandler', 'onBeforeInsert', JSON.serialize(uas) + '\n' + 'Unable to populate SSS on UAS: ' + e.getMessage() +
                '\n' + e.getStackTraceString());
            }
        }
    }


    public static void assignSSS(List<Utility_Account_Subscription__c> uases, Map<Id, Utility_Account_Subscription__c> oldMap) {
        Set<Id> oppIds = new Set<Id>();
        Set<Id> uasIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : uases) {
            uasIds.add(uas.Id);
            oppIds.add(uas.Opportunity__c);
        }

        Map<Id, Opportunity> uasToOppMap = OpportunitiesSelector.selectOpportunityMap(oppIds);
        List<Utility_Account_Subscription__c> uasList = UASSelector.selectByIds(uasIds);

        List<Utility_Account_Subscription__c> uasListForClients = new List<Utility_Account_Subscription__c>();
        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Opportunity__c != null && oldMap.get(uas.Id).Opportunity__c == null && uas.Shared_Solar_System__c == null) {
                Opportunity opp = uasToOppMap.get(uas.Opportunity__c);
                uasListForClients.add(uas);
                    uas.Shared_Solar_System__c = opp.Shared_Solar_System__c;
            }
        }

        //Create a client UAS because it wasn't created onInsert because Opp was missing from UAS
        if (uasListForClients.size() > 0) {
            ClientReportingService.insertClientUAS(uasListForClients);
            try {
                update uasList;
            } catch (Exception e ) {
                Logger.logNow('UtilityAccountSubscriptionHandler', 'onBeforeUpdate', JSON.serialize(uasList) + '\n' + 'Unable to populate SSS on UASes: ' + e.getMessage() +
                    '\n' + e.getStackTraceString());
            }
        }

    }
}