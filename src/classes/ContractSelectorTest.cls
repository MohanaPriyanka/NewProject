@IsTest
public with sharing class ContractSelectorTest {
    @TestSetup public static void testSetup() {
        OpportunitiesSelectorTest.testSetup();
        Product2 productA = new Product2(
            Name = 'Generic Product'
        );

        Product2 productB = new Product2(
            Name = 'Project Specific Product',
            Addendum_Template_Id__c = 'AAABBB'
        );
        insert new List<Product2>{productA, productB};

        List<Opportunity> oppList = [
            SELECT Id, Name, AccountId
            FROM Opportunity
        ];

        Contract newContract = new Contract(
            Name = oppList[0].Name,
            AccountId = oppList[0].AccountId,
            Product__c = productA.Id
        );
        insert newContract;
        oppList[0].ContractId = newContract.Id;

        Contract newContractTwo = new Contract(
            Name = oppList[1].Name,
            AccountId = oppList[1].AccountId,
            Product__c = productB.Id
        );
        insert newContractTwo;
        oppList[1].ContractId = newContractTwo.Id;

        Contract newContractThree = new Contract(
            Name = oppList[2].Name,
            AccountId = oppList[2].AccountId,
            Product__c = productB.Id,
            Customer_Signature_Date_Time__c = System.today()
        );
        insert newContractThree;

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
        ContractSelector.AssignmentAgreementRequest assignmentAgreementRequest = new ContractSelector.AssignmentAgreementRequest();
        assignmentAgreementRequest.entityId = entities[0].Id;
        assignmentAgreementRequest.cutoffDate = Date.newInstance(2021,1,1);
        assignmentAgreementRequest.clientAcquiredCustomers = false;
        List<Contract> contracts =
            ContractSelector.selectContractsForClientAssignment(new List<ContractSelector.AssignmentAgreementRequest>{assignmentAgreementRequest})[0];
        System.assertNotEquals(null, contracts, 'Expected a non-null contract list');
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
        contracts = selector.getCustomerContractsByAssignmentAgreement(new Set<Id>{assignmentAgreement.Id});
        System.assert(contracts.size() > 0);
    }

    @IsTest
    private static void testGetcustomerContractsForAddendum() {
        List<Contract> contractList = [
            SELECT Id
            FROM Contract
        ];
        Set<Id> contractIds = new Set<Id>();
        for (Contract cntr : contractList){
            contractIds.add(cntr.Id);
        }

        List<Contract> contracts;
        ContractSelector selector = new ContractSelector();
        contracts = selector.getCustomerContractsForAddendum(contractIds);
        System.assertEquals(1, contracts.size(), 'Query should only return the Contract that is both assigned to the Addendum product ' +
            'and has not already been signed');
    }

    @IsTest
    private static void testInvocableAddendumGenerator() {
        List<Contract> contractList = [
            SELECT Id
            FROM Contract
        ];
        List<List<Contract>> invocableVariable = new List<List<Contract>>{contractList};

        Test.startTest();
        InvocableAddendumGenerator.generateAddendumsForContracts(invocableVariable);
        Test.stopTest();

        List<Contract> contracts = [
            SELECT Id, Generate_Addendum__c, Product__r.Addendum_Template_Id__c, Customer_Signature_Date_Time__c
            FROM Contract
        ];
        for (Contract c : contracts) {
            if (c.Customer_Signature_Date_Time__c != null || c.Product__r.Addendum_Template_Id__c == null) {
                System.assertEquals(false, c.Generate_Addendum__c, 'Contract should not have an Addendum Generated');
            } else {
                System.assert(c.Generate_Addendum__c, 'Contract should have Addendum Generated');
            }
        }
    }
}