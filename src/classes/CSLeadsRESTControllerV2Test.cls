/**
 * Created by jlugo on 2019-07-09.
 */

@IsTest
public with sharing class CSLeadsRESTControllerV2Test {

    private static CSLeadsRESTControllerV2 controller = new CSLeadsRESTControllerV2();
    private static MockLeadService mockLeadService;

    public static void useMocks () {
        mockLeadService = new MockLeadService();
        controller.leadService = (LeadService) Test.createStub(LeadService.class, mockLeadService);
        controller.accountService = (AccountService) Test.createStub(AccountService.class, new MockAccountService());
        controller.ualService = (UALService) Test.createStub(UALService.class, new MockUALService());

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
     *** patchLead() ***
     *******************/

    @IsTest
    public static void testPatchLeadSuccess() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '", "applicationCompleteDate": "2019-01-01T01:00" }';
        controller.patchLead(jsonRequest);

        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
        System.assertEquals(true, mockLeadService.getLastUpdatedLead().Soft_Pull_Credit_Report__c, 'Soft credit pull should be done when the application is complete');
    }

    @IsTest
    public static void testPatchLeadCreditPullOnce() {
        useMocks();
        // ID of ...999 is an ID with an existing app date of Jan 1 2017 in the mock svc
        String jsonRequest = '{ "id": "00Q000000000999", "applicationCompleteDate": "2019-11-18T01:00" }';
        controller.patchLead(jsonRequest);

        // when patching a lead that already has an application complete date, don't try to pull credit again
        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
        System.assertEquals(false, mockLeadService.getLastUpdatedLead().Soft_Pull_Credit_Report__c, 'Soft credit pull should not be done if the app complete date has been previously set');
    }

    @IsTest
    public static void testPatchLeadNoFields() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '"}';
        controller.patchLead(jsonRequest);

        System.assertEquals(400, RestContext.response.statusCode, 'PATCH should throw an error when no patchable fields are provided');
    }

    @IsTest
    public static void testPatchLeadInvalidId() {
        useMocks();
        String jsonRequest = '{ "id": "00Q000000000111"}'; // ID of ...111 is set as an non-existent ID in the mock svc
        controller.patchLead(jsonRequest);

        System.assertEquals(404, RestContext.response.statusCode, 'PATCH should throw an error if the ID provided is not valid');
    }

    /******************************
     *** patchPropertyAccount() ***
     ******************************/

    @IsTest
    public static void testPatchPropertyAccountSuccess() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Account.SObjectType) + '", "zuoraPaymentRefId": "mockId", "zuoraPaymentRefIdExpirationDate": "2019-01-01T01:00" }';
        controller.patchPropertyAccount(jsonRequest);

        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
    }

    @IsTest
    public static void testPatchPropertyAccountNoFields() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Account.SObjectType) + '"}';
        controller.patchPropertyAccount(jsonRequest);

        System.assertEquals(400, RestContext.response.statusCode, 'PATCH should throw an error when no patchable fields are provided');
    }

    @IsTest
    public static void testPatchPropertyAccountInvalidId() {
        useMocks();
        String jsonRequest = '{ "id": "00Q000000000111"}'; // ID of ...111 is set as an non-existent ID in the mock svc
        controller.patchPropertyAccount(jsonRequest);

        System.assertEquals(404, RestContext.response.statusCode, 'PATCH should throw an error if the ID provided is not valid');
    }


    /********************************
     *** patchUtilityAccountLog() ***
     ********************************/

    @IsTest
    public static void testPatchUtilityAccountLogSuccess() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Account.SObjectType) + '", "annualKWh": 500 }';
        controller.patchUtilityAccountLog(jsonRequest);

        System.assertEquals(200, RestContext.response.statusCode, 'Properly formed PATCH should succeed');
    }

    @IsTest
    public static void testPatchUtilityAccountLogNoFields() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Account.SObjectType) + '"}';
        controller.patchUtilityAccountLog(jsonRequest);

        System.assertEquals(400, RestContext.response.statusCode, 'PATCH should throw an error when no patchable fields are provided');
    }

    @IsTest
    public static void testPatchUtilityAccountLogInvalidId() {
        useMocks();
        String jsonRequest = '{ "id": "00Q000000000111"}'; // ID of ...111 is set as an non-existent ID in the mock svc
        controller.patchUtilityAccountLog(jsonRequest);

        System.assertEquals(404, RestContext.response.statusCode, 'PATCH should throw an error if the ID provided is not valid');
    }


    /******************
     *** postLead() ***
     ******************/

    @IsTest
    public static void testPostLeadNoFields() {
        useMocks();
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '" }';
        controller.postLead(jsonRequest);

        System.assertEquals(400, RestContext.response.statusCode, 'POST should throw an error when required fields are not provided');
    }

    @IsTest
    public static void testPostLeadWithTooManyAccounts() {
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
    public static void testPostLeadSuccess() {
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


    /********************
     *** SYSTEM TESTS ***
     ********************/

    @IsTest
    public static void testPostLeadSuccessSystem() {
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

        List<Object> responsePropertyAccounts = (List<Object>) responseLead.get('propertyAccounts');
        Map<String, Object> responsePropertyAccount = (Map<String,Object>) responsePropertyAccounts[0];
        List<Object> responseUtilityAccountLogs = (List<Object>) responsePropertyAccount.get('utilityAccountLogs');
        Map<String, Object> responseUtilityAccountLog = (Map<String,Object>) responseUtilityAccountLogs[0];

        System.assertEquals(201, response.statusCode, 'POST should create properly');

        // verify lead request/response fields
        System.assertNotEquals(responseLead.get('id'), null, 'id should be set on POST response');
        for (String key : requestLead.keySet()) {
            if (requestLead.get(key) instanceof String) {
                System.assertEquals(requestLead.get(key), responseLead.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }

        // verify propertyAccount request/response fields
        System.assertEquals(requestLead.get('firstName') + ' ' + requestLead.get('lastName'), responsePropertyAccount.get('name'), 'For resi customers, the name on the prop account should be their first & last name');
        for (String key : requestPropertyAccount.keySet()) {
            if (requestPropertyAccount.get(key) instanceof String) {
                System.assertEquals(requestPropertyAccount.get(key), responsePropertyAccount.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }

        // verify UALs request/response fields
        for (String key : requestUtilityAccountLog.keySet()) {
            if (requestUtilityAccountLog.get(key) instanceof String) {
                System.assertEquals(requestUtilityAccountLog.get(key), responseUtilityAccountLog.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }

    }


    /*************
     *** MOCKS ***
     *************/

    public class MockLeadService extends MockProvider {
        public MockLeadService(){}

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'updateLead' {
                    return new Lead();
                }
                when 'insertLead' {
                    return new Lead(Id = Util.getFakeId(Schema.Lead.SObjectType));
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
        public MockLeadSelector(){}
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            Lead newLead = new Lead();
            if (String.valueOf(listOfArgs.get(0)).substring(0,15) == '00Q000000000111') {
                return null;
            } else if (String.valueOf(listOfArgs.get(0)).substring(0,15) == '00Q000000000999') {
                newLead.Application_Complete_Date__c = Datetime.newInstance(2017, 1, 1);
            }
            return newLead;
        }
    }

    public class MockAccountService implements StubProvider {
        public MockAccountService(){}
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'updateAccount' {
                    return new Account();
                }
                when 'insertAccount' {
                    return new Account(Id = Util.getFakeId(Schema.Account.SObjectType));
                }
            }
            return null;
        }
    }

    public class MockAccountsSelector implements StubProvider {
        public MockAccountsSelector(){}
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            if (String.valueOf(listOfArgs.get(0)).substring(0,15) == '00Q000000000111') {
                return null;
            }
            return new Account();
        }
    }

    public class MockUALService implements StubProvider {
        public MockUALService(){}
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'updateUAL' {
                    return new Utility_Account_Log__c();
                }
                when 'insertUALs' {
                    return new List<Utility_Account_Log__c>{new Utility_Account_Log__c(Id = Util.getFakeId(Schema.Utility_Account_Log__c.SObjectType))};
                }
            }
            return null;
        }
    }

    public class MockUALSelector implements StubProvider {
        public MockUALSelector(){}
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            if (String.valueOf(listOfArgs.get(0)).substring(0,15) == '00Q000000000111') {
                return null;
            }
            return new Utility_Account_Log__c();
        }
    }

}