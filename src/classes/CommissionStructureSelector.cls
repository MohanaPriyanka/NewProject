/**
 * Test: CommissionStructureSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CommissionStructureSelector {
    public List<Commission_Structure__c> getActiveCommissionStructures(Set<Id> partnerIds) {
        List<Commission_Structure__c> commissionStructures = [
            SELECT Id, Partner__c, Product__c, Cents_kW_DC_Up_Front__c
            FROM Commission_Structure__c
            WHERE Partner__c IN : partnerIds
            AND Active__c = true
        ];
        return commissionStructures;
    }
}