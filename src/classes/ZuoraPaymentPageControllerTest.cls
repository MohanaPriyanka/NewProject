/*************************************************************************************
 * Created By: peteryao on 2019-04-11  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraPaymentPageControllerTest {
    @IsTest
    public static void testGetPageMetadata() {
        Test.setMock(HttpCalloutMock.class, new ZuoraAPIMock());
        ZuoraPaymentPageController.PaymentPageMetadata paymentPageMetadata = ZuoraPaymentPageController.getPageMetadata();
        System.assertEquals('30689', paymentPageMetadata.ccRsaSignature.tenantId);

        Organization o = [SELECT IsSandbox FROM Organization];
        List<Zuora_Setting__mdt> zuoraSettings = [
            SELECT Id, API_Endpoint_URL__c
            FROM Zuora_Setting__mdt
            WHERE Is_Sandbox__c = :o.IsSandbox
        ];
        System.assertEquals(zuoraSettings[0].API_Endpoint_URL__c, paymentPageMetadata.zuoraSetting.API_Endpoint_URL__c);
    }

    @IsTest
    public static void testGetPaymentMethod() {
        Test.setMock(HttpCalloutMock.class, new ZuoraAPIMock());
        ZuoraAPI.PaymentMethod paymentMethod = ZuoraPaymentPageController.getPaymentMethod('foo');
        System.assertEquals('AmericanExpress', paymentMethod.CreditCardType);
    }
}