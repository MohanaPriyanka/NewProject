/**
 * Created by peteryao on 7/15/20.
 * Tested BY: ClientContractSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ClientContractSelector {
    public List<Client_Contract__c> getClientContracts(Set<Id> sharedSolarSystemIds) {
        return [
            SELECT Id, Name, CS_Services_Type__c, Effective_Date__c, End_Date__c, Shared_Solar_System__c, Contract__c
            FROM Client_Contract__c
            WHERE Shared_Solar_System__c IN :sharedSolarSystemIds
        ];
    }

    public List<Client_Contract__c> getActiveClientContracts() {
        return [
            SELECT Id, Shared_Solar_System__c, CS_Services_Type__c, Contract__c,
                Shared_Solar_System__r.Client_Acquisition_Contract__c, Shared_Solar_System__r.Client_Management_Contract__c
            FROM Client_Contract__c
            WHERE Effective_Date__c <= :System.today()
            AND End_Date__c >= :System.today()
        ];
    }
}