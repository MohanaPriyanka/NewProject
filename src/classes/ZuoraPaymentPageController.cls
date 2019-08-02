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

    public class PaymentResponse {
        @AuraEnabled
        public String gatewayResponseCode;
        @AuraEnabled
        public String gatewayResponse;
        @AuraEnabled
        public String status; // 'Error' or 'Processed'
        @AuraEnabled
        public Boolean success;
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


    @AuraEnabled
    public static ZuoraAccountSelector.AccountWithPaymentMethod getAccountAndPayMethodFromZuora (String sfAccountId){
        return ZuoraAccountSelector.getAccountWithDefaultPaymentMethod(sfAccountId);
    }

    @AuraEnabled
    public static PaymentResponse makePayment(String zuoraAcctId, String paymentMethodId, Decimal paymentAmount) {
        ZuoraAPI.Payment newPayment = new ZuoraAPI.Payment();
        newPayment.accountId = zuoraAcctId;
        newPayment.paymentMethodId = paymentMethodId;
        newPayment.type = 'Electronic';
        newPayment.gatewayId = '2c92c0f9699ec9fe0169a68ab88b6ae3';
        newPayment.currency_Zreserved = 'USD';
        newPayment.amount = paymentAmount;

        PaymentResponse result;
        try {
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST','/v1/payments',newPayment,true);
            result = (PaymentResponse) System.JSON.deserialize(response.getBody(), PaymentResponse.class);
            if (!result.success) {
                String customErrorMessage =
                    'Error Updating account: ' + zuoraAcctId +
                        ' with paymentAmount: ' + paymentAmount +
                        ' and payment method Id: ' + paymentMethodId;
                Logger.logNow('ZuoraPaymentPageController', 'makePayment', customErrorMessage, 'ERROR');
            }
        } catch (Exception unhandledException) {
            Logger.logNow('ZuoraPaymentPageController', 'makePayment', unhandledException.getMessage(), 'ERROR');
        }
        return result;
    }

    @AuraEnabled
    public static Boolean handleGeneralUpdate(String method, Object itemToUpdate) {
        Boolean isSuccess = false;
        try {
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/action/update', itemToUpdate, true);
            List<ZuoraAPI.SaveResult> result = (List<ZuoraAPI.SaveResult>) System.JSON.deserialize(response.getBody(), List<ZuoraAPI.SaveResult>.class);
            if (result[0].Success) {
                isSuccess = true;
            } else {
                String customErrorMessage =
                    'Object: ' + String.valueOf(itemToUpdate) +
                    ' Zuora Error Message: ' + String.valueOf(result[0].Errors);
                Logger.logNow('ZuoraPaymentPageController', method, customErrorMessage, 'ERROR');
            }
        } catch (Exception unhandledException) {
            Logger.logNow('ZuoraPaymentPageController', method, unhandledException.getMessage(), 'ERROR');
        }
        return isSuccess;
    }

    @AuraEnabled
    public static Boolean linkPaymentMethodToAccount(String zuoraAccountId, String paymentMethodId) {
        ZuoraAPI.PaymentMethod payMethodToUpdate = new ZuoraAPI.PaymentMethod();
        payMethodToUpdate.Id = paymentMethodId;
        payMethodToUpdate.AccountId = zuoraAccountId;

        ZuoraAPI.ActionItems item = new ZuoraAPI.ActionItems();
        item.type = 'PaymentMethod';
        item.objects = new List<Object>{payMethodToUpdate};

        return handleGeneralUpdate('linkPaymentMethodToAccount',item);
    }

    @AuraEnabled
    public static Boolean toggleAutopayAndPaymentMethod(String zuoraAccountId, Boolean autopaySelection, String paymentMethodId) {
        ZuoraAPI.ZuoraAccount accountToUpdate = new ZuoraAPI.ZuoraAccount();
        accountToUpdate.Id = zuoraAccountId;
        accountToUpdate.AutoPay = autopaySelection;
        if (paymentMethodId != null){
            accountToUpdate.DefaultPaymentMethodId = paymentMethodId;
        }

        ZuoraAPI.ActionItems item = new ZuoraAPI.ActionItems();
        item.type = 'Account';
        item.objects = new List<Object>{accountToUpdate};

        return handleGeneralUpdate('toggleAutopayAndPaymentMethod',item);
    }
}