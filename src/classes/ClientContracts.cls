/**
 * Created by peteryao on 7/16/20.
 * Tested By: ClientContractServiceTest
 */

public inherited sharing class ClientContracts {
    private List<Client_Contract__c> records;
    @TestVisible
    private static ClientContractSelector clientContractSelector = new ClientContractSelector();

    public ClientContracts(List<Client_Contract__c> clientContracts) {
        this.records = clientContracts;
    }

    public void validate() {
        List<Client_Contract__c> existingClientContracts =
            getExistingClientContracts(records);
        for (Client_Contract__c record : records) {
            validate(record, existingClientContracts);
        }
    }

    public Set<Id> getSharedSolarSystemIds() {
        Set<Id> sharedSolarSystemIds = new Set<Id>();
        for (Client_Contract__c record : records) {
            sharedSolarSystemIds.add(record.Shared_Solar_System__c);
        }
        return sharedSolarSystemIds;
    }

    private List<Client_Contract__c> getExistingClientContracts(List<Client_Contract__c> clientContractsToValidate) {
        Set<Id> sharedSolarSystemIds = new Set<Id>();
        for (Client_Contract__c clientContract : clientContractsToValidate) {
            sharedSolarSystemIds.add(clientContract.Shared_Solar_System__c);
        }
        return clientContractSelector.getClientContracts(sharedSolarSystemIds);
    }

    private void validate(Client_Contract__c clientContract, List<Client_Contract__c> existingClientContracts) {
        if (clientContract.End_Date__c <= clientContract.Effective_Date__c) {
            clientContract.addError('The end date should be after the effective date');
        }
        for (Client_Contract__c existingCC : existingClientContracts) {
            if (hasExisting(clientContract, existingCC)) {
                clientContract.addError('An existing client contract ('+existingCC.Name+') is effective (' +
                    existingCC.Effective_Date__c.format() + ' to ' + existingCC.End_Date__c.format() +') at the same time as this one would be. ' +
                    'Please change the effective or end date of the existing one first');
            }
        }
    }

    @TestVisible
    private static Boolean hasExisting(Client_Contract__c clientContract, Client_Contract__c existingCC) {
        return clientContract.Id != existingCC.Id &&
            clientContract.Shared_Solar_System__c == existingCC.Shared_Solar_System__c &&
            overlapsType(existingCC, clientContract) &&
            (overlapsDates(existingCC, clientContract) || overlapsDates(clientContract, existingCC));
    }

    private static Boolean overlapsDates(Client_Contract__c clientContract1, Client_Contract__c clientContract2) {
        return DateUtil.between(clientContract1.Effective_Date__c, clientContract2.Effective_Date__c, clientContract1.End_Date__c) ||
            DateUtil.between(clientContract1.Effective_Date__c, clientContract2.End_Date__c, clientContract1.End_Date__c) ||
            (clientContract1.Effective_Date__c <= clientContract2.Effective_Date__c && clientContract1.End_Date__c >= clientContract2.End_Date__c);
    }

    private static Boolean overlapsType(Client_Contract__c clientContract1, Client_Contract__c clientContract2) {
        return clientContract1.CS_Services_Type__c == clientContract2.CS_Services_Type__c ||
            clientContract1.CS_Services_Type__c == 'Acquisition & Management' ||
            clientContract2.CS_Services_Type__c == 'Acquisition & Management';
    }
}