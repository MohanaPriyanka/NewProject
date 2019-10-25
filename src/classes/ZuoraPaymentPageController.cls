/*************************************************************************************
 * Created By: peteryao on 2019-04-11  
 * Description: 
 * Test: 
 *************************************************************************************/

public with sharing class ZuoraPaymentPageController {
    @AuraEnabled
    public static PaymentPageMetadata getPageMetadataWithDomain(String domain) {
        PaymentPageMetadata pageMetadata = new PaymentPageMetadata();
        pageMetadata.zuoraSetting = ZuoraAPIHelper.getZuoraSetting();
        Map<String, Object> ccJsonBody = new Map<String, Object>();
        ccJsonBody.put('method', 'POST');
        ccJsonBody.put('pageId', getHostedPaymentPageId(domain, true, pageMetadata.zuoraSetting));
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
        achJsonBody.put('pageId', getHostedPaymentPageId(domain, false, pageMetadata.zuoraSetting));
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
        pageMetadata.ccPaymentPageId = getHostedPaymentPageId(domain, true, pageMetadata.zuoraSetting);
        pageMetadata.achPaymentPageId = getHostedPaymentPageId(domain, false, pageMetadata.zuoraSetting);
        return pageMetadata;
    }

    @TestVisible
    private static String getHostedPaymentPageId(String domain, Boolean creditCard, Zuora_Setting__mdt zuoraSetting) {
        // Hosted Payment Pages are domain specific
        // Eg.) bluewavememberportal.force.com (community) or bluewavesolar.lightning.force.com (internal)
        if (domain.contains('lightning.force.com') && creditCard){
            return zuoraSetting.CC_Payment_Page_Id_Internal__c;
        } else if (domain.contains('lightning.force.com')){
            return zuoraSetting.ACH_Payment_Page_Id_Internal__c;
        } else if (creditCard){
            return zuoraSetting.CC_Payment_Page_Id__c;
        } else {
            return zuoraSetting.ACH_Payment_Page_Id__c;
        }
    }

    public class PaymentPageMetadata {
        @AuraEnabled
        public ZuoraAPI.RSASignature ccRsaSignature;
        @AuraEnabled
        public ZuoraAPI.RSASignature achRsaSignature;
        @AuraEnabled
        public Zuora_Setting__mdt zuoraSetting;
        @AuraEnabled
        public String ccPaymentPageId;
        @AuraEnabled
        public String achPaymentPageId;
    }

    public class PaymentResponse {
        @AuraEnabled
        public String gatewayResponseCode;
        @AuraEnabled
        public String gatewayResponse;
        @AuraEnabled
        // We expect to either see 'Error' or 'Processed' for Declined and Approved electronic transactions respectively,
        // but Status also has other values https://www.zuora.com/developer/api-reference/#operation/POST_CreatePayment
        // https://knowledgecenter.zuora.com/CB_Billing/K_Payment_Operations/Electronic_Payment_Processing
        public String status;
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String accountId;
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
    public static PaymentResponse makePayment(String zuoraAcctId, String gatewayId, String paymentMethodId, Decimal paymentAmount) {
        ZuoraAPI.Payment newPayment = new ZuoraAPI.Payment();
        newPayment.accountId = zuoraAcctId;
        newPayment.paymentMethodId = paymentMethodId;
        newPayment.type = 'Electronic';
        newPayment.gatewayId = gatewayId;
        newPayment.currency_Zreserved = 'USD';
        newPayment.amount = paymentAmount;

        PaymentResponse result;
        try {
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST','/v1/payments',newPayment,true);
            result = (PaymentResponse) System.JSON.deserialize(response.getBody(), PaymentResponse.class);
            if (!result.success) {
                // System error, call not completed:
                String customErrorMessage =
                    'Error making payment for account: ' + zuoraAcctId +
                        ' with paymentAmount: ' + paymentAmount +
                        ' and payment method Id: ' + paymentMethodId;
                Logger.logNow('ZuoraPaymentPageController', 'makePayment', customErrorMessage, 'ERROR');
            } else if (result.status == 'Processed'){
                // Call is completed successfully, and transaction is approved:
                newPayment.id = result.id;
                String paymentAsString = JSON.serialize(newPayment);
                applyPaymentInFuture(paymentAsString);
            } else {
                // Call is completed successfully, but transaction is not approved:
                String customErrorMessage =
                        ' Payment Transaction Not Approved: ' +
                        String.valueOf(result) +
                        ' account: ' + zuoraAcctId +
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

    @Future(callout=true)
    public static void applyPaymentInFuture(String paymentAsString){
        ZuoraAPI.Payment successfulPayment = (ZuoraAPI.Payment) JSON.deserialize(paymentAsString, ZuoraAPI.Payment.class);
        applyPaymentToBalance(successfulPayment);
    }

    @TestVisible
    private static void applyPaymentToBalance(ZuoraAPI.Payment successfulPayment){
        try {
            List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems;
            outstandingItems = ZuoraOutstandingItemsService.getOutstandingItemParentsByDate(successfulPayment.accountId);
            ZuoraAPI.ZuoraPaymentApplication application = applyPaymentToOutstandingItems(outstandingItems, successfulPayment);
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('PUT', '/v1/payments/' + successfulPayment.id + '/apply', application);
            PaymentResponse result = (PaymentResponse) System.JSON.deserialize(response.getBody(), PaymentResponse.class);
            if (!result.success) {
                Logger.logNow('ZuoraPaymentPageController', 'applyPaymentToBalance', 'Failure in Zuora:' + response.getBody() + String.valueOf(successfulPayment), Logger.ERROR);
            }
            Logger.flushLogs();
        } catch (Exception applicationException) {
            Logger.logNow('ZuoraPaymentPageController', 'applyPaymentToBalance', applicationException.getMessage() + applicationException.getStackTraceString(), 'ERROR');
        }
    }

    @TestVisible
    private static ZuoraAPI.ZuoraPaymentApplication applyPaymentToOutstandingItems(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems,
                                                                    ZuoraAPI.Payment payment){
        ZuoraAPI.ZuoraPaymentApplication application = new ZuoraAPI.ZuoraPaymentApplication();
        application.invoices = new List<ZuoraAPI.ZuoraInvoiceApplication>();
        application.debitMemos = new List<ZuoraAPI.ZuoraDebitMemoApplication>();

        Decimal paymentAmount = payment.amount;
        Decimal applicationAmount;
        for (ZuoraOutstandingItemsService.OutstandingItem item : outstandingItems){
            if (paymentAmount == 0){
                break;
            }
            // Don't expect anything in Zuora to have more than 2 decimals,
            // but just to be safe, we never want to apply with more than 2 decimals:
            paymentAmount = paymentAmount.setScale(2, RoundingMode.HALF_UP);
            item.AmountOutstanding = item.AmountOutstanding.setScale(2, RoundingMode.HALF_UP);
            applicationAmount = Math.min(paymentAmount,item.AmountOutstanding);
            paymentAmount -= applicationAmount;
            if (item.IsInvoiceItem){
                ZuoraAPI.ZuoraInvoiceApplication invoice = new ZuoraAPI.ZuoraInvoiceApplication();
                invoice.invoiceId = item.id;
                invoice.amount = applicationAmount;
                application.invoices.add(invoice);
            } else {
                ZuoraAPI.ZuoraDebitMemoApplication debitMemo = new ZuoraAPI.ZuoraDebitMemoApplication();
                debitMemo.debitMemoId = item.id;
                debitMemo.amount = applicationAmount;
                application.debitMemos.add(debitMemo);
            }
        }
        if (paymentAmount > 0){
            Logger.logLater('ZuoraPaymentPageController','applyPaymentToOutstandingItems','Payment was not completely applied: ' + String.valueOf(payment));
        }
        return application;
    }

}