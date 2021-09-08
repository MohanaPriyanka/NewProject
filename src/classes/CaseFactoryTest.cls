/**
 * @description Created by mstackhouse on 12/28/2018.
 * Description: Tests for CaseFactory
 */
@IsTest
public with sharing class CaseFactoryTest {

    @TestSetup
    public static void setupTestData() {
        Load_U__c loadZone = new Load_U__c (
            Name = '12345',
            LZ__c = 'Hudson Valley',
            Town__c = 'Albany'
        );

        Utility__c nyseg = new Utility__c(
            Name = 'NYS Electric and Gas',
            Number_of_Decimal_Places__c = 2,
            EIA_ID__c = '1234'
        );

        Product2 vderProduct = new Product2(Name = 'VDER',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'VDER - Community Solar',
            State__c = 'NY',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_in_Bill_Period__c = 20,
            Monthly_Late_Fee__c = 1);

        Lead resiLead = new Lead(
            FirstName = 'Switch',
            LastName = 'Testcase',
            Email = 'test@email.com',
            MobilePhone = '1231231234',
            Company = 'Post Testcase',
            Application_Type__c = 'Residential',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Albany',
            LASERCA__Home_State__c = 'NY',
            LASERCA__Home_Zip__c = '12345',
            Street = '55 Boston St',
            City = 'Albany',
            State = BlueWaveParent.convertAbbreviationToState('NY'),
            PostalCode = '12345',
            Parcel_Zip__c = '12345',
            Application_Source_Phase_1__c = 'Switch without Partner',
            LeadSource = 'Switch',
            Product_line__c = 'Community Solar',
            Product__c = vderProduct.Id,
            LoadZone__c = loadZone.LZ__c,
            Utility_relationship__c = nyseg.Id,
            Phone = '1231231234',
            Customer_type__c = 'Residential',
            Status = 'Sales Qualified'
        );

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        resiLead.setOptions(dmo);
        insert resiLead;
    }

    @IsTest
    public static void testGetProductSupportCase() {
        RecordType productSupport = [
            SELECT Id, Name
            FROM RecordType
            WHERE SobjectType = 'Case' AND DeveloperName = 'Product_Support'
            LIMIT 1
        ];

        Group productQueueID = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Product_Support'
            LIMIT 1
        ];

        CaseFactory caseFactory = new CaseFactory();
        Case testCase = caseFactory.getCase('Product_Support');

        System.assertEquals(productSupport.Id, testCase.RecordTypeId);
        System.assertEquals(productQueueID.Id, testCase.OwnerId);
    }

    @IsTest
    public static void testGetCustomerCareCase() {
        RecordType customerCare = [
            SELECT Id, Name
            FROM RecordType
            WHERE SobjectType = 'Case' AND DeveloperName = 'Customer_Care'
            LIMIT 1
        ];

        Group customerCareQueueID = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Customer_Care'
            LIMIT 1
        ];

        CaseFactory caseFactory = new CaseFactory();
        Case testCase = caseFactory.getCase('Customer_Care');

        System.assertEquals(customerCare.Id, testCase.RecordTypeId);
        System.assertEquals(customerCareQueueID.Id, testCase.OwnerId);
    }

    @IsTest
    public static void getCollectionsCase() {
        RecordType customerCare = [
            SELECT Id, Name
            FROM RecordType
            WHERE SobjectType = 'Case' AND DeveloperName = 'Customer_Care'
            LIMIT 1
        ];

        Group collectionsQueue = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Collections'
            LIMIT 1
        ];

        CaseFactory caseFactory = new CaseFactory();
        Case testCase = caseFactory.getCase('Collections');

        System.assertEquals(customerCare.Id, testCase.RecordTypeId);
        System.assertEquals(collectionsQueue.Id, testCase.OwnerId);
    }

    @IsTest
    public static void getDataOpsCase() {
        RecordType customerCare = [
            SELECT Id, Name
            FROM RecordType
            WHERE SobjectType = 'Case' AND DeveloperName = 'Customer_Care'
            LIMIT 1
        ];

        Group dataOpsQueue = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Data_Ops'
            LIMIT 1
        ];

        CaseFactory caseFactory = new CaseFactory();
        Case testCase = caseFactory.getCase('Data_Ops');

        System.assertEquals(customerCare.Id, testCase.RecordTypeId);
        System.assertEquals(dataOpsQueue.Id, testCase.OwnerId);
    }

    @IsTest
    public static void testGetPartnerCareCase() {
        RecordType partnerCareCase = [
            SELECT Id, Name
            FROM RecordType
            WHERE SobjectType = 'Case' AND DeveloperName = 'Partner_Care_Case'
            LIMIT 1
        ];

        Group partnerCareQueueID = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Partner_Support'
            LIMIT 1
        ];

        CaseFactory caseFactory = new CaseFactory();
        Case testCase = caseFactory.getCase('Partner_Care_Case');

        System.assertEquals(partnerCareCase.Id, testCase.RecordTypeId);
        System.assertEquals(partnerCareQueueID.Id, testCase.OwnerId);
    }

    @IsTest
    public static void testGetCaseWithoutType() {
        CaseFactory caseFactory = new CaseFactory();
        Case testCase = caseFactory.getCase('Emotional_Support');

        System.assertEquals(null, testCase.RecordTypeId);
        System.assertEquals(null, testCase.OwnerId);
    }

    @IsTest
    public static void testNoMatchCaseCreation() {
        Lead switchLead = [
            SELECT Id,Name,Parent_Account__c
            FROM Lead
            LIMIT 1
        ];

        System.assertEquals(0, new CaseSelector().selectOpenNoMatchCasesFromLead(switchLead).size(), 'There should be no open cases for ' +
            'this lead before enqueuing');
        Test.startTest();
        CaseFactory testFactory = new CaseFactory();
        CaseFactory testFactory2 = new CaseFactory();
        testFactory.setLead(switchLead);
        testFactory.setQueueType('No FICO Match');
        testFactory2.setLead(switchLead);
        testFactory2.setQueueType('No FICO Match');
        System.enqueueJob(testFactory);
        System.enqueueJob(testFactory2);
        Test.stopTest();
        System.assertEquals(1, new CaseSelector().selectOpenNoMatchCasesFromLead(switchLead).size(), 'If a case already ' +
            'exists another should not be created. There should only be 1 open case at a time.');
    }

    @IsTest
    public static void testLowMatchCaseCreation() {
        Lead switchLead = [
            SELECT Id,Name,Parent_Account__c
            FROM Lead
            LIMIT 1
        ];
        System.assertEquals(0, new CaseSelector().selectOpenLowMatchCasesFromLead(switchLead).size(),
            'There should be no open cases for this lead before enqueuing');
        Test.startTest();
        CaseFactory testFactory = new CaseFactory();
        CaseFactory testFactory2 = new CaseFactory();
        testFactory.setLead(switchLead);
        testFactory.setQueueType('Low FICO Match');
        testFactory2.setLead(switchLead);
        testFactory2.setQueueType('Low FICO Match');
        System.enqueueJob(testFactory);
        System.enqueueJob(testFactory2);
        Test.stopTest();
        System.assertEquals(1, new CaseSelector().selectOpenLowMatchCasesFromLead(switchLead).size(), 'If a case already ' +
            'exists another should not be created. There should only be 1 open case at a time.');
    }

    @IsTest
    public static void testEDIErrorCaseWithMapping() {
        List<EDI_Error_Mapping__mdt> cmdtRecords = [
            SELECT Exception_Reason_Code__c, Case_Subject__c, Case_Description__c
            FROM EDI_Error_Mapping__mdt
        ];
        EDI_Error_Mapping__mdt selectedErrorMapping;
        for (EDI_Error_Mapping__mdt detail : cmdtRecords) {
            if (detail.Exception_Reason_Code__c == 'HUR') {
                selectedErrorMapping = detail;
            }
        }
        CaseFactory factory = new CaseFactory();
        Case generatedCase;
        factory.erroredUtilityDataRequestIds = new Set<Id>{
            Util.getFakeId(Utility_Data_Request__c.SObjectType)
        };
        factory.setQueueType('EDI Error');
        Test.startTest();
        factory.getEDIErrorMappings();
        Utility_Data_Request__c mockUDR = getMockUDRForErrorCase('HUR');
        generatedCase = factory.createEDIErrorCase(mockUDR);
        Test.stopTest();
        System.assertEquals('Upload Complete Utility Bill to Case - Need More Pages', generatedCase.QC_Case_Subject__c,
            'Invalid QC case status');
        System.assertEquals('Community Solar', generatedCase.Product_Line__c, 'Invalid product line on Case');
        System.assertEquals('QC', generatedCase.Category__c, 'Invalid category for case');
        System.assertEquals('3rd Party', generatedCase.Case_Type__c, 'Invalid case type');

        String expectedCaseSubject = factory.parseEDIMergeFields(
            mockUDR, factory.getEDICaseFieldText(selectedErrorMapping, 'Subject')
        );
        String expectedCaseDescription = factory.parseEDIMergeFields(
            mockUDR, factory.getEDICaseFieldText(selectedErrorMapping, 'Description')
        );
        System.assertEquals(expectedCaseSubject, generatedCase.Subject,
            'Unexpected case Subject value for Case: ' + generatedCase.Subject);
        System.assertEquals(expectedCaseDescription, generatedCase.Description,
            'Unexpected case Description value for Case: ' + generatedCase.Description);
    }

    @IsTest
    public static void testEDIErrorCaseWithoutMapping() {
        CaseFactory factory = new CaseFactory();
        Case generatedCase;
        factory.erroredUtilityDataRequestIds = new Set<Id>{
            Util.getFakeId(Utility_Data_Request__c.SObjectType)
        };
        factory.setQueueType('EDI Error');
        Test.startTest();
        factory.getEDIErrorMappings();
        generatedCase = factory.createEDIErrorCase(getMockUDRForErrorCase('NOT_REAL_ERROR_CODE'));
        Test.stopTest();
        System.assertEquals('Upload Complete Utility Bill to Case - Need More Pages', generatedCase.QC_Case_Subject__c,
            'Invalid QC case status');
        System.assertEquals('Community Solar', generatedCase.Product_Line__c, 'Invalid product line on Case');
        System.assertEquals('QC', generatedCase.Category__c, 'Invalid category for case');
        System.assertEquals('3rd Party', generatedCase.Case_Type__c, 'Invalid case type');
        System.assert(!generatedCase.Subject.contains('{Lead}'), 'Merge field present where one should not be: ' +
            generatedCase.Subject);
        System.assert(!generatedCase.Description.contains('{Lead}') && !generatedCase.Description.contains('{UAL}'),
            'Merge fields present in case description where none should exist: ' + generatedCase.Description);
    }

    public static Utility_Data_Request__c getMockUDRForErrorCase(String exceptionCode) {
        sfab_FabricatedSObject leadRecord = new sfab_FabricatedSObject(Lead.class);
        leadRecord.setField(Lead.Name, 'Jamal Testcase');
        leadRecord.setField(Lead.Partner_Account__c, Util.getFakeId(Account.SObjectType));
        leadRecord.setField(Lead.Sales_Person__c, Util.getFakeId(Account.SObjectType));

        sfab_FabricatedSObject ual = new sfab_FabricatedSObject(Utility_Account_Log__c.class);
        ual.setField(Utility_Account_Log__c.Lead__c, Util.getFakeId(Lead.SObjectType));
        ual.setField(Utility_Account_Log__c.Name, '012345678');
        ual.setParent('Lead__r', leadRecord);

        sfab_FabricatedSObject udr = new sfab_FabricatedSObject(Utility_Data_Request__c.class);
        udr.setField(Utility_Data_Request__c.Id, Util.getFakeId(Utility_Data_Request__c.SObjectType));
        udr.setField(Utility_Data_Request__c.Exception_Reason_Code__c, exceptionCode);
        udr.setParent('Utility_Account_Log__r', ual);

        return (Utility_Data_Request__c) udr.toSObject();
    }

    @IsTest
    public static void testcreateBouncedEmailCases() {
        // list of leads
        List<Lead> leadsWithBouncedEmail = new List<Lead>();
        CaseFactory caseFactory = new CaseFactory();

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'TestCase'
        );
        insert testContact;

        Lead testLead = new Lead(
            FirstName = 'Lead',
            LastName = 'Testcase',
            Email = 'testEmail@email.com',
            Partner_Account__c = testAccount.Id,
            Partner_Contact__c = testContact.Id,
            Company = 'Company'
        );
        insert testLead;

        leadsWithBouncedEmail.add(testLead);

        List<Case> existingRelatedCases = [SELECT Id FROM Case WHERE Lead_Lookup__c = :testLead.Id];

        System.assertEquals(0, existingRelatedCases.size(), 'there should be no cases for this lead');

        Test.startTest();
        caseFactory.createBouncedEmailCases(leadsWithBouncedEmail);
        Test.stopTest();

        List<Case> createdCases = [SELECT Id, Description, ContactId, AccountId, Category__c FROM Case WHERE Lead_Lookup__c = :testLead.Id];

        System.assertEquals(1, createdCases.size(), 'there should be one new case for this lead');
        System.assertEquals(testContact.Id, createdCases[0].ContactId, 'Contact Id on the case should be the Lead Partner Contact');
        System.assertEquals(testAccount.Id, createdCases[0].AccountId, 'Account Id on the case should be the Lead Partner Account');



    }

    @IsTest
    public static void testCloseRelatedBouncedEmailCases() {
        List<Lead> testLeads = new List<Lead>();
        Lead testLead1 = new Lead(
            FirstName = 'John',
            LastName = 'Testcase',
            Company = 'Company',
            Email = 'emailBounceTest1@email.com'
        );

        testLeads.add(testLead1);
        insert testLeads;

        testLead1.EmailBouncedDate = System.now();
        update testLead1;

        CaseFactory caseFactory = new CaseFactory();
        caseFactory.createBouncedEmailCases(testLeads);

        List<Case> existingCases = [SELECT Id, Status FROM Case WHERE Lead_Lookup__c = :testLead1.Id];

        System.assertEquals('New', existingCases[0].Status, 'there should be one open case for this lead');


        Test.startTest();
        testLead1.EmailBouncedDate = null;
        testLead1.Email = 'newEmail@email.com';
        update testLead1;
        Test.stopTest();


        List<Case> closedCases = [SELECT Id, Status FROM Case WHERE Lead_Lookup__c = :testLead1.Id];

        System.assertEquals('Closed', closedCases[0].Status, 'the case should now be closed for this lead');

    }

}