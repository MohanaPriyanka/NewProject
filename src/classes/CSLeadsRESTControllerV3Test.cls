/**
 * Created by peteryao on 2/21/20.
 */
@IsTest
public with sharing class CSLeadsRESTControllerV3Test {
    private static CSLeadsRESTControllerV3 controller = new CSLeadsRESTControllerV3();
    private static CSLeadsRESTControllerV2Test.MockLeadService mockLeadService;

    @TestSetup
    private static void testSetup() {
        CSLeadsRESTControllerV2Test.testSetup();
    }

    @IsTest
    private static void testAuthorization() {
        useMocks();
        try {
            controller.validateAuthorization(Util.getFakeId(Lead.SObjectType), CSLeadsRESTControllerV2Test.SAMPLE_EMAIL);
        } catch (Exception e) {
            System.assert(false, 'Did not expect validateAuthorization to throw an exception ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        try {
            controller.validateAuthorization(Util.getFakeId(Lead.SObjectType), 'invalidemail@invalid.com');
            System.assert(false, 'Expected to throw an exception on invalid email');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Invalid authorization'), 'Expected to catch the invalid email for the lead id');
        }
    }

    @IsTest
    private static void testGetLeadSuccess() {
        useMocks();
        controller.getLead(Util.getFakeId(Schema.Lead.SObjectType), CSLeadsRESTControllerV2Test.SAMPLE_EMAIL);
        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed GET request should succeed');
    }

    @IsTest
    private static void testPatchLeadSuccess() {
        useMocks();
        String jsonRequest = '{' +
            '"id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '", ' +
            '"email": "'+ CSLeadsRESTControllerV2Test.SAMPLE_EMAIL +'",' +
            '"applicationCompleteDate": "2019-01-01T01:00"' +
            '}';
        controller.patchLead(jsonRequest);

        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
        System.assertEquals(true, mockLeadService.getLastUpdatedLead().Soft_Pull_Credit_Report__c, 'Soft credit pull should be done when the application is complete');
    }

    @IsTest
    private static void testPatchPropertyAccountSuccess() {
        useMocks();
        String jsonRequest = '{' +
            '"id": "' + Util.getFakeId(Schema.Account.SObjectType) + '",' +
            '"leadId": "' + Util.getFakeId(Schema.Lead.SObjectType) + '",' +
            '"email": "'+ CSLeadsRESTControllerV2Test.SAMPLE_EMAIL +'",' +
            '"zuoraPaymentRefId": "mockId",' +
            '"zuoraPaymentRefIdExpirationDate": "2019-01-01T01:00"' +
            '}';
        controller.patchPropertyAccount(jsonRequest);

        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
    }

    @IsTest
    private static void testPatchUtilityAccountLogSuccess() {
        useMocks();
        String jsonRequest = '{' +
            '"id": "' + Util.getFakeId(Schema.Account.SObjectType) + '",' +
            '"leadId": "' + Util.getFakeId(Schema.Lead.SObjectType) + '",' +
            '"email": "'+ CSLeadsRESTControllerV2Test.SAMPLE_EMAIL +'",' +
            '"annualKWh": 500' +
            '}';
        controller.patchUtilityAccountLog(jsonRequest);

        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
    }

    @IsTest
    private static void testPatchApplicationSuccess() {
        useMocks();
        String jsonRequest = '{' +
            '"id": "00Q000000000888",' +
            '"firstName": "Unit",' +
            '"lastName": "Testcase",' +
            '"email": "' + CSLeadsRESTControllerV2Test.SAMPLE_EMAIL + '",' +
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

    public static void useMocks () {
        mockLeadService =  new CSLeadsRESTControllerV2Test.MockLeadService();
        controller.leadService = (LeadService) Test.createStub(LeadService.class, mockLeadService);
        controller.accountService = (AccountService) Test.createStub(AccountService.class, new CSLeadsRESTControllerV2Test.MockAccountService());
        controller.ualService = (UALService) Test.createStub(UALService.class, new CSLeadsRESTControllerV2Test.MockUALService());
        controller.capacityService = (CapacityService) Test.createStub(CapacityService.class, new CSLeadsRESTControllerV2Test.MockCapacityService());

        controller.leadSelector = (LeadSelector) Test.createStub(LeadSelector.class, new CSLeadsRESTControllerV2Test.MockLeadSelector());
        controller.accountsSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new CSLeadsRESTControllerV2Test.MockAccountsSelector());
        controller.ualSelector = (UALSelector) Test.createStub(UALSelector.class, new CSLeadsRESTControllerV2Test.MockUALSelector());

        RestContext.response = new RestResponse();
    }

}