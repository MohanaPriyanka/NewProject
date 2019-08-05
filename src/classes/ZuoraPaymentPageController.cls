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
        HttpResponse ccResponse = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/rsa-signatures', ccJsonBody, false);
        ZuoraAPI.RSASignature ccRsaSignature;
        if (ccResponse.getStatusCode() == 200) {
            ccRsaSignature = (ZuoraAPI.RSASignature) System.JSON.deserialize(ccResponse.getBody(), ZuoraAPI.RSASignature.class);
        } else {
            throw new AuraHandledException(ccResponse.getBody());
        }

        Map<String, Object> achJsonBody = new Map<String, Object>();
        achJsonBody.put('method', 'POST');
        achJsonBody.put('pageId', pageMetadata.zuoraSetting.ACH_Payment_Page_Id__c);
        achJsonBody.put('uri', pageMetadata.zuoraSetting.Hosted_Payment_Page_URI__c);
        ZuoraAPI.RSASignature achRsaSignature;
        HttpResponse achResponse = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/rsa-signatures', achJsonBody);
        if (achResponse.getStatusCode() == 200) {
            achRsaSignature = (ZuoraAPI.RSASignature) System.JSON.deserialize(achResponse.getBody(), ZuoraAPI.RSASignature.class);
        } else {
            throw new AuraHandledException(achResponse.getBody());
        }

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
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/object/payment-method/' + refId, null);
        if (response.getStatusCode() == 200) {
            return (ZuoraAPI.PaymentMethod) System.JSON.deserialize(response.getBody(), ZuoraAPI.PaymentMethod.class);
        } else {
            throw new AuraHandledException(response.getBody());
        }
    }
}