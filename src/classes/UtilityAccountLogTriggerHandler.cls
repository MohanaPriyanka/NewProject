/**
 * Created by mstackhouse on 12/17/2018.
 * Description: 
 * Test: UtilityAccountLogTriggerHandler, CSCancellationService
 */


public without sharing class UtilityAccountLogTriggerHandler {
    public static void onAfterUpdate(Map<Id, Utility_Account_Log__c> oldMap, List<Utility_Account_Log__c> newUALs) {
        List<Utility_Account_Subscription__c> uasesToFinal =
            CSCancellationService.getUASesForFinaledUALs(newUALs, oldMap);
        if (!uasesToFinal.isEmpty()) {
            CSCancellationService.processFinaledUtilityAccounts(uasesToFinal);
        }
    }

    public static void updateProposedkWh(List<Utility_Account_Log__c> uals, Map<Id, Utility_Account_Log__c> oldUALsByIds) {
        Set<Id> productTariffs = new Set<Id>();
        for (Utility_Account_Log__c ual : uals) {
            productTariffs.add(ual.Product_Tariff__c);
        }

        Map<Id, Product_Tariff__c> tariffsByIds = new Map<Id, Product_Tariff__c>();

        for (Product_Tariff__c tariff : [
            SELECT Id, Size_Ratio__c
            FROM Product_Tariff__c
            WHERE Id IN :productTariffs
        ]) {
            tariffsByIds.put(tariff.Id, tariff);
        }

        for (Utility_Account_Log__c ual : uals) {
            Utility_Account_Log__c oldUAL = oldUALsByIds.get(ual.Id);
            if (oldUAL.Annual_kWh__c != ual.Annual_kWh__c) {
                if (ual.Product_Tariff__c != null) {
                    Product_Tariff__c tariff = tariffsByIds.get(ual.Product_Tariff__c);
                    ual.Proposed_kWh__c = ual.Annual_kWh__c * tariff.Size_Ratio__c;
                } else {
                    ual.Proposed_kWh__c = ual.Annual_kWh__c;
                }
            }
        }
    }
}