/*  These methods can only handle 1 record at a time.

Can't use generic create/edit/delete actions
    https://www.zuora.com/developer/api-reference/#tag/Actions
    "Note: Actions do not support the Invoice Settlement feature.
    This feature includes Unapplied Payments, Credit and Debit Memo, and Invoice Item Settlement."

    Tested by: ZuoraCreditDebitMemoServiceTest
*/

public class ZuoraCreditDebitMemoService {
    private static ZuoraInvoiceService invoiceService = new ZuoraInvoiceService();
    @TestVisible
    private static FeatureService featureService = new FeatureService();

    public static Bill_Adjustment__c createCreditOrDebitMemo(Bill_Adjustment__c adjustment, Date effectiveDate){
        if (adjustment.Adjustment_Amount__c < 0){
            return handleCreditMemo(adjustment, effectiveDate);
        } else {
            return handleDebitMemo(adjustment, effectiveDate);
        }
    }

    private static Bill_Adjustment__c handleDebitMemo(Bill_Adjustment__c adjustment, Date effectiveDate) {
        ZuoraAPI.DebitMemo debitMemo;
        HttpResponse response;
        if (featureService.isEnabled('Relate_Debit_Memos_To_Invoices')) {
            try {
                debitMemo = convertSFAdjustToDebitMemoFromInvoice(adjustment, effectiveDate);
                debitMemo.effectiveDate = effectiveDate;
                response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/invoices/' + debitMemo.invoiceId + '/debitmemos', debitMemo, false);
            } catch (Util.BWException bwe) {
                Logger.logLater(
                    'ZuoraCreditDebitMemoService',
                    'createCreditOrDebitMemo',
                    'Handle this adjustment manually: ' + bwe.getMessage() + '\n' + bwe.getStackTraceString(),
                    Logger.ERROR
                );
                return null;
            }
        } else {
            debitMemo = convertSFAdjustToDebitMemo(adjustment);
            debitMemo.effectiveDate = effectiveDate;
            response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/debitmemos', debitMemo, false);
        }

        adjustment = handleAPIResponse(
            debitMemo.CRM_ID_Zcustom,
            response,
            false
        );
        return adjustment;
    }

    @TestVisible
    private static Bill_Adjustment__c handleCreditMemo(Bill_Adjustment__c adjustment, Date effectiveDate) {
        ZuoraAPI.CreditMemo creditMemo;
        HttpResponse response;
        try {
            creditMemo = convertSFAdjustToCreditMemo(adjustment);
            creditMemo.effectiveDate = effectiveDate;
            response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/creditmemos', creditMemo, false);
        } catch (Util.BWException bwe) {
            Logger.logLater(
                'ZuoraCreditDebitMemoService',
                'createCreditOrDebitMemo',
                'Handle this adjustment manually: ' + bwe.getMessage() + '\n' + bwe.getStackTraceString(),
                Logger.ERROR
            );
            return null;
        }

        adjustment = handleAPIResponse(
            creditMemo.CRM_ID_Zcustom,
            response,
            true
        );
        return adjustment;
    }

    public static void createAndPostDebitMemos(List<ZuoraAPI.DebitMemo> debitMemos) {
        for (ZuoraAPI.DebitMemo debitMemo : debitMemos) {
            if (featureService.isEnabled('Relate_Debit_Memos_To_Invoices')) {
                HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/invoices/' + debitMemo.invoiceId + '/debitmemos', debitMemo, false);
                ZuoraCreditDebitMemoService.handleAPIResponse(null, response, false);
            } else {
                HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/debitmemos', debitMemo, false);
                ZuoraCreditDebitMemoService.handleAPIResponse(null, response, false);
            }
        }
    }

    private static ZuoraAPI.DebitMemo convertSFAdjustToDebitMemo(Bill_Adjustment__c adjust) {
        ZuoraAPI.DebitMemoCharge debitCharge = new ZuoraAPI.DebitMemoCharge();
        debitCharge.amount = adjust.Adjustment_Amount__c;
        debitCharge.chargeId = getChargeFromAdjustment(adjust);

        ZuoraAPI.DebitMemo debitMemo = new ZuoraAPI.DebitMemo();
        debitMemo.accountId = adjust.Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c;
        debitMemo.Project_Zcustom = adjust.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c;
        debitMemo.ClientOwner_Zcustom = adjust.Client__r.Account_Number__c;
        debitMemo.charges = new List<ZuoraAPI.DebitMemoCharge>{debitCharge};
        debitMemo.CRM_ID_Zcustom = adjust.Id;
        debitMemo.reasonCode = adjust.Adjustment_Type__c;
        return debitMemo;
    }

    // Uses 5 callouts:
    // 3 queries to get the active rate plan charges for this account
    // 1 query to get invoices from the past year
    // 1 query to get invoice items from invoices
    // Plus a callout to create the debit memo and a callout to post it
    @TestVisible
    private static ZuoraAPI.DebitMemo convertSFAdjustToDebitMemoFromInvoice(Bill_Adjustment__c adjust, Date effectiveDate) {
        String accountId = adjust.Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c;
        String client = adjust.Client__r.Account_Number__c;
        String project = adjust.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c;

        ZuoraAPI.DebitMemo debitMemo = new ZuoraAPI.DebitMemo();
        ZuoraAPI.DebitMemoItem debitMemoItem = new ZuoraAPI.DebitMemoItem();
        debitMemoItem.amount = adjust.Adjustment_Amount__c;
        debitMemoItem.skuName = 'Utility Credit';
        debitMemo.items = new List<ZuoraAPI.DebitMemoItem>{debitMemoItem};
        debitMemo.effectiveDate = effectiveDate;
        debitMemo.reasonCode = adjust.Adjustment_Type__c;
        debitMemo.Project_Zcustom = project;
        debitMemo.ClientOwner_Zcustom = client;
        debitMemo.CRM_ID_Zcustom = adjust.Id;

        setDebitMemoInvoiceItem(accountId, debitMemo);
        return debitMemo;
    }

