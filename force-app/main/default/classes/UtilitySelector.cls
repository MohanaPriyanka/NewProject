/**
 * @description Created by jeffparlin on 10/1/21.
 * Tested By: CSLeadsConverterTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UtilitySelector {

    public Map<Id, Utility__c> getAllUtilitiesMap() {
        return new Map<Id, Utility__c>(
        [
            SELECT Id, Average_Demand_Threshold__c, Auto_Qualify_Convert_Active__c
            FROM Utility__c
        ]);
    }

}