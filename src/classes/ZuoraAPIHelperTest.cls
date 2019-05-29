/*************************************************************************************
 * Created By: peteryao on 2019-04-10  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraAPIHelperTest {
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
        String result = ZuoraAPIHelper.query('SELECT Id FROM Account');
        System.assert(result.contains('"done":true'));
    }

    @IsTest
    public static void testDelete() {
        String result = ZuoraAPIHelper.deleteObjects(new List<String>{'12345'}, 'Account', false);
        System.assert(result.contains('"success": true'));
    }

    @IsTest
    public static void testClean() {
        String json = '{"Name" : "type", "type" : "AddProduct", "currency" : "USD", "ClientOwner__c" : "AMP"}';
        String expectedJson = '{"Name" : "type", "type_Zreserved" : "AddProduct", "currency_Zreserved" : "USD", "ClientOwner_Zcustom" : "AMP"}';
        String cleanedJson = ZuoraAPIHelper.cleanJSON(json);
        System.assertEquals(expectedJson, cleanedJson);
    }
}