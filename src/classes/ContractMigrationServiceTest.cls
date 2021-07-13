@IsTest
public with sharing class ContractMigrationServiceTest {
    @TestSetup
    public static void testSetup() {
        Account customerAccountOne = new Account(Name = 'Customer');
        Account customerAccountTwo = new Account(Name = 'Customer');
        Account customerAccountThree = new Account(Name = 'Customer');
        Account customerAccountFour = new Account(Name = 'Customer');
        Account clientAccount = new Account(Name = 'Client');
        insert new List<Account>{
            customerAccountOne, customerAccountTwo, customerAccountThree, customerAccountFour, clientAccount
        };

        Id rtAssign = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId();

        Contract assignmentAgreement = new Contract(
            Name = 'Assignment Agreement',
            RecordTypeId = rtAssign,
            AccountId = clientAccount.Id
        );
        insert assignmentAgreement;

        Product2 normalCSProduct = new Product2(
            Name = 'Normal 10% Community Solar',
            Family = 'Community Solar',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True);
        insert normalCSProduct;
    }

    @IsTest
    public static void testServiceLogic() {
        // 6 Opps, (2 Opps should log error for missing data)
        List<Account> accounts = new List<Account>([SELECT Id FROM Account WHERE Name LIKE '%Customer%']);
        Contract assignAgree = [SELECT Id FROM Contract LIMIT 1];
        Product2 normalCSProduct = [SELECT Id FROM Product2 WHERE Name = 'Normal 10% Community Solar' LIMIT 1];

        List<Opportunity> oppList = getOpportunityMocks(accounts,assignAgree.Id,normalCSProduct.Id);
        
        ContractMigrationService service = new ContractMigrationService();
        service.convertOpportunityToContract(oppList);

        List<Contract> contracts = [
            SELECT Id, AccountId, Assignment_Agreement__c
            FROM Contract
            WHERE Id != : assignAgree.Id
        ];

        Integer countOfContractsAccount1 = 0;
        Boolean containsAccount2 = false;
        Set<Id> contractIdSet = new Set<Id>();

        for (Contract cntr : contracts){
            if (cntr.AccountId == accounts[1].Id){
                countOfContractsAccount1 += 1;
            } else if (cntr.AccountId == accounts[2].Id){
                System.assertEquals(assignAgree.Id,cntr.Assignment_Agreement__c);
                containsAccount2 = true;
            }
            contractIdSet.add(cntr.Id);
        }
        System.assertEquals(6,contracts.size());
        System.assertEquals(2,countOfContractsAccount1);
        System.assert(containsAccount2);

    }

    @IsTest
    public static void testBatchJob() {
        // 6 Opps, with 5 DS and 4 attachments (2 Opps should log error for missing data)
        List<Account> accounts = new List<Account>([SELECT Id FROM Account WHERE Name LIKE '%Customer%']);
        Contract assignAgree = [SELECT Id FROM Contract LIMIT 1];
        Product2 normalCSProduct = [SELECT Id FROM Product2 LIMIT 1];

        List<Opportunity> oppList = getOpportunityMocks(accounts,assignAgree.Id,normalCSProduct.Id);

        Test.startTest();
            BatchContractMigration batchJob = new BatchContractMigration();
            batchJob.opportunitiesToRun = oppList;
            Database.executeBatch(batchJob, 50);
        Test.stopTest();

        List<Contract> contracts = [
            SELECT Id, AccountId, Assignment_Agreement__c
            FROM Contract
            WHERE Id != : assignAgree.Id
        ];

        System.assertEquals(6,contracts.size());
    }

    @IsTest
    public static void testScheduledJob() {
        Test.startTest();
            BatchContractMigration batchJob = new BatchContractMigration();
            System.schedule('testContractMigration', '0 0 0 * * ? *', batchJob);
        Test.stopTest();
        System.assert(true, 'Should not have thrown an exception when executing the schedule. The batch is tested in testBatchJob');
    }

    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static List<Opportunity> getOpportunityMocks(List<Account> accounts, Id assignmentAgreementId, Id productId){
        Opportunity oppOne = new Opportunity(
            Id = '0062f00000EllRvAAJ',
            AccountId = accounts[0].Id,
            Product__c = productId,
            Assignment_Agreement__c = null
        );
        Opportunity oppTwo = new Opportunity(
            Id = '0062f00000EllRwAAJ',
            AccountId = accounts[0].Id,
            Product__c = productId,
            Assignment_Agreement__c = null
        );
        Opportunity oppThree = new Opportunity(
            Id = '0062f00000EllRxAAJ',
            AccountId = accounts[1].Id,
            Product__c = productId,
            Assignment_Agreement__c = assignmentAgreementId
        );
        Opportunity oppFour = new Opportunity(
            Id = '0062f00000EllRyAAJ',
            AccountId = accounts[1].Id,
            Product__c = productId,
            Assignment_Agreement__c = null
        );
        Opportunity oppFive = new Opportunity(
            Id = '0062f00000EllRzAAJ',
            AccountId = accounts[2].Id,
            Product__c = productId,
            Assignment_Agreement__c = assignmentAgreementId
        );
        Opportunity oppSix = new Opportunity(
            Id = '0062f00000EllS0AAJ',
            AccountId = accounts[3].Id,
            Product__c = productId,
            Assignment_Agreement__c = null
        );
        List<Opportunity> oppList = new List<Opportunity>{
            oppOne, oppTwo, oppThree, oppFour, oppFive, oppSix
        };
        return oppList;
    }
}