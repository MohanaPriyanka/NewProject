/**
 * Created by peteryao on 7/16/20.
 * Tested by: ClientContractServiceTest
 */

public without sharing class ClientContractService {
    private static ClientContractSelector clientContractSelector = new ClientContractSelector();
    private static SharedSolarSystemsSelector sharedSolarSystemsSelector = new SharedSolarSystemsSelector();
    @TestVisible
    private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType> {
            Shared_Solar_System__c.SObjectType
        }
    );

    public void setActiveContractsOnSSS(Set<Id> sharedSolarSystemIds) {
        setActiveContractsOnSSS(sharedSolarSystemsSelector.selectAll(sharedSolarSystemIds));
    }

    public void setActiveContractsOnAllSSSes() {
        setActiveContractsOnSSS(sharedSolarSystemsSelector.getAllSSSes());
    }

    private void setActiveContractsOnSSS(List<Shared_Solar_System__c> sharedSolarSystems) {
        List<Client_Contract__c> activeClientContracts = clientContractSelector.getActiveClientContracts();
        Map<Id, ClientContractsForSystem> activeContractsBySystemId = getActiveContractsBySystemId(activeClientContracts);
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            ClientContractsForSystem clientContracts = activeContractsBySystemId.get(sss.Id);
            registerSystemForUpdate(clientContracts, sss);
        }
        uow.commitWork();
    }

    private Map<Id, ClientContractsForSystem> getActiveContractsBySystemId(List<Client_Contract__c> activeClientContracts) {
        Map<Id, ClientContractsForSystem> activeContractsBySystemId = new Map<Id, ClientContractsForSystem>();
        for (Client_Contract__c clientContract : activeClientContracts) {
            ClientContractsForSystem clientContracts = activeContractsBySystemId.get(clientContract.Shared_Solar_System__c);
            if (clientContracts == null) {
                activeContractsBySystemId.put(clientContract.Shared_Solar_System__c, new ClientContractsForSystem(clientContract));
            } else {
                clientContracts.addClientContract(clientContract);
            }
        }
        return activeContractsBySystemId;
    }

    @TestVisible
    private void registerSystemForUpdate(ClientContractsForSystem clientContracts, Shared_Solar_System__c sss) {
        if (clientContracts == null) {
            if (sss.Client_Acquisition_Contract__c != null ||
                sss.Client_Management_Contract__c != null) {
                sss.Client_Acquisition_Contract__c = null;
                sss.Client_Management_Contract__c = null;
                sss.CS_Services_Type__c = null;
                uow.registerDirty(sss);
            } else {
                // SSS is up to date: both contracts are null and we found no active contracts for that system
            }
        } else {
            if (sss.Client_Acquisition_Contract__c != clientContracts.acquisitionContractId ||
                sss.Client_Management_Contract__c != clientContracts.managementContractId) {
                sss.Client_Acquisition_Contract__c = clientContracts.acquisitionContractId;
                sss.Client_Management_Contract__c = clientContracts.managementContractId;
                setCSServicesType(sss);
                uow.registerDirty(sss);
            } else {
                // SSS is up to date: the contracts on it match the active contracts that we found
            }
        }
    }

    private void setCSServicesType(Shared_Solar_System__c sss) {
        if (sss.Client_Management_Contract__c != null) {
            if (sss.Client_Acquisition_Contract__c != null) {
                sss.CS_Services_Type__c = 'Acquisition & Management';
            } else {
                sss.CS_Services_Type__c = 'Management Only';
            }
        } else {
            if (sss.Client_Acquisition_Contract__c != null) {
                sss.CS_Services_Type__c = 'Acquisition Only';
            } else {
                sss.CS_Services_Type__c = null;
            }
        }
    }

    @TestVisible
    private class ClientContractsForSystem {
        @TestVisible
        private Id acquisitionContractId;
        @TestVisible
        private Id managementContractId;
        @TestVisible
        private ClientContractsForSystem(Client_Contract__c clientContract) {
            addClientContract(clientContract);
        }
        @TestVisible
        private void addClientContract(Client_Contract__c clientContract) {
            if (clientContract.CS_Services_Type__c == 'Acquisition & Management') {
                if (this.acquisitionContractId == null) {
                    this.acquisitionContractId = clientContract.Contract__c;
                }
                if (this.managementContractId == null) {
                    this.managementContractId = clientContract.Contract__c;
                }
            } else if (clientContract.CS_Services_Type__c == 'Management Only') {
                if (this.managementContractId == null) {
                    this.managementContractId = clientContract.Contract__c;
                }
            } else if (clientContract.CS_Services_Type__c == 'Acquisition Only') {
                if (this.acquisitionContractId == null) {
                    this.acquisitionContractId = clientContract.Contract__c;
                }
            }
        }
    }
}