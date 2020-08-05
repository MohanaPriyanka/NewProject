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
        // 6 Opps, with 5 DS and 4 attachments (2 Opps should log error for missing data)
        List<Account> accounts = new List<Account>([SELECT Id FROM Account WHERE Name LIKE '%Customer%']);
        Contract assignAgree = [SELECT Id FROM Contract LIMIT 1];
        Product2 normalCSProduct = [SELECT Id FROM Product2 WHERE Name = 'Normal 10% Community Solar' LIMIT 1];

        List<Opportunity> oppList = getOpportunityMocks(accounts,assignAgree.Id,normalCSProduct.Id);

        useMocks();

        ContractMigrationService service = new ContractMigrationService();
        service.convertOpportunityToContract(oppList);
        service.cloneDocuSignAttachmentsToContract(oppList, 'Credit Allocation Agreement');
        service.cloneDocuSignAttachmentsToContract(oppList, 'Disclosure');

        List<ContentDocumentLink> cdlToInsertList = (List<ContentDocumentLink>)
            FFLibHelperTest.getRegisterNewListFromUnitOfWork(service.uow, 'ContentDocumentLink');

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

        // 1 for agreement, 1 for disclosure for each opp with a DS
        System.assertEquals(8,cdlToInsertList.size());
    }

    @IsTest
    public static void testBatchJob() {
        // 6 Opps, with 5 DS and 4 attachments (2 Opps should log error for missing data)
        List<Account> accounts = new List<Account>([SELECT Id FROM Account WHERE Name LIKE '%Customer%']);
        Contract assignAgree = [SELECT Id FROM Contract LIMIT 1];
        Product2 normalCSProduct = [SELECT Id FROM Product2 LIMIT 1];

        List<Opportunity> oppList = getOpportunityMocks(accounts,assignAgree.Id,normalCSProduct.Id);

        useMocks();

        Test.startTest();
            BatchContractMigration batchJob = new BatchContractMigration();
            batchJob.opportunitiesToRun = oppList;
        	batchJob.batchSize = 50;
            batchJob.runBatch();
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
        // 6 Opps, with 5 DS and 4 attachments (2 Opps should log error for missing data)
        List<Account> accounts = new List<Account>([SELECT Id FROM Account WHERE Name LIKE '%Customer%']);
        Contract assignAgree = [SELECT Id FROM Contract LIMIT 1];
        Product2 normalCSProduct = [SELECT Id FROM Product2 LIMIT 1];

        List<Opportunity> oppList = getOpportunityMocks(accounts,assignAgree.Id,normalCSProduct.Id);
        System.assertEquals(6,oppList.size());

        Test.startTest();
            BatchContractMigration batchJob = new BatchContractMigration();
            batchJob.opportunitiesToRun = oppList;
            batchJob.batchSize = 50;
            Datetime dt = Datetime.now().addMinutes(2);
            String cronExpress = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
            System.schedule('testContractMigration',cronExpress,batchJob);
        Test.stopTest();
    }

    private static void useMocks() {
        ContractMigrationService.docuSignSelector = (DocuSignSelector) Test.createStub(DocuSignSelector.class, new MockDocuSignStatusSelector());
        ContractMigrationService.attachSelector = (AttachmentSelector) Test.createStub(AttachmentSelector.class, new MockAttachSelector());
    }

    public class MockDocuSignStatusSelector extends MockProvider {
        MockDocuSignStatusSelector() {}
        public override Object handleMethodCall(MethodCall methodCall) {
            // No DS for Opp 0062f00000EllRvAAJ
            Map<Id, dsfs__DocuSign_Status__c> dsMap = new Map<Id, dsfs__DocuSign_Status__c>();
            dsfs__DocuSign_Status__c statusOne = new dsfs__DocuSign_Status__c(
                Id = 'a0S2f000000adRDEAY',
                dsfs__Opportunity__c = '0062f00000EllS0AAJ'
            );
            dsfs__DocuSign_Status__c statusTwo = new dsfs__DocuSign_Status__c(
                Id = 'a0S2f000000bbRDEAY',
                dsfs__Opportunity__c = '0062f00000EllRwAAJ'
            );
            dsfs__DocuSign_Status__c statusThree = new dsfs__DocuSign_Status__c(
                Id = 'a0S2f000000ccRDEAY',
                dsfs__Opportunity__c = '0062f00000EllRxAAJ'
            );
            dsfs__DocuSign_Status__c statusFour = new dsfs__DocuSign_Status__c(
                Id = 'a0S2f000000eeRDEAY',
                dsfs__Opportunity__c = '0062f00000EllRyAAJ'
            );
            dsfs__DocuSign_Status__c statusFive = new dsfs__DocuSign_Status__c(
                Id = 'a0S2f000000ffRDEAY',
                dsfs__Opportunity__c = '0062f00000EllRzAAJ'
            );

            dsMap.put(statusOne.Id, statusOne);
            dsMap.put(statusTwo.Id, statusTwo);
            dsMap.put(statusThree.Id, statusThree);
            dsMap.put(statusFour.Id, statusFour);
            dsMap.put(statusFive.Id, statusFive);

            switch on methodCall.stubbedMethodName {
                when 'getDocusignStatuses' {
                    return dsMap;
                }
            }
            return null;
        }
    }

    public class MockAttachSelector extends MockProvider {
        MockAttachSelector() {}
        public override Object handleMethodCall(MethodCall methodCall) {
            // No attachment for DS a0S2f000000eeRDEAY / Opp 0062f00000EllRyAAJ
            Attachment attachOne = new Attachment(
                Name = 'File Customer Agreement',
                Body = Blob.valueOf('This is the file body'),
                ParentId = 'a0S2f000000adRDEAY',
                Description = 'Descirption'
            );
            Attachment attachTwo = new Attachment(
                Name = 'Customer Agreement Two',
                Body = Blob.valueOf('This is the file body'),
                ParentId = 'a0S2f000000bbRDEAY',
                Description = 'Descirption'
            );
            Attachment attachThree = new Attachment(
                Name = 'Customer Agreement',
                Body = Blob.valueOf('This is the file body'),
                ParentId = 'a0S2f000000ccRDEAY',
                Description = 'Descirption'
            );
            Attachment attachFour = new Attachment(
                Name = 'Customer Agreement',
                Body = Blob.valueOf('This is the file body'),
                ParentId = 'a0S2f000000ffRDEAY',
                Description = 'Descirption'
            );

            List<Attachment> attachList = new List<Attachment>{
                attachOne, attachTwo, attachThree, attachFour
            };

            switch on methodCall.stubbedMethodName {
                when 'getAttachmentsByParentIdAndName' {
                    return attachList;
                }
            }
            return null;
        }
    }

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