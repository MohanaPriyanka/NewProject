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
        List<ZuoraCreditMemo> zuoraCreditMemos = new List<ZuoraCreditMemo>();

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
        zuoraCreditMemos.add(creditMemo);

        return creditMemo;
    }

    public static String convertZuoraCreditMemoToJSON (ZuoraCreditMemo zuoraCreditMemo) {
        String jsonString = JSON.serialize(zuoraCreditMemo);
        jsonString = jsonString.replace('_Zcustom','__c');
        jsonString = jsonString.removeEnd(']');
        jsonString = jsonString.removeStart('[');
        return jsonString;
    }

    public static HttpResponse creditMemoAPICall(String jsonString){
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('https://rest.apisandbox.zuora.com/v1/creditmemos');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('zuora-version', '224.0');
        request.setHeader('Accept', 'application/json');
        request.setBody(jsonString);
        HttpResponse response;
        if(!Test.isRunningTest()){
            Zuora.zApi zApiInstance = new Zuora.zApi();
            response = zApiInstance.sendRequest(request);
        } else {
            response = mockAPICall();
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

    private static HttpResponse mockAPICall(){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(
            '{ "id" : "2c92c0fa6a3458e1016a45ac238e0d74", ' +
            '"number" : "CM00000049", ' +
            '"accountId" : "2c92c0f869c8e5c50169dfb877685bd8", ' +
            '"currency" : "USD", ' +
            '"creditMemoDate" : "2019-04-22", ' +
            '"targetDate" : null, ' +
            '"postedById" : null, ' +
            '"postedOn" : null, ' +
            '"status" : "Draft", ' +
            '"amount" : 34.00, ' +
            '"taxAmount" : 0.00, ' +
            '"totalTaxExemptAmount" : 0.00, ' +
            '"unappliedAmount" : 34.00, ' +
            '"refundAmount" : 0E-9, ' +
            '"appliedAmount" : 0E-9, ' +
            '"comment" : "Comment", ' +
            '"source" : "AdhocFromPrpc", ' +
            '"sourceId" : null, ' +
            '"referredInvoiceId" : null, ' +
            '"reasonCode" : "BW - Initiated Credit", ' +
            '"createdDate" : "2019-04-22 15:31:10", ' +
            '"createdById" : "2c92c0f968a20f350168ca0efb2309e7", ' +
            '"updatedDate" : "2019-04-22 15:31:10", ' +
            '"updatedById" : "2c92c0f968a20f350168ca0efb2309e7", ' +
            '"cancelledOn" : null, "cancelledById" : null, ' +
            '"latestPDFFileId" : null, ' +
            '"Project__c" : "Project A Oak Road", ' +
            '"CRM_ID__c" : "a0p0j00000CwTIHAA3", ' +
            '"transferredToAccounting" : "No", ' +
            '"excludeFromAutoApplyRules" : false, ' +
            '"autoApplyUponPosting" : false, ' +
            '"success" : true }'
        );

        res.setStatusCode(200);
        return res;
    }
}