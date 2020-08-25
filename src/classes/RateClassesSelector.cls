/**
 * Created by lholmes_gearscrm on 8/17/2020.
 * Description: Used to query rate classes
 * Test: RateClassesSelectorTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class RateClassesSelector {
    
    public List<Rate_Class__c> selectByUtilities(Set<Id> utilityIds) {
        return [
            SELECT Id, Name
            FROM Rate_Class__c
            WHERE Utility__c = :utilityIds
            ORDER BY Name
        ];
    }

    public List<Rate_Class__c> selectByName(String name) {
        return [
            SELECT Id, Name 
            FROM Rate_Class__c 
            WHERE Name = :name
            ORDER BY Name
        ];
    }

    public List<Rate_Class__c> selectByNameAndUtility(String name, String utilityId) {
        return [
            SELECT Id, Name 
            FROM Rate_Class__c 
            WHERE Name = :name AND Utility__c = :utilityId
            ORDER BY Name
        ];
    }
}