/*************************************************************************************
 * Created By: peteryao on 2019-04-11  
 * Description: 
 * Test: 
 *************************************************************************************/

public with sharing class ZuoraPaymentPageController {
    @AuraEnabled
    public static PaymentPageMetadata getPageMetadata() {
        PaymentPageMetadata pageMetadata = new PaymentPageMetadata();
        pageMetadata.zuoraSetting = ZuoraAPIHelper.getZuoraSetting();
        Map<String, Object> ccJsonBody = new Map<String, Object>();
        ccJsonBody.put('method', 'POST');
        ccJsonBody.put('pageId', pageMetadata.zuoraSetting.CC_Payment_Page_Id__c);
        ccJsonBody.put('uri', pageMetadata.zuoraSetting.Hosted_Payment_Page_URI__c);
        String ccbody = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/rsa-signatures', ccJsonBody, false);
        ZuoraAPI.RSASignature ccRsaSignature = (ZuoraAPI.RSASignature) System.JSON.deserialize(ccbody, ZuoraAPI.RSASignature.class);

        Map<String, Object> achJsonBody = new Map<String, Object>();
        achJsonBody.put('method', 'POST');
        achJsonBody.put('pageId', pageMetadata.zuoraSetting.ACH_Payment_Page_Id__c);
        achJsonBody.put('uri', pageMetadata.zuoraSetting.Hosted_Payment_Page_URI__c);
        String achbody = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/rsa-signatures', achJsonBody);
        ZuoraAPI.RSASignature achRsaSignature = (ZuoraAPI.RSASignature) System.JSON.deserialize(achbody, ZuoraAPI.RSASignature.class);

        pageMetadata.ccRsaSignature = ccRsaSignature;
        pageMetadata.achRsaSignature = achRsaSignature;
        return pageMetadata;
    }

    public class PaymentPageMetadata {
        @AuraEnabled
        public ZuoraAPI.RSASignature ccRsaSignature;
        @AuraEnabled
        public ZuoraAPI.RSASignature achRsaSignature;
        @AuraEnabled
        public Zuora_Setting__mdt zuoraSetting;
    }

    @AuraEnabled
    public static ZuoraAPI.PaymentMethod getPaymentMethod(String refId) {
        String body = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/object/payment-method/' + refId, null);
        return (ZuoraAPI.PaymentMethod) System.JSON.deserialize(body, ZuoraAPI.PaymentMethod.class);
    }
}