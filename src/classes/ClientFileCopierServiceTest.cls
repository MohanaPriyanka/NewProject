@IsTest
public with sharing class ClientFileCopierServiceTest {

    public static Boolean testForAssignmentAgreement = false;
    public static Boolean testForAllocationSchedule = false;

    public static Contract setupAssignmentAgreementData() {
        Account clientAccount = new Account(Name = 'Client');
        insert clientAccount;
        Id rtAssign = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId();

        Contract assignmentAgreement = new Contract(
            Name = 'Assignment Agreement',
            RecordTypeId = rtAssign,
            AccountId = clientAccount.Id
        );
        insert assignmentAgreement;
        return assignmentAgreement;
    }

    public static Id setupAllocationScheduleData() {
        Shared_Solar_System__c sss = new Shared_Solar_System__c(Name='Test System');
        insert sss;

        Schedule_Z__c allocationSchedule = new Schedule_Z__c(
            Shared_Solar_System__c = sss.Id
        );
        insert allocationSchedule;
        return allocationSchedule.Id;
    }

    @IsTest
    public static void testCustomerAgreementMigration() {
        testForAssignmentAgreement = true;
        Contract assignmentAgreement = setupAssignmentAgreementData();

        List<Supporting_Document_Folder__c> beforeFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = :assignmentAgreement.Id
        ];
        System.assertEquals(0, beforeFolders.size());

        Test.startTest();
            useMocks(true);
            ClientFileCopierService.CloneInputs inputs = new ClientFileCopierService.CloneInputs();
            inputs.parentSobjectId = assignmentAgreement.Id;
            inputs.documentType = 'Customer Agreement';
            inputs.deleteExisting = false;
            ClientFileCopierService.findAndCloneDocuments(new List<ClientFileCopierService.CloneInputs>{inputs});
        Test.stopTest();

        List<Supporting_Document_Folder__c> afterFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = :assignmentAgreement.Id
        ];
        System.assertEquals(1, afterFolders.size());

        List<ContentDocumentLink> afterFiles = [
            SELECT Id, ContentDocument.LatestPublishedVersion.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :afterFolders[0].Id
        ];
        // 7 Contracts, 1 doesn't have any files, 2 others have 2 UASes each = 7 - 1 + 2 = 8
        System.assertEquals(8, afterFiles.size());
    }

    @IsTest
    public static void testCustomerDisclosureMigration() {
        testForAssignmentAgreement = true;
        Contract assignmentAgreement = setupAssignmentAgreementData();

        List<Supporting_Document_Folder__c> beforeFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = :assignmentAgreement.Id
        ];
        System.assertEquals(0, beforeFolders.size());

        Test.startTest();
            useMocks(true);
            ClientFileCopierService.CloneInputs inputs = new ClientFileCopierService.CloneInputs();
            inputs.parentSobjectId = assignmentAgreement.Id;
            inputs.documentType = 'Customer Disclosure Form';
            inputs.deleteExisting = false;
            ClientFileCopierService.findAndCloneDocuments(new List<ClientFileCopierService.CloneInputs>{inputs});
        Test.stopTest();

        List<Supporting_Document_Folder__c> afterFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = :assignmentAgreement.Id
        ];
        System.assertEquals(1, afterFolders.size());

        List<ContentDocumentLink> afterFiles = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :afterFolders[0].Id
        ];
        // 7 Contracts, 3 of which have a disclosure form attachment, 1 of which has 2 UASes
        System.assertEquals(4, afterFiles.size());
    }

    @IsTest
    public static void testPCRMigration() {
        testForAssignmentAgreement = true;
        Contract assignmentAgreement = setupAssignmentAgreementData();

        List<Supporting_Document_Folder__c> beforeFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = :assignmentAgreement.Id
        ];
        System.assertEquals(0, beforeFolders.size());

        Test.startTest();
            useMocks(false);
            ClientFileCopierService.CloneInputs inputs = new ClientFileCopierService.CloneInputs();
            inputs.parentSobjectId = assignmentAgreement.Id;
            inputs.documentType = 'Customer Credit Report';
            inputs.deleteExisting = false;
            ClientFileCopierService.findAndCloneDocuments(new List<ClientFileCopierService.CloneInputs>{inputs});
        Test.stopTest();

        List<Supporting_Document_Folder__c> afterFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = :assignmentAgreement.Id
        ];
        System.assertEquals(1, afterFolders.size());

        List<ContentDocumentLink> afterFiles = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :afterFolders[0].Id
        ];
        // 4 Opportunities, 1 of which has 2 UASes
        System.assertEquals(5, afterFiles.size());
    }

    @IsTest
    private static void testAddendumMigration() {
        testForAssignmentAgreement = true;
        Contract assignmentAgreement = setupAssignmentAgreementData();

        List<Supporting_Document_Folder__c> beforeFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = :assignmentAgreement.Id
        ];
        System.assertEquals(0, beforeFolders.size());

        Test.startTest();
            useMocks(true);
            ClientFileCopierService.CloneInputs inputs = new ClientFileCopierService.CloneInputs();
            inputs.parentSobjectId = assignmentAgreement.Id;
            inputs.documentType = 'Customer Addendum';
            inputs.deleteExisting = false;
            ClientFileCopierService.findAndCloneDocuments(new List<ClientFileCopierService.CloneInputs>{inputs});
        Test.stopTest();

        List<Supporting_Document_Folder__c> afterFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = :assignmentAgreement.Id
        ];
        System.assertEquals(1, afterFolders.size());

        List<ContentDocumentLink> afterFiles = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :afterFolders[0].Id
        ];
        System.assertEquals(1, afterFiles.size(), 'Only one contract has an Addendum attachment');
    }

    @IsTest
    public static void testCreateSupportingDocumentsFolder() {
        testForAssignmentAgreement = true;
        Contract assignmentAgreement = setupAssignmentAgreementData();

        Test.startTest();
            useMocks(true);
            ClientFileCopierService.CloneInputs inputs = new ClientFileCopierService.CloneInputs();
            inputs.parentSobjectId = assignmentAgreement.Id;
            inputs.documentType = 'Customer Agreement';
            inputs.deleteExisting = false;
            ClientFileCopierService.findAndCloneDocuments(new List<ClientFileCopierService.CloneInputs>{inputs});
        Test.stopTest();

        Supporting_Document_Folder__c folder = [SELECT Name, Id,Type__c FROM Supporting_Document_Folder__c LIMIT 1];
        System.assertEquals('Customer Agreements', folder.Name, 'Folder name should be the same as the type passed through the docType param with a trailing s.');
    }

    @IsTest
    public static void testDisclosureCopyForAllocationSchedule() {
        testForAllocationSchedule = true;
        Id allocationScheduleId = setupAllocationScheduleData();

        Test.startTest();
            useMocks(true);
            ClientFileCopierService.CloneInputs inputs = new ClientFileCopierService.CloneInputs();
            inputs.parentSobjectId = allocationScheduleId;
            inputs.documentType = 'Customer Disclosure Form';
            inputs.deleteExisting = false;
            ClientFileCopierService.findAndCloneDocuments(new List<ClientFileCopierService.CloneInputs>{inputs});
        Test.stopTest();

        List<Supporting_Document_Folder__c> afterFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Allocation_Schedule__c =: allocationScheduleId
        ];
        System.assertEquals(1, afterFolders.size());

        List<ContentDocumentLink> afterFiles = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :afterFolders[0].Id
        ];
        // 5 Allocation Schedule Subscriptions / UASes, 2 of which utilize the same Contract & disclosure documents
        // There should be 5 Disclosure files copied into the Supporting Docs folder, and only 3 unique documents
        System.assertEquals(5, afterFiles.size(), '5 files should have been copied for Allocation Schedule client file download');
    }

    @IsTest
    public static void testAgreementCopyForAllocationSchedule() {
        testForAllocationSchedule = true;
        Id allocationScheduleId = setupAllocationScheduleData();

        Test.startTest();
        useMocks(true);
        ClientFileCopierService.CloneInputs inputs = new ClientFileCopierService.CloneInputs();
        inputs.parentSobjectId = allocationScheduleId;
        inputs.documentType = 'Customer Agreement';
        inputs.deleteExisting = false;
        ClientFileCopierService.findAndCloneDocuments(new List<ClientFileCopierService.CloneInputs>{inputs});
        Test.stopTest();

        List<Supporting_Document_Folder__c> afterFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Allocation_Schedule__c =: allocationScheduleId
        ];
        System.assertEquals(1, afterFolders.size());

        List<ContentDocumentLink> afterFiles = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :afterFolders[0].Id
        ];
        System.assertEquals(1, afterFiles.size(), 'The mock should have included one Terms and Conditions file on a parent contract to copy');
    }

    private static void useMocks(Boolean returnContractDocs) {
        ClientFileCopierService.contractSelector = (ContractSelector) Test.createStub(ContractSelector.class, new MockContractSelector());
        ClientFileCopierService.oppSelector = (OpportunitiesSelector) Test.createStub(OpportunitiesSelector.class, new MockOppSelector());
        ClientFileCopierService.uasSelector = (UASSelector) Test.createStub(UASSelector.class, new MockUASSelector());
        ClientFileCopierService.scheduleZSubSelector = (ScheduleZSubscriptionSelector) Test.createStub(ScheduleZSubscriptionSelector.class, new MockScheduleZSubscriptionSelector());
        BatchClientFileCopierService.contentVersionSelector = (ContentVersionSelector) Test.createStub(ContentVersionSelector.class, new MockContentVersionSelector());
        if (returnContractDocs) {
            ClientFileCopierService.contentDocumentSelector = (ContentDocumentSelector) Test.createStub(ContentDocumentSelector.class, new MockContentDocumentSelector());
        } else {
            ClientFileCopierService.contentDocumentSelector = (ContentDocumentSelector) Test.createStub(ContentDocumentSelector.class, new MockContentDocumentOpportunitySelector());
        }
    }

    public class MockContractSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            String contractsAsString = '[' +
                '{"Id":"8002f000000GebbAAC"},' + // has no files
                '{"Id":"8002f000000GevzAAC"},' +
                '{"Id":"8002f000000Gew0AAC"},' + // has 2 UASes
                '{"Id":"8002f000000Gew1AAC"},' +
                '{"Id":"8002f000000Gew2AAC"},' +
                '{"Id":"8002f000000GewFAAS"},' + // has 2 UASes
                '{"Id":"8002f000000GewNAAS", "Parent_Contract__c" : "8002f000000GewNBBB"}]'; // Hybrid Customer with Generic and Project Specific Contracts
            switch on methodCall.stubbedMethodName {
                when 'getCustomerContractsByAssignmentAgreement' {
                    return (List<Contract>) JSON.deserialize(contractsAsString, List<Contract>.class);
                }
            }
            return null;
        }
    }

    public class MockOppSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            String oppAsString = '[' +
                '{"Id":"0062f00000EllRvAAJ","Personal_Credit_Report2__c":"a0Fj000000EYyV1EAL"},' +
                '{"Id":"0062f00000EllRwAAJ","Personal_Credit_Report2__c":"a0Fj000000EYyV2EAL"},' + // 2 UASes
                '{"Id":"0062f00000EllRqAAJ","Personal_Credit_Report2__c":"a0Fj000000EYyZ4EAL"},' +
                '{"Id":"0062f00000EllRrAAJ","Personal_Credit_Report2__c":"a0Fj000000EYyZ5EAL"}' +
            ']';
            switch on methodCall.stubbedMethodName {
                when 'getCustomerOpportunitiesByAssignmentAgreement' {
                    return (List<Opportunity>) JSON.deserialize(oppAsString, List<Opportunity>.class);
                }
            }
            return null;
        }
    }

    public class MockContentDocumentOpportunitySelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            String docLinkAsString = '[' +
                '{"Id":"06A2f000009rUqOEAU","LinkedEntityId":"a0Fj000000EYyZ5EAL","ContentDocumentId":"0692f000001g4u2AAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001eitDAAQ","LatestPublishedVersion":{"Title":"LASERCA_FileName"}}},' +
                '{"Id":"06A2f000005tUqOEAU","LinkedEntityId":"a0Fj000000EYyZ4EAL","ContentDocumentId":"0692f000001g5u2AAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001fitDAAQ","LatestPublishedVersion":{"Title":"LASERCA_FileName"}}},' +
                '{"Id":"06A2f000008tUqOEAU","LinkedEntityId":"a0Fj000000EYyV2EAL","ContentDocumentId":"0692f000001g8u2AAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001jitDAAQ","LatestPublishedVersion":{"Title":"LASERCA_FileName"}}},' +
                '{"Id":"06A2f000009tUqOEAU","LinkedEntityId":"a0Fj000000EYyV1EAL","ContentDocumentId":"0692f000001g0u2AAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001kitDAAQ","LatestPublishedVersion":{"Title":"LASERCA_FileName"}}}' +
            ']';

            switch on methodCall.stubbedMethodName {
                when 'selectByLinkedEntitiesWithoutData' {
                    return (List<ContentDocumentLink>) JSON.deserialize(docLinkAsString, List<ContentDocumentLink>.class);
                }
            }
            return null;
        }
    }

    public class MockContentDocumentSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            String docLinksForAssignmentAgreement = '[' +
                '{"Id":"06A2f000004rUrQEAU","LinkedEntityId":"8002f000000GevzAAC","ContentDocumentId":"0692f000001g9v4AAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001giuFAAQ","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Credit Allocation Agreement"}}},' +
                '{"Id":"06A2f000004rUrLEAU","LinkedEntityId":"8002f000000Gew0AAC","ContentDocumentId":"0692f000001g9uzAAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001giuAAAQ","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Credit Allocation Agreement"}}},' +
                '{"Id":"06A2f000004rUrGEAU","LinkedEntityId":"8002f000000Gew1AAC","ContentDocumentId":"0692f000001g9uuAAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001giu5AAA","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Credit Allocation Agreement"}}},' +
                '{"Id":"06A2f000004rUr1EAE","LinkedEntityId":"8002f000000Gew2AAC","ContentDocumentId":"0692f000001g9ukAAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001gitvAAA","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Credit Allocation Agreement"}}},' +
                '{"Id":"06A2f000004rUrNEAE","LinkedEntityId":"8002f000000Gew2AAC","ContentDocumentId":"0692f000001g9ujAAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001gitbAAA","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Disclosure Form"}}},' +
                '{"Id":"06A2f000004rUqrEAE","LinkedEntityId":"8002f000000GewFAAS","ContentDocumentId":"0692f000001g9uVAAQ","ContentDocument":{"LatestPublishedVersionId":"0682f000001gitgAAA","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Credit Allocation Agreement"}}},' +
                '{"Id":"06A2f000004rUqXEAE","LinkedEntityId":"8002f000000GewFAAS","ContentDocumentId":"0692f000001g9uxAAQ","ContentDocument":{"LatestPublishedVersionId":"0682f000001gittAAA","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Disclosure Form"}}},' +
                '{"Id":"06A2f000004rUqXCCC","LinkedEntityId":"8002f000000GewNAAS","ContentDocumentId":"0692f000001g9uxCCC","ContentDocument":{"LatestPublishedVersionId":"0682f000001gittCCC","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Customer Addendum"}}},' +
                '{"Id":"06A2f000004rUqXDDD","LinkedEntityId":"8002f000000GewNAAS","ContentDocumentId":"0692f000001g9uxDDD","ContentDocument":{"LatestPublishedVersionId":"0682f000001gittDDD","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Disclosure Form"}}},' +
                '{"Id":"06A2f000004rUqOEBB","LinkedEntityId":"8002f000000GewNBBB","ContentDocumentId":"0692f000001g9u2AAB","ContentDocument":{"LatestPublishedVersionId":"0682f000001gitDAAB","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Community Solar Agreement"}}}' +
            ']';
            String docLinksForAllocationSchedule = '[' +
                '{"Id":"06A2f000004rUrQEAU","LinkedEntityId":"8000a0000012jqUAAQ","ContentDocumentId":"0692f000001g9v4AAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001giuFAAQ","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Disclosure Form"}}},' +
                '{"Id":"06A2f000004rUqXCCC","LinkedEntityId":"8000a0000012igyAAA","ContentDocumentId":"0692f000001g9uuAAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001giuFAAQ","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Disclosure Form"}}},' +
                '{"Id":"06A2f000004rUqXDDD","LinkedEntityId":"8000a0000012nz3AAA","ContentDocumentId":"0692f000001g9uxDDD","ContentDocument":{"LatestPublishedVersionId":"0682f000001giuFAAQ","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Disclosure Form"}}},' +
                '{"Id":"06A2f000004rUqXEEE","LinkedEntityId":"8000a0000012nz3AAC","ContentDocumentId":"0692f000001g9uxEEE","ContentDocument":{"LatestPublishedVersionId":"0682f000001giuFAAQ","LatestPublishedVersion":{"Signing_Status__c":"Countersigned","Title":"Terms and Conditions"}}}' +
            ']';
            if (methodCall.stubbedMethodName == 'selectByLinkedEntitiesWithoutData' && testForAssignmentAgreement) {
                return (List<ContentDocumentLink>) JSON.deserialize(docLinksForAssignmentAgreement, List<ContentDocumentLink>.class);
            } else if (methodCall.stubbedMethodName == 'selectByLinkedEntitiesWithoutData' && testForAllocationSchedule) {
                return (List<ContentDocumentLink>) JSON.deserialize(docLinksForAllocationSchedule, List<ContentDocumentLink>.class);
            }
            return null;
        }
    }

    public class MockScheduleZSubscriptionSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            String alssAsString = '[' +
                '{"Id":"a545b000000VHFqAAO","Utility_Account_Subscription__r":{"Opportunity__r":{"ContractId":"8000a0000012jqUAAQ"}}},'+
                '{"Id":"a545b000000VHFtAAO","Utility_Account_Subscription__r":{"Opportunity__r":{"ContractId":"8000a0000012igyAAA"}}},'+
                '{"Id":"a545b000000VHFuAAO","Utility_Account_Subscription__r":{"Opportunity__r":{"ContractId":"8000a0000012igyAAA"}}},'+
                '{"Id":"a545b000000VHFvAAO","Utility_Account_Subscription__r":{"Opportunity__r":{"ContractId":"8000a0000012nz3AAA"}}},'+
                '{"Id":"a545b000000VHFwAAO","Utility_Account_Subscription__r":{"Opportunity__r":{"ContractId":"8000a0000012nz3AAA"}}},'+
                '{"Id":"a545b000000VHFwAAT","Utility_Account_Subscription__r":{"Opportunity__r":{"ContractId":"8000a0000012nz3AAB","Contract":{"Parent_Contract__c":"8007j000000cl80AAC"}}}}'+
            ']';
            switch on methodCall.stubbedMethodName {
                when 'getALSSforClientFileDownload' {
                    return (List<Schedule_Z_Subscription__c>) JSON.deserialize(alssAsString, List<Schedule_Z_Subscription__c>.class);
                }
            }
            return null;
        }
    }

    public class MockUASSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            String uasesForAssignmentAgreement = '[' +
                '{"Id":"a1d2f000000FYqDAAW","Name":"0002340","Opportunity__c":"0062f00000EllRvAAJ","Opportunity__r":{"Name":"Joshua Phillips","Personal_Credit_Report2__c":"a0Fj000000EYyV1EAL","ContractId":"8002f000000GevzAAC","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8002f000000GevzAAC","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"0000234"}},' +
                '{"Id":"a1d2f000000FZqDAAW","Name":"0002300","Opportunity__c":"8002f000000GebbAAC","Opportunity__r":{"Name":"Joshua River","Personal_Credit_Report2__c":"a0Fj000000EZZV1EAL","ContractId":"8002f000000GennAAC","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8002f000000GennAAC","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"00002340"}},' +
                '{"Id":"a1d2f000000FYqEAAW","Name":"0002340","Opportunity__c":"0062f00000EllRwAAJ","Opportunity__r":{"Name":"Joshua Phillips","Personal_Credit_Report2__c":"a0Fj000000EYyV2EAL","ContractId":"8002f000000Gew0AAC","Shared_Solar_System__r":{"Name":"Project E Dog St"},"Contract":{"Id":"8002f000000Gew0AAC","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"0000235"}},' +
                '{"Id":"a1d2f000000FYqFAAW","Name":"0002341","Opportunity__c":"0062f00000EllRwAAJ","Opportunity__r":{"Name":"Joshua Phillips","Personal_Credit_Report2__c":"a0Fj000000EYyV2EAL","ContractId":"8002f000000Gew0AAC","Shared_Solar_System__r":{"Name":"Project E Dog St"},"Contract":{"Id":"8002f000000Gew0AAC","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"0000235"}},' +
                '{"Id":"a1d2f000000FYqGAAW","Name":"0002342","Opportunity__c":"0062f00000EllRxAAJ","Opportunity__r":{"Name":"Donna Simmons","Personal_Credit_Report2__c":"","ContractId":"8002f000000Gew1AAC","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8002f000000Gew1AAC","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"00002341"}},' +
                '{"Id":"a1d2f000000FYqHAAW","Name":"0002343","Opportunity__c":"0062f00000EllRyAAJ","Opportunity__r":{"Name":"Keith Morgan","Personal_Credit_Report2__c":"","ContractId":"8002f000000Gew2AAC","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8002f000000Gew2AAC","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"00002342"}},' +
                '{"Id":"a1d2f000000FYqIAAW","Name":"0002344","Opportunity__c":"0062f00000EllRzAAJ","Opportunity__r":{"Name":"Mark Allen","Personal_Credit_Report2__c":"","ContractId":"8002f000000Gew3AAC","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8002f000000Gew3AAC","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"00002343"}},' +
                '{"Id":"a1d2f000000FYqJAAW","Name":"0002345","Opportunity__c":"0062f00000EllS0AAJ","Opportunity__r":{"Name":"Albert Price","Personal_Credit_Report2__c":"","ContractId":"8002f000000Gew4AAC","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8002f000000Gew4AAC","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"00002344"}},' +
                '{"Id":"a1d2f000000FYqKAAW","Name":"0002346","Opportunity__c":"0062f00000EllS1AAJ","Opportunity__r":{"Name":"Naveed Ventura","Personal_Credit_Report2__c":"","ContractId":"8002f000000Gew5AAC","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8002f000000Gew5AAC","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"00002345"}},' +
                '{"Id":"a1d2f000000FYqLAAW","Name":"0002347","Opportunity__c":"0062f00000EllS2AAJ","Opportunity__r":{"Name":"Woody Walsh","Personal_Credit_Report2__c":"","ContractId":"8002f000000Gew6AAC","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8002f000000Gew6AAC","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"00002346"}},' +
                '{"Id":"a1d2f000000FYq4AAG","Name":"0002343","Opportunity__c":"0062f00000EllRmAAJ","Opportunity__r":{"Name":"Justin Jenkins","Personal_Credit_Report2__c":"","ContractId":"8002f000000GewFAAS","Shared_Solar_System__r":{"Name":"Project E Dog St"},"Contract":{"Id":"8002f000000GewFAAS","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"00002342"}},' +
                '{"Id":"a1d2f000000FYq5AAG","Name":"0002344","Opportunity__c":"0062f00000EllRmAAJ","Opportunity__r":{"Name":"Justin Jenkins","Personal_Credit_Report2__c":"","ContractId":"8002f000000GewFAAS","Shared_Solar_System__r":{"Name":"Project E Dog St"},"Contract":{"Id":"8002f000000GewFAAS","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"00002343"}},' +
                '{"Id":"a1d2f000000FYq9AAG","Name":"0002348","Opportunity__c":"0062f00000EllRqAAJ","Opportunity__r":{"Name":"Margaux Maldonado","Personal_Credit_Report2__c":"a0Fj000000EYyZ4EAL","ContractId":"8002f000000GewKAAS","Shared_Solar_System__r":{"Name":"Project E Dog St"},"Contract":{"Id":"8002f000000GewKAAS","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"00002347"}},' +
                '{"Id":"a1d2f000000FYqAAAW","Name":"0002349","Opportunity__c":"0062f00000EllRrAAJ","Opportunity__r":{"Name":"Conor Schmitt","Personal_Credit_Report2__c":"a0Fj000000EYyZ5EAL","ContractId":"8002f000000GewLAAS","Shared_Solar_System__r":{"Name":"Project E Dog St"},"Contract":{"Id":"8002f000000GewLAAS","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"00002348"}},' +
                '{"Id":"a1d2f000000FYqBAAW","Name":"00023410","Opportunity__c":"0062f00000EllRsAAJ","Opportunity__r":{"Name":"Akbar Boyce","Personal_Credit_Report2__c":"","ContractId":"8002f000000GewMAAS","Shared_Solar_System__r":{"Name":"Project E Dog St"},"Contract":{"Id":"8002f000000GewMAAS","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"00002349"}},' +
                '{"Id":"a1d2f000000FYqCAAW","Name":"00023411","Opportunity__c":"0062f00000EllRtAAJ","Opportunity__r":{"Name":"Viaan Faulkner","Personal_Credit_Report2__c":"","ContractId":"8002f000000GewNAAS","Shared_Solar_System__r":{"Name":"Project E Dog St"},"Contract":{"Id":"8002f000000GewNAAS", "Parent_Contract__c" : "8002f000000GewNBBB", "Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"000023410"}}' +
            ']';
            String uasesForAllocationSchedule = '[' +
                '{"Id":"a1d2f000000FYqDAAW","Name":"0002301","Opportunity__c":"0062f00000EllRvAAJ","Opportunity__r":{"Name":"Test 1","Personal_Credit_Report2__c":"a0Fj000000EYyV1EAL","ContractId":"8000a0000012jqUAAQ","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8000a0000012jqUAAQ","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"0002301"}},' +
                '{"Id":"a1d2f000000FZqDAAW","Name":"0002302","Opportunity__c":"8002f000000GebbAAC","Opportunity__r":{"Name":"Test 2a","Personal_Credit_Report2__c":"a0Fj000000EZZV1EAL","ContractId":"8000a0000012igyAAA","Shared_Solar_System__r":{"Name":"Project E Dog St"},"Contract":{"Id":"8000a0000012igyAAA","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"0002302"}},' +
                '{"Id":"a1d2f000000FYqEAAW","Name":"0002303","Opportunity__c":"0062f00000EllRwAAJ","Opportunity__r":{"Name":"Test 2b","Personal_Credit_Report2__c":"a0Fj000000EYyV2EAL","ContractId":"8000a0000012igyAAA","Shared_Solar_System__r":{"Name":"Project E Dog St"},"Contract":{"Id":"8000a0000012igyAAA","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"0002303"}},' +
                '{"Id":"a1d2f000000FYqFAAW","Name":"0002304","Opportunity__c":"0062f00000EllRwAAJ","Opportunity__r":{"Name":"Test 3a","Personal_Credit_Report2__c":"a0Fj000000EYyV2EAL","ContractId":"8000a0000012nz3AAA","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8000a0000012nz3AAA","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"0002304"}},' +
                '{"Id":"a1d2f000000FYqGAAW","Name":"0002305","Opportunity__c":"0062f00000EllRxAAJ","Opportunity__r":{"Name":"Test 3b","Personal_Credit_Report2__c":"a0Fj000000EYyV2EAL","ContractId":"8000a0000012nz3AAA","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8000a0000012nz3AAA","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"0002305"}},' +
                '{"Id":"a1d2f000000FYqGAAX","Name":"0002306","Opportunity__c":"0062f00000EllRxAAK","Opportunity__r":{"Name":"Test 3c","ContractId":"8000a0000012nz3AAB","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8000a0000012nz3AAB","Parent_Contract__c":"8000a0000012nz3AAC"}},"Utility_Account_Log__r":{"Name":"0002305"}}' +
            ']';
            Id parentSObjectId = (Id) methodCall.listOfArgs[0];
            if (parentSObjectId.getSobjectType() == Contract.SObjectType) {
                return (List<Utility_Account_Subscription__c>) JSON.deserialize(uasesForAssignmentAgreement, List<Utility_Account_Subscription__c>.class);
            } else {
                return (List<Utility_Account_Subscription__c>) JSON.deserialize(uasesForAllocationSchedule, List<Utility_Account_Subscription__c>.class);
            }
        }
    }

    @SuppressWarnings('PMD.AvoidHardcodingId')
    public class MockContentVersionSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            ContentVersion fileOne = new ContentVersion(Id = '0682f000001giuFAAQ', ContentDocumentId = '0692f000001g9v4AAA', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileTwo = new ContentVersion(Id = '0682f000001giuAAAQ', ContentDocumentId = '0692f000001g9uzAAA', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileThree = new ContentVersion(Id = '0682f000001giu5AAA', ContentDocumentId = '0692f000001g9uuAAA', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileFour = new ContentVersion(Id = '0682f000001gitvAAA', ContentDocumentId = '0692f000001g9ukAAA', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileFive = new ContentVersion(Id = '0682f000001gitbAAA', ContentDocumentId = '0692f000001g9ujAAA', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileSix = new ContentVersion(Id = '0682f000001gitgAAA', ContentDocumentId = '0692f000001g9uVAAQ', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileSeven = new ContentVersion(Id = '0682f000001gittAAA', ContentDocumentId = '0692f000001g9uxAAQ', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileTweleve = new ContentVersion(Id = '0682f000001gitDAAQ', ContentDocumentId = '0692f000001g9u2AAA', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileEighteen = new ContentVersion(Id = '0682f000001eitDAAQ', ContentDocumentId = '0692f000001g4u2AAA', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileNineteen = new ContentVersion(Id = '0682f000001fitDAAQ', ContentDocumentId = '0692f000001g5u2AAA', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileTwentyTwo = new ContentVersion(Id = '0682f000001jitDAAQ', ContentDocumentId = '0692f000001g8u2AAA', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileTwentyThree = new ContentVersion(Id = '0682f000001kitDAAQ', ContentDocumentId = '0692f000001g0u2AAA', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileTwentyFour = new ContentVersion(Id = '0682f000001gitDAAB', ContentDocumentId = '0692f000001g0u2BBB', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileTwentyFive = new ContentVersion(Id = '0682f000001gittCCC', ContentDocumentId = '0692f000001g9uxCCC', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');
            ContentVersion fileTwentySix = new ContentVersion(Id = '0682f000001gittDDD', ContentDocumentId = '0692f000001g9uxDDD', VersionData = Blob.valueOf('textBody'), Signing_Status__c = 'Countersigned');

            Map<Id,ContentVersion> assignmentAgreementCvs = new Map<Id,ContentVersion>{
                fileOne.Id => fileOne,
                fileTwo.Id => fileTwo,
                fileThree.Id => fileThree,
                fileFour.Id => fileFour,
                fileFive.Id => fileFive,
                fileSix.Id => fileSix,
                fileSeven.Id => fileSeven,
                fileTweleve.Id => fileTweleve,
                fileEighteen.Id => fileEighteen,
                fileNineteen.Id => fileNineteen,
                fileTwentyTwo.Id => fileTwentyTwo,
                fileTwentyThree.Id => fileTwentyThree,
                fileTwentyFour.Id => fileTwentyFour,
                fileTwentyFive.Id => fileTwentyFive,
                fileTwentySix.Id => fileTwentySix
            };
            Map<Id,ContentVersion> allocationScheduleCvs = new Map<Id,ContentVersion>{
                fileOne.Id => fileOne,
                fileThree.Id => fileThree,
                fileTwentySix.Id => fileTwentySix
            };

            switch on methodCall.stubbedMethodName {
                when 'selectByIdWithData' {
                    return testForAssignmentAgreement ? assignmentAgreementCvs : allocationScheduleCvs;
                }
                when 'selectById' {
                    Map<Id,ContentVersion> versionMap = new Map<Id,ContentVersion>([
                        SELECT Id, ContentDocumentId
                        FROM ContentVersion
                    ]);
                    return versionMap;
                }
            }
            return null;
        }
    }
}