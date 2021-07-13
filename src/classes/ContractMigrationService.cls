// Tested by ContractMigrationServiceTest

public without sharing class ContractMigrationService {

    @TestVisible
    private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType> {
            Opportunity.SObjectType
        }
    );

    public Map<Id,Contract> oppToContractMap = new Map<Id,Contract>();

    public void executeForOpps(List<Opportunity> oppList){
        convertOpportunityToContract(oppList);
        Logger.flushLogs();
        uow.commitWork();
    }

    public void convertOpportunityToContract(List<Opportunity> oppList) {
        Id customerRecordType = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Customer Contract').getRecordTypeId();
        for (Opportunity opp : oppList){
            Contract newContract = new Contract(
                AccountId = opp.AccountId,
                Product__c = opp.Product__c,
                RecordTypeId = customerRecordType,
                Contract_Type__c = 'Project Specific',
                Assignment_Agreement__c = opp.Assignment_Agreement__c
            );
            oppToContractMap.put(opp.Id,newContract);
        }
        insert oppToContractMap.values();
        for (Opportunity opp : oppList){
            Contract cntrt = oppToContractMap.get(opp.Id);
            opp.ContractId = cntrt.Id;
            uow.registerDirty(opp);
        }
    }
}