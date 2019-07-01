/*  These methods can only handle 1 record at a time.

Can't use generic create/edit/delete actions
    https://www.zuora.com/developer/api-reference/#tag/Actions
    "Note: Actions do not support the Invoice Settlement feature.
    This feature includes Unapplied Payments, Credit and Debit Memo, and Invoice Item Settlement." */

public class ZuoraCreditDebitMemoService{

    public static ZuoraAPI.CreditMemo convertSFAdjustToCreditMemo (Bill_Adjustment__c adjust){
        String zuoraAcctId = adjust.UASB__r.Opportunity__r.Account.Zuora_Id__c;

        ZuoraAPI.OrderBySubscriptionOwner subscription = ZuoraSubscriptionService.getOrderBySubscriptionOwner(zuoraAcctId);
        String chargeId = subscription.getProductRatePlanChargeId(
            adjust.Client__r.Account_Number__c,
            adjust.UASB__r.Shared_Solar_System__r.Unique_ID__c
        );

        // Credit Memo Application assumes we only have one credit item here:
        ZuoraAPI.CreditCharge chargeLine = new ZuoraAPI.CreditCharge();
        chargeLine.amount = (-1*adjust.Adjustment_Amount__c);
        chargeLine.chargeId = chargeId;

        ZuoraAPI.CreditMemo creditMemo = new ZuoraAPI.CreditMemo();
        creditMemo.accountId = zuoraAcctId;
        creditMemo.effectiveDate = adjust.UASB__r.Date__c;
        creditMemo.Project_Zcustom = adjust.UASB__r.Shared_Solar_System__r.Unique_ID__c;
        creditMemo.ClientOwner_Zcustom = adjust.Client__r.Account_Number__c;
        creditMemo.charges = new List<ZuoraAPI.CreditCharge>{chargeLine};
        creditMemo.CRM_ID_Zcustom = adjust.Id;
        creditMemo.reasonCode = adjust.Adjustment_Type__c;
        return creditMemo;
    }

    public static HttpResponse creditMemoAPICall(ZuoraAPI.CreditMemo creditMemo){
        HttpResponse response;
        if(!Test.isRunningTest()){
            response = ZuoraAPIHelper.callJSONEndpoint('POST','/v1/creditmemos',creditMemo,false);
        } else {
            response = ZuoraAPIMock.postCreditMemo();
        }
        return response;
    }

    public static Bill_Adjustment__c handleAPIResponse(ZuoraAPI.CreditMemo attemptedCreditMemo, HttpResponse response){
        ZuoraAPI.GenericResponse zResponse = new ZuoraAPI.GenericResponse();
        zResponse = (ZuoraAPI.GenericResponse)JSON.deserialize(response.getBody(), ZuoraAPI.GenericResponse.class);
        Bill_Adjustment__c adjustToUpdate;

        if (zResponse.Success){
            adjustToUpdate = new Bill_Adjustment__c(
                Id = attemptedCreditMemo.CRM_ID_Zcustom,
                Zuora_Id__c = zResponse.Id
            );
            postCreditMemo(zResponse.Id);
        } else {
            String errorMessage = attemptedCreditMemo.CRM_ID_Zcustom + '_' + String.valueOf(zResponse.reasons);
            Logger.logLater('ZuoraCreditDebitMemoService', 'handleAPIResponse', errorMessage);
        }
        return adjustToUpdate;
    }

    public static void postCreditMemo(String creditMemoId){
        String urlParam = '/v1/creditmemos/'+ creditMemoId + '/post';
        ZuoraAPIHelper.callJSONEndpoint('POST',urlParam,null,false);
    }
}