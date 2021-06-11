/**
 * Created by Kristin White
 * 
 * Tested by: ContractSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class InvocableSelectAllocationContracts {
    
    @InvocableMethod(Label='selectContractsForAllocationSchedule' Description='Gets Contracts for an Allocation Schedule without an Addendum Sent Date')
    public static List<List<Contract>> selectContractsForAllocationSchedule(List<Id> allocationScheduleId) {
        List<Schedule_Z_Subscription__c> szsList = [
            SELECT Utility_Account_Subscription__r.Opportunity__r.ContractId
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c IN : allocationScheduleId
        ];
        List<Id> szsContractIdList = new List<Id>();
        for(Schedule_Z_Subscription__c szs : szsList){
            szsContractIdList.add(szs.Utility_Account_Subscription__r.Opportunity__r.ContractId);
        }
        List<Contract> szsContractList = [
            SELECT Id, Name, Parent_Contract__c, AccountId, Product__c,
            Addendum_Sent_Date__c, Assignment_Agreement__c
            FROM Contract
            WHERE Id IN :szsContractIdList
            AND Addendum_Sent_Date__c = null
        ];
        return new List<List<Contract>>{szsContractList};
    }
    
}