/*  These methods can only handle 1 record at a time.

Can't use generic create/edit/delete actions
    https://www.zuora.com/developer/api-reference/#tag/Actions
    "Note: Actions do not support the Invoice Settlement feature.
    This feature includes Unapplied Payments, Credit and Debit Memo, and Invoice Item Settlement."

    Tested by: ZuoraCreditDebitMemoServiceTest
*/

public class ZuoraCreditDebitMemoService{
    public static Bill_Adjustment__c createCreditOrDebitMemo(Bill_Adjustment__c adjustment){
        if (adjustment.Adjustment_Amount__c < 0){
            ZuoraAPI.CreditMemo creditMemo;
            creditMemo = convertSFAdjustToCreditMemo(adjustment);
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST','/v1/creditmemos',creditMemo,false);
            adjustment = handleAPIResponse(
                creditMemo.CRM_ID_Zcustom,
                response,
                true
            );
        } else {
            ZuoraAPI.DebitMemo debitMemo;
            debitMemo = convertSFAdjustToDebitMemo(adjustment);
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST','/v1/debitmemos',debitMemo,false);
            adjustment = handleAPIResponse(
                debitMemo.CRM_ID_Zcustom,
                response,
                false
            );
        }
        return adjustment;
    }

    public static void createAndPostDebitMemos(List<ZuoraAPI.DebitMemo> debitMemos) {
        for (ZuoraAPI.DebitMemo debitMemo : debitMemos) {
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/debitmemos', debitMemo, false);
            ZuoraCreditDebitMemoService.handleAPIResponse(null, response, false);
        }
    }

    public static ZuoraAPI.DebitMemo convertSFAdjustToDebitMemo(Bill_Adjustment__c adjust) {
        ZuoraAPI.DebitMemoCharge debitCharge = new ZuoraAPI.DebitMemoCharge();
        debitCharge.amount = adjust.Adjustment_Amount__c;
        debitCharge.chargeId = getChargeFromAdjustment(adjust);

        ZuoraAPI.DebitMemo debitMemo = new ZuoraAPI.DebitMemo();
        debitMemo.accountId = adjust.Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c;
        debitMemo.effectiveDate = adjust.UASB__r.Date__c;
        debitMemo.Project_Zcustom = adjust.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c;
        debitMemo.ClientOwner_Zcustom = adjust.Client__r.Account_Number__c;
        debitMemo.charges = new List<ZuoraAPI.DebitMemoCharge>{debitCharge};
        debitMemo.CRM_ID_Zcustom = adjust.Id;
        debitMemo.reasonCode = adjust.Adjustment_Type__c;
        return debitMemo;
    }

    public static ZuoraAPI.CreditMemo convertSFAdjustToCreditMemo (Bill_Adjustment__c adjust){
        // Credit Memo Application assumes we only have one credit item here:
        ZuoraAPI.CreditCharge chargeLine = new ZuoraAPI.CreditCharge();
        chargeLine.amount = (-1*adjust.Adjustment_Amount__c);
        chargeLine.chargeId = getChargeFromAdjustment(adjust);

        ZuoraAPI.CreditMemo creditMemo = new ZuoraAPI.CreditMemo();
        creditMemo.accountId = adjust.Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c;
        creditMemo.effectiveDate = adjust.UASB__r.Date__c;
        creditMemo.Project_Zcustom = adjust.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c;
        creditMemo.ClientOwner_Zcustom = adjust.Client__r.Account_Number__c;
        creditMemo.charges = new List<ZuoraAPI.CreditCharge>{chargeLine};
        creditMemo.CRM_ID_Zcustom = adjust.Id;
        creditMemo.reasonCode = adjust.Adjustment_Type__c;
        return creditMemo;
    }

    public static String getChargeFromAdjustment(Bill_Adjustment__c adjust){
        String zuoraAcctId = adjust.Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c;

        ZuoraAPI.OrderBySubscriptionOwner subscription = ZuoraSubscriptionService.getOrderBySubscriptionOwner(zuoraAcctId);
        return subscription.getProductRatePlanChargeId(
            adjust.Client__r.Account_Number__c,
            adjust.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c
        );
    }

    public static Bill_Adjustment__c handleAPIResponse(String memoCRMId, HttpResponse response, Boolean isCredit){
        ZuoraAPI.GenericResponse zResponse = new ZuoraAPI.GenericResponse();
        zResponse = (ZuoraAPI.GenericResponse)JSON.deserialize(response.getBody(), ZuoraAPI.GenericResponse.class);
        Bill_Adjustment__c adjustToUpdate;

        if (zResponse.success){
            adjustToUpdate = new Bill_Adjustment__c(
                Id = memoCRMId,
                Zuora_Id__c = zResponse.Id
            );
            if (isCredit){
                postCreditMemo(zResponse.Id);
            } else {
                postDebitMemo(zResponse.Id);
            }
        } else {
            String errorMessage = memoCRMId + '_' + String.valueOf(zResponse.reasons);
            Logger.logLater('ZuoraCreditDebitMemoService', 'handleAPIResponse', errorMessage);
        }
        return adjustToUpdate;
    }

    public static void postCreditMemo(String creditMemoId){
        String urlParam = '/v1/creditmemos/'+ creditMemoId + '/post';
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST',urlParam,null,false);
        ZuoraAPI.ZuoraCreditMemo creditMemo = (ZuoraAPI.ZuoraCreditMemo) JSON.deserialize(ZuoraAPIHelper.cleanJSON(response.getBody()), ZuoraAPI.ZuoraCreditMemo.class);
        if (creditMemo.id == null) {
            throw new Util.FatalBWException('Credit memo post failed: ' + response.getBody());
        }
    }

    public static void postDebitMemo(String debitMemoId){
        String urlParam = '/v1/debitmemos/'+ debitMemoId + '/post';
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST',urlParam,null,false);
        ZuoraAPI.ZuoraDebitMemo debitMemo = (ZuoraAPI.ZuoraDebitMemo) JSON.deserialize(ZuoraAPIHelper.cleanJSON(response.getBody()), ZuoraAPI.ZuoraDebitMemo.class);
        if (debitMemo.id == null) {
            throw new Util.FatalBWException('Debit memo post failed: ' + response.getBody());
        }
    }
}