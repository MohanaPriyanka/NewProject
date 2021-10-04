/**
 * @description  Created by mstackhouse on 12/17/2018.
 * Test: UtilityAccountLogTriggerHandlerTest, CSCancellationServiceTest
 */
public without sharing class UtilityAccountLogTriggerHandler {
    
    private Map<Id, Utility_Account_Log__c> oldMap;
    private List<Utility_Account_Log__c> newList;

    public UtilityAccountLogTriggerHandler(Map<Id, Utility_Account_Log__c> oldMap, List<Utility_Account_Log__c> newList) {
        this.oldMap = oldMap;
        this.newList = newList;
    }
    
    public void beforeInsert() {
        setCleanedUtilityAccountNumberBeforeSave();
    }
    
    public void beforeUpdate() {
        setCleanedUtilityAccountNumberBeforeSave();
    }

    public void afterUpdate() {
        List<Utility_Account_Subscription__c> uasesToFinal =
            CSCancellationService.getUASesForFinaledUALs(newList, oldMap);
        if (!uasesToFinal.isEmpty()) {
            CSCancellationService.processFinaledUtilityAccounts(uasesToFinal);
        }
        Set<Id> leadIdSet = new Set<Id>();
        for (Utility_Account_Log__c ual : newList) {
            if (ual.Utility_Rate_Class__c != oldMap.get(ual.Id).Utility_Rate_Class__c) {
                leadIdSet.add(ual.Lead__c);
            }
        }
        if (!leadIdSet.isEmpty()) {
            updateRateClassOnContract(leadIdSet);
        }
        new SystemCapacityRollupCalculator(new UALCapacityRollupInitializer(oldMap, newList)).performRollup();
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void updateRateClassOnContract(Set<Id> leadIdSet) {
        List<Lead> leadList = [
            SELECT Id, (
                SELECT Id, Generate_Disclosure_Form__c, Product__c, Product__r.Disclosure_Form_Conga_Template__c
                FROM Contracts__r
            ), (
                SELECT Id, Utility_Rate_Class__c, Utility_Rate_Class__r.Suppress_Disclosure_Form__c
                FROM Utility_Account_Logs__r
            )
            FROM Lead
            WHERE Id = :leadIdSet
        ];
        List<Contract> contractsForUpdate = new List<Contract>();
        for (Lead associatedLead : leadList) {
            for (Contract c : associatedLead.Contracts__r) {
                Boolean generateDisclosureForm = calculateGenerateDisclosureForm(c.Product__r, associatedLead.Utility_Account_Logs__r);
                if (c.Generate_Disclosure_Form__c != generateDisclosureForm) {
                    c.Generate_Disclosure_Form__c = generateDisclosureForm;
                    c.Generate_Review_Version__c = true;
                    contractsForUpdate.add(c);
                }
            }
        }
        if (!contractsForUpdate.isEmpty()) {
            Util.updateAndLog(contractsForUpdate, 'UtilityAccountLogTriggerHandler', 'updateRateClassOnContract');
        }
    }

    private Boolean calculateGenerateDisclosureForm(Product2 product, List<Utility_Account_Log__c> ualList) {
        if (product == null || product.Disclosure_Form_Conga_Template__c == null) {
            return false;
        }
        Boolean allSuppress = true;
        Boolean allNull = true;
        for (Utility_Account_Log__c ual : ualList) {
            if (ual.Utility_Rate_Class__c != null) {
                allNull = false;
            }
            if (ual.Utility_Rate_Class__c == null || !ual.Utility_Rate_Class__r.Suppress_Disclosure_Form__c) {
                allSuppress = false;
            }
        }
        if (allNull) {
            return true;
        }
        if (allSuppress) {
            return false;
        }
        return true;
    }

    /**
     * @description Strips dashes and leading 0's from Utility Account Numbers and sets in a new text field, for duplicate
     * purposes
     */
    private void setCleanedUtilityAccountNumberBeforeSave() {
        for (Utility_Account_Log__c utilityAccountLog : newList) {
            utilityAccountLog.Cleaned_Utility_Account_Number__c = cleanUtilityAccountNumber(utilityAccountLog.Name);
        }
    }

    @TestVisible
    private String cleanUtilityAccountNumber(String utilityAccountNumber) {
        if (utilityAccountNumber == null) {
            return null;
        }
        String cleaned = utilityAccountNumber.remove('-').remove(' ');
        return stripLeadingCharacter(cleaned, '0');
    }

    private String stripLeadingCharacter(String dirtyString, String stringToStrip) {
        Integer indexOfNonSpace = dirtyString.indexOfAnyBut(stringToStrip);
        if (indexOfNonSpace != -1) {
            return dirtyString.substring(dirtyString.indexOfAnyBut(stringToStrip));
        }
        return '';
    }
}