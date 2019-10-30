/*************************************************************************************
 * Created By: peteryao on 2019-04-10  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraAPIHelperTest {
    @TestSetup
    public static void testSetup(){
        API_Credential__c credential = new API_Credential__c();
        credential.Credential_ID__c = 'XXXXXX';
        credential.Credential_Secret__c = 'XXXXXXX';
        credential.Name = 'Zuora_O_Auth';
        insert credential;
    }

    @IsTest
    public static void testCallEndpoint() {
        Test.setMock(HttpCalloutMock.class, new ZuoraAPIMock());
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', 'error', null);
        if (response.getStatusCode() == 200) {
            ZuoraAPI.GenericResponse error = (ZuoraAPI.GenericResponse) System.JSON.deserialize(response.getBody(), ZuoraAPI.GenericResponse.class);
            System.assertEquals(false, error.success);
        } else {
            System.assert(false, 'Expected ZuoraAPIMock to return status code 200');
        }
    }

    @IsTest
    public static void testOAuthTokens() {
        Test.setMock(HttpCalloutMock.class, new ZuoraAPIMock());

        // Actually Generates it:
        String token = ZuoraAPIHelper.generateOAuthToken();
        System.assertEquals('aff6cd3b49934212980e6e0836fe0964', token);

        // Should be saved to the cache:
        String cachedToken = (String) Cache.Org.get('ZuoraOAuthToken');
        System.assertEquals('aff6cd3b49934212980e6e0836fe0964', cachedToken);
    }

    @IsTest
    public static void testOAuthCallEndpoint() {
        Test.setMock(HttpCalloutMock.class, new ZuoraAPIMock());

        HttpResponse response = ZuoraAPIHelper.callJSONEndpointWithOAuth('GET', 'error', null, false);
        if (response.getStatusCode() == 200) {
            ZuoraAPI.GenericResponse error = (ZuoraAPI.GenericResponse) System.JSON.deserialize(response.getBody(), ZuoraAPI.GenericResponse.class);
            System.assertEquals(false, error.success);
        } else {
            System.assert(false, 'Expected ZuoraAPIMock to return status code 200');
        }
    }

    @IsTest
    public static void testZuoraPaymentPageEnabled() {
        // If there's no system property, don't use payment page
        System.assertEquals(false, ZuoraAPIHelper.zuoraPaymentPageEnabled());

        System_Properties__c property = new System_Properties__c(Name = 'System', Use_Zuora_for_Payment_Capture__c = true);
        insert property;

        System.assertEquals(true, ZuoraAPIHelper.zuoraPaymentPageEnabled());

        property.Use_Zuora_for_Payment_Capture__c = false;
        update property;

        System.assertEquals(false, ZuoraAPIHelper.zuoraPaymentPageEnabled());
    }

    @IsTest
    public static void testQuery() {
        String query = 'SELECT Id FROM Account';
        String result = ZuoraAPIHelper.query(query, false);
        System.assert(result.contains('"done":true'));
        System.assertEquals(1, ZuoraAPIHelper.endpointsCalled.size(), 'Should have saved a single endpoint');
        System.assertEquals('/v1/action/query', ZuoraAPIHelper.endpointsCalled[0].endpoint);
        System.assert(ZuoraAPIHelper.endpointsCalled[0].jsonBody.contains(query));
    }

    @IsTest
    public static void testDelete() {
        String result = ZuoraAPIHelper.deleteObjects(new List<String>{'12345'}, 'Account');
        System.assert(result.contains('"Success":true'));
    }

    @IsTest
    public static void testClean() {
        String json = '{"Name" : "type", "type" : "AddProduct", "currency" : "USD", "ClientOwner__c" : "AMP"}';
        String expectedJson = '{"Name" : "type", "type_Zreserved" : "AddProduct", "currency_Zreserved" : "USD", "ClientOwner_Zcustom" : "AMP"}';
        String cleanedJson = ZuoraAPIHelper.cleanJSON(json);
        System.assertEquals(expectedJson, cleanedJson);
    }

    @IsTest
    public static void testCalloutLimit() {
        ZuoraAPIHelper.query('SELECT Id FROM Account', false);
        System.assertEquals(1, ZuoraAPIHelper.numberCalloutsForZuoraNamespace, 'Should have incremented our callout counter');

        ZuoraAPIHelper.numberCalloutsForZuoraNamespace = ZuoraAPIHelper.maxCalloutsForZuoraNamespace;
        Boolean exceptionCaught = false;
        try {
            ZuoraAPIHelper.query('SELECT Id FROM Account', false);
        } catch (Util.BWException bwe) {
            exceptionCaught = true;
        }
        System.assert(exceptionCaught, 'ZuoraAPIHelper should have thrown an exception before hitting the uncatchable System.LimitException');
    }

    @IsTest
    public static void testActionUpdate() {
        ZuoraAPI.ActionItems accountActionItems = new ZuoraAPI.ActionItems();
        accountActionItems.type = 'AccountWithErrors';
        accountActionItems.objects = new List<ZuoraAPI.ZuoraAccount>();
        accountActionItems.objects.add(new ZuoraAPI.ZuoraAccount());

        Boolean caughtException = false;
        try {
            ZuoraAPIHelper.actionUpdate(accountActionItems);
        } catch (Util.BWException bwe) {
            caughtException = true;
            Logger.flushLogs();
        }
        System.assert(caughtException, 'Expected to catch an exception');
        List<Error_Log__c> errorLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraAPIHelper'
            AND Method__c = 'containsErrors'
            AND Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size());
    }

}