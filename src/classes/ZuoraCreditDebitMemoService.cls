/*  These methods can only handle 1 record at a time.

Can't use generic create/edit/delete actions
    https://www.zuora.com/developer/api-reference/#tag/Actions
    "Note: Actions do not support the Invoice Settlement feature.
    This feature includes Unapplied Payments, Credit and Debit Memo, and Invoice Item Settlement." */

public class ZuoraCreditDebitMemoService implements Database.AllowsCallouts{

    public class ZuoraCreditMemo {
        public String accountId;
        public List<ZuoraCreditCharge> charges;
        public Date effectiveDate;
        public String reasonCode;
        public String Project_Zcustom;
        public String CRM_ID_Zcustom;
    }

    public class ZuoraCreditCharge {
        public Decimal amount;
        public String chargeId;
    }

    public class ZuoraResponse {
        public String Id;
        public Boolean Success;
        public List<ZuoraError> reasons;
    }

    public class ZuoraError {
        public String Code;
        public String Message;
    }

    public static ZuoraCreditMemo convertSFAdjustToCreditMemo (Bill_Adjustment__c adjust){
        ZuoraCreditCharge chargeLine = new ZuoraCreditCharge();
        chargeLine.Amount = adjust.Adjustment_Amount__c;
        chargeLine.ChargeId = adjust.UASB__r.Utility_Account_Subscription__r.SRPC__r.Zuora__OriginalProductRatePlanChargeId__c;

        ZuoraCreditMemo creditMemo = new ZuoraCreditMemo();
        creditMemo.AccountId = adjust.UASB__r.Utility_Account_Subscription__r.SRPC__r.Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c;
        creditMemo.EffectiveDate = adjust.UASB__r.Date__c;
        creditMemo.Project_Zcustom = adjust.UASB__r.Shared_Solar_System__r.SSS_Unique_ID__c;
        creditMemo.Charges = new List<ZuoraCreditCharge>{chargeLine};
        creditMemo.CRM_ID_Zcustom = adjust.Id;
        if (adjust.Adjustment_Type__c == 'Client Credit'){
            creditMemo.ReasonCode = 'Client Credit';
        } else if (adjust.Adjustment_Type__c == 'BW Credit'){
            creditMemo.ReasonCode = 'BW - Initiated Credit';
        }
        return creditMemo;
    }

    public static HttpResponse creditMemoAPICall(ZuoraCreditMemo creditMemo){
        HttpResponse response;
        if(!Test.isRunningTest()){
            response = ZuoraAPIHelper.callJSONEndpoint('POST','/v1/creditmemos',creditMemo,false);
        } else {
            response = ZuoraAPIMock.postCreditMemo();
        }
        return response;
    }

    public static Bill_Adjustment__c handleAPIResponse(ZuoraCreditMemo attemptedCreditMemo, HttpResponse response){
        ZuoraResponse zResponse = new ZuoraResponse();
        zResponse = (ZuoraResponse)JSON.deserialize(response.getBody(), ZuoraResponse.class);
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