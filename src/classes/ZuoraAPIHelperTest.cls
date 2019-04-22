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
        String body = ZuoraAPIHelper.callJsonEndpoint('GET', 'error', null);
        ZuoraAPI.GenericError error = (ZuoraAPI.GenericError) System.JSON.deserialize(body, ZuoraAPI.GenericError.class);
        System.assertEquals(false, error.success);
    }
}