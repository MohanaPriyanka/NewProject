@IsTest
public with sharing class ContractSelectorTest {
    @TestSetup public static void testSetup() {
        OpportunitiesSelectorTest.testSetup();
        List<Opportunity> oppList = [
            SELECT Id, Name, AccountId
            FROM Opportunity
        ];

        Contract newContract = new Contract(
            Name = oppList[0].Name,
            AccountId = oppList[0].AccountId
        );
        insert newContract;
        oppList[0].ContractId = newContract.Id;

        Contract newContractTwo = new Contract(
            Name = oppList[1].Name,
            AccountId = oppList[1].AccountId
        );
        insert newContractTwo;
        oppList[1].ContractId = newContractTwo.Id;

        update oppList;
    }

    @IsTest public static void testSelectContractsForClientAssignment() {
        List<Entity__c> entities = [
            SELECT Id
            FROM Entity__c
        ];
        System.assert(entities.size() > 0);
        List<String> entityIds = new List<String>();
        for (Entity__c entity : entities){
            entityIds.add(entity.Id);
        }

        List<Contract> contracts;
        contracts = ContractSelector.selectContractsForClientAssignment(new List<List<String>>{entityIds})[0];

        System.assert(contracts.size() > 0);
    }

    @IsTest public static void testGetCustomerContractsByAssignmentAgreement(){
        Account clientAccount = new Account(Name = 'Client');
        insert clientAccount;
        Id rtAssign = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId();
        Contract assignmentAgreement = new Contract(
            Name = 'Assignment Agreement',
            RecordTypeId = rtAssign,
            AccountId = clientAccount.Id
        );
        insert assignmentAgreement;

        List<Contract> contractList = [
            SELECT Id, Assignment_Agreement__c
            FROM Contract
            WHERE Id != : assignmentAgreement.Id
        ];
        for (Contract cntr : contractList){
            cntr.Assignment_Agreement__c = assignmentAgreement.Id;
        }
        update contractList;

        List<Contract> contracts;
        ContractSelector selector = new ContractSelector();
        contracts = selector.getCustomerContractsByAssignmentAgreement(assignmentAgreement.Id);
        System.assert(contracts.size() > 0);
    }
}