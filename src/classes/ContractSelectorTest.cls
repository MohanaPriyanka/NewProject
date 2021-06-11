@IsTest
public with sharing class ContractSelectorTest {
    @SuppressWarnings('PMD.ApexCRUDViolation')
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
            SELECT Id, Name, AccountId, ContractId
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
            Product__c = productB.Id
        );
        insert newContractThree;

        update oppList;
        
        Product2 testProduct1 = new Product2(
            Name = 'testProduct1',
            Addendum_Template_Id__c = 'testId01'
        );
        insert testProduct1;
        
        Contact testContact1 = new Contact(
            Department = 'testContact1',
            LastName = 'testContact1'
        );
        insert testContact1;
        
        Account testAccount1 = new Account(
            Send_Bills_Contact__c = testContact1.Id,
            Name = 'testAccount1'
        );
        insert testAccount1;
        
        List<RecordType> assignmentAgreementId = [SELECT Id FROM RecordType WHERE Name='Assignment Agreement'];
        Contract testAA1 = new Contract(
            RecordTypeId = assignmentAgreementId[0].Id,
            Name = 'testAA1',
            AccountId = testAccount1.Id
        );
        insert testAA1;
        
        Contract testContract1 = new Contract(
            AccountId = testAccount1.Id,
            Addendum_Sent_Date__c = null,
            Assignment_Agreement__c = testAA1.Id,
            Name = 'testContract1',
            Product__c = testProduct1.Id
        );
        insert testContract1;
        
        Lead testLead1 = new Lead(
            IsConverted = FALSE,
            LastName = 'testLead1', 
            Company = 'testBizApps'
        );
        insert testLead1;
        
        Opportunity testOpp1 = new Opportunity(
            zqu__DeliveryInstallationStatus__c ='Completed',
            Status_of_Financials__c = 'Approved',
            Product__c = testProduct1.Id,
            ContractId = testContract1.Id,
            AccountId = testAccount1.Id,
            Name = 'testOpp1Name',
            StageName = 'testOpp1StageName',
            CloseDate = Date.today(),
            Lead__c = testLead1.Id
        );
        insert testOpp1;
        
        Utility_Account_Log__c testUAL1 = new Utility_Account_Log__c();
        insert testUAL1;
        
        Shared_Solar_System__c testSSS1 = new Shared_Solar_System__c(
            Name = 'testSSS1',
            Address__c = 'test address',
            City__c = 'Atlanta',
            State__c = 'GA',
            Zip_Code__c = '54321',
            Total_System_Size_kWh_DC__c = 1.1
        );
        insert testSSS1;
        
        testOpp1.Shared_Solar_System__c = testSSS1.Id;
        update testOpp1;
        
        testContract1.Opportunity__c = testOpp1.Id;
        update testContract1;
        
        Utility_NMC_Tariff__c testSizingMethod1 = new Utility_NMC_Tariff__c(
            Name = 'testSizingMethod1'
        );
        insert testSizingMethod1;
        
        Util.disableAllTriggers();
        Utility_Account_Subscription__c  testUAS1 = new Utility_Account_Subscription__c(
            Opportunity__c = testOpp1.Id,
            Utility_Account_Log__c = testUAL1.Id,
            Shared_Solar_System__c = testSSS1.Id,
            Sizing_Method__c = testSizingMethod1.Id
        );
        insert testUAS1;
        
        Schedule_Z__c testAls1 = new Schedule_Z__c(
            Name = 'testAls1', 
            Shared_Solar_System__c = testSSS1.Id
        );
        insert testAls1;
        
        Schedule_Z_Subscription__c testAlsSub1 = new Schedule_Z_Subscription__c(
            Utility_Account_Subscription__c = testUAS1.Id, 
            Schedule_Z__c = testAls1.Id
        );
        insert testAlsSub1;
        Util.enableAllTriggers();
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
        assignmentAgreementRequest.assignAnchors = false;
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
        System.assertEquals(3, contracts.size(), 'Query should return the Contracts that are assigned to the Addendum product');
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
            if (c.Product__r.Addendum_Template_Id__c == null) {
                System.assertEquals(false, c.Generate_Addendum__c, 'Contract should not have an Addendum Generated for contract: ' + c.Product__r.Addendum_Template_Id__c + ' & ' + c.Customer_Signature_Date_Time__c);
            } else {
                System.assert(c.Generate_Addendum__c, 'Contract should have Addendum Generated for contract: ' + c.Product__r.Addendum_Template_Id__c + ' & ' + c.Customer_Signature_Date_Time__c);
            }
        }
    }
    
    @IsTest
    public static void testGetContractsForAddendumMapById(){
        ContractSelector selector = new ContractSelector();
        Contract testContract = [SELECT Id, Addendum_Sent_Date__c, Account.Send_Bills_Contact__r.Id, Name FROM Contract WHERE Name = 'testContract1'];
        Set<Id> contractIdSet = new Set<Id>();
        contractIdSet.add(testContract.Id);
        Map<Id,Contract> resultMap = selector.getContractsForAddendumMapById(contractIdSet);
        System.assert(resultMap.keySet().contains(testContract.Id));
    }
    
    @IsTest
    public static void testInvocableSelectContractsForAllocationSchedule() {
        Schedule_Z__c als = [SELECT Id FROM Schedule_Z__c WHERE Name = 'testAls1'];
        Contract testContract = [SELECT Id, Addendum_Sent_Date__c, Account.Send_Bills_Contact__r.Id, Name FROM Contract WHERE Name = 'testContract1'];
        List<Id> allocationId = new List<Id>();
        allocationId.add(als.Id);
        List<List<Contract>> resultList = InvocableSelectAllocationContracts.selectContractsForAllocationSchedule(allocationId);
        System.assertEquals(1, resultList.size());
        System.assertEquals(testContract.Id, resultList[0][0].Id);
    }
    
}