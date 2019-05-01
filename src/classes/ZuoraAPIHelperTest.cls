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
            ZuoraAPI.GenericError error = (ZuoraAPI.GenericError) System.JSON.deserialize(response.getBody(), ZuoraAPI.GenericError.class);
            System.assertEquals(false, error.success);
        } else {
            System.assert(false, 'Expected ZuoraAPIMock to return status code 200');
        }
    }

    @IsTest
    public static void testZuoraEnabled() {
        // At the time of writing, we can't do DML on Zuora settings
        List<Zuora_Setting__mdt> zuoraSettings = [SELECT Id, Active__c FROM Zuora_Setting__mdt];
        Integer numActive = 0;
        for (Zuora_Setting__mdt zuoraSetting : zuoraSettings) {
            if (zuoraSetting.Active__c) {
                numActive ++;
            }
        }
        if (numActive == 0) {
            System.assertEquals(true, ZuoraAPIHelper.zuoraEnabled());
            System.assertEquals('TestSetting', ZuoraAPIHelper.getZuoraSetting().DeveloperName);
        } else if (numActive == 1) {
            System.assertEquals(true, ZuoraAPIHelper.zuoraEnabled());
        } else {
            System.assertEquals(false, ZuoraAPIHelper.zuoraEnabled());
        }
    }
}