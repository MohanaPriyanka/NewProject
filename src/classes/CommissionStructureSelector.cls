/**
 * Test: CommissionStructureSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class CommissionStructureSelector {
    public Map<Id, Commission_Structure__c> getCommissionStructureMapByIds(Set<Id> comIds) {
        List<Commission_Structure__c> commissionStructures = [
            SELECT Id, Partner__c, Product__c, Cents_kW_DC_Up_Front__c
            FROM Commission_Structure__c
            WHERE Id IN :comIds
        ];
        Map<Id, Commission_Structure__c> commissionStructureMap = new Map<Id, Commission_Structure__c>();
        for (Commission_Structure__c cs : commissionStructures) {
            commissionStructureMap.put(cs.Id, cs);
        }
        return commissionStructureMap;
    }
}