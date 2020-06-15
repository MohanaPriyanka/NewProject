/**
 * Created by Lindsay Holmes (Gears CRM) on 5/15/2020.
 * Description: Selector for the Contract object
 * Test: CustomerContractServiceTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class CustomerContractSelector {
    
    public Contract selectOne(Id contractId) {
        List<Contract> contracts = this.selectAll(new Set<Id>{contractId});
        if (contracts.isEmpty()) {
            return null;
        }
        return contracts[0];
    }

    public List<Contract> selectAll(Set<Id> contractIds) {
        Id recordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId();
        return [
            SELECT Id, Lead__c, Product__c, RecordTypeId, AccountId, Contract_Type__c
            FROM Contract
            WHERE Id = :contractIds AND RecordTypeId = :recordTypeId
        ];
    }

    public List<Contract> selectByRelatedLead(Id leadId) {
        return selectByRelatedLeads(new Set<Id>{leadId});
    }

    public List<Contract> selectByRelatedLeads(Set<Id> leadIds) {
        Id recordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId();
        return [
            SELECT Id, Customer_Signature_Date_Time__c, Generate_Review_Version__c, Generate_Signed_Version__c, Lead__c, Product__c
            FROM Contract
            WHERE Lead__c = :leadIds AND RecordTypeId = :recordTypeId
            ORDER BY CreatedDate ASC
        ];
    }
}