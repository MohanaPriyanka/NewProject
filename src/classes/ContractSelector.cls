// Tested by ContractSelectorTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ContractSelector {
    // Invocable methods can have at most one input parameter and its data type must be a List of primitive data types
    @InvocableMethod(Label='selectContractsForClientAssignment' Description='Gets Contract without Assignment Agreement for a list of entities')
    public static List<List<Contract>> selectContractsForClientAssignment(List<List<String>> inputParameters){
        List<Opportunity> oppList = OpportunitiesSelector.selectOpportunitiesForClientAssignment(inputParameters)[0];
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
            AND Assignment_Agreement__c = null
        ];
        return new List<List<Contract>>{contracts};
    }

    public List<Contract> getCustomerContractsByAssignmentAgreement(Id assignmentAgreementId) {
        return [
            SELECT Id, Name
            FROM Contract
            WHERE Assignment_Agreement__c = : assignmentAgreementId
        ];
    }
}