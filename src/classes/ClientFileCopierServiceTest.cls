@IsTest
public with sharing class ClientFileCopierServiceTest {
    @TestSetup
    public static void testSetup() {
        Account clientAccount = new Account(Name = 'Client');
        insert clientAccount;
        Id rtAssign = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId();

        Contract assignmentAgreement = new Contract(
            Name = 'Assignment Agreement',
            RecordTypeId = rtAssign,
            AccountId = clientAccount.Id
        );
        insert assignmentAgreement;
    }

    @IsTest
    public static void testCustomerAgreementMigration() {
        useMocks(true);
        Contract assignmentAgreement = [
            SELECT Id
            FROM Contract
            WHERE Name = 'Assignment Agreement'
            LIMIT 1
        ];

        List<Supporting_Document_Folder__c> beforeFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = : assignmentAgreement.Id
        ];
        System.assertEquals(0,beforeFolders.size());

        Test.startTest();
            ClientFileCopierService service = new ClientFileCopierService();
            service.findAndCloneDocuments(assignmentAgreement.Id,ClientFileCopierService.FileType.CUSTOMERAGREEMENT);
        Test.stopTest();

        List<Supporting_Document_Folder__c> afterFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = : assignmentAgreement.Id
        ];
        System.assertEquals(1,afterFolders.size());

        List<ContentDocumentLink> afterFiles = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = : afterFolders[0].Id
        ];
        // 6 Contracts, 2 of which have 2 UASes each.
        System.assertEquals(8,afterFiles.size());
    }

    @IsTest
    public static void testCustomerDisclosureMigration() {
        useMocks(true);
        Contract assignmentAgreement = [
            SELECT Id
            FROM Contract
            WHERE Name = 'Assignment Agreement'
            LIMIT 1
        ];

        List<Supporting_Document_Folder__c> beforeFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = : assignmentAgreement.Id
        ];
        System.assertEquals(0,beforeFolders.size());

        Test.startTest();
            ClientFileCopierService service = new ClientFileCopierService();
            service.findAndCloneDocuments(assignmentAgreement.Id,ClientFileCopierService.FileType.DISCLOSURE);
        Test.stopTest();

        List<Supporting_Document_Folder__c> afterFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = : assignmentAgreement.Id
        ];
        System.assertEquals(1,afterFolders.size());

        List<ContentDocumentLink> afterFiles = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = : afterFolders[0].Id
        ];
        // 6 Contracts, 2 of which have a disclosure form attachment, 1 of which has 2 UASes
        System.assertEquals(3,afterFiles.size());
    }

    @IsTest
    public static void testPCRMigration() {
        useMocks(false);
        Contract assignmentAgreement = [
            SELECT Id
            FROM Contract
            WHERE Name = 'Assignment Agreement'
            LIMIT 1
        ];

        List<Supporting_Document_Folder__c> beforeFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = : assignmentAgreement.Id
        ];
        System.assertEquals(0,beforeFolders.size());

        Test.startTest();
            ClientFileCopierService service = new ClientFileCopierService();
            service.findAndCloneDocuments(assignmentAgreement.Id,ClientFileCopierService.FileType.CREDITREPORT);
        Test.stopTest();

        List<Supporting_Document_Folder__c> afterFolders = [
            SELECT Id
            FROM Supporting_Document_Folder__c
            WHERE Assignment_Agreement__c = : assignmentAgreement.Id
        ];
        System.assertEquals(1,afterFolders.size());

        List<ContentDocumentLink> afterFiles = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = : afterFolders[0].Id
        ];
        // 4 Opportunities, 1 of which has 2 UASes
        System.assertEquals(5,afterFiles.size());
    }

    private static void useMocks(Boolean returnContractDocs) {
        ClientFileCopierService.contractSelector = (ContractSelector) Test.createStub(ContractSelector.class, new MockContractSelector());
        ClientFileCopierService.oppSelector = (OpportunitiesSelector) Test.createStub(OpportunitiesSelector.class, new MockOppSelector());
        ClientFileCopierService.uasSelector = (UASSelector) Test.createStub(UASSelector.class, new MockUASSelector());
        ClientFileCopierService.mockedContentVersionSelector = (ContentVersionSelector) Test.createStub(ContentVersionSelector.class, new MockContentVersionSelector());
        if (returnContractDocs){
            ClientFileCopierService.contentDocumentSelector = (ContentDocumentSelector) Test.createStub(ContentDocumentSelector.class, new MockContentDocumentContractSelector());
        } else {
            ClientFileCopierService.contentDocumentSelector = (ContentDocumentSelector) Test.createStub(ContentDocumentSelector.class, new MockContentDocumentOpportunitySelector());
        }
    }

    public class MockContractSelector extends MockProvider {
        MockContractSelector() {}
        public override Object handleMethodCall(MethodCall methodCall) {
            String contractsAsString = '[' +
                '{"Id":"8002f000000GevzAAC"},' +
                '{"Id":"8002f000000Gew0AAC"},' + // has 2 UASes
                '{"Id":"8002f000000Gew1AAC"},' +
                '{"Id":"8002f000000Gew2AAC"},' +
                '{"Id":"8002f000000GewFAAS"},' + // has 2 UASes
                '{"Id":"8002f000000GewNAAS"}]';

            switch on methodCall.stubbedMethodName {
                when 'getCustomerContractsByAssignmentAgreement' {
                    return (List<Contract>)JSON.deserialize(contractsAsString, List<Contract>.class);
                }
            }
            return null;
        }
    }

    public class MockOppSelector extends MockProvider {
        MockOppSelector() {}
        public override Object handleMethodCall(MethodCall methodCall) {
            String oppAsString = '[' +
                '{"Id":"0062f00000EllRvAAJ","Personal_Credit_Report_2__c":"a0Fj000000EYyV1EAL"},' +
                '{"Id":"0062f00000EllRwAAJ","Personal_Credit_Report_2__c":"a0Fj000000EYyV2EAL"},' + // 2 UASes
                '{"Id":"0062f00000EllRqAAJ","Personal_Credit_Report_2__c":"a0Fj000000EYyZ4EAL"},' +
                '{"Id":"0062f00000EllRrAAJ","Personal_Credit_Report_2__c":"a0Fj000000EYyZ5EAL"}' +
                ']';

            switch on methodCall.stubbedMethodName {
                when 'getCustomerOpportunitiesByAssignmentAgreement' {
                    return (List<Opportunity>)JSON.deserialize(oppAsString, List<Opportunity>.class);
                }
            }
            return null;
        }
    }

    public class MockContentDocumentOpportunitySelector extends MockProvider {
        MockContentDocumentOpportunitySelector() {}
        public override Object handleMethodCall(MethodCall methodCall) {
            String docLinkAsString = '[' +
                '{"Id":"06A2f000009rUqOEAU","LinkedEntityId":"a0Fj000000EYyZ5EAL","ContentDocumentId":"0692f000001g4u2AAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001eitDAAQ","LatestPublishedVersion":{"Title":"LASERCA_FileName"}}},' +
                '{"Id":"06A2f000005tUqOEAU","LinkedEntityId":"a0Fj000000EYyZ4EAL","ContentDocumentId":"0692f000001g5u2AAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001fitDAAQ","LatestPublishedVersion":{"Title":"LASERCA_FileName"}}},' +
                '{"Id":"06A2f000008tUqOEAU","LinkedEntityId":"a0Fj000000EYyV2EAL","ContentDocumentId":"0692f000001g8u2AAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001jitDAAQ","LatestPublishedVersion":{"Title":"LASERCA_FileName"}}},' +
                '{"Id":"06A2f000009tUqOEAU","LinkedEntityId":"a0Fj000000EYyV1EAL","ContentDocumentId":"0692f000001g0u2AAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001kitDAAQ","LatestPublishedVersion":{"Title":"LASERCA_FileName"}}}' +
                ']';

            switch on methodCall.stubbedMethodName {
                when 'selectByLinkedEntitiesWithoutData' {
                    return (List<ContentDocumentLink>)JSON.deserialize(docLinkAsString, List<ContentDocumentLink>.class);
                }
            }
            return null;
        }
    }

    public class MockContentDocumentContractSelector extends MockProvider {
        MockContentDocumentContractSelector() {}
        public override Object handleMethodCall(MethodCall methodCall) {
            String docLinkAsString = '[' +
                '{"Id":"06A2f000004rUrQEAU","LinkedEntityId":"8002f000000GevzAAC","ContentDocumentId":"0692f000001g9v4AAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001giuFAAQ","LatestPublishedVersion":{"Title":"Credit Allocation Agreement"}}},' +
                '{"Id":"06A2f000004rUrLEAU","LinkedEntityId":"8002f000000Gew0AAC","ContentDocumentId":"0692f000001g9uzAAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001giuAAAQ","LatestPublishedVersion":{"Title":"Credit Allocation Agreement"}}},' +
                '{"Id":"06A2f000004rUrGEAU","LinkedEntityId":"8002f000000Gew1AAC","ContentDocumentId":"0692f000001g9uuAAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001giu5AAA","LatestPublishedVersion":{"Title":"Credit Allocation Agreement"}}},' +
                '{"Id":"06A2f000004rUr1EAE","LinkedEntityId":"8002f000000Gew2AAC","ContentDocumentId":"0692f000001g9ukAAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001gitvAAA","LatestPublishedVersion":{"Title":"Credit Allocation Agreement"}}},' +
                '{"Id":"06A2f000004rUrNEAE","LinkedEntityId":"8002f000000Gew2AAC","ContentDocumentId":"0692f000001g9ujAAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001gitbAAA","LatestPublishedVersion":{"Title":"Disclosure Form"}}},' +
                '{"Id":"06A2f000004rUqrEAE","LinkedEntityId":"8002f000000GewFAAS","ContentDocumentId":"0692f000001g9uVAAQ","ContentDocument":{"LatestPublishedVersionId":"0682f000001gitgAAA","LatestPublishedVersion":{"Title":"Credit Allocation Agreement"}}},' +
                '{"Id":"06A2f000004rUqXEAE","LinkedEntityId":"8002f000000GewFAAS","ContentDocumentId":"0692f000001g9uxAAQ","ContentDocument":{"LatestPublishedVersionId":"0682f000001gittAAA","LatestPublishedVersion":{"Title":"Disclosure Form"}}},' +
                '{"Id":"06A2f000004rUqOEAU","LinkedEntityId":"8002f000000GewNAAS","ContentDocumentId":"0692f000001g9u2AAA","ContentDocument":{"LatestPublishedVersionId":"0682f000001gitDAAQ","LatestPublishedVersion":{"Title":"Credit Allocation Agreement"}}}' +
                ']';

            switch on methodCall.stubbedMethodName {
                when 'selectByLinkedEntitiesWithoutData' {
                    return (List<ContentDocumentLink>)JSON.deserialize(docLinkAsString, List<ContentDocumentLink>.class);
                }
            }
            return null;
        }
    }

    public class MockUASSelector extends MockProvider {
        MockUASSelector() {}
        public override Object handleMethodCall(MethodCall methodCall) {
            String uasesAsString = '[' +
                '{"Id":"a1d2f000000FYqDAAW","Name":"0002340","Opportunity__c":"0062f00000EllRvAAJ","Opportunity__r":{"Name":"Joshua Phillips","Personal_Credit_Report2__c":"a0Fj000000EYyV1EAL","ContractId":"8002f000000GevzAAC","Shared_Solar_System__r":{"Name":"Project D Dee St"},"Contract":{"Id":"8002f000000GevzAAC","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"0000234"}},' +
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
                '{"Id":"a1d2f000000FYqCAAW","Name":"00023411","Opportunity__c":"0062f00000EllRtAAJ","Opportunity__r":{"Name":"Viaan Faulkner","Personal_Credit_Report2__c":"","ContractId":"8002f000000GewNAAS","Shared_Solar_System__r":{"Name":"Project E Dog St"},"Contract":{"Id":"8002f000000GewNAAS","Assignment_Agreement__c":"8002f000000GgXJAA0"}},"Utility_Account_Log__r":{"Name":"000023410"}}' +
                ']';

            switch on methodCall.stubbedMethodName {
                when 'getUASesForAssignmentAgreement' {
                    return (List<Utility_Account_Subscription__c>)JSON.deserialize(uasesAsString, List<Utility_Account_Subscription__c>.class);
                }
            }
            return null;
        }
    }

    public class MockContentVersionSelector extends MockProvider {
        MockContentVersionSelector() {}
        public override Object handleMethodCall(MethodCall methodCall) {
            ContentVersion fileOne = new ContentVersion(Id = '0682f000001giuFAAQ', ContentDocumentId = '0692f000001g9v4AAA', VersionData = Blob.valueOf('textBody'));
            ContentVersion fileTwo = new ContentVersion(Id = '0682f000001giuAAAQ', ContentDocumentId = '0692f000001g9uzAAA', VersionData = Blob.valueOf('textBody'));
            ContentVersion fileThree = new ContentVersion(Id = '0682f000001giu5AAA', ContentDocumentId = '0692f000001g9uuAAA', VersionData = Blob.valueOf('textBody'));
            ContentVersion fileFour = new ContentVersion(Id = '0682f000001gitvAAA', ContentDocumentId = '0692f000001g9ukAAA', VersionData = Blob.valueOf('textBody'));
            ContentVersion fileFive = new ContentVersion(Id = '0682f000001gitbAAA', ContentDocumentId = '0692f000001g9ujAAA', VersionData = Blob.valueOf('textBody'));
            ContentVersion fileSix = new ContentVersion(Id = '0682f000001gitgAAA', ContentDocumentId = '0692f000001g9uVAAQ', VersionData = Blob.valueOf('textBody'));
            ContentVersion fileSeven = new ContentVersion(Id = '0682f000001gittAAA', ContentDocumentId = '0692f000001g9uxAAQ', VersionData = Blob.valueOf('textBody'));
            ContentVersion fileTweleve = new ContentVersion(Id = '0682f000001gitDAAQ', ContentDocumentId = '0692f000001g9u2AAA', VersionData = Blob.valueOf('textBody'));
            ContentVersion fileEighteen = new ContentVersion(Id = '0682f000001eitDAAQ', ContentDocumentId = '0692f000001g4u2AAA', VersionData = Blob.valueOf('textBody'));
            ContentVersion fileNineteen = new ContentVersion(Id = '0682f000001fitDAAQ', ContentDocumentId = '0692f000001g5u2AAA', VersionData = Blob.valueOf('textBody'));
            ContentVersion fileTwentyTwo = new ContentVersion(Id = '0682f000001jitDAAQ', ContentDocumentId = '0692f000001g8u2AAA', VersionData = Blob.valueOf('textBody'));
            ContentVersion fileTwentyThree = new ContentVersion(Id = '0682f000001kitDAAQ', ContentDocumentId = '0692f000001g0u2AAA', VersionData = Blob.valueOf('textBody'));

            Map<Id,ContentVersion> cvMap = new Map<Id,ContentVersion>();
            cvMap.put(fileOne.Id,fileOne);
            cvMap.put(fileTwo.Id,fileTwo);
            cvMap.put(fileThree.Id,fileThree);
            cvMap.put(fileFour.Id,fileFour);
            cvMap.put(fileFive.Id,fileFive);
            cvMap.put(fileSix.Id,fileSix);
            cvMap.put(fileSeven.Id,fileSeven);
            cvMap.put(fileTweleve.Id,fileTweleve);
            cvMap.put(fileEighteen.Id,fileEighteen);
            cvMap.put(fileNineteen.Id,fileNineteen);
            cvMap.put(fileTwentyTwo.Id,fileTwentyTwo);
            cvMap.put(fileTwentyThree.Id,fileTwentyThree);

            switch on methodCall.stubbedMethodName {
                when 'selectByIdWithData' {
                    return cvMap;
                }
            }
            return null;
        }
    }
}