/*  These methods can only handle 1 record at a time.

Can't use generic create/edit/delete actions
    https://www.zuora.com/developer/api-reference/#tag/Actions
    "Note: Actions do not support the Invoice Settlement feature.
    This feature includes Unapplied Payments, Credit and Debit Memo, and Invoice Item Settlement." */

public class ZuoraCreditDebitMemoService{

    public static ZuoraAPI.CreditMemo convertSFAdjustToCreditMemo (Bill_Adjustment__c adjust){
        if (adjust.Adjustment_Amount__c < 0){
            ZuoraAPI.CreditCharge chargeLine = new ZuoraAPI.CreditCharge();
            chargeLine.Amount = (-1*adjust.Adjustment_Amount__c);
            chargeLine.ChargeId = adjust.UASB__r.Utility_Account_Subscription__r.Subscription_Rate_Plan_Charge__r.Zuora__OriginalProductRatePlanChargeId__c;

            ZuoraAPI.CreditMemo creditMemo = new ZuoraAPI.CreditMemo();
            creditMemo.accountId = adjust.UASB__r.Utility_Account_Subscription__r.Subscription_Rate_Plan_Charge__r.Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c;
            creditMemo.effectiveDate = adjust.UASB__r.Date__c;
            creditMemo.Project_Zcustom = adjust.UASB__r.Shared_Solar_System__r.Unique_ID__c;
            creditMemo.charges = new List<ZuoraAPI.CreditCharge>{chargeLine};
            creditMemo.CRM_ID_Zcustom = adjust.Id;
            creditMemo.reasonCode = adjust.Adjustment_Type__c;
            return creditMemo;
        } else {
            return null;
        }
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
        } else {
            String errorMessage = attemptedCreditMemo.CRM_ID_Zcustom + '_' + String.valueOf(zResponse.reasons);
            Logger.logLater('ZuoraCreditDebitMemoService', 'handleAPIResponse', errorMessage);
        }
        return adjustToUpdate;
    }
}