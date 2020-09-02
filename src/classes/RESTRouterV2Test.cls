/**
 * Created by jlugo on 2019-07-09.
 */

@IsTest
public with sharing class RESTRouterV2Test {
    @TestVisible
    private static String validLead =
        '"firstName": "System"' +
            ',"lastName": "Testcase"' +
            ',"email": "test@invalid.bluewavesolar.com"' +
            ',"mobilePhone": "555-555-5555"' +
            ',"streetAddress": "1 Test Street"' +
            ',"city": "Suffern"' +
            ',"state": "NY"' +
            ',"zipCode": "10901"' +
            ',"eiaId": "1234"' +
            ',"productName": "CS Product"' +
            ',"referralName": "RefFirst RefLast"' +
            ',"referralEmail": "refemail@invalid.bluewavesolar.com"';

    @TestVisible
    private static String validResiLead = validLead + ',"applicationType": "Residential"';

    @TestVisible
    private static String validNonResiLead = validLead +
        ',"applicationType": "Non-Residential"' +
        ',"businessName": "My Cool Company"' +
        ',"businessTitle": "Janitor"' +
        ',"businessPhone": "5551239876"';

    @TestVisible
    private static String validPropertyAccount =
        '   "billingStreet": "Test billing street"' +
        ',  "billingCity": "Test billing city"' +
        ',  "billingState": "NY"' +
        ',  "billingPostalCode": "14472"';

    @TestVisible
    private static String validUtilityAccountLog =
        '       "nameOnAccount": "Test Accounts Payable"' +
        ',      "serviceStreet": "Test service street"' +
        ',      "serviceCity": "Test service city"' +
        ',      "serviceState": "NY"' +
        ',      "servicePostalCode": "14472"' +
        ',      "utilityAccountNumber": "555555"';

    @TestVisible
    private static String validResiJsonRequest = '{' +
        validResiLead + ',' +
        '"propertyAccounts": [{' +
        validPropertyAccount + ',' +
        '"utilityAccountLogs": [{' +
        validUtilityAccountLog +
        '}]}]}';

    @TestVisible
    private static String validNonResiJsonRequest = '{' +
        validNonResiLead + ',' +
        '"propertyAccounts": [{' +
        validPropertyAccount + ',' +
        '"utilityAccountLogs": [{' +
        validUtilityAccountLog +
        '}]}]}';


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

    /********************
     *** SYSTEM TESTS ***
     ********************/

    /** Leads **/

    @IsTest
    public static void testPostResiLeadSuccess() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;

        Map<String, Object> requestLead = (Map<String,Object>) JSON.deserializeUntyped(validResiJsonRequest);
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

    @IsTest
    public static void testPostNonResiLeadSuccess() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validNonResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;

        Map<String, Object> requestLead = (Map<String,Object>) JSON.deserializeUntyped(validNonResiJsonRequest);
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
        System.assertEquals(requestLead.get('businessName'), responsePropertyAccount.get('name'), 'For non-resi customers, the name on the prop account should be the company name');
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

    @IsTest
    public static void testPatchLeadSuccess() {

        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        Map<String, Object> postResponseLead = (Map<String, Object>) responseEnvelope.get('data');
        // </setup>

        String patchRequest = '{ "id": "' + postResponseLead.get('id') + '", "applicationCompleteDate": "2019-01-01T01:00" }';

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseLead = (Map<String,Object>) responseEnvelope.get('data');

        System.assertEquals(200, response.statusCode, 'Properly formed PATCH should succeed');
        System.assertNotEquals(responseLead.get('applicationCompleteDate'), null, 'When patching app complete date, the response\'s app complete date should not be null');

    }

    @IsTest
    public static void testGetLeadSuccess() {
        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        Map<String, Object> postResponseLead = (Map<String, Object>) responseEnvelope.get('data');
        // </setup>

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.addParameter('leadId', (String)postResponseLead.get('id'));
        req.addParameter('email', (String)postResponseLead.get('email'));
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.getRequest();

        response = RestContext.response;
        System.assertEquals(200, response.statusCode, 'Properly formed GET request should succeed');
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseLead = (Map<String,Object>) responseEnvelope.get('data');


    }

    /** Property Accounts **/

    @IsTest
    public static void testPostPropertyAccountSuccess() {
        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{' + validResiLead + '}');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        Map<String, Object> postResponseLead = (Map<String, Object>) responseEnvelope.get('data');

        // </setup>


        req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/property-accounts';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        String propertyAccountJson = '{' +
            validPropertyAccount + ',' +
            '"leadId": "' + postResponseLead.get('id') + '",' +
            '"utilityAccountLogs": [{' +
            validUtilityAccountLog +
            '}]}';

        req.requestBody = Blob.valueOf(propertyAccountJson);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        response = RestContext.response;

        Map<String, Object> requestPropertyAccount = (Map<String,Object>) JSON.deserializeUntyped(propertyAccountJson);

        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responsePropertyAccount = (Map<String,Object>) responseEnvelope.get('data');


        System.assertEquals(201, response.statusCode, 'POST should create properly');

        // verify lead request/response fields
        System.assertNotEquals(responsePropertyAccount.get('id'), null, 'id should be set on POST response');
        for (String key : requestPropertyAccount.keySet()) {
            if (requestPropertyAccount.get(key) instanceof String) {
                System.assertEquals(requestPropertyAccount.get(key), responsePropertyAccount.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }
    }

    @IsTest
    public static void testPatchPropertyAccountSuccess() {

        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        Map<String, Object> postResponseLead = (Map<String, Object>) responseEnvelope.get('data');
        Map<String, Object> postResponsePropertyAccount = (Map<String, Object>) ((List<Object>) postResponseLead.get('propertyAccounts'))[0];

        // </setup>

        String patchRequest = '{' +
            '"id":"' + postResponsePropertyAccount.get('id')  + '",' +
            '"zuoraPaymentRefId":"mock-zuoraId",' +
            '"zuoraPaymentRefIdExpirationDate":"2019-01-05T14:00-05:00"' +
            '}';

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/property-accounts';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responsePropertyAccount = (Map<String,Object>) responseEnvelope.get('data');

        System.assertEquals(200, response.statusCode, 'Properly formed PATCH should succeed');

        System.assertEquals('mock-zuoraId', responsePropertyAccount.get('zuoraPaymentRefId'));
        System.assertEquals('2019-01-05T19:00:00.000Z', responsePropertyAccount.get('zuoraPaymentRefIdExpirationDate'));

    }

    /** Utility Account Logs **/

    @IsTest
    public static void testPostUtilityAccountLogSuccess() {
        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        req.requestBody = Blob.valueOf('{' +
            validResiLead + ',' +
            '"propertyAccounts": [{' +
            validPropertyAccount +
            '}]}'
        );

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseLead = (Map<String,Object>) responseEnvelope.get('data');

        List<Object> responsePropertyAccounts = (List<Object>) responseLead.get('propertyAccounts');
        Map<String, Object> responsePropertyAccount = (Map<String,Object>) responsePropertyAccounts[0];

        // </setup>


        req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/utility-account-logs';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');

        String utilityAccountLogJson = '{' +
            '"propertyAccountId": "' + responsePropertyAccount.get('id') + '",' +
            validUtilityAccountLog +
            '}';


        req.requestBody = Blob.valueOf(utilityAccountLogJson);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        response = RestContext.response;

        Map<String, Object> requestUtilityAccountLog = (Map<String, Object>) JSON.deserializeUntyped(utilityAccountLogJson);

        jsonResponse = response.responseBody.toString();

        responseEnvelope = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseUtilityAccountLog = (Map<String, Object>) responseEnvelope.get('data');


        System.assertEquals(201, response.statusCode, 'POST should create properly');

        // verify lead request/response fields
        System.assertNotEquals(responseUtilityAccountLog.get('id'), null, 'id should be set on POST response');
        for (String key : requestUtilityAccountLog.keySet()) {
            if (requestUtilityAccountLog.get(key) instanceof String) {
                System.assertEquals(requestUtilityAccountLog.get(key), responseUtilityAccountLog.get(key), 'The requested ' + key + ' is expected to match the actual response');
            }
        }
    }

    @IsTest
    public static void testPatchUtilityAccountLogSuccess() {

        // <setup>
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(validResiJsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        RestResponse response = RestContext.response;
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);

        Map<String, Object> postResponseLead = (Map<String, Object>) responseEnvelope.get('data');
        Map<String, Object> postResponsePropertyAccount = (Map<String, Object>) ((List<Object>) postResponseLead.get('propertyAccounts'))[0];
        Map<String, Object> postResponseUtilityAccountLog = (Map<String, Object>) ((List<Object>) postResponsePropertyAccount.get('utilityAccountLogs'))[0];

        // </setup>

        String patchRequest = '{' +
            '"id":"' + postResponseUtilityAccountLog.get('id') + '",' +
            '"annualKWh":8000' +
            '}';

        req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/utility-account-logs';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(patchRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();

        response = RestContext.response;
        jsonResponse = response.responseBody.toString();
        responseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> responseUAL = (Map<String,Object>) responseEnvelope.get('data');

        System.assertEquals(200, response.statusCode, 'Properly formed PATCH should succeed');

        System.assertEquals(8000, responseUAL.get('annualKWh'));

    }


    /** Application **/

    @IsTest
    private static void testPatchApplicationSuccessNoDocRegen() {
        // <setup>
        Lead lead = createLead();
        
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('SDF body'),
            Title = 'Solar Disclosure Form.pdf',
            PathOnClient = '/Solar Disclosure Form.pdf'
        );
        ContentVersion cv2 = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('CSA body'),
            Title = 'Community Solar Agreement.pdf',
            PathOnClient = '/Community Solar Agreement.pdf'
        );
        insert new List<ContentVersion>{cv,cv2};
        List<ContentVersion> cvList = [SELECT Id, ContentDocumentId FROM ContentVersion];
        Datetime createdDate = Datetime.now().addDays(-1);
        Test.setCreatedDate(cvList[0].ContentDocumentId, createdDate);
        Test.setCreatedDate(cvList[1].ContentDocumentId, createdDate);

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cvList[0].ContentDocumentId,
            LinkedEntityId = lead.Contracts__r[0].Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        ContentDocumentLink cdl2 = new ContentDocumentLink(
            ContentDocumentId = cvList[1].ContentDocumentId,
            LinkedEntityId = lead.Contracts__r[0].Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert new List<ContentDocumentLink>{cdl, cdl2};

        // </setup>


        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/application';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');

        CSLeadsRESTControllerV2 ctrl = new CSLeadsRESTControllerV2();
        RestLead restLead = ctrl.formatRestLeadFromLeadAndChildren(lead.Id, false, 2);
        String applicationJson = JSON.serialize(restLead);
        req.requestBody = Blob.valueOf(applicationJson);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();
        
        RestResponse response = RestContext.response;
        System.assertEquals(200, response.statusCode, 'Properly formatted PATCH call should succeed');
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> patchResponseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        RestLead returnedLead = (RestLead) JSON.deserialize(JSON.serialize(patchResponseEnvelope.get('data')), RestLead.class);
        System.assertEquals(lead.Id, returnedLead.id, 'The lead returned should be the same one created during setup');
        System.assertEquals(1, returnedLead.propertyAccounts.size(), 'One property account should be returned');
        System.assertEquals(lead.Accounts__r[0].Id, returnedLead.propertyAccounts[0].id, 'The property account returned should be the same one created during setup');
        System.assertEquals(1, returnedLead.propertyAccounts[0].utilityAccountLogs.size(), 'One utility account log should be returned');
        System.assertEquals(lead.Utility_Account_Logs__r[0].Id, returnedLead.propertyAccounts[0].utilityAccountLogs[0].id, 'The utility account log returned should be the same one created during setup');
        System.assertEquals(2, returnedLead.contentDocs.size(), 'Two ContentDocumentLinks should be returned, as docs exist but no changes were made to the lead');
    }

    private static Lead createLead() {
        Lead l = new Lead(
            FirstName = 'System',
            LastName = 'Testcase',
            Email = 'test@invalid.bluewavesolar.com',
            MobilePhone = '555-555-5555',
            Phone = '555-555-5555',
            Company = 'System Testcase',
            Application_Type__c = 'Residential',
            LASERCA__Home_Address__c = '1 Test Street',
            LASERCA__Home_City__c = 'Suffern',
            LASERCA__Home_State__c = 'NY',
            LASERCA__Home_Zip__c = '10901',
            Street = '1 Test Street',
            City = 'Suffern',
            State = BlueWaveParent.convertAbbreviationToState('NY'),
            PostalCode = '10901',
            LeadSource = 'Switch',
            Product_line__c = 'Community Solar',
            Customer_type__c = 'Residential',
            Application_Source_Phase_1__c = 'Switch without Partner',
            Continue_Application_Link__c = 'http://switch.bluewavesolar.invalid',
            Referral_Name__c = 'RefFirst RefLast',
            Referral_Email__c = 'refemail@invalid.bluewavesolar.com',
            Product__c = [SELECT Id FROM Product2 LIMIT 1].Id,
            Utility_relationship__c = [SELECT Id FROM Utility__c LIMIT 1].Id
        );
        LeadService leadService = new LeadService();
        l = leadService.insertLead(l);

        Account a = new Account(
            Lead__c = l.Id,
            Name = l.Company,
            Product_Line__c = 'Community Solar',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId(),
            Electricity_Provider__c = l.Utility_relationship__c,
            BillingStreet = 'Test billing street',
            BillingCity = 'Test billing city',
            BillingState = BlueWaveParent.convertAbbreviationToState('NY'),
            BillingPostalCode = '14472'
        );
        AccountService accountService = new AccountService();
        a = accountService.insertAccount(a);

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Account__c = a.Id,
            Lead__c = l.Id,
            Name = '555555',
            Name_on_Account__c = 'Test Accounts Payable',
            Service_Address__c = 'Test service street',
            Service_City__c = 'Test service city',
            Service_State__c = 'NY',
            Service_Zip_Code__c = '14472'
        );
        insert ual;

        CustomerContractService ccs = new CustomerContractService();
        Contract c = ccs.setContractFields(l, 2);
        c.AccountId = a.Id;
        insert c;

        LeadSelector leadSelector = new LeadSelector();
        return leadSelector.selectOneWithPropertiesAndUtilities(l.Id);
    }

    @IsTest
    private static void testPatchApplicationSuccessRegenDocs() {
        // <setup>
        Lead lead = createLead();
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('SDF body'),
            Title = 'Solar Disclosure Form.pdf',
            PathOnClient = '/Solar Disclosure Form.pdf'
        );
        ContentVersion cv2 = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('CSA body'),
            Title = 'Community Solar Agreement.pdf',
            PathOnClient = '/Community Solar Agreement.pdf'
        );
        insert new List<ContentVersion>{cv,cv2};
        List<ContentVersion> cvList = [SELECT Id, ContentDocumentId FROM ContentVersion];
        Datetime createdDate = Datetime.now().addDays(-1);
        Test.setCreatedDate(cvList[0].ContentDocumentId, createdDate);
        Test.setCreatedDate(cvList[1].ContentDocumentId, createdDate.addMinutes(-10));

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cvList[0].ContentDocumentId,
            LinkedEntityId = lead.Contracts__r[0].Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        ContentDocumentLink cdl2 = new ContentDocumentLink(
            ContentDocumentId = cvList[1].ContentDocumentId,
            LinkedEntityId = lead.Contracts__r[0].Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert new List<ContentDocumentLink>{cdl, cdl2};
        ClientReportingService.uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType> {
                Account.SObjectType
            }
        );
    
        // </setup>


        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/application';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');

        String applicationJson = getApplicationJson(
            lead.Id, 
            lead.Accounts__r[0].Id, 
            lead.Utility_Account_Logs__r[0].Id
        );
        req.requestBody = Blob.valueOf(applicationJson);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();
        
        RestResponse response = RestContext.response;
        System.assertEquals(200, response.statusCode, 'Properly formatted PATCH call should succeed');
        String jsonResponse = response.responseBody.toString();
        Map<String, Object> patchResponseEnvelope = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        RestLead returnedLead = (RestLead) JSON.deserialize(JSON.serialize(patchResponseEnvelope.get('data')), RestLead.class);
        assertLeadAndChildrenChanged(lead, returnedLead);

        System.assertEquals(null, returnedLead.contentDocs, 'No ContentDocumentLinks should be returned, as docs exist and changes were made to the lead');
        System.assertEquals(Date.today().addDays(-1), returnedLead.mostRecentContractGen.date(), 'mostRecentContractGen should be returned, as docs exist and changes were made to the lead');
    }

    private static String getApplicationJson(Id leadId, Id acctId, Id ualId) {
        return '{' +
        '"id": "' + leadId + '",' +
        '"streetAddress": "9 Test Avenue",' +
        '"propertyAccounts": [' +
        '   { ' +
        '       "id": "' + acctId + '",' +
        '       "leadId": "' + leadId + '",' +
        '       "name": "99999",' +
        '       "billingStreet": "99 Test St",' +
        '       "billingCity": "Ninenine",' +
        '       "billingState": "MA",' +
        '       "billingPostalCode": "99999",' +
        '       "utilityAccountLogs": [' +
        '           { ' +
        '               "id": "' + ualId + '",' +
        '               "leadId": "' + leadId + '",' +
        '               "propertyAccountId": "' + acctId + '",' +
        '               "utilityAccountNumber": "999999",' +
        '               "nameOnAccount": "Test Name",' +
        '               "serviceStreet": "999 Test Blvd",' +
        '               "serviceCity": "Nineninenine",' +
        '               "serviceState": "MA",' +
        '               "servicePostalCode": "99999"' +
        '           } ' +
        '       ] ' +
        '   }' +
        '] ' +
        '}';
    }

    private static void assertLeadAndChildrenChanged(Lead originalLead, RestLead updatedLead) {
        System.assertEquals(originalLead.Id, updatedLead.id, 'The lead returned should be the same one created during setup');
        System.assertNotEquals(originalLead.LASERCA__Home_Address__c, updatedLead.streetAddress, 'The updated lead streetAddress field value should not match the original field value');
        
        Account originalPropertyAccount = originalLead.Accounts__r[0];
        RestLead.RestPropertyAccount updatedPropertyAccount = updatedLead.propertyAccounts[0];
        System.assertEquals(1, updatedLead.propertyAccounts.size(), 'One property account should be returned');
        System.assertEquals(originalPropertyAccount.Id, updatedPropertyAccount.id, 'The property account returned should be the same one created during setup');
        System.assertNotEquals(originalPropertyAccount.BillingStreet, updatedPropertyAccount.billingStreet, 'The updated property account BillingStreet field value should not match the original field value');
        System.assertNotEquals(originalPropertyAccount.BillingCity, updatedPropertyAccount.billingCity, 'The updated property account BillingCity field value should not match the original field value');
        System.assertNotEquals(originalPropertyAccount.BillingStateCode, updatedPropertyAccount.billingState, 'The updated property account BillingStateCode field value should not match the original field value');
        System.assertNotEquals(originalPropertyAccount.BillingPostalCode, updatedPropertyAccount.billingPostalCode, 'The updated property account BillingPostalCode field value should not match the original field value');

        Utility_Account_Log__c originalUal = originalLead.Utility_Account_Logs__r[0];
        RestLead.RestUtilityAccountLog updatedUal = updatedPropertyAccount.utilityAccountLogs[0];
        System.assertEquals(1, updatedPropertyAccount.utilityAccountLogs.size(), 'One utility account log should be returned');
        System.assertEquals(originalUal.Id, updatedUal.id, 'The utility account log returned should be the same one created during setup');
        System.assertNotEquals(originalUAL.Name, updatedUal.utilityAccountNumber, 'The updated utility account log utilityAccountNumber field value should not match the original field value');
        System.assertNotEquals(originalUAL.Name_on_Account__c, updatedUal.nameOnAccount, 'The updated utility account log nameOnAccount field value should not match the original field value');
        System.assertNotEquals(originalUAL.Service_Address__c, updatedUal.serviceStreet, 'The updated utility account log serviceStreet field value should not match the original field value');
        System.assertNotEquals(originalUAL.Service_City__c, updatedUal.serviceCity, 'The updated utility account log serviceCity field value should not match the original field value');
        System.assertNotEquals(originalUAL.Service_State__c, updatedUal.serviceState, 'The updated utility account log serviceState field value should not match the original field value');
        System.assertNotEquals(originalUAL.Service_Zip_Code__c, updatedUal.servicePostalCode, 'The updated utility account log servicePostalCode field value should not match the original field value');
    }


    /** Other **/

    @IsTest
    public static void testZipCheck() {
        RESTRouterV2.controller = (CSLeadsRESTControllerV2) Test.createStub(CSLeadsRESTControllerV2.class, new MockCSLeadsRESTControllerV2());

        String zipCode = '12345';
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/zip-check';
        req.addParameter('zipCode', zipCode);
        req.httpMethod = 'GET';

        RestContext.request = req;
        RESTRouterV2.getRequest();

        Boolean caughtException = false;
        try {
            RestZipCode restZipCode =
                (RestZipCode) JSON.deserialize(RestContext.response.responseBody.toString(), RestZipCode.class);
            System.assertEquals(zipCode, restZipCode.zipCode, 'Expected to get the requested zipCode in the response, got: ' + restZipCode.zipCode);
            System.assertEquals(true, restZipCode.hasCapacity, 'Expected the mock to find capacity');
        } catch (Exception e) {
            caughtException = true;
            System.assert(!caughtException, e.getMessage() + '\n' + e.getStackTraceString());
        }
        System.assertEquals(false, caughtException, 'Did not expect to catch an exception');
    }

    @IsTest
    public static void testGetInvalidPath() {
        RESTRouterV2.controller = (CSLeadsRESTControllerV2) Test.createStub(CSLeadsRESTControllerV2.class, new MockCSLeadsRESTControllerV2());

        String zipCode = '12345';
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/invalidpath';
        req.addParameter('zipCode', zipCode);
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = new RestResponse();
        RESTRouterV2.getRequest();

        Boolean caughtException = false;
        try {
            System.assertEquals(404, RestContext.response.statusCode, 'Expected a 404 for an invalid path');
        } catch (Exception e) {
            caughtException = true;
            System.assert(!caughtException, e.getMessage() + '\n' + e.getStackTraceString());
        }
        System.assertEquals(false, caughtException, 'Did not expect to catch an exception');
    }

    @IsTest
    public static void testGetWithException() {
        RESTRouterV2.controller = (CSLeadsRESTControllerV2) Test.createStub(CSLeadsRESTControllerV2.class, new MockCSLeadsRESTControllerV2());

        String zipCode = '12345';
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/zip-check';
        req.addParameter('zipCode', 'exception');
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = new RestResponse();
        RESTRouterV2.getRequest();

        Boolean caughtException = false;
        try {
            System.assertEquals(500, RestContext.response.statusCode, 'Expected a 500 for a system error');
        } catch (Exception e) {
            caughtException = true;
            System.assert(!caughtException, e.getMessage() + '\n' + e.getStackTraceString());
        }
        System.assertEquals(false, caughtException, 'Did not expect to catch an exception');
    }


    /** General Verb **/

    @IsTest
    public static void testPatchInvalidPath() {
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '"}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/some-invalid-path';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();

        System.assertEquals(404, RestContext.response.statusCode, 'PATCHing to an invalid path should give a 404 - not found');
    }

    @IsTest
    public static void testPatchServerError() {
        String jsonRequest = 'bogusJSONString';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.patchRequest();

        System.assertEquals(500, RestContext.response.statusCode, 'PATCHing with invalid JSON should yield a 500');
    }

    @IsTest
    public static void testPostInvalidPath() {
        String jsonRequest = '{ "id": "' + Util.getFakeId(Schema.Lead.SObjectType) + '"}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/some-invalid-path';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        System.assertEquals(404, RestContext.response.statusCode, 'POSTing to an invalid path should give a 404 - not found');
    }

    @IsTest
    public static void testPostServerError() {
        String jsonRequest = 'bogusJSONString';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/v2/leads';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonRequest);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        RESTRouterV2.postRequest();

        System.assertEquals(500, RestContext.response.statusCode, 'PATCHing with invalid JSON should yield a 500');
    }

    public class MockCSLeadsRESTControllerV2 extends MockProvider {
        public MockCSLeadsRESTControllerV2() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'performZipCheck' {
                    String zipCode = RestContext.request.params.get('zipCode');
                    if (zipCode == 'exception') {
                        throw new Util.BWException('system exception');
                    }
                    RestContext.response = new RestResponse();
                    CapacityService.ZipcodeResponse zipcodeResponse = new CapacityService.ZipcodeResponse();
                    zipcodeResponse.zipcode = zipCode;
                    RestZipCode restZipCode = new RestZipCode(zipcodeResponse);
                    restZipCode.hasCapacity = true;
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(restZipCode));
                }
            }
            return null;
        }
    }

}