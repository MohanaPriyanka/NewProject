/**
 * @description Created by Lindsay Holmes (Gears CRM) on 5/15/2020.
 * Tested By: CustomerContractServiceTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class CustomerContractSelector {

    public static final Id recordTypeId = CustomerContractService.RECORD_TYPE_ID;
    
    public Contract selectOne(Id contractId) {
        List<Contract> contracts = this.selectAll(new Set<Id>{contractId});
        if (contracts.isEmpty()) {
            return null;
        }
        return contracts[0];
    }

    public List<Contract> selectAll(Set<Id> contractIds) {
        return [
            SELECT Id, Lead__c, Product__c, RecordTypeId, AccountId, Contract_Type__c, Generate_Disclosure_Form__c
            FROM Contract
            WHERE Id = :contractIds AND RecordTypeId = :recordTypeId
        ];
    }

    public List<Contract> selectByRelatedLead(Id leadId) {
        return selectByRelatedLeads(new Set<Id>{leadId});
    }

    public List<Contract> selectByRelatedLeads(Set<Id> leadIds) {
        return [
            SELECT Id, Customer_Signature_Date_Time__c, Generate_Review_Version__c, Generate_Signed_Version__c, Lead__c,
                Product__c, Product__r.Parent_Product__c, Contract_Type__c, Conga_Template_ID_Countersigned__c
            FROM Contract
            WHERE Lead__c = :leadIds AND RecordTypeId = :recordTypeId
            ORDER BY CreatedDate ASC
        ];
    }
}