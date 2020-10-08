/**
 * Created by lholmes_gearscrm on 8/17/2020.
 * Description: Used to query rate classes
 * Test: RateClassesSelectorTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class RateClassesSelector {
    
    public List<Rate_Class__c> selectByUtilities(Set<Id> utilityIds) {
        return [
            SELECT Id, Name, Suppress_Disclosure_Form__c
            FROM Rate_Class__c
            WHERE Utility__c = :utilityIds
            ORDER BY Name
        ];
    }

    public List<Rate_Class__c> selectByName(String name) {
        return [
            SELECT Id, Name, Suppress_Disclosure_Form__c
            FROM Rate_Class__c 
            WHERE Name = :name
            ORDER BY Name
        ];
    }

    public List<Rate_Class__c> selectByNameAndUtility(String name, String utilityId) {
        return [
            SELECT Id, Name, Suppress_Disclosure_Form__c
            FROM Rate_Class__c 
            WHERE Name = :name AND Utility__c = :utilityId
            ORDER BY Name
        ];
    }
    
    public Map<String, Rate_Class__c> selectWithEDI() {
        Map<String, Rate_Class__c> rateClassEDIMap = new Map<String, Rate_Class__c>();

        List<Rate_Class__c> rateClassWithEDI = [
            SELECT Id, Name, EDI_Rate_Class__c, Utility__c 
            FROM Rate_Class__c 
            WHERE EDI_Rate_Class__c != NULL
        ];

        for(Rate_Class__c rateClass : rateClassWithEDI) {
            rateClassEDIMap.put(rateClass.EDI_Rate_Class__c, rateClass);
        }
        
        return rateClassEDIMap;
    }
    
}