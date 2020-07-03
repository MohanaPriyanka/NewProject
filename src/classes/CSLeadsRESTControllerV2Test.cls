/**
 * Created by jlugo on 2019-07-09.
 */

@IsTest
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class CSLeadsRESTControllerV2Test {

    private static CSLeadsRESTControllerV2 controller = new CSLeadsRESTControllerV2();
    private static MockLeadService mockLeadService;

    public static void useMocks () {
        mockLeadService = new MockLeadService();
        controller.leadService = (LeadService) Test.createStub(LeadService.class, mockLeadService);
        controller.accountService = (AccountService) Test.createStub(AccountService.class, new MockAccountService());
        controller.ualService = (UALService) Test.createStub(UALService.class, new MockUALService());
        controller.customerContractService = (CustomerContractService) Test.createStub(CustomerContractService.class, new MockCustomerContractService());
        controller.capacityService = (CapacityService) Test.createStub(CapacityService.class, new MockCapacityService());
        controller.duplicateService = (CSLeadsDuplicateService) Test.createStub(CSLeadsDuplicateService.class , new MockDuplicateService(false));
        controller.uow = (fflib_SObjectUnitOfWork) Test.createStub(fflib_SObjectUnitOfWork.class, new MockUOW());

        controller.leadSelector = (LeadSelector) Test.createStub(LeadSelector.class, new MockLeadSelector());
        controller.accountsSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new MockAccountsSelector());
        controller.ualSelector = (UALSelector) Test.createStub(UALSelector.class, new MockUALSelector());

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
            EIA_ID__c = '1234'
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
        controller.getLead('00Q000000000888', SAMPLE_EMAIL);
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
        useMocks();
        controller.getLead('00Q000000000777', SAMPLE_EMAIL);
        System.assertEquals(400, RestContext.response.statusCode, 'Method should return error when lead has multiple property accounts');
    }


    /*******************
     *** patchLead() ***
     *******************/

    @IsTest
    private static void testPatchLeadSuccess() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '", "applicationCompleteDate": "2019-01-01T01:00" }';
        controller.patchLead(jsonRequest);

        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
        System.assertEquals(true, mockLeadService.getLastUpdatedLead().Soft_Pull_Credit_Report__c, 'Soft credit pull should be done when the application is complete');
    }

    @IsTest
    private static void testPatchLeadStreetAddress() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '", "streetAddress": "123 Patched Street" }';
        controller.patchLead(jsonRequest);

        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
        System.assertEquals('123 Patched Street', mockLeadService.getLastUpdatedLead().Street, 'Street should be updated when streetAddress is PATCHed.');
        System.assertEquals('123 Patched Street', mockLeadService.getLastUpdatedLead().LASERCA__Home_Address__c, 'LASERCA Home Address should be updated when streetAddress is PATCHed.');
        System.assertEquals(false, mockLeadService.getLastUpdatedLead().Soft_Pull_Credit_Report__c, 'Soft credit pull should only be updated if the field being updated is app compl date');
    }

    @IsTest
    private static void testPatchLeadCreditPullOnce() {
        useMocks();
        // ID of ...999 is an ID with an existing app date of Jan 1 2017 in the mock svc
        String jsonRequest = '{ "id": "00Q000000000999", "applicationCompleteDate": "2019-11-18T01:00" }';
        controller.patchLead(jsonRequest);

        // when patching a lead that already has an application complete date, don't try to pull credit again
        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
        System.assertEquals(false, mockLeadService.getLastUpdatedLead().Soft_Pull_Credit_Report__c, 'Soft credit pull should not be done if the app complete date has been previously set');
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
        useMocks();
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


    /********************************
     *** patchUtilityAccountLog() ***
     ********************************/

    @IsTest
    private static void testPatchUtilityAccountLogSuccess() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Account.SObjectType) + '", "annualKWh": 500 }';
        controller.patchUtilityAccountLog(jsonRequest);

        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
    }

    @IsTest
    private static void testPatchUtilityAccountLogNoFields() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Account.SObjectType) + '"}';
        controller.patchUtilityAccountLog(jsonRequest);

        System.assertEquals(400, RestContext.response.statusCode, 'PATCH should throw an error when no patchable fields are provided');
    }

    @IsTest
    private static void testPatchUtilityAccountLogInvalidId() {
        useMocks();
        String jsonRequest = '{ "id": "a1b000000000111"}'; // ID of ...111 is set as an non-existent ID in the mock svc
        controller.patchUtilityAccountLog(jsonRequest);

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
        useMocks();

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


    /*****************************
     *** postPropertyAccount() ***
     *****************************/

    @IsTest
    private static void testPostPropertyAccountNoFields() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Account.SObjectType) + '" }';
        controller.postPropertyAccount(jsonRequest);

        System.assertEquals(400, RestContext.response.statusCode, 'POST should throw an error when required fields are not provided');
    }

    @IsTest
    private static void testPostPropertyAccountWhenOneAlreadyExists() {
        useMocks();
        // We only support one property account today.  If you try to pass another in after one exists, you should get an error

        String jsonRequest = '{' +
            '"leadId": "00Q000000000999",' +
            '"billingStreet": "Test billing street",' +
            '"billingCity": "Test billing city",' +
            '"billingState": "NY",' +
            '"billingPostalCode": "14472"' +
            '}';

        controller.postPropertyAccount(jsonRequest);

        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        List<Object> errors = (List<Object>) responseEnvelope.get('errors');
        String error = String.valueOf(errors.get(0));

        System.assertEquals(400, RestContext.response.statusCode, 'We currently only support 1 propertyAccount');
        System.assert(error.contains('only <=1 propertyAccount per lead is supported'));

    }

    @IsTest
    private static void testPostPropertyAccountWithInvalidLead() {
        useMocks();

        String jsonRequest = '{' +
            '"leadId": "00Q000000000111",' + // ID of ...111 is set as an non-existent ID in the mock svc
            '"billingStreet": "Test billing street",' +
            '"billingCity": "Test billing city",' +
            '"billingState": "NY",' +
            '"billingPostalCode": "14472"' +
            '}';

        controller.postPropertyAccount(jsonRequest);

        System.assertEquals(404, RestContext.response.statusCode, 'POST should throw an error if the ID provided is not valid');
    }

    @IsTest
    private static void testPostPropertyAccountWithMinimalFields() {
        useMocks();

        String jsonRequest = '{' +
            '"leadId": "00Q000000000888",' +
            '"billingStreet": "Test billing street",' +
            '"billingCity": "Test billing city",' +
            '"billingState": "NY",' +
            '"billingPostalCode": "14472"' +
            '}';

        controller.postPropertyAccount(jsonRequest);

        System.assertEquals(201, RestContext.response.statusCode, 'A PropertyAccount POST with minimal fields should succeed');
    }


    /*******************************
     *** postUtilityAccountLog() ***
     *******************************/

    @IsTest
    private static void testPostUtilityAccountLogNoFields() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Utility_Account_Log__c.SObjectType) + '" }';
        controller.postUtilityAccountLog(jsonRequest);

        System.assertEquals(400, RestContext.response.statusCode, 'POST should throw an error when required fields are not provided');
    }

    @IsTest
    private static void testPostUtilityAccountLogWithInvalidAccount() {
        useMocks();

        String jsonRequest = '{' +
            '"propertyAccountId": "001000000000111",' + // ID of ...111 is set as an non-existent ID in the mock svc
            '"nameOnAccount": "Bob",' +
            '"serviceStreet": "Test service street",' +
            '"serviceCity": "Test service city",' +
            '"serviceState": "NY",' +
            '"servicePostalCode": "14472"' +
            '}';

        controller.postUtilityAccountLog(jsonRequest);

        System.assertEquals(404, RestContext.response.statusCode, 'POST should throw an error if the ID provided is not valid');
    }

    @IsTest
    private static void testPostUtilityAccountLogWithMinimalFields() {
        useMocks();

        String jsonRequest = '{' +
            '"propertyAccountId": "001000000000888",' +
            '"nameOnAccount": "Bob",' +
            '"serviceStreet": "Test service street",' +
            '"serviceCity": "Test service city",' +
            '"serviceState": "NY",' +
            '"servicePostalCode": "14472"' +
            '}';

        controller.postUtilityAccountLog(jsonRequest);

        System.assertEquals(201, RestContext.response.statusCode, 'A UAL POST with minimal fields should succeed');
    }

    @IsTest
    private static void testPerformZipCheck() {
        useMocks();
        RestContext.response = new RestResponse();
        controller.performZipCheck('12345', '');
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
        useMocks();
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
            '"id": "00Q000000000888",' +
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
            '   "leadId": "00Q000000000888", ' +
            '   "billingStreet": "Test billing street",' +
            '   "billingCity": "Test billing city",' +
            '   "billingState": "NY",' +
            '   "billingPostalCode": "14472",' +
            '   "utilityAccountLogs": [{' +
            '       "id": "a1b000000000999",' +
            '       "leadId": "00Q000000000888", ' +
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
            '                   "Service_Zip_Code__c": "14472"' +
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
        String jsonRequest = '{ "leadId": "' + Util.getFakeId(Schema.Lead.SObjectType) + '" }';
        controller.patchContract(jsonRequest);
        System.assertEquals(200, RestContext.response.statusCode, 'PATCH contract should not throw an error when a valid lead id is provided');
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

        ContentVersion contentVersion = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('utility bill'),
            Title = 'UtilityBill.pdf',
            PathOnClient = '/UtilityBill.pdf'
        );
        insert contentVersion;
        ContentDocumentSelector cds = new ContentDocumentSelector();
        Id contentDocId = cds.getDocumentIdFromVersionId(contentVersion.Id);

        String jsonRequest = getPostLeadJson(contentDocId);
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
        List<Object> requestUtilityBills = (List<Object>) requestUtilityAccountLog.get('utilityBills');
        Map<String, Object> requestUtilityBill = (Map<String, Object>) requestUtilityBills[0];

        
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseLead = (Map<String,Object>) responseEnvelope.get('data');

        System.assertEquals(201, response.statusCode, 'POST should create properly');
        System.assertEquals(1, [SELECT Id FROM Contract WHERE Lead__c = :(Id)responseLead.get('id')].size(), 'A contract should be created for this lead, as it has both a product and a property account');

        // verify lead request/response fields
        System.assertNotEquals(responseLead.get('id'), null, 'id should be set on POST response');
        System.assertEquals(websiteLead.Id, responseLead.get('id'));
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

        // verify utilityBill response fields
        List<Object> responseUtilityBills = (List<Object>) responseUtilityAccountLog.get('utilityBills');
        Map<String, Object> responseUtilityBill = (Map<String, Object>) responseUtilityBills[0];
        System.assertEquals(contentDocId, responseUtilityBill.get('id'), 'The request should have returned a valid content document ID for utility bill');
        System.assertEquals(contentVersion.Id, responseUtilityBill.get('lastPublishedVersionId'), 'The request should have returned a valid content version ID for utility bill');
        System.assertEquals('UtilityBill.pdf', responseUtilityBill.get('title'), 'The request should have returned a valid content version ID for utility bill');
        System.assertNotEquals(null, responseUtilityBill.get('docLinkId'), 'The request should have returned a valid content document link ID for utility bill');
        System.assertNotEquals(null, responseUtilityBill.get('body'), 'The request should have returned a valid content document link ID for utility bill');
        System.assertNotEquals(null, responseUtilityBill.get('size'), 'The request should have returned a valid content document link ID for utility bill');
        System.assertNotEquals(null, responseUtilityBill.get('createdDate'), 'The request should have returned a valid content document link ID for utility bill');
    }

    private static String getPostLeadJson(Id contentDocId) {
        return '{' +
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
            '       "utilityAccountNumber": "555555",' +
            '       "utilityBills": [{' +
            '           "id": "' + contentDocId + '"' +
            '       }]' +
            '   }]' +
            '}]}';
    }


    @IsTest
    private static void testPostSuccessSystemNoContract() {
        String jsonRequest = '{' +
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
            '"continueApplicationLink": "http://switch.bluewavesolar.invalid",' +
            '"productName": "CS Product",' +
            '"campaignId": "0005500000"' +
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
        Id leadId = (Id)responseLead.get('id');

        System.assertEquals(201, response.statusCode, 'POST should create properly');
        System.assertEquals(0, [SELECT Id FROM Contract WHERE Lead__c = :leadId].size(), 'No contract should be created for this lead, as it has a product but no property account');

        jsonRequest = '{' +
            '"leadId": "' + leadId + '",' +
            '"billingStreet": "Test billing street",' +
            '"billingCity": "Test billing city",' +
            '"billingState": "NY",' +
            '"billingPostalCode": "14472"' +
            '}';
        controller.postPropertyAccount(jsonRequest);

        System.assertEquals(201, RestContext.response.statusCode, 'A PropertyAccount POST with minimal fields should succeed');
        System.assertEquals(1, [SELECT Id FROM Contract WHERE Lead__c = :leadId].size(), 'A contract should be created for this lead, as it now has both a product and a property account');
    }


    /*************
     *** MOCKS ***
     *************/
    @TestVisible
    private static String SAMPLE_EMAIL = 'email@invalid.com';
    
    @TestVisible
    private class MockLeadService extends MockProvider {
        public MockLeadService(){}

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

    @TestVisible
    private class MockLeadSelector implements StubProvider {
        public MockLeadSelector(){}
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
                Lead newLead = new Lead();
                newLead.Email = SAMPLE_EMAIL;
                if(!listOfArgs.isEmpty() && listOfArgs.get(0) != null) {
                    if (String.valueOf(listOfArgs.get(0)).substring(0,15) == '00Q000000000111') {
                        return null;
                    } else if (String.valueOf(listOfArgs.get(0)).substring(0,15) == '00Q000000000999') {
                        newLead.Application_Complete_Date__c = Datetime.newInstance(2017, 1, 1);
                    } else if (String.valueOf(listOfArgs.get(0)).substring(0,15) == '00Q000000000888') {
                        newLead.Id = '00Q000000000888';
                    } else if (String.valueOf(listOfArgs.get(0)).substring(0,15) == '00Q000000000777') {
                        String leadMapJson = '{ ' +
                        '   "attributes": {' +
                        '       "type": "Lead",' +
                        '       "url": "/services/data/v48.0/sobjects/Lead/00Q000000000777"' +
                        '   },' +
                        '   "Email": "' + SAMPLE_EMAIL + '",' +
                        '   "Id": "00Q000000000777",' +
                        '   "Accounts__r": {' +
                        '       "totalSize": 2,' +
                        '       "done": true,' +
                        '       "records": ' +
                        '           [' +
                        '               {' +
                        '                   "attributes": {' +
                        '                       "type": "Account",' +
                        '                       "url": "/services/data/v48.0/sobjects/Account/001000000000999"' +
                        '                   },' +
                        '                   "Lead__c": "00Q000000000777",' +
                        '                   "Id": "001000000000999"' +
                        '               },' +
                        '               {' +
                        '                   "attributes": {' +
                        '                       "type": "Account",' +
                        '                       "url": "/services/data/v48.0/sobjects/Account/001000000000999"' +
                        '                   },' +
                        '                   "Lead__c": "00Q000000000777",' +
                        '                   "Id": "001000000000999"' +
                        '               }' +
                        '           ]' +
                        '   }' +  
                        '}';
                        return (Lead)JSON.deserialize(leadMapJson, Lead.class);
                    }
                }
                if(stubbedMethodName == 'selectOneWithPropertiesAndUtilities') {
                    String createDate = Datetime.now().format('yyyy-MM-dd') + 'T' + Datetime.now().format('kk:mm:ss.SSS') + '+0000';
                    
                    String leadMapJson = '{ ' +
                        '   "attributes": {' +
                        '       "type": "Lead",' +
                        '       "url": "/services/data/v48.0/sobjects/Lead/00Q000000000999"' +
                        '   },' +
                        '   "Email": "' + SAMPLE_EMAIL + '",' +
                        '   "Id": "00Q000000000999",' +
                        '   "CreatedDate": "' + createDate + '",' +
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
                        '                   "Account__c": "001000000000999"' +
                        '               }' +
                        '           ]' +
                        '   }' + 
                        '}';
                    return (Lead)JSON.deserialize(leadMapJson, Lead.class);
                }

                return newLead;
        }
    }

    @TestVisible
    private class MockAccountService implements StubProvider {
        public MockAccountService(){}
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

    @TestVisible
    private class MockAccountsSelector implements StubProvider {
        public MockAccountsSelector(){}
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'selectOne' {
                    Account newAccount = new Account();
                    if(!listOfArgs.isEmpty() && listOfArgs.get(0) != null) {
                        if (String.valueOf(listOfArgs.get(0)).substring(0,15) == '001000000000111') {
                            return null;
                        } else if (String.valueOf(listOfArgs.get(0)).substring(0,15) == '001000000000888') {
                            newAccount.Id = '001000000000888';
                            newAccount.Lead__c = Util.getFakeId(Schema.Lead.SObjectType);
                        }
                    }
                    return newAccount;

                }
                when 'selectPropertyAccountsByLeadIds' {
                    for (Id leadId : (Set<Id>) listOfArgs.get(0)) {
                        if(!listOfArgs.isEmpty() && listOfArgs.get(0) != null) {
                            if (String.valueOf(leadId).substring(0,15) == '00Q000000000999') {
                                return new List<Account>{new Account()};
                            }
                        }
                    }
                }
                when 'selectPropertyAccountsByLeadIdsMap' {
                    return new Map<Id, Account>{'001000000000999' => new Account(Id = '001000000000999')};
                }
            }
            return null;
        }
    }

    @TestVisible
    private class MockUALService implements StubProvider {
        public MockUALService(){}
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

    @TestVisible
    private class MockUALSelector implements StubProvider {
        public MockUALSelector(){}
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

    @TestVisible
    private class MockCustomerContractService extends MockProvider {
        public MockCustomerContractService(){}

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

    @TestVisible
    private class MockCapacityService implements StubProvider {
        public MockCapacityService() {}
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            String zipResponseWithCapacity = '{"zipcode":"02633","utilityIds":["a1MS0000008BldpMAC"],"utilities":[{"attributes":{"type":"Utility__c","url":"/services/data/v47.0/sobjects/Utility__c/a1MS0000008BldpMAC"},"Id":"a1MS0000008BldpMAC","Name":"Eversource"}],"sharedSolarSystems":[{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvGMAW"},"Id":"a1JS0000003BMvGMAW","Name":"Project A Oak Road","Capacity_Available_to_be_Reserved__c":144499.98,"Product__c":"01tS0000005j7AVIAY","Sales_Partners__c":"BlueWave Test Partner","Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AVIAY"},"Id":"01tS0000005j7AVIAY","Name":"BlueWave SMART","Customer_Subscription_Type__c":"kWh"}},{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvHMAW"},"Id":"a1JS0000003BMvHMAW","Name":"Project B Main St","Capacity_Available_to_be_Reserved__c":1445.86,"Product__c":"01tS0000005j7AVIAY","Sales_Partners__c":"BlueWave Test Partner","Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AVIAY"},"Id":"01tS0000005j7AVIAY","Name":"BlueWave SMART","Customer_Subscription_Type__c":"kWh"}},{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvIMAW"},"Id":"a1JS0000003BMvIMAW","Name":"Project C Second St","Capacity_Available_to_be_Reserved__c":1445.86,"Product__c":"01tS0000005j7AWIAY","Sales_Partners__c":"BlueWave Test Partner","Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AWIAY"},"Id":"01tS0000005j7AWIAY","Name":"BlueWave SREC","Customer_Subscription_Type__c":"Electricity Cost ($)"}}],"products":[{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AVIAY"},"Id":"01tS0000005j7AVIAY","Name":"BlueWave SMART","Customer_Subscription_Type__c":"kWh"},{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AWIAY"},"Id":"01tS0000005j7AWIAY","Name":"BlueWave SREC","Customer_Subscription_Type__c":"Electricity Cost ($)"}],"loadZones":[{"attributes":{"type":"Load_U__c","url":"/services/data/v47.0/sobjects/Load_U__c/a0ZS0000007rJ3mMAE"},"Id":"a0ZS0000007rJ3mMAE","LZ__c":"SEMA","Town__c":"Medfield","Name":"02633"}],"loadZoneNames":["SEMA"]}';
            CapacityService.ZipcodeResponse response =
                (CapacityService.ZipcodeResponse) JSON.deserialize(zipResponseWithCapacity, CapacityService.ZipcodeResponse.class);
            return response;
        }
    }

    private class MockDuplicateService extends MockProvider {
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

    @TestVisible
    private class MockUOW extends MockProvider {
        public MockUOW(){}

        public override Object handleMethodCall(MethodCall methodCall) {
            return null;
        }
    }

}