    public static void setDebitMemoInvoiceItem(String accountId, ZuoraAPI.DebitMemo debitMemo) {
        String project = debitMemo.Project_Zcustom;
        String client = debitMemo.ClientOwner_Zcustom;
        String relatedId = debitMemo.CRM_ID_Zcustom;
        Map<String, ZuoraOutstandingItemsService.RatePlanCharge> ratePlanChargesByChargeId =
            ZuoraSubscriptionService.getAllRatePlanChargesByAccountId(accountId);
        List<ZuoraAPI.InvoiceItem> invoiceItems = invoiceService.getRecentItems(accountId);
        invoiceItems.sort();
        for (ZuoraAPI.InvoiceItem invoiceItem : invoiceItems) {
            ZuoraOutstandingItemsService.RatePlanCharge ratePlanCharge = ratePlanChargesByChargeId.get(invoiceItem.chargeId);
            if (ratePlanCharge != null && ratePlanCharge.matches(client, project)) {
                debitMemo.invoiceId = invoiceItem.invoiceId;
                debitMemo.items[0].invoiceItemId = invoiceItem.id;
                break;
            }
        }

        if (debitMemo.invoiceId == null || debitMemo.items[0].invoiceItemId == null) {
            throw new Util.BWException('Could not relate adjustment or payment ' + relatedId +
                ' with client: ' + client + ' and project: ' + project + ' to an invoice.\n' +
                'RatePlanCharges: ' + JSON.serialize(ratePlanChargesByChargeId) + '\n' +
                'InvoiceItems: ' + JSON.serialize(invoiceItems));
        }
    }

    public static ZuoraAPI.CreditMemo convertSFAdjustToCreditMemo(Bill_Adjustment__c adjust) {
        // Credit Memo Application assumes we only have one credit item here:
        ZuoraAPI.CreditCharge chargeLine = new ZuoraAPI.CreditCharge();
        chargeLine.amount = (-1*adjust.Adjustment_Amount__c);
        chargeLine.chargeId = getChargeFromAdjustment(adjust);

        ZuoraAPI.CreditMemo creditMemo = new ZuoraAPI.CreditMemo();
        creditMemo.accountId = adjust.Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c;
        creditMemo.Project_Zcustom = adjust.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c;
        creditMemo.ClientOwner_Zcustom = adjust.Client__r.Account_Number__c;
        creditMemo.charges = new List<ZuoraAPI.CreditCharge>{chargeLine};
        creditMemo.CRM_ID_Zcustom = adjust.Id;
        creditMemo.reasonCode = adjust.Adjustment_Type__c;
        return creditMemo;
    }

    private static String getChargeFromAdjustment(Bill_Adjustment__c adjust){
        String zuoraAcctId = adjust.Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c;
        String client = adjust.Client__r.Account_Number__c;
        String project = adjust.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c;

        if (featureService.isEnabled('Multiple_Subscriptions')) {
            Map<String, ZuoraOutstandingItemsService.RatePlanCharge> ratePlanChargesByChargeId =
                ZuoraSubscriptionService.getAllRatePlanChargesByAccountId(zuoraAcctId);
            for (ZuoraOutstandingItemsService.RatePlanCharge ratePlanCharge : ratePlanChargesByChargeId.values()) {
                if (ratePlanCharge.matches(client, project)) {
                    return ratePlanCharge.ProductRatePlanChargeId;
                }
            }
            throw new Util.BWException('No client/project found for client: ' + client + ' and project '+ project);
        } else {
            ZuoraAPI.OrderBySubscriptionOwner subscription = ZuoraSubscriptionService.getOrderBySubscriptionOwner(zuoraAcctId);
            return subscription.getProductRatePlanChargeId(client, project);
        }
    }

    public static Bill_Adjustment__c handleAPIResponse(String memoCRMId, HttpResponse response, Boolean isCredit){
        ZuoraAPI.GenericResponse zResponse = new ZuoraAPI.GenericResponse();
        zResponse = (ZuoraAPI.GenericResponse)JSON.deserialize(response.getBody(), ZuoraAPI.GenericResponse.class);
        Bill_Adjustment__c adjustToUpdate;

        if (zResponse.success && !String.isBlank(zResponse.Id)) {
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
            String errorMessage = 'Memo did not successfully create: ' + memoCRMId + '\n' + response.getBody();
            throw new Util.BWException(errorMessage);
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

    public static void beforeAdjustmentUpdate(List<Bill_Adjustment__c> adjustmentsToCheck){
        Boolean adjustmentsToUpload = false;

        for (Bill_Adjustment__c adjust : adjustmentsToCheck){
            if (adjust.Approval_Status__c == 'Approved'
                && adjust.Effective__c == 'Post When Approved'
                && adjust.Zuora_Id__c == null){
                adjustmentsToUpload = true;
                break;
            }
        }

        if (adjustmentsToUpload){
            ZuoraCreditMemoBatchSend batchSend = new ZuoraCreditMemoBatchSend();
            batchSend.mode = ZuoraCreditMemoBatchSend.AdjustmentType.PostWhenApproved;
            batchSend.executeBatch();
        }
    }
}