// Tested by ContractSelectorTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ContractSelector {
    // Invocable methods can have at most one input parameter and its data type must be a List of primitive data types
    @InvocableMethod(Label='selectContractsForClientAssignment' Description='Gets Contract without Assignment Agreement for a list of entities')
    public static List<List<Contract>> selectContractsForClientAssignment(List<List<String>> inputParameters){
        List<String> entityIds = inputParameters[0];
        List<Contract> contracts = [
            SELECT Id, Assignment_Agreement__c
            FROM Contract
            WHERE Id IN (
                SELECT ContractId
                FROM Opportunity
                WHERE Shared_Solar_System__r.BWC_Project_Entity_Manual__c IN : entityIds
                AND StageName = 'Complete'
                AND Partner_tag_lookup__r.Account__r.RecordType.DeveloperName != 'Client_Account'
                AND Account.Parent_Account__r.Account_Temperature__c != 'Hot'
                AND Assignment_Agreement__c = null
            )
            AND Assignment_Agreement__c = null
        ];
        return new List<List<Contract>>{contracts};
    }
}