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

        List<Utility_Account_Log__c> ualsForRateClassUpdate = new List<Utility_Account_Log__c>();
        Set<Id> leadIdSet = new Set<Id>();
        Set<Id> rateClassIdSet = new Set<Id>();
        for(Utility_Account_Log__c ual : newUALs) {
            if(ual.Utility_Rate_Class__c != oldMap.get(ual.Id).Utility_Rate_Class__c) {
                ualsForRateClassUpdate.add(ual);
                leadIdSet.add(ual.Lead__c);
                rateClassIdSet.add(ual.Utility_Rate_Class__c);
            }
        }
        if(!ualsForRateClassUpdate.isEmpty()) {
            updateRateClassOnContract(ualsForRateClassUpdate, leadIdSet, rateClassIdSet);
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

    private static void updateRateClassOnContract(List<Utility_Account_Log__c> ualList, Set<Id> leadIdSet, Set<Id> rateClassIdSet) {
        Map<Id, Rate_Class__c> rateClassMap = new Map<Id, Rate_Class__c>([
            SELECT Id, Suppress_Disclosure_Form__c
            FROM Rate_Class__c
            WHERE Id = :rateClassIdSet
        ]);
        Map<Id, Lead> leadMap = new Map<Id, Lead>([
            SELECT Id, 
                (SELECT Id, Generate_Disclosure_Form__c, Product__c, Product__r.Disclosure_Form_Conga_Template__c
                FROM Contracts__r)
            FROM Lead
            WHERE Id = :leadIdSet
        ]);

        List<Contract> contractsForUpdate = new List<Contract>();
        for(Utility_Account_Log__c ual : ualList) {
            Lead associatedLead = leadMap.get(ual.Lead__c);
            Rate_Class__c associatedRateClass;
            if(rateClassMap.containsKey(ual.Utility_Rate_Class__c)) {
                associatedRateClass = rateClassMap.get(ual.Utility_Rate_Class__c);
            } else {
                associatedRateClass = new Rate_Class__c();
            }
            for(Contract c : associatedLead.Contracts__r) {
                if(c.Product__r != null) {
                    c.Generate_Disclosure_Form__c = calculateGenerateDisclosureForm(c.Product__r.Disclosure_Form_Conga_Template__c, associatedRateClass.Suppress_Disclosure_Form__c);
                } else {
                    c.Generate_Disclosure_Form__c = calculateGenerateDisclosureForm(null, associatedRateClass.Suppress_Disclosure_Form__c);
                }
                contractsForUpdate.add(c);
            }
        }

        if(!contractsForUpdate.isEmpty()) {
            Util.updateAndLog(contractsForUpdate, 'UtilityAccountLogTriggerHandler', 'updateRateClassOnContract');
        }
    }

    private static Boolean calculateGenerateDisclosureForm(String disclosureFormTemplate, Boolean suppressDisclosureForm) {
        if(disclosureFormTemplate == null) {
            return false;
        }

        if(suppressDisclosureForm == null || !suppressDisclosureForm) {
            return true;
        }

        return false;
    }


}