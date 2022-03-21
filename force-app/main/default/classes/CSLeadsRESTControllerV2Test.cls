/**
 * @description Created by jlugo on 2019-07-09.
 */
@IsTest
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.AvoidHardcodingId')
public with sharing class CSLeadsRESTControllerV2Test {

    private static CSLeadsRESTControllerV2 controller = new CSLeadsRESTControllerV2();
    private static MockLeadService mockLeadService;
    public static final String SAMPLE_EMAIL = 'email@invalid.com';

    private static void useMocks() {
        Lead newLead = new Lead(
            Id = Util.getFakeId(Lead.SObjectType),
            Email = SAMPLE_EMAIL
        );
        useMocks(newLead);
    }

    private static void useMocks(Lead leadToReturnFromLeadSelector) {
        mockLeadService = new MockLeadService();
        controller.leadService = (LeadService) Test.createStub(LeadService.class, mockLeadService);
        controller.accountService = (AccountService) Test.createStub(AccountService.class, new MockAccountService());
        controller.ualService = (UALService) Test.createStub(UALService.class, new MockUALService());
        controller.customerContractService = (CustomerContractService) Test.createStub(CustomerContractService.class, new MockCustomerContractService());
        controller.capacityService = (CapacityService) Test.createStub(CapacityService.class, new MockCapacityService());
        controller.duplicateService = (CSLeadsDuplicateService) Test.createStub(CSLeadsDuplicateService.class , new MockDuplicateService(false));
        controller.uow = (fflib_SObjectUnitOfWork) Test.createStub(fflib_SObjectUnitOfWork.class, new MockUOW());
        controller.leadSelector = (LeadSelector) Test.createStub(LeadSelector.class, new MockLeadSelector(leadToReturnFromLeadSelector));
        controller.accountsSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new MockAccountsSelector());
        controller.ualSelector = (UALSelector) Test.createStub(UALSelector.class, new MockUALSelector());
        CSApplicationFinisher.leadSelector = (LeadSelector) Test.createStub(LeadSelector.class, new MockLeadSelector(leadToReturnFromLeadSelector));
        CSApplicationFinisher.qualificationService = (CSQualificationService) Test.createStub(CSQualificationService.class, new MockQualificationService());
        CSApplicationFinisher.leadService = (LeadService) Test.createStub(LeadService.class, mockLeadService);
        RestContext.response = new RestResponse();
    }

    @TestSetup
    public static void testSetup() {
        Utility__c utility = new Utility__c(
            Name = 'Utility'
        );
        insert utility;
        Utility__c utilityWithEIA = new Utility__c(
            Name = 'Utility with EIA ID',
            EIA_ID__c = '1234',
            Utility_Data_Collection_Mechanism__c = 'File Upload'
        );
        insert utilityWithEIA;
        Product2 product = new Product2(
            Name = 'CS Product'
        );
        insert product;
    }

    /*******************
     *** getLead() ***
     *******************/
    @IsTest
    private static void testGetLeadSuccess() {
        useMocks();
        controller.getLead(Util.getFakeId(Lead.SObjectType), SAMPLE_EMAIL);
        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed GET request should succeed');
    }

    @IsTest
    private static void testGetLeadInvalidAuth() {
        useMocks();
        Boolean authError = false;
        try {
            controller.getLead(Util.getFakeId(Schema.Lead.SObjectType), 'test@test.com');
        } catch(Util.AuthorizationBWException abwe) {
            authError = true;
        }
        System.assert(authError, 'Incorrect email should throw authorization error');
    }

    @IsTest
    private static void testGetLeadMissingFields() {
        useMocks();
        controller.getLead(Util.getFakeId(Schema.Lead.SObjectType), null);
        System.assertEquals(400, RestContext.response.statusCode, 'Method should return error when either lead ID or email is omitted');
    }

    @IsTest
    private static void testGetLeadTooManyAccounts() {
        sfab_FabricatedSObject fabbedLead = new sfab_FabricatedSObject(Lead.class);
        fabbedLead.setField(Lead.Email, SAMPLE_EMAIL);
        fabbedLead.setField(Lead.Id, Util.getFakeId(Lead.SObjectType));
        sfab_FabricatedSObject fabbedPropertyAccount1 = new sfab_FabricatedSObject(Account.class);
        fabbedPropertyAccount1.setField(Account.Lead__c, Util.getFakeId(Lead.SObjectType));
        fabbedPropertyAccount1.setField(Account.Id, Util.getFakeId(Account.SObjectType));
        sfab_FabricatedSObject fabbedPropertyAccount2 = new sfab_FabricatedSObject(Account.class);
        fabbedPropertyAccount2.setField(Account.Lead__c, Util.getFakeId(Lead.SObjectType));
        fabbedPropertyAccount2.setField(Account.Id, Util.getFakeId(Account.SObjectType));
        fabbedLead.setChildren('Accounts__r', new List<sfab_FabricatedSObject>{fabbedPropertyAccount1, fabbedPropertyAccount2});
        useMocks((Lead) fabbedLead.toSObject());
        controller.getLead(Util.getFakeId(Lead.SObjectType), SAMPLE_EMAIL);
        System.assertEquals(400, RestContext.response.statusCode, 'Method should return error when lead has multiple property accounts');
    }

    /*******************
     *** patchLead() ***
     *******************/
    @IsTest
    private static void testPullCreditOnContractSignature() {
        sfab_FabricatedSObject fabbedLead = new sfab_FabricatedSObject(Lead.class);
        fabbedLead.setField(Lead.Id, Util.getFakeId(Lead.SObjectType));
        fabbedLead.setField(Lead.Email, SAMPLE_EMAIL);
        fabbedLead.setField(Lead.Customer_Signed_Date__c, Datetime.now());
        fabbedLead.setField(Lead.Underwriting_Criteria__c, 'FICO');
        sfab_FabricatedSObject fabbedContract = new sfab_FabricatedSObject(Contract.class);
        fabbedContract.setField(Contract.Id, Util.getFakeId(Contract.SObjectType));
        fabbedContract.setField(Contract.Lead__c, Util.getFakeId(Lead.SObjectType));
        fabbedContract.setField(Contract.Customer_Signature_Date_Time__c, Datetime.now());
        fabbedLead.setChildren('Contracts__r', new List<sfab_FabricatedSObject>{fabbedContract});
        useMocks((Lead) fabbedLead.toSObject());
        Util.mockDML = true;
        controller.updateLeadApplicationStatus(Util.getFakeId(Lead.SObjectType));
        System.assertNotEquals(null, Util.objectsUpdatedIfMockingDML);
        List<Lead> updatedLeads = (List<Lead>) Util.objectsUpdatedIfMockingDML;
        for (Lead checkLead : updatedLeads) {
            System.assertEquals(true, checkLead.Soft_Pull_Credit_Report__c, 'Credit should be pulled after Contracts have been signed');
        }
    }

    @IsTest
    private static void testDontPullCreditForFinancialDocs() {
        sfab_FabricatedSObject fabbedLead = new sfab_FabricatedSObject(Lead.class);
        fabbedLead.setField(Lead.Id, Util.getFakeId(Lead.SObjectType));
        fabbedLead.setField(Lead.Email, SAMPLE_EMAIL);
        fabbedLead.setField(Lead.Customer_Signed_Date__c, Datetime.now());
        fabbedLead.setField(Lead.Underwriting_Criteria__c, 'Financial Review');
        sfab_FabricatedSObject fabbedContract = new sfab_FabricatedSObject(Contract.class);
        fabbedContract.setField(Contract.Id, Util.getFakeId(Contract.SObjectType));
        fabbedContract.setField(Contract.Lead__c, Util.getFakeId(Lead.SObjectType));
        fabbedContract.setField(Contract.Customer_Signature_Date_Time__c, Datetime.now());
        fabbedLead.setChildren('Contracts__r', new List<sfab_FabricatedSObject>{fabbedContract});
        useMocks((Lead) fabbedLead.toSObject());
        Util.mockDML = true;
        controller.updateLeadApplicationStatus(Util.getFakeId(Lead.SObjectType));
        System.assertNotEquals(null, Util.objectsUpdatedIfMockingDML);
        List<Lead> updatedLeads = (List<Lead>) Util.objectsUpdatedIfMockingDML;
        for (Lead checkLead : updatedLeads) {
            System.assertEquals(false, checkLead.Soft_Pull_Credit_Report__c, 'Credit should not be pulled when Underwriting Criteria = Fincancial Docs');
        }
    }

    @IsTest
    private static void testPatchLeadSuccessFinancialDocs() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '", "applicationCompleteDate": "2019-01-01T01:00", "underwritingCriteria": "Financial Review" }';
        Test.startTest();
        controller.patchLead(jsonRequest);
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
        System.assertEquals(null, mockLeadService.getLastUpdatedLead().Status,
            'As of W-023944, Lead status should not be modified at the end of the application process.');
    }

    @IsTest
    private static void testPatchLeadStreetAddress() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '", "streetAddress": "123 Patched Street" }';
        controller.patchLead(jsonRequest);
        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
        System.assertEquals('123 Patched Street', mockLeadService.getLastUpdatedLead().Street, 'Street should be updated when streetAddress is PATCHed.');
        System.assertEquals('123 Patched Street', mockLeadService.getLastUpdatedLead().LASERCA__Home_Address__c, 'LASERCA Home Address should be updated when streetAddress is PATCHed.');
    }

    @IsTest
    private static void testPatchLeadCreditPullOnce() {
        sfab_FabricatedSObject fabbedLead = new sfab_FabricatedSObject(Lead.class);
        fabbedLead.setField(Lead.Id, Util.getFakeId(Lead.SObjectType));
        fabbedLead.setField(Lead.Email, SAMPLE_EMAIL);
        fabbedLead.setField(Lead.Customer_Signed_Date__c, Datetime.now());
        fabbedLead.setField(Lead.Underwriting_Criteria__c, 'FICO');
        fabbedLead.setField(Lead.Application_Status__c, 'Contracts Signed');
        sfab_FabricatedSObject fabbedContract = new sfab_FabricatedSObject(Contract.class);
        fabbedContract.setField(Contract.Id, Util.getFakeId(Contract.SObjectType));
        fabbedContract.setField(Contract.Lead__c, Util.getFakeId(Lead.SObjectType));
        fabbedContract.setField(Contract.Customer_Signature_Date_Time__c, Datetime.now());
        fabbedLead.setChildren('Contracts__r', new List<sfab_FabricatedSObject>{fabbedContract});
        useMocks((Lead) fabbedLead.toSObject());
        Util.mockDML = true;
        controller.updateLeadApplicationStatus(Util.getFakeId(Lead.SObjectType));
        System.assertEquals(null, Util.objectsUpdatedIfMockingDML, 'Application Status is the same and therefore does not require an update');
    }

    @IsTest
    private static void testPatchLeadNoFields() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '"}';
        controller.patchLead(jsonRequest);
        System.assertEquals(400, RestContext.response.statusCode, 'PATCH should throw an error when no patchable fields are provided');
    }

    @IsTest
    private static void testPatchLeadInvalidId() {
        useMocks(null);
        String jsonRequest = '{ "id": "00Q000000000111"}'; // ID of ...111 is set as an non-existent ID in the mock svc
        controller.patchLead(jsonRequest);
        System.assertEquals(404, RestContext.response.statusCode, 'PATCH should throw an error if the ID provided is not valid');
    }

    /******************************
     *** patchPropertyAccount() ***
     ******************************/
    @IsTest
    private static void testPatchPropertyAccountSuccess() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Account.SObjectType) + '", "zuoraPaymentRefId": "mockId", "zuoraPaymentRefIdExpirationDate": "2019-01-01T01:00" }';
        controller.patchPropertyAccount(jsonRequest);
        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
    }

    @IsTest
    private static void testPatchPropertyAccountNoFields() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Account.SObjectType) + '"}';
        controller.patchPropertyAccount(jsonRequest);
        System.assertEquals(400, RestContext.response.statusCode, 'PATCH should throw an error when no patchable fields are provided');
    }

    @IsTest
    private static void testPatchPropertyAccountInvalidId() {
        useMocks();
        String jsonRequest = '{ "id": "001000000000111"}'; // ID of ...111 is set as an non-existent ID in the mock svc
        controller.patchPropertyAccount(jsonRequest);
        System.assertEquals(404, RestContext.response.statusCode, 'PATCH should throw an error if the ID provided is not valid');
    }

    /******************
     *** postLead() ***
     ******************/
    @IsTest
    private static void testPostLeadNoFields() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '" }';
        controller.postLead(jsonRequest);
        System.assertEquals(400, RestContext.response.statusCode, 'POST should throw an error when required fields are not provided');
    }

    @IsTest
    private static void testPostLeadWithDuplicate() {
        useMocks();
        controller.duplicateService = (CSLeadsDuplicateService) Test.createStub(CSLeadsDuplicateService.class , new MockDuplicateService(true));
        String jsonRequest = '{' +
            '"leadId": "' + Util.getFakeId(Schema.Lead.SObjectType) + '",' +
            '"firstName": "Unit",' +
            '"lastName": "Testcase",' +
            '"email": "test@invalid.bluewavesolar.com",' +
            '"applicationType": "Residential",' +
            '"productName": "CS Product"' +
            '}';
        controller.postLead(jsonRequest);
        System.assertEquals(201, RestContext.response.statusCode, 'A lead Post with a duplicate lead should succeed');
    }

    @IsTest
    private static void testPostLeadWithMinimalFields() {
        useMocks();
        String jsonRequest = '{' +
            '"firstName": "Unit",' +
            '"lastName": "Testcase",' +
            '"email": "test@invalid.bluewavesolar.com",' +
            '"applicationType": "Residential",' +
            '"productName": "CS Product"' +
            '}';
        controller.postLead(jsonRequest);
        System.assertEquals(201, RestContext.response.statusCode, 'A Lead POST with minimal fields should succeed');
    }

    @IsTest
    private static void testPostLeadWithMinimalFieldsReturnUrl() {
        useMocks();
        String jsonRequest = '{' +
            '"firstName": "Unit",' +
            '"lastName": "Testcase",' +
            '"email": "test@invalid.bluewavesolar.com",' +
            '"applicationType": "Residential",' +
            '"productName": "CS Product"' +
            '}';
        controller.postLead(jsonRequest);
        System.assertEquals(201, RestContext.response.statusCode, 'A Lead POST with minimal fields should succeed');
        System.assertNotEquals(null, mockLeadService.getLastUpdatedLead().Continue_Application_Link__c, 'If a resume URL is not provided in a Lead POST call, one should be created automatically');
    }

    @IsTest
    private static void testPostLeadWithTooManyAccounts() {
        useMocks();
        // We only support one property account today.  If you try to pass multiple it, you should get an error
        String jsonRequest = '{' +
            '"firstName": "Unit",' +
            '"lastName": "Testcase",' +
            '"email": "test@invalid.bluewavesolar.com",' +
            '"mobilePhone": "555-555-5555",' +
            '"applicationType": "Residential",' +
            '"streetAddress": "1 Test Street",' +
            '"city": "Suffern",' +
            '"state": "NY",' +
            '"zipCode": "10901",' +
            '"productName": "CS Product",' +
            '"campaignId": "0005500000",' +
            '"propertyAccounts": [' +
            '   {' +
            '       "billingStreet": "Test billing street",' +
            '       "billingCity": "Test billing city",' +
            '       "billingState": "NY",' +
            '       "billingPostalCode": "14472",' +
            '       "utilityAccountLogs": [{' +
            '           "nameOnAccount": "Test Accounts Payable",' +
            '           "serviceStreet": "Test service street",' +
            '           "serviceCity": "Test service city",' +
            '           "serviceState": "NY",' +
            '           "servicePostalCode": "14472"' +
            '       }]' +
            '   },' +
            '   {' +
            '       "billingStreet": "Test billing street",' +
            '       "billingCity": "Test billing city",' +
            '       "billingState": "NY",' +
            '       "billingPostalCode": "14472",' +
            '       "utilityAccountLogs": [{' +
            '           "nameOnAccount": "Test Accounts Payable",' +
            '           "serviceStreet": "Test service street",' +
            '           "serviceCity": "Test service city",' +
            '           "serviceState": "NY",' +
            '           "servicePostalCode": "14472"' +
            '       }]' +
            '   }' +
            ']}';
        controller.postLead(jsonRequest);
        System.assertEquals(400, RestContext.response.statusCode, 'We currently only support 1 propertyAccount');
    }

    @IsTest
    private static void testPostLeadSuccess() {
        sfab_FabricatedSObject fabbedLead = new sfab_FabricatedSObject(Lead.class);
        fabbedLead.setField(Lead.Email, SAMPLE_EMAIL);
        fabbedLead.setField(Lead.Id, Util.getFakeId(Lead.SObjectType));
        fabbedLead.setField(Lead.CreatedDate, Datetime.now());
        sfab_FabricatedSObject fabbedPropertyAccount1 = new sfab_FabricatedSObject(Account.class);
        fabbedPropertyAccount1.setField(Account.Lead__c, Util.getFakeId(Lead.SObjectType));
        fabbedPropertyAccount1.setField(Account.Id, Util.getFakeId(Account.SObjectType));
        fabbedLead.setChildren('Accounts__r', new List<sfab_FabricatedSObject>{fabbedPropertyAccount1});
        sfab_FabricatedSObject fabbedUAL = new sfab_FabricatedSObject(Utility_Account_Log__c.class);
        fabbedUAL.setField(Utility_Account_Log__c.Lead__c, Util.getFakeId(Utility_Account_Log__c.SObjectType));
        fabbedUAL.setField(Utility_Account_Log__c.Id, Util.getFakeId(Utility_Account_Log__c.SObjectType));
        fabbedUAL.setField(Utility_Account_Log__c.Account__c, Util.getFakeId(Account.SObjectType));
        fabbedLead.setChildren('Utility_Account_Logs__r', new List<sfab_FabricatedSObject>{fabbedUAL});
        useMocks((Lead) fabbedLead.toSObject());
        String jsonRequest = '{' +
            '"firstName": "Unit",' +
            '"lastName": "Testcase",' +
            '"email": "test@invalid.bluewavesolar.com",' +
            '"mobilePhone": "555-555-5555",' +
            '"applicationType": "Residential",' +
            '"streetAddress": "1 Test Street",' +
            '"city": "Suffern",' +
            '"state": "NY",' +
            '"zipCode": "10901",' +
            '"eiaId": "1234",' +
            '"continueApplicationLink": "http://switch.bluewavesolar.invalid",' +
            '"productName": "CS Product",' +
            '"campaignId": "0005500000",' +
            '"propertyAccounts": [{' +
            '   "billingStreet": "Test billing street",' +
            '   "billingCity": "Test billing city",' +
            '   "billingState": "NY",' +
            '   "billingPostalCode": "14472",' +
            '   "utilityAccountLogs": [{' +
            '       "nameOnAccount": "Test Accounts Payable",' +
            '       "serviceStreet": "Test service street",' +
            '       "serviceCity": "Test service city",' +
            '       "serviceState": "NY",' +
            '       "servicePostalCode": "14472",' +
            '       "utilityAccountNumber": "555555"' +
            '   }]' +
            '}]}';
        controller.postLead(jsonRequest);
        System.assertEquals(201, RestContext.response.statusCode, 'Properly formed POST should succeed');
    }

    @IsTest
    private static void testPerformZipCheck() {
        useMocks();
        RestContext.response = new RestResponse();
        controller.getZipcodeCapacity('12345', '', '');
        Boolean caughtException = false;
        try {
            RESTController.ResponseEnvelope envelope =
                (RESTController.ResponseEnvelope) JSON.deserialize(RestContext.response.responseBody.toString(), RESTController.ResponseEnvelope.class);
            System.assertEquals(true, ((RestZipCode) envelope.data).hasCapacity, 'Expected mock to return a response with capacity');
        } catch (Exception e) {
            System.assert(!caughtException, e.getMessage() + '\n' + e.getStackTraceString());
        }
        System.assertEquals(false, caughtException, 'Did not expect to catch an exception');
    }

    /**************************
     *** patchApplication() ***
     **************************/
    @IsTest
    private static void testPatchApplicationNoLeadFields() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '"}';
        controller.patchApplication(jsonRequest);
        System.assertEquals(400, RestContext.response.statusCode, 'PATCH should throw an error when no patchable fields are provided');
    }

    @IsTest
    private static void testPatchApplicationInvalidLeadId() {
        useMocks(null);
        String jsonRequest = '{ "id": "00Q000000000111"}'; // ID of ...111 is set as an non-existent ID in the mock svc
        controller.patchApplication(jsonRequest);
        System.assertEquals(404, RestContext.response.statusCode, 'PATCH should throw an error if the ID provided is not valid');
    }

    @IsTest
    private static void testPatchApplicationMultiplePropertyAccounts() {
        useMocks();
        String jsonRequest = '{ ' +
            '"id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '",' +
            '"propertyAccounts": [ ' +
            '{ "id": "' + Util.getFakeId(Schema.Account.SObjectType) + '" },' +
            '{ "id": "' + Util.getFakeId(Schema.Account.SObjectType) + '" }' +
            '] ' +
            ' }';
        controller.patchApplication(jsonRequest);
        System.assertEquals(400, RestContext.response.statusCode, 'PATCH should throw an error when more than one property account is provided');
    }

    @IsTest
    private static void testPatchApplicationMissingUALs() {
        useMocks();
        String jsonRequest = '{ ' +
            '   "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '",' +
            '   "propertyAccounts": [ ' +
            '       { "id": "' + Util.getFakeId(Schema.Account.SObjectType) + '" }' +
            '   ] ' +
            '}';
        controller.patchApplication(jsonRequest);
        System.assertEquals(400, RestContext.response.statusCode, 'PATCH should throw an error when no property account fields or UALs are provided');
    }

    @IsTest
    private static void testPatchApplicationSuccessNoDocs() {
        useMocks();
        String jsonRequest = '{' +
            '"id": "'+Util.getFakeId(Lead.SObjectType)+'",' +
            '"firstName": "Unit",' +
            '"lastName": "Testcase",' +
            '"email": "test@invalid.bluewavesolar.com",' +
            '"mobilePhone": "555-555-5555",' +
            '"applicationType": "Residential",' +
            '"streetAddress": "1 Test Street",' +
            '"city": "Suffern",' +
            '"state": "NY",' +
            '"zipCode": "10901",' +
            '"productName": "CS Product",' +
            '"propertyAccounts": [{' +
            '   "id": "001000000000999",' +
            '   "leadId": "'+Util.getFakeId(Lead.SObjectType)+'", ' +
            '   "billingStreet": "Test billing street",' +
            '   "billingCity": "Test billing city",' +
            '   "billingState": "NY",' +
            '   "billingPostalCode": "14472",' +
            '   "utilityAccountLogs": [{' +
            '       "id": "a1b000000000999",' +
            '       "leadId": "'+Util.getFakeId(Lead.SObjectType)+'", ' +
            '       "propertyAccountId": "001000000000999",' +
            '       "nameOnAccount": "Test Accounts Payable",' +
            '       "serviceStreet": "Test service street",' +
            '       "serviceCity": "Test service city",' +
            '       "serviceState": "NY",' +
            '       "servicePostalCode": "14472",' +
            '       "utilityAccountNumber": "555555"' +
            '   }]' +
            '}]}';
        controller.patchApplication(jsonRequest);
        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
    }

    @IsTest
    private static void testContractFieldsUpdated() {
        Partner__c p0 = new Partner__c(Name = 'test record');
        Partner__c p1 = new Partner__c(Name = 'default test');
        insert new List<Partner__c>{p0, p1};
        BSST__c sr0 = new BSST__c(Name = 'test rep', Partner__c = p0.Id);
        BSST__c sr1 = new BSST__c(Name = 'default rep', Partner__c = p1.Id);
        insert new List<BSST__c>{sr0, sr1};
        p0.Default_Sales_Rep__c = sr0.Id;
        p1.Default_Sales_Rep__c = sr1.Id;
        update new List<Partner__c>{p0, p1};
        System_Properties__c sp = new System_Properties__c(Name = 'test', Default_CS_Partner__c = p1.Id);
        insert sp;
        Rate_Class__c rateClass = new Rate_Class__c(Name = 'Rate Class 1');
        insert rateClass;
        RestLead requestLead = new RestLead();
        requestLead.firstName = 'Unit';
        requestLead.lastName = 'Testcase';
        requestLead.email = 'test@invalid.bluewavesolar.com';
        requestLead.mobilePhone = '555-555-5555';
        requestLead.businessPhone = '555-555-1111';
        requestLead.businessName = 'Test Business';
        requestLead.streetAddress = '1 Test Street';
        requestLead.city = 'Suffern';
        requestLead.state = 'NY';
        requestLead.zipCode = '10901';
        requestLead.businessTitle = 'CEO';
        requestLead.partnerId = p1.Id;
        requestLead.salesRepId = sr1.Id;
        RestLead.RestPropertyAccount requestAccount = new RestLead.RestPropertyAccount();
        RestLead.RestUtilityAccountLog requestUAL1 = new RestLead.RestUtilityAccountLog();
        requestUAL1.serviceStreet = 'Test service street';
        requestUAL1.serviceCity = 'Test service city';
        requestUAL1.serviceState = 'NY';
        requestUAL1.servicePostalCode = '14472';
        requestUAL1.utilityAccountNumber = '555555';
        requestUAL1.rateClass = 'Rate Class 1';
        requestAccount.utilityAccountLogs = new List<RestLead.RestUtilityAccountLog>{requestUAL1};
        requestLead.propertyAccounts = new List<RestLead.RestPropertyAccount>{requestAccount};
        String leadJSON = '{ ' +
            '   "attributes": {' +
            '       "type": "Lead",' +
            '       "url": "/services/data/v48.0/sobjects/Lead/00Q000000000999"' +
            '   },' +
            '   "FirstName": "Unit",' +
            '   "LastName": "Testcase",' +
            '   "Email": "test@invalid.bluewavesolar.com",' +
            '   "MobilePhone": "555-555-5555",' +
            '   "Business_Phone__c": "555-555-1111",' +
            '   "Company": "Test Business",' +
            '   "LASERCA__Home_Address__c": "1 Test Street",' +
            '   "LASERCA__Home_City__c": "Suffern",' +
            '   "LASERCA__Home_State__c": "NY",' +
            '   "LASERCA__Home_Zip__c": "10901",' +
            '   "Business_Title__c": "CEO",' +
            '   "Partner_Lookup__c": "' + p1.Id + '",' +
            '   "bs_Sales_ID__c": "' + sr1.Id + '",' +
            '   "Id": "00Q000000000999",' +
            '   "Accounts__r": {' +
            '       "totalSize": 1,' +
            '       "done": true,' +
            '       "records": ' +
            '           [' +
            '               {' +
            '                   "attributes": {' +
            '                       "type": "Account",' +
            '                       "url": "/services/data/v48.0/sobjects/Account/001000000000999"' +
            '                   },' +
            '                   "Lead__c": "00Q000000000999",' +
            '                   "Id": "001000000000999"' +
            '               }' +
            '           ]' +
            '   },' +
            '   "Utility_Account_Logs__r": {' +
            '       "totalSize": 1,' +
            '       "done": true,' +
            '       "records": ' +
            '           [' +
            '               {' +
            '                   "attributes": {' +
            '                       "type": "Utility_Account_Log__c",' +
            '                       "url": "/services/data/v48.0/sobjects/Utility_Account_Log__c/a1b2C000000wv1JQAQ"' +
            '                   },' +
            '                   "Lead__c": "00Q000000000999",' +
            '                   "Id": "a1b000000000999",' +
            '                   "Account__c": "001000000000999",' +
            '                   "Name": "555555",' +
            '                   "Service_Address__c": "Test service street",' +
            '                   "Service_City__c": "Test service city",' +
            '                   "Service_State__c": "NY",' +
            '                   "Service_Zip_Code__c": "14472",' +
            '                   "Utility_Rate_Class__c": "' + rateClass.Id + '",' +
            '                   "Utility_Rate_Class__r": {' +
            '                       "attributes": {' +
            '                           "type": "Rate_Class__c",' +
            '                           "url": "/services/data/v48.0/sobjects/Rate_Class__c/' + rateClass.Id + '"' +
            '                       },' +
            '                       "Id": "' + rateClass.Id + '",' +
            '                       "Name": "' + rateClass.Name + '"' +
            '                   }' +
            '               }' +
            '           ]' +
            '   }' +
            '}';
        Lead l = (Lead)JSON.deserialize(leadJSON, Lead.class);
        CSLeadsRESTControllerV2 controller = new CSLeadsRESTControllerV2();
        System.assert(!controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'No field differences; method should return false');
        requestLead.firstName = 'Change';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to firstName field');
        requestLead.firstName = 'Unit';
        requestLead.lastName = 'Change';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to lastName field');
        requestLead.lastName = 'Testcase';
        requestLead.email = 'Change@invalid.bluewavesolar.com';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to email field');
        requestLead.email = 'test@invalid.bluewavesolar.com';
        requestLead.mobilePhone = '555-555-0000';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to mobilePhone field');
        requestLead.mobilePhone = '555-555-5555';
        requestLead.businessPhone = '555-555-0000';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to businessPhone field');
        requestLead.businessPhone = '555-555-1111';
        requestLead.businessName = 'Change Business';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to businessName field');
        requestLead.businessName = 'Test Business';
        requestLead.streetAddress = '1 Change Street';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to streetAddress field');
        requestLead.streetAddress = '1 Test Street';
        requestLead.city = 'Change';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to city field');
        requestLead.city = 'Suffern';
        requestLead.state = 'MA';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to state field');
        requestLead.state = 'NY';
        requestLead.zipCode = '00000';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to zipCode field');
        requestLead.zipCode = '10901';
        requestLead.businessTitle = 'CEO of Change';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to businessTitle field');
        requestLead.businessTitle = 'CEO';
        requestLead.partnerId = p0.Id;
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to partnerId field');
        requestLead.partnerId = null;
        System.assert(!controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return false, as Lead has default value set for partner ID');
        requestLead.salesRepId = sr0.Id;
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to salesRepId field');
        requestLead.salesRepId = null;
        System.assert(!controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return false, as Lead has default value set for sales rep ID');
        leadJSON = leadJSON.replace(p1.Id, p0.Id);
        l = (Lead)JSON.deserialize(leadJSON, Lead.class);
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true, as RestLead.partnerId is null but Lead.Partner_Lookup__c does not have default value set');
        requestLead.partnerId = p0.Id;
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true, as RestLead.salesRepId is null but Lead.bs_Sales_ID__c does not have default value set');
        leadJSON = leadJSON.replace(sr1.Id, sr0.Id);
        l = (Lead)JSON.deserialize(leadJSON, Lead.class);
        System.assert(!controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'No field differences; method should return false');
        requestLead.salesRepId = sr0.Id;
        System.assert(!controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'No field differences; method should return false');
        // test UAL fields
        requestLead.propertyAccounts[0].utilityAccountLogs[0].serviceStreet = 'Changed service street';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to serviceStreet field');
        requestLead.propertyAccounts[0].utilityAccountLogs[0].serviceStreet = 'Test service street';
        requestLead.propertyAccounts[0].utilityAccountLogs[0].serviceCity = 'Changed service city';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to serviceCity field');
        requestLead.propertyAccounts[0].utilityAccountLogs[0].serviceCity = 'Test service city';
        requestLead.propertyAccounts[0].utilityAccountLogs[0].serviceState = 'MA';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to serviceState field');
        requestLead.propertyAccounts[0].utilityAccountLogs[0].serviceState = 'NY';
        requestLead.propertyAccounts[0].utilityAccountLogs[0].servicePostalCode = '00000';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to servicePostalCode field');
        requestLead.propertyAccounts[0].utilityAccountLogs[0].servicePostalCode = '14472';
        requestLead.propertyAccounts[0].utilityAccountLogs[0].rateClass = 'Rate Class 2';
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to change to rateClass field');
        requestLead.propertyAccounts[0].utilityAccountLogs[0].rateClass = 'Rate Class 1';
        System.assert(!controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'No field differences; method should return false');
        RestLead.RestUtilityAccountLog requestUAL2 = new RestLead.RestUtilityAccountLog();
        requestUAL1.serviceStreet = 'Test service street';
        requestUAL1.serviceCity = 'Test service city';
        requestUAL1.serviceState = 'NY';
        requestUAL1.servicePostalCode = '14472';
        requestUAL1.utilityAccountNumber = '999999';
        requestAccount.utilityAccountLogs = new List<RestLead.RestUtilityAccountLog>{requestUAL1, requestUAL2};
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return true due to more UALs in RestLead than Lead');
        requestAccount.utilityAccountLogs = new List<RestLead.RestUtilityAccountLog>{requestUAL2};
        System.assert(controller.contractFieldsUpdated(JSON.serialize(requestLead), l), 'Method should return because RestLead UAL is different from Lead UAL');
    }

    /**************************
     *** patchContract() ***
     **************************/
    @IsTest
    static void testPatchContractInvalidLeadId() {
        useMocks();
        String jsonRequest = '{ "leadId": null }';
        controller.patchContract(jsonRequest);
        System.assertEquals(400, RestContext.response.statusCode, 'PATCH contract should throw an error when no lead id is provided');
        jsonRequest = '{ "leadId": "" }';
        controller.patchContract(jsonRequest);
        System.assertEquals(400, RestContext.response.statusCode, 'PATCH contract should throw an error when an invalid lead id is provided');
        jsonRequest = '{ "email": "' + SAMPLE_EMAIL + '" }';
        controller.patchContract(jsonRequest);
        System.assertEquals(400, RestContext.response.statusCode, 'PATCH contract should throw an error when no lead id is provided');
        jsonRequest = '{ "leadId": 12345 }';
        controller.patchContract(jsonRequest);
        System.assertEquals(400, RestContext.response.statusCode, 'PATCH contract should throw an error when an invalid lead id is provided');
    }

    @IsTest
    static void testPatchContractSuccess() {
        useMocks();
        String jsonRequest = '{ "leadId": "' + Util.getFakeId(Schema.Lead.SObjectType) + '", "signatureId": "' + Util.getFakeId(ContentVersion.SObjectType) + '" }';
        controller.patchContract(jsonRequest);
        System.assertEquals(200, RestContext.response.statusCode, 'PATCH contract should not throw an error when a valid lead id is provided');
    }

    @IsTest
    private static void testPatchContractWithAppCompleteActions() { // e.g. Powersetter 3rd party origination
        CSTestDataFactory dataset = new CSTestDataFactory();
        dataset.insertOpenUCBSystem();
        dataset.insertLeadViaAPI(true, 'None', false);
        dataset.insertContractFiles();
        JSONGenerator jsonGenerator = JSON.createGenerator(false);
        jsonGenerator.writeStartObject();
        jsonGenerator.writeStringField('leadId', dataset.leadId);
        jsonGenerator.writeStringField('signatureId', Util.getFakeId(ContentVersion.SObjectType));
        jsonGenerator.writeEndObject();
        Test.startTest();
        RestContext.response = new RestResponse();
        controller.patchContract(jsonGenerator.getAsString());
        Test.stopTest();
        Lead leadAfterPatch = [
            SELECT Application_Complete_Date__c, Status, Application_Status__c
            FROM Lead WHERE Id =: dataset.leadId LIMIT 1
        ];
        System.assertEquals(200, RestContext.response.statusCode, 'PATCH should return OK');
        System.assert(leadAfterPatch.Application_Complete_Date__c != null, 'Application Complete Date should be set');
        System.assertEquals('Qualified', leadAfterPatch.Status, 'CS Lead should have gone through automatic Qualify logic');
        System.assertEquals('Application Completed', leadAfterPatch.Application_Status__c,
            'Lead Application Status (internal) should be Application Completed');
    }

    @IsTest
    private static void testPatchContractWithSuppressAppCompleteActions() { // e.g. SSF origination
        CSTestDataFactory dataset = new CSTestDataFactory();
        dataset.insertLeadViaAPI(true, 'None', false);
        dataset.insertContractFiles();
        JSONGenerator jsonGenerator = JSON.createGenerator(false);
        jsonGenerator.writeStartObject();
        jsonGenerator.writeStringField('leadId', dataset.leadId);
        jsonGenerator.writeStringField('signatureId', Util.getFakeId(ContentVersion.SObjectType));
        jsonGenerator.writeBooleanField('suppressAppComplete', true);
        jsonGenerator.writeEndObject();
        Test.startTest();
        RestContext.response = new RestResponse();
        controller.patchContract(jsonGenerator.getAsString());
        Test.stopTest();
        Lead leadAfterPatch = [
            SELECT Application_Complete_Date__c, Status, Application_Status__c
            FROM Lead WHERE Id =: dataset.leadId LIMIT 1
        ];
        System.assertEquals(200, RestContext.response.statusCode, 'PATCH should return OK');
        System.assert(leadAfterPatch.Application_Complete_Date__c == null, 'Application Complete Date should NOT be set');
        System.assertEquals('Sales Qualified', leadAfterPatch.Status, 'Qualify logic should not have run yet for SSF lead');
        System.assertNotEquals('Application Completed', leadAfterPatch.Application_Status__c,
            'Lead Application Status (internal) should not be Complete');
    }

    /********************
     *** SYSTEM TESTS ***
     ********************/
    @IsTest
    private static void testPostLeadSuccessSystem() {
        //Insert website lead to test duplicate
        Lead websiteLead = new Lead(
            FirstName = 'System',
            LastName = 'Testcase',
            Email = 'test@invalid.bluewavesolar.com',
            Company = 'System Testcase',
            LeadSource = 'Website',
            Phone = '4444444444',
            CreatedDate = System.today().addMonths(-3)
        );
        insert websiteLead;
        ContentVersion cvUtilBill = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('utility bill'),
            Title = 'UtilityBill.pdf',
            PathOnClient = '/UtilityBill.pdf',
            File_Category__c = 'Customer Utility Bill'
        );
        ContentVersion cvFinDoc = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('financial document'),
            Title = 'FinancialDocument.pdf',
            PathOnClient = '/FinancialDocument.pdf',
            File_Category__c = 'Financial Review Documents'
        );
        insert new List<ContentVersion>{cvUtilBill, cvFinDoc};
        ContentDocumentSelector cds = new ContentDocumentSelector();
        Id contentDocIdUtil = cds.getDocumentIdFromVersionId(cvUtilBill.Id);
        Id contentDocIdFin = cds.getDocumentIdFromVersionId(cvFinDoc.Id);
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocIdUtil,
            ShareType = 'V',
            Visibility = 'AllUsers',
            LinkedEntityId = websiteLead.Id
        );
        insert cdl;
        String financialDocs = '"financialDocs": [{ "id": "' + contentDocIdFin + '" }]';
        String utilityBills = '"utilityBills": [{ "id": "' + contentDocIdUtil + '", "docLinkId": "' + cdl.Id + '", "title": "UtilityBill2.pdf", "body": "dXRpbGl0eSBiaWxscyAjMg==", "fileCategory": "Customer Utility Bill" }]';
        String jsonRequest = getPostLeadJson(financialDocs, utilityBills);
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        RESTRouterV2.postRequest();
        RestResponse response = RestContext.response;
        Map<String, Object> requestLead = (Map<String,Object>) JSON.deserializeUntyped(jsonRequest);
        List<Object> requestPropertyAccounts = (List<Object>) requestLead.get('propertyAccounts');
        Map<String, Object> requestPropertyAccount = (Map<String,Object>) requestPropertyAccounts[0];
        List<Object> requestUtilityAccountLogs = (List<Object>) requestPropertyAccount.get('utilityAccountLogs');
        Map<String, Object> requestUtilityAccountLog = (Map<String,Object>) requestUtilityAccountLogs[0];
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseLead = (Map<String,Object>) responseEnvelope.get('data');
        System.assertEquals(201, response.statusCode, 'POST should create properly');
        System.assertEquals(1, [SELECT Id FROM Contract WHERE Lead__c = :(Id)responseLead.get('id')].size(), 'A contract should be created for this lead, as it has both a product and a property account');
        // verify lead request/response fields
        System.assertNotEquals(responseLead.get('id'), null, 'id should be set on POST response');
        System.assertEquals(websiteLead.Id, responseLead.get('id'), 'returned id should match that of the website lead');
        for (String key : requestLead.keySet()) {
            if (requestLead.get(key) instanceof String) {
                System.assertEquals(requestLead.get(key), responseLead.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }
        // verify propertyAccount request/response fields
        List<Object> responsePropertyAccounts = (List<Object>) responseLead.get('propertyAccounts');
        Map<String, Object> responsePropertyAccount = (Map<String,Object>) responsePropertyAccounts[0];
        System.assertEquals(requestLead.get('firstName') + ' ' + requestLead.get('lastName'), responsePropertyAccount.get('name'), 'For resi customers, the name on the prop account should be their first & last name');
        for (String key : requestPropertyAccount.keySet()) {
            if (requestPropertyAccount.get(key) instanceof String) {
                System.assertEquals(requestPropertyAccount.get(key), responsePropertyAccount.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }
        // verify UALs request/response fields
        List<Object> responseUtilityAccountLogs = (List<Object>) responsePropertyAccount.get('utilityAccountLogs');
        Map<String, Object> responseUtilityAccountLog = (Map<String,Object>) responseUtilityAccountLogs[0];
        for (String key : requestUtilityAccountLog.keySet()) {
            if (requestUtilityAccountLog.get(key) instanceof String) {
                System.assertEquals(requestUtilityAccountLog.get(key), responseUtilityAccountLog.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }
    }

    @IsTest
    private static void testPostLeadDocSuccessSystem() {
        ContentVersion cvUtilBill = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('utility bill'),
            Title = 'UtilityBill.pdf',
            PathOnClient = '/UtilityBill.pdf'
        );
        insert cvUtilBill;
        ContentDocumentSelector cds = new ContentDocumentSelector();
        Id contentDocIdUtil = cds.getDocumentIdFromVersionId(cvUtilBill.Id);
        String financialDocs = '"financialDocs": [{ "title": "FinancialDocument.pdf", "body": "ZmluYW5jaWFsIGRvY3M=", "fileCategory": "Financial Review Documents" }]';
        String utilityBills = '"utilityBills": [{ "id": "' + contentDocIdUtil + '" }]';
        String jsonRequest = getPostLeadJson(financialDocs, utilityBills);
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        RESTRouterV2.postRequest();
        System.debug(LoggingLevel.ERROR, 'error logs: ' + [SELECT Id, Class__c, Method__c, Message__c FROM Error_Log__c]);
        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseLead = (Map<String,Object>) responseEnvelope.get('data');
        System.assertEquals(201, response.statusCode, 'POST should create properly');
        List<Object> responsePropertyAccounts = (List<Object>) responseLead.get('propertyAccounts');
        Map<String, Object> responsePropertyAccount = (Map<String,Object>) responsePropertyAccounts[0];
        List<Object> responseUtilityAccountLogs = (List<Object>) responsePropertyAccount.get('utilityAccountLogs');
        Map<String, Object> responseUtilityAccountLog = (Map<String,Object>) responseUtilityAccountLogs[0];
        // verify utilityBill response fields
        List<Object> responseUtilityBills = (List<Object>) responseUtilityAccountLog.get('utilityBills');
        Map<String, Object> responseUtilityBill = (Map<String, Object>) responseUtilityBills[0];
        System.assertEquals(contentDocIdUtil, responseUtilityBill.get('id'), 'The request should have returned a valid content document ID for utility bill');
        System.assertEquals(responseUtilityAccountLog.get('id'), responseUtilityBill.get('parentId'), 'The request should have returned a valid utility account log ID as the parent of this utility bill');
        System.assertEquals(cvUtilBill.Id, responseUtilityBill.get('lastPublishedVersionId'), 'The request should have returned a valid content version ID for utility bill');
        System.assertEquals('UtilityBill.pdf', responseUtilityBill.get('title'), 'The request should have returned a valid content version ID for utility bill');
        System.assertNotEquals(null, responseUtilityBill.get('docLinkId'), 'The request should have returned a valid content document link ID for utility bill');
        System.assertEquals(null, responseUtilityBill.get('body'), 'The request should NOT have returned a valid body for utility bill because we never use it');
        System.assertNotEquals(null, responseUtilityBill.get('size'), 'The request should have returned a valid size for utility bill');
        System.assertNotEquals(null, responseUtilityBill.get('createdDate'), 'The request should have returned a valid created date for utility bill');
        // verify financialDocs response fields
        List<Object> responseFinancialDocs = (List<Object>) responseLead.get('financialDocs');
        Map<String, Object> responseFinancialDoc = (Map<String, Object>) responseFinancialDocs[0];
        System.assertNotEquals(null, responseFinancialDoc.get('id'), 'The request should have returned a valid content document ID for financial document');
        System.assertEquals([SELECT Id FROM Financial_Underwriting_Document__c LIMIT 1].Id, responseFinancialDoc.get('parentId'), 'The request should have returned a valid financial underwriting document ID as the parent of this financial document');
        System.assertNotEquals(null, responseFinancialDoc.get('lastPublishedVersionId'), 'The request should have returned a valid content version ID for financial document');
        System.assertEquals('FinancialDocument.pdf', responseFinancialDoc.get('title'), 'The request should have returned the input title for financial document');
        System.assertNotEquals(null, responseFinancialDoc.get('docLinkId'), 'The request should have returned a valid content document link ID for financial document');
        System.assertEquals(null, responseFinancialDoc.get('body'), 'The request should not have returned a valid body for financial document because we never use it');
        System.assertNotEquals(null, responseFinancialDoc.get('size'), 'The request should have returned a valid size for financial document');
        System.assertNotEquals(null, responseFinancialDoc.get('createdDate'), 'The request should have returned a valid created date for financial document');
    }

    private static String getPostLeadJson(String financialDocs, String utilityBills) {
        String json = '{' +
            '"firstName": "System",' +
            '"lastName": "Testcase",' +
            '"email": "test@invalid.bluewavesolar.com",' +
            '"mobilePhone": "555-555-5555",' +
            '"applicationType": "Residential",' +
            '"streetAddress": "1 Test Street",' +
            '"city": "Suffern",' +
            '"state": "NY",' +
            '"zipCode": "10901",' +
            '"eiaId": "1234",' +
            '"productName": "CS Product",' +
            '"campaignId": "0005500000",' +
            '"noPayment": false,' +
            '"replacementCapacity": false,';
        if (financialDocs != null) {
            json += financialDocs + ',';
        }
        json += '"propertyAccounts": [{' +
            '   "billingStreet": "Test billing street",' +
            '   "billingCity": "Test billing city",' +
            '   "billingState": "NY",' +
            '   "billingPostalCode": "14472",' +
            '   "utilityAccountLogs": [{' +
            '       "nameOnAccount": "Test Accounts Payable",' +
            '       "serviceStreet": "Test service street",' +
            '       "serviceCity": "Test service city",' +
            '       "serviceState": "NY",' +
            '       "servicePostalCode": "14472",' +
            '       "utilityAccountNumber": "555555"';
        if (utilityBills != null) {
            json += ',' + utilityBills;
        }
        json += '   }]' +
            '}]}';
        return json;
    }

    @IsTest
    static void testApplicationStatus() {
        // Initial POST /lead, without utility bill data
        String jsonRequest = '{' +
            '"firstName": "Unit",' +
            '"lastName": "Testcase",' +
            '"email": "test@invalid.bluewavesolar.com",' +
            '"mobilePhone": "555-555-5555",' +
            '"applicationType": "Residential",' +
            '"streetAddress": "1 Test Street",' +
            '"city": "Suffern",' +
            '"state": "NY",' +
            '"zipCode": "10901",' +
            '"eiaId": "1234",' +
            '"continueApplicationLink": "http://switch.bluewavesolar.invalid",' +
            '"productName": "CS Product",' +
            '"campaignId": "0005500000",' +
            '"noPayment": false,' +
            '"replacementCapacity": false,' +
            '"propertyAccounts": [{' +
            '   "billingStreet": "Test billing street",' +
            '   "billingCity": "Test billing city",' +
            '   "billingState": "NY",' +
            '   "billingPostalCode": "14472",' +
            '   "utilityAccountLogs": [{' +
            '       "nameOnAccount": "Test Accounts Payable",' +
            '       "serviceStreet": "Test service street",' +
            '       "serviceCity": "Test service city",' +
            '       "serviceState": "NY",' +
            '       "servicePostalCode": "14472",' +
            '       "utilityAccountNumber": "555555"' +
            '   }]' +
            '}]' +
            '}';
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        RESTRouterV2.postRequest();
        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseLead = (Map<String,Object>) responseEnvelope.get('data');
        Id leadId = (Id) responseLead.get('id');
        Lead lead = [SELECT Id, Application_Status__c, Continue_Application_Link__c,
        (SELECT Id FROM Utility_Account_Logs__r),
        (SELECT Id FROM Accounts__r)
        FROM Lead WHERE Id = :leadId];
        System.assertEquals(201, response.statusCode, 'POST should create properly');
        System.assertEquals('Started', lead.Application_Status__c, 'Application status should be Started');
        PageReference url = new PageReference(lead.Continue_Application_Link__c);
        System.assertEquals('info', url.getParameters().get('loc'), 'Continue Application Link loc param should be info');

        Id utilityAccountLogId = lead.Utility_Account_Logs__r[0].Id;
        ContentVersion contentVersion = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('utility bill'),
            Title = 'UtilityBill.pdf',
            PathOnClient = '/UtilityBill.pdf',
            File_Category__c = 'Customer Utility Bill'
        );
        insert contentVersion;
        ContentDocumentSelector cds = new ContentDocumentSelector();
        Id contentDocId = cds.getDocumentIdFromVersionId(contentVersion.Id);

        // PATCH /application with utility bill file
        // NOTE: this is not how SSF handles this as of 6/30/21...
        // All utility bill data (if needed) is submitted in the initial POST /lead, this is legacy fragment from jlugo
        jsonRequest = '{' +
            '   "id": "' + leadId + '",' +
            '   "email": "test@invalid.bluewavesolar.com",' +
            '   "propertyAccounts": [{' +
            '      "id": "' + lead.Accounts__r[0].Id + '",' +
            '      "utilityAccountLogs": [{' +
            '          "id": "' + utilityAccountLogId + '",' +
            '          "utilityBills": [{' +
            '              "id": "' + contentDocId + '",' +
            '              "lastPublishedVersionId": "' + contentVersion.Id + '"' +
            '          }]' +
            '      }]' +
            '   }]' +
            '}';
        controller.patchApplication(jsonRequest);
        lead = [SELECT Id, Application_Status__c, Continue_Application_Link__c FROM Lead WHERE Id = :leadId];
        System.assertEquals(200, RestContext.response.statusCode, 'An Application PATCH with required fields should succeed');
        System.assertEquals('Customer Info Completed', lead.Application_Status__c,
            'All data present, but contracts not signed yet; application status should be Customer Info Completed');
        url = new PageReference(lead.Continue_Application_Link__c);
        System.assertEquals('agree', url.getParameters().get('loc'), 'Continue link loc param should be agree');

        // PATCH /contract - contract signature
        jsonRequest = '{' +
            '   "leadId": "' + leadId + '",' +
            '   "email": "test@invalid.bluewavesolar.com"' +
            '}';
        controller.patchContract(jsonRequest);
        lead = [SELECT Id, Application_Status__c, Continue_Application_Link__c FROM Lead WHERE Id = :leadId];
        System.assertEquals(200, RestContext.response.statusCode, 'A Contract PATCH with required fields should succeed');
        System.assertEquals('Contracts Signed', lead.Application_Status__c,
            'All customer info is present and all contracts are signed; application status should be Contracts Signed');
        url = new PageReference(lead.Continue_Application_Link__c);
        System.assertEquals('pay', url.getParameters().get('loc'),
            'Because Application Status is Contracts Signed, Continue Application Link loc param should be pay');

        // PATCH /lead - application completion
        jsonRequest = '{' +
            '   "id": "' + leadId + '",' +
            '   "email": "test@invalid.bluewavesolar.com",' +
            '   "applicationCompleteDate": "2020-07-22T00:00:00Z"' +
            '}';
        controller.patchLead(jsonRequest);
        lead = [SELECT Id, Application_Status__c, Continue_Application_Link__c FROM Lead WHERE Id = :leadId];
        System.assertEquals(200, RestContext.response.statusCode, 'A Lead PATCH with required fields should succeed');
        System.assertEquals('Application Completed', lead.Application_Status__c, 'Status should be Application Completed');
        url = new PageReference(lead.Continue_Application_Link__c);
        System.assertEquals('complete', url.getParameters().get('loc'), 'Continue Application Link loc param should be complete');
    }

    @IsTest
    private static void testPartnerEmailSendApplicationComplete() {
        Account partnerAccount = new Account(
            Name = 'Partner Account'
        );
        insert partnerAccount;
        Lead leadToUpdate = new Lead (
            FirstName = 'Other',
            LastName = 'Testcase',
            Email = 'test@invalid.bluewavesolar.com',
            Company = 'System Testcase',
            LeadSource = 'Switch',
            Partner_Account__c = partnerAccount.Id,
            Partner_Email__c = 'partner@testcase.com'
        );
        insert leadToUpdate;

        CSApplicationFinisher appFinisher = new CSApplicationFinisher(leadToUpdate.Id, null);
        CSApplicationFinisher.featureSelector = (FeatureSelector) Test.createStub(FeatureSelector.class, new MockFeatureSelector());

        MessagingService.emailTemplateMap = new Map<String, EmailTemplate>();
        sfab_FabricatedSObject fabbedEmailTemplate = new sfab_FabricatedSObject(EmailTemplate.class);
        fabbedEmailTemplate.setField(EmailTemplate.HtmlValue, '{{{Recipient.Name}}}');
        MessagingService.emailTemplateMap.put('MockTemplate', (EmailTemplate) fabbedEmailTemplate.toSObject());

        Test.startTest();
        LeadSelector leadSelector = new LeadSelector();
        leadToUpdate = leadSelector.selectOne(leadToUpdate.Id);
        appFinisher.createAndSendCSPartnerEmail(leadToUpdate);
        Test.stopTest();

        System.assertEquals(1, MessagingService.emailsSent.size(), 'Application Complete email should be sent to Partner');
        Messaging.SingleEmailMessage sentEmail = (Messaging.SingleEmailMessage) MessagingService.emailsSent[0];
        System.assert(!sentEmail.htmlBody.contains('{{{Recipient.Name}}}'),
            'Merge fields should be merged, but got: ' + sentEmail.htmlBody);
        System.assert(sentEmail.htmlBody.contains('Other Testcase'),
            'The Lead Name should have gotten merge in, but got: ' + sentEmail.htmlBody);
    }

    @IsTest
    private static void testCreateQCCaseForNoMatch() {
        Lead leadToUpdate = new Lead (
            FirstName = 'Other',
            LastName = 'Testcase',
            Email = 'test@invalid.bluewavesolar.com',
            Company = 'System Testcase',
            LeadSource = 'Switch',
            Partner_Email__c = 'partner@testcase.com',
            Underwriting_Criteria__c = 'FICO'
        );
        insert leadToUpdate;
        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = leadToUpdate.Id,
            LASERCA__Credit_Score__c = null
        );
        insert pcr;
        leadToUpdate.Personal_Credit_Report__c = pcr.Id;
        update leadToUpdate;
        leadToUpdate = new LeadSelector().selectOne(leadToUpdate.Id);

        Test.startTest();
        CSApplicationFinisher appFinisher = new CSApplicationFinisher(leadToUpdate.Id, null);
        appFinisher.createQCCaseForNoMatchPCR(leadToUpdate);
        Test.stopTest();

        List<Case> qcCase = [
            SELECT Id, QC_Case_Subject__c, Category__c
            FROM Case
            WHERE Category__c = 'QC'
        ];
        System.assertEquals(1, qcCase.size(), 'QC Case is created for completed applications that still have a No Match PCR');
        System.assertEquals('No Credit Match - Provide Additional Background on Guarantor (New Address or DOB)', qcCase[0].QC_Case_Subject__c, 'No FICO Match QC case should be created');
    }

    @IsTest
    private static void testContractFilesCompilation() {
        // Mock data
        CSTestDataFactory dataSet = new CSTestDataFactory();
        dataSet.insertLeadViaAPI(false, 'None', false);
        Lead generatedLead = new LeadSelector().selectOneWithPropertiesAndUtilities(dataSet.leadId);
        dataSet.insertContractFiles();

        // Start test
        Test.startTest();

        // Run standard scenario with 2 contract files
        controller.setResponseLeadContentDocs(generatedLead, dataSet.restLead, false);
        System.assertEquals(2, dataSet.restLead.contentDocs.size(),'TEST A: Incorrect number of contract files');

        // Set rate class to suppress disclosure form, then re-run => 1 contract file should exist in response
        dataSet.setRateClassToSuppressDisclosureForm();
        controller.setResponseLeadContentDocs(generatedLead, dataSet.restLead, false);
        System.assertEquals(1, dataSet.restLead.contentDocs.size(),'TEST B: Incorrect number of contract files');

        // Set Product Disclosure_Form_Conga_Template__c field to null => 1 contract file should exist on response
        // OTHER NOTE: All Products must have the Project_Specific_Conga_Template__c field entered
        dataSet.resetRateClass();
        dataSet.setProductDisclosureTemplateToNull();
        Lead leadWithModifiedProduct = new LeadSelector().selectOneWithPropertiesAndUtilities(dataSet.leadId);
        controller.setResponseLeadContentDocs(leadWithModifiedProduct, dataSet.restLead, false);
        System.assertEquals(1, dataSet.restLead.contentDocs.size(),'TEST C: Incorrect number of contract files');

        Test.stopTest();
    }

    @IsTest
    private static void testContractFilesCompilationWithNoRateClass() {
        // Mock data
        CSTestDataFactory dataSet = new CSTestDataFactory();
        dataSet.insertLeadViaAPI(true, 'None', false);
        Lead generatedLead = new LeadSelector().selectOneWithPropertiesAndUtilities(dataSet.leadId);
        dataSet.insertContractFiles();

        // Start test
        Test.startTest();

        controller.setResponseLeadContentDocs(generatedLead, dataSet.restLead, false);
        System.assertEquals(2, dataSet.restLead.contentDocs.size(),'Incorrect number of contract files');

        Test.stopTest();
    }

    @IsTest
    private static void testAppFinisherNoLeadFound() {
        Lead lead = new Lead(
            Id = Util.getFakeId(Lead.SObjectType),
            Email = SAMPLE_EMAIL
        );
        CSApplicationFinisher appFinisher = new CSApplicationFinisher(lead.Id, null);
        appFinisher.execute(null);
        List<Error_Log__c> errorLogs = [SELECT Id, Message__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size(), 'Lead does not exist, app finisher should fail and log error');
        System.assert(errorLogs[0].Message__c.contains('Unable to locate lead'), 'Error should indicate unable to locate lead');
    }

    @IsTest
    private static void testAppFinisherLeadError() {
        CSTestDataFactory dataFactory = new CSTestDataFactory();
        dataFactory.insertLeadViaAPI(false, 'None', false);
        Lead lead = [SELECT Id FROM Lead];

        CSApplicationFinisher appFinisher = new CSApplicationFinisher(lead.Id, null);
        CSApplicationFinisher.triggerErrorInTest = true;
        appFinisher.execute(null);

        List<Error_Log__c> errorLogs = [SELECT Id, Message__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size(), 'Error was intentionally tripped in test, should have logged error');
        System.assert(errorLogs[0].Message__c.contains('Test error encountered'), 'Error should include test error message');
    }

    /*************
     *** MOCKS ***
     *************/
    public class MockLeadService extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'updateLead' {
                    return new Lead(Company = 'test');
                }
                when 'insertLead' {
                    return new Lead(Id = Util.getFakeId(Schema.Lead.SObjectType), Company = 'test');
                }
            }
            return null;
        }
        public Lead getLastUpdatedLead() {
            List<MethodCall> updateCalls = getMethodCallsByName('updateLead');
            return (Lead) updateCalls.get(updateCalls.size() - 1).listOfArgs.get(0);
        }
    }

    public class MockLeadSelector implements StubProvider {
        private Lead leadToReturn;
        public MockLeadSelector(Lead leadToReturn) {
            this.leadToReturn = leadToReturn;
        }
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            return leadToReturn;
        }
    }

    public class MockAccountService implements StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'updateAccount' {
                    return new Account();
                }
                when 'insertAccount' {
                    return new Account(Id = Util.getFakeId(Schema.Account.SObjectType), Lead__c = Util.getFakeId(Schema.Lead.SObjectType));
                }
            }
            return null;
        }
    }

    public class MockAccountsSelector implements StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'selectOne' {
                    Account newAccount = new Account();
                    switch on String.valueOf(listOfArgs.get(0)).substring(0,15) {
                        when '001000000000111' {
                            return null;
                        } when '001000000000888' {
                            newAccount.Id = '001000000000888';
                            newAccount.Lead__c = Util.getFakeId(Schema.Lead.SObjectType);
                        }
                    }
                    return newAccount;
                }
                when 'selectPropertyAccountsByLeadIds' {
                    Set<Id> leadIds = (Set<Id>) listOfArgs.get(0);
                    if (leadIds.contains('00Q000000000999')) {
                        return new List<Account>{new Account()};
                    }
                }
                when 'selectPropertyAccountsByLeadIdsMap' {
                    return new Map<Id, Account>{'001000000000999' => new Account(Id = '001000000000999')};
                }
            }
            return null;
        }
    }

    public class MockUALService implements StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'updateUAL' {
                    return new Utility_Account_Log__c();
                }
                when 'insertUAL' {
                    return new Utility_Account_Log__c(Id = Util.getFakeId(Schema.Utility_Account_Log__c.SObjectType));
                }
                when 'insertUALs' {
                    return new List<Utility_Account_Log__c>{new Utility_Account_Log__c(Id = Util.getFakeId(Schema.Utility_Account_Log__c.SObjectType))};
                }
            }
            return null;
        }
    }

    public class MockUALSelector implements StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            if (String.valueOf(listOfArgs.get(0)).substring(0,15) == 'a1b000000000111') {
                return null;
            }
            switch on stubbedMethodName {
                when 'selectOne' {
                    return new Utility_Account_Log__c();
                }
                when 'selectAll' {
                    return new List<Utility_Account_Log__c>{new Utility_Account_Log__c()};
                }
                when 'selectAllMap'{
                    return new Map<Id, Utility_Account_Log__c>{Util.getFakeId(Schema.Utility_Account_Log__c.SObjectType) => new Utility_Account_Log__c()};
                }
                when 'selectAllByLeadMap' {
                    return new Map<Id, Utility_Account_Log__c>{'a1b000000000999' => new Utility_Account_Log__c(Id='a1b000000000999')};
                }
            }
            return new Utility_Account_Log__c();
        }
    }

    public class MockCustomerContractService extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'createContractFromLead' {
                    return new Contract();
                }
                when 'signCustomerContracts' {
                    return true;
                }
            }
            return null;
        }
    }

    public class MockCapacityService implements StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            String zipResponseWithCapacity = '{"zipcode":"02633","utilityIds":["a1MS0000008BldpMAC"],"utilities":[{"attributes":{"type":"Utility__c","url":"/services/data/v47.0/sobjects/Utility__c/a1MS0000008BldpMAC"},"Id":"a1MS0000008BldpMAC","Name":"Eversource"}],"sharedSolarSystems":[{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvGMAW"},"Id":"a1JS0000003BMvGMAW","Name":"Project A Oak Road","Capacity_Available_to_be_Reserved__c":144499.98,"Product__c":"01tS0000005j7AVIAY","Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AVIAY"},"Id":"01tS0000005j7AVIAY","Name":"BlueWave SMART","Customer_Subscription_Type__c":"kWh"}},{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvHMAW"},"Id":"a1JS0000003BMvHMAW","Name":"Project B Main St","Capacity_Available_to_be_Reserved__c":1445.86,"Product__c":"01tS0000005j7AVIAY","Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AVIAY"},"Id":"01tS0000005j7AVIAY","Name":"BlueWave SMART","Customer_Subscription_Type__c":"kWh"}},{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvIMAW"},"Id":"a1JS0000003BMvIMAW","Name":"Project C Second St","Capacity_Available_to_be_Reserved__c":1445.86,"Product__c":"01tS0000005j7AWIAY","Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AWIAY"},"Id":"01tS0000005j7AWIAY","Name":"BlueWave SREC","Customer_Subscription_Type__c":"Electricity Cost ($)"}}],"products":[{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AVIAY"},"Id":"01tS0000005j7AVIAY","Name":"BlueWave SMART","Customer_Subscription_Type__c":"kWh"},{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AWIAY"},"Id":"01tS0000005j7AWIAY","Name":"BlueWave SREC","Customer_Subscription_Type__c":"Electricity Cost ($)"}],"loadZones":[{"attributes":{"type":"Load_U__c","url":"/services/data/v47.0/sobjects/Load_U__c/a0ZS0000007rJ3mMAE"},"Id":"a0ZS0000007rJ3mMAE","LZ__c":"SEMA","Town__c":"Medfield","Name":"02633"}],"loadZoneNames":["SEMA"]}';
            CapacityService.ZipcodeResponse response =
                (CapacityService.ZipcodeResponse) JSON.deserialize(zipResponseWithCapacity, CapacityService.ZipcodeResponse.class);
            return response;
        }
    }

    public class MockContentDocumentSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectByLinkedEntities' {
                    ContentVersion content = new ContentVersion(
                        Title = 'Test',
                        PathOnClient = 'Community Solar Agreement (Review).csv',
                        VersionData = Blob.valueOf('Test'),
                        IsMajorVersion = true
                    );
                    insert content;
                    ContentDocumentLink cdl = new ContentDocumentLink(
                        LinkedEntityId = [SELECT Id FROM Utility__c LIMIT 1].Id,
                        ContentDocumentId = [SELECT Id FROM ContentDocument LIMIT 1].Id,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    );
                    insert cdl;
                    List<ContentDocumentLink> mockResult = [
                        SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.ContentSize,ContentDocument.CreatedDate,
                            ContentDocument.LatestPublishedVersion.Id, ContentDocument.LatestPublishedVersion.Title,
                            ContentDocument.LatestPublishedVersion.VersionData,ContentDocument.LatestPublishedVersion.FileExtension
                        FROM ContentDocumentLink WHERE Id =: cdl.Id
                    ];
                    return mockResult;
                }
                when 'getPublicDistributionLinkByDocId' {
                    return 'a1MS0000008BldpMAC';
                }
                when 'selectByLinkedEntitiesWithoutData' {
                    String contentDocumentLink = '{' +
                        '"ContentDocumentId": "a1MS0000008BldpMAC",' +
                        '"LinkedEntityId": "a1MS0000008BldpMAC"' +
                        '}';
                    ContentDocumentLink cdlInstance = (ContentDocumentLink) JSON.deserialize(contentDocumentLink, ContentDocumentLink.class);
                    return new List<ContentDocumentLink>{cdlInstance};
                }
            }
            return null;
        }
    }

    public class MockDuplicateService extends MockProvider {
        private Boolean hasDuplicates;
        public MockDuplicateService(Boolean hasDuplicates) {
            this.hasDuplicates = hasDuplicates;
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            //If there are duplicates, will return a lead with an Id that has been merged with api Lead
            String duplicateLead = '{"attributes":{"type":"Lead","url":"/services/data/v47.0/sobjects/Lead/001000000000111EEA"},' +
                '"Id": "001000000000111EEA",' +
                '"FirstName": "Unit",' +
                '"LastName": "Testcase",' +
                '"Email": "test@invalid.bluewavesolar.com",' +
                '"LeadSource": "Switch"' +
                '}';
            String jsonLead = '{"attributes":{"type":"Lead","url":"/services/data/v47.0/sobjects/Lead/001000000000111EEA"},' +
                '"FirstName": "Unit",' +
                '"LastName": "Testcase",' +
                '"Email": "test@invalid.bluewavesolar.com",' +
                '"LeadSource": "Switch"' +
                '}';
            if (hasDuplicates) {
                return (Lead) JSON.deserialize(duplicateLead, Lead.class);
            } else {
                return (Lead) JSON.deserialize(jsonLead, Lead.class);
            }
        }
    }

    public class MockUOW extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            return null;
        }
    }

    public class MockQualificationService implements StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs)
        {
            if (stubbedMethodName == 'qualifyLead') {
                Lead lead = (Lead) listOfArgs[0];
                lead.Status = 'Qualified';
            }
            return null;
        }
    }

    public class MockFeatureSelector implements StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs)
        {
            if (stubbedMethodName == 'getSystemDefaults') {
                sfab_FabricatedSObject fabbedSystemDefault = new sfab_FabricatedSObject(System_Default__mdt.class);
                fabbedSystemDefault.setField(System_Default__mdt.Application_Complete_Email_Template__c, 'MockTemplate');
                return fabbedSystemDefault.toSObject();
            }
            return null;
        }
    }
}