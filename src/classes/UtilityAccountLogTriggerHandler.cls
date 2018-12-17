/**
 * Created by mstackhouse on 12/17/2018.
 * Description: 
 * Test: 
 */


public without sharing class UtilityAccountLogTriggerHandler {
    public static void updateProposedkWh(List<Utility_Account_Log__c> uals, Map<Id, Utility_Account_Log__c> oldUALsByIds) {
        Set<Id> utilityNMCTariffs = new Set<Id>();
        for (Utility_Account_Log__c ual : uals) {
            utilityNMCTariffs.add(ual.Utility_NMC_Tariff__c);
        }

        Map<Id, Utility_NMC_Tariff__c> tariffsByIds = new Map<Id, Utility_NMC_Tariff__c>();

        for (Utility_NMC_Tariff__c tariff : [
            SELECT Id, Size_Ratio__c
            FROM Utility_NMC_Tariff__c
            WHERE Id IN : utilityNMCTariffs
        ]) {
            tariffsByIds.put(tariff.Id, tariff);
        }

        for (Utility_Account_Log__c ual : uals) {
            Utility_Account_Log__c oldUAL = oldUALsByIds.get(ual.Id);
            if (oldUAL.Annual_kWh__c != ual.Annual_kWh__c) {
                if (ual.Utility_NMC_Tariff__c != null) {
                    Utility_NMC_Tariff__c tariff = tariffsByIds.get(ual.Utility_NMC_Tariff__c);
                    ual.Proposed_kWh__c = ual.Annual_kWh__c * tariff.Size_Ratio__c;
                } else {
                    ual.Proposed_kWh__c = ual.Annual_kWh__c;
                }
            }
        }
    }
}