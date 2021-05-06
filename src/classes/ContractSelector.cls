// Tested by ContractSelectorTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ContractSelector {
    // Invocable methods can have at most one input parameter and its data type must be a List of primitive data types
    @InvocableMethod(Label='selectContractsForClientAssignment' Description='Gets Contract without Assignment Agreement for a list of entities')
    public static List<List<Contract>> selectContractsForClientAssignment(List<AssignmentAgreementRequest> assignmentAgreementRequests) {
        List<Opportunity> oppList =
            OpportunitiesSelector.selectOpportunitiesForClientAssignment(
                assignmentAgreementRequests[0].entityId,
                assignmentAgreementRequests[0].cutoffDate,
                assignmentAgreementRequests[0].clientAcquiredCustomers
            );

        Set<Id> oppIdSet = new Set<Id>();
        for (Opportunity opp : oppList){
            oppIdSet.add(opp.Id);
        }
        List<Contract> contracts = [
            SELECT Id, Assignment_Agreement__c
            FROM Contract
            WHERE Id IN (
                SELECT ContractId
                FROM Opportunity
                WHERE Id IN : oppIdSet
            )
            AND Assignment_Agreement__c = NULL
        ];
        return new List<List<Contract>>{contracts};
    }

    public List<Contract> getCustomerContractsByAssignmentAgreement(Id assignmentAgreementId) {
        return getCustomerContractsByAssignmentAgreement(new Set<Id>{assignmentAgreementId});
    }

    public List<Contract> getCustomerContractsByAssignmentAgreement(Set<Id> assignmentAgreementIds) {
        return [
            SELECT Id, Name, Parent_Contract__c
            FROM Contract
            WHERE Assignment_Agreement__c = : assignmentAgreementIds
        ];
    }
    
    public List<Contract> getCustomerContractsForAddendum(Set<Id> contractIds) {
        return [
            SELECT Id, Product__r.Addendum_Template_Id__c
            FROM Contract
            WHERE Id IN :contractIds
            AND Product__r.Addendum_Template_Id__c != NULL
            AND Customer_Signature_Date_Time__c = NULL
        ];
    }
    
    public Map<Id, Contract> getContractsWithUnsentAddendumsById(List<Id> contactIds) {
        Map<Id, Contract> contractsWithUnsentAddendumsById = new Map<Id, Contract>();
        for(Contract currentContract : [
            SELECT Id, Addendum_Sent_Date__c, Account.Send_Bills_Contact__r.Id
            FROM Contract
            WHERE Addendum_Sent_Date__c = null 
            AND Account.Send_Bills_Contact__r.Id IN : contactIds
            AND Id IN (SELECT ContractId 
                       FROM Opportunity 
                       WHERE Product__r.Addendum_Template_Id__c != null)
        ]){
            contractsWithUnsentAddendumsById.put(currentContract.Id, currentContract);
        }
        return contractsWithUnsentAddendumsById;
    }
    
    public Contract getSingleContractWithUnsentAddendumsById(Id contactId){
        return [
            SELECT Id, Addendum_Sent_Date__c, Account.Send_Bills_Contact__r.Id
            FROM Contract
            WHERE Addendum_Sent_Date__c = null 
            AND Account.Send_Bills_Contact__r.Id =:contactId
            AND Id IN (SELECT ContractId 
                       FROM Opportunity 
                       WHERE Product__r.Addendum_Template_Id__c != null)];
    }

    /**
     * @description: User Defined Type used by the Assign Customers to Client Agreement Flow
     */
    public with sharing class AssignmentAgreementRequest {
        @InvocableVariable
        public Id entityId;

        @InvocableVariable
        public Date cutoffDate;

        @InvocableVariable
        public Boolean clientAcquiredCustomers;
    }
}