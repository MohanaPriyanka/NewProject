/**
 * Created by PeterYao on 8/26/2019.
 * Tested by: ZuoraReturnedPaymentServiceTest
 */

public with sharing class ZuoraReturnedPaymentService implements Queueable, Database.AllowsCallouts {
    @TestVisible private static FeatureService featureService = new FeatureService();
    @TestVisible private static ZuoraPaymentSelector paymentSelector = new ZuoraPaymentSelector();
    private static ZuoraPaymentMethodSelector paymentMethodSelector = new ZuoraPaymentMethodSelector();
    private Zuora__PaymentMethod__c payMethod;
    @TestVisible private List<Id> paymentIdsToReturn;
    @TestVisible private static ZuoraReturnedPaymentService chainedReturnedPaymentService;

    /**
     * @description Default constructor
     */
    public ZuoraReturnedPaymentService() {
    }

    /**
     * @description Constructor used when returning multiple payments
     * @param returnedPaymentIds List of Salesforce payment Ids to return
     */
    public ZuoraReturnedPaymentService(List<Id> returnedPaymentIds) {
        this.paymentIdsToReturn = returnedPaymentIds;
    }

    /**
     * @description To avoid callout limits when returning payments in bulk, returns the first payment in paymentsToReturn
     * and then queues itself to return the rest
     * @param context QueueableContext
     */
    public void execute(QueueableContext context) {
        if (paymentIdsToReturn.isEmpty()) {
            return;
        }

        try {
            PaymentReturnResult result = performReturn(paymentIdsToReturn[0]);
            if (!result.success) {
                Logger.logLater('ZuoraReturnedPaymentService', 'execute', 'Coulpd not return paymentId ' + paymentIdsToReturn[0] + '\n', Logger.ERROR);
            }
        } catch (Exception e) {
            Logger.logLater('ZuoraReturnedPaymentService', 'execute', e.getMessage() + '\n' + e.getStackTraceString() + '\n' + paymentIdsToReturn, Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }

        paymentIdsToReturn.remove(0);
        ZuoraReturnedPaymentService paymentServiceToQueue = new ZuoraReturnedPaymentService(paymentIdsToReturn);
        if (!paymentIdsToReturn.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(paymentServiceToQueue);
        } else {
            chainedReturnedPaymentService = paymentServiceToQueue;
        }

    }

    /**
     * @description Reverses payments that are found to be returned by leaving the payment as applied, but creating a
     * new debit memo with the current effective date. Will affect aging, since the original payment is left applied.
     * @param salesforcePaymentId Salesforce Payment Id to return
     * @return result of the return, suitable for displaying to user
     */
    public PaymentReturnResult performReturn(Id salesforcePaymentId) {
        List<Zuora__Payment__c> paymentsToReturn = paymentSelector.selectById(new Set<Id>{salesforcePaymentId});
        if (paymentsToReturn.size() != 1) {
            ZuoraReturnedPaymentService.PaymentReturnResult paymentReturnResult =
                new ZuoraReturnedPaymentService.PaymentReturnResult();
            paymentReturnResult.message = 'Expected a single Zuora Payment record to reverse';
            paymentReturnResult.success = false;
            return paymentReturnResult;
        }
        Zuora__Payment__c paymentToReturn = paymentsToReturn[0];
        ZuoraAPI.Payment zuoraPayment = checkIfPaymentIsAlreadyReturned(paymentToReturn.Zuora__EXT_ID__c);
        PaymentReturnResult paymentReturnResult = executeMarkPaymentAsReturned(zuoraPayment, paymentToReturn);
        insertCaseForReturns(paymentToReturn);
        Logger.flushLogs();
        return paymentReturnResult;
    }

    @TestVisible
    private ZuoraAPI.Payment checkIfPaymentIsAlreadyReturned(String paymentId) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/payments/' + paymentId, null, false);
        ZuoraAPI.Payment payment = (ZuoraAPI.Payment) JSON.deserialize(ZuoraAPIHelper.cleanJSON(response.getBody()), ZuoraAPI.Payment.class);
        // Response status can be Approved, Declined, Error, RETURNED, Voided for history, or blank for payments just coming from Zuora
        // So the Zuora Payment should have a response status of blank or Approved to be returned
        if (!String.isBlank(payment.ResponseStatus_Zcustom) && !(payment.ResponseStatus_Zcustom == 'Approved')) {
            throw new Util.FatalBWException('This payment is already marked as returned: ' + payment);
        }
        return payment;
    }

    /**
     * @description Converts each payment part items of a single payment into debit memos that can then be created and posted in Zuora
     * @param payment the payment for which debit memos should be created
     * @return List of DebitMemos that can be created and posted in Zuora
     */
    @TestVisible
    private List<ZuoraAPI.DebitMemo> convertPaymentToDebitMemos(ZuoraAPI.Payment payment) {
        HttpResponse response;
        ZuoraAPI.OrderBySubscriptionOwner subscription;
        if (featureService.isEnabled('Relate_Debit_Memos_To_Invoices')) {
            // We don't create debit memos from a subscription charge, so we don't need the subscription
        } else {
            subscription = ZuoraSubscriptionService.getOrderBySubscriptionOwner(payment.accountId);
        }
        response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/payments/'+ payment.id +'/parts', null, false);
        ZuoraAPI.PaymentParts paymentParts =
            (ZuoraAPI.PaymentParts) JSON.deserialize(response.getBody(), ZuoraAPI.PaymentParts.class);

        List<ZuoraAPI.DebitMemo> debitMemos = new List<ZuoraAPI.DebitMemo>();
        for (ZuoraAPI.PaymentPart paymentPart : paymentParts.parts) {
            response = ZuoraAPIHelper.callJsonEndpoint(
                'GET',
                '/v1/payments/' + payment.id + '/parts/' + paymentPart.id + '/itemparts',
                null,
                false
            );
            ZuoraAPI.PaymentPartItems paymentPartItems =
                (ZuoraAPI.PaymentPartItems) JSON.deserialize(response.getBody(), ZuoraAPI.PaymentPartItems.class);
            for (ZuoraAPI.PaymentPartItem paymentPartItem : paymentPartItems.itemParts) {
                // There's a payment part for unapplied items as well that this should ignore (since invoiceItemId is null
                // and debitMemoItemId is null). We definitely don't want to assume that if one is null, the other is
                // populated
                if (paymentPartItem.invoiceItemId != null) {
                    debitMemos.add(getDebitMemoFromInvoiceItem(paymentPartItem, subscription, payment));
                }
                if (paymentPartItem.debitMemoItemId != null) {
                    debitMemos.add(getDebitMemoFromDebitMemoItem(paymentPart.debitMemoId, subscription, paymentPartItem, payment));
                }
            }
        }
        return debitMemos;
    }

    private ZuoraAPI.DebitMemo getDebitMemoFromDebitMemoItem(String debitMemoId, ZuoraAPI.OrderBySubscriptionOwner subscription, ZuoraAPI.PaymentPartItem paymentPartItem, ZuoraAPI.Payment payment) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/debitmemos/' + debitMemoId, null, false);
        ZuoraAPI.ZuoraDebitMemo appliedDebitMemo = (ZuoraAPI.ZuoraDebitMemo) JSON.deserialize(ZuoraAPIHelper.cleanJSON(response.getBody()), ZuoraAPI.ZuoraDebitMemo.class);
        ZuoraAPI.DebitMemo debitMemo;
        if (featureService.isEnabled('Relate_Debit_Memos_To_Invoices')) {
            debitMemo = getDebitMemoTemplateFromPayment(paymentPartItem, null, payment, appliedDebitMemo.Project_Zcustom, appliedDebitMemo.ClientOwner_Zcustom);
        } else {
            String productRatePlanChargeId =
                subscription.getProductRatePlanChargeId(appliedDebitMemo.ClientOwner_Zcustom, appliedDebitMemo.Project_Zcustom);
            debitMemo = getDebitMemoTemplateFromPayment(paymentPartItem, productRatePlanChargeId, payment, appliedDebitMemo.Project_Zcustom, appliedDebitMemo.ClientOwner_Zcustom);
        }
        return debitMemo;
    }

    // Uses up to seven callouts, invoice-item, rate-plan-charge, and then to associate the DM to an old invoice item
    private ZuoraAPI.DebitMemo getDebitMemoFromInvoiceItem(ZuoraAPI.PaymentPartItem paymentPartItem, ZuoraAPI.OrderBySubscriptionOwner subscription, ZuoraAPI.Payment payment) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/object/invoice-item/' + paymentPartItem.invoiceItemId, null, false);
        ZuoraAPI.InvoiceItem invoiceItem = (ZuoraAPI.InvoiceItem) JSON.deserialize(response.getBody(), ZuoraAPI.InvoiceItem.class);
        response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/object/rate-plan-charge/' + invoiceItem.RatePlanChargeId + '?fields=Project__c,ClientOwner__c', null, false);
        ZuoraAPI.RatePlanCharge ratePlanCharge =
            (ZuoraAPI.RatePlanCharge) JSON.deserialize(ZuoraAPIHelper.cleanJSON(response.getBody()), ZuoraAPI.RatePlanCharge.class);
        ZuoraAPI.DebitMemo debitMemo;
        if (featureService.isEnabled('Relate_Debit_Memos_To_Invoices')) {
            debitMemo = getDebitMemoTemplateFromPayment(paymentPartItem, null, payment, ratePlanCharge.Project_Zcustom, ratePlanCharge.ClientOwner_Zcustom);
        } else {
            String productRatePlanChargeId =
                subscription.getProductRatePlanChargeId(ratePlanCharge.ClientOwner_Zcustom, ratePlanCharge.Project_Zcustom);
            debitMemo = getDebitMemoTemplateFromPayment(paymentPartItem, productRatePlanChargeId, payment, ratePlanCharge.Project_Zcustom, ratePlanCharge.ClientOwner_Zcustom);
        }
        return debitMemo;
    }

    private ZuoraAPI.DebitMemo getDebitMemoTemplateFromPayment(ZuoraAPI.PaymentPartItem paymentPartItem, String productRatePlanChargeId, ZuoraAPI.Payment payment, String project, String client) {
        Map<String,String> gatewayNameFromIdMap = gatewayNameFromGatewayIdMap();

        ZuoraAPI.DebitMemo debitMemo = new ZuoraAPI.DebitMemo();
        debitMemo.effectiveDate = System.today();
        debitMemo.Project_Zcustom = project;
        debitMemo.ClientOwner_Zcustom = client;
        debitMemo.CRM_ID_Zcustom = payment.number_Zreserved;
        if (featureService.isEnabled('Relate_Debit_Memos_To_Invoices')) {
            ZuoraAPI.DebitMemoItem debitMemoItem = new ZuoraAPI.DebitMemoItem();
            debitMemoItem.amount = paymentPartItem.amount;
            debitMemoItem.skuName = 'Utility Credit';
            debitMemo.items = new List<ZuoraAPI.DebitMemoItem>{debitMemoItem};
            ZuoraCreditDebitMemoService.setDebitMemoInvoiceItem(payment.accountId, debitMemo);
        } else {
            ZuoraAPI.DebitMemoCharge debitCharge = new ZuoraAPI.DebitMemoCharge();
            debitCharge.amount = paymentPartItem.amount;
            debitCharge.chargeId = productRatePlanChargeId;
            debitMemo.accountId = payment.accountId;
            debitMemo.charges = new List<ZuoraAPI.DebitMemoCharge>{debitCharge};
        }
        debitMemo.reasonCode = 'Returned Payment';
        debitMemo.comment = 'Original Payment ' + payment.id + ', PaymentPartItem ' + paymentPartItem.id;
        // Stamp payment values for later use in GL download:
        debitMemo.ArchivedChargentData_Zcustom = payment.ArchivedChargentData_Zcustom;
        debitMemo.Gateway_Zcustom = gatewayNameFromIdMap.get(payment.gatewayId);
        debitMemo.Lockbox_Zcustom = payment.Lockbox_zcustom;

        List<Zuora__PaymentMethod__c> methods = paymentMethodSelector.getSFRecordFromZuoraId(new List<String>{payment.paymentMethodId});
        if (methods.size() > 0){
            payMethod = methods[0];
            debitMemo.PaymentMethod_Zcustom = payMethod.Zuora__Type__c;
        }
        return debitMemo;
    }

    /**
     * @description Updates the Zuora payment's Response Status to be "Returned"
     * @param paymentId The Zuora Id of the Payment to mark returned
     */
    private void markPaymentReturned(String paymentId) {
        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        payment.ResponseStatus_Zcustom = 'Returned';
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('PUT', '/v1/payments/' + paymentId, payment, false);
        ZuoraAPI.GenericResponse genericResponse = (ZuoraAPI.GenericResponse) JSON.deserialize(response.getBody(), ZuoraAPI.GenericResponse.class);
        if (!genericResponse.success) {
            throw new Util.BWException('Did not mark payment ' + paymentId + 'as Returned:\n' + response.getBody());
        }
    }

    /**
     * @description Updates the Zuora account to remove the payment method as default for the payment provided
     * @param returnedPayment A payment (presumably with a payment method that does not work)
     * @return True, if the payment method was removed from the account
     */
    @TestVisible
    private Boolean removePaymentMethodFromAccount(Zuora__Payment__c returnedPayment) {
        String zuoraAcctId = returnedPayment.Zuora__BillingAccount__r.Zuora__Zuora_Id__c;
        Boolean paymentMethodUpdateNeeded = false;
        ZuoraAccountSelector selector = new ZuoraAccountSelector();
        ZuoraAPI.ZuoraAccount accountFromZuora = selector.getAccountFromZuora(zuoraAcctId);

        // If they've already provided a new payment method, we don't want to overwrite it:
        if (accountFromZuora.DefaultPaymentMethodId == returnedPayment.Zuora__PaymentMethodId__c){
            ZuoraAPI.ZuoraAccount account = new ZuoraAPI.ZuoraAccount();
            account.Id = zuoraAcctId;
            account.AutoPay = false;
            account.DefaultPaymentMethodId = ZuoraPaymentMethodSelector.getDefaultPaymentMethodId();

            ZuoraAPI.ActionItems items = new ZuoraAPI.ActionItems();
            items.type = 'Account';
            items.objects = new List<ZuoraAPI.ZuoraAccount>{account};
            ZuoraAPIHelper.actionUpdate(items);
            paymentMethodUpdateNeeded = true;
        }
        return paymentMethodUpdateNeeded;
    }

    /**
     * @description Creates a case for Customer Care related to a returned payment
     * @param zuoraPayment The payment related to the case
     * @return A case ready to be inserted
     */
    private Case insertCaseForReturns(Zuora__Payment__c zuoraPayment) {
        List<Zuora__PaymentMethod__c> paymentMethods =
            paymentMethodSelector.getSFRecordFromZuoraId(new List<String>{zuoraPayment.Zuora__PaymentMethodId__c});
        CaseFactory caseFactory = new CaseFactory();
        Case newCase = caseFactory.getCase('Customer_Care');
        newCase.Subject = 'Customer Transaction Marked as Returned';
        newCase.Priority = 'Medium';
        newCase.Product_Line__c = 'Community Solar';
        newCase.Category__c = 'Billing-Issue';
        newCase.Description = 'This transaction was marked as returned. There may be followup required with the customer to resolve issues with their payment method.';
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'BlueWave';
        newCase.Disable_Followup_Email__c = true;
        newCase.AccountId = zuoraPayment.Zuora__BillingAccount__r.Zuora__Account__c;
        if (paymentMethods.size() == 1) {
            newCase.Zuora_Payment_Method__c = paymentMethods[0].Id;
        } else {
            Logger.logLater('ZuoraReturnedPaymentService','getPaymentMethod','When creating a returned payment case, expected one payment method for this payment but got ' +
                paymentMethods.size() + '\n' + JSON.serializePretty(zuoraPayment));
        }

        insert newCase;
        return newCase;
    }

    private Map<String, String> gatewayNameFromGatewayIdMap(){
        Map<String, String> gatewayIdNameMap = new Map<String, String>();
        GatewaySelector gatewaySelector = new GatewaySelector();
        List<Zuora__PaymentGateway__c> zuoraGateways = gatewaySelector.getAllZuoraGateways();

        for (Zuora__PaymentGateway__c zuoraGateway : zuoraGateways){
            gatewayIdNameMap.put(
                zuoraGateway.Zuora__External_Id__c,
                zuoraGateway.Name
            );
        }
        return gatewayIdNameMap;
    }

    private PaymentReturnResult executeMarkPaymentAsReturned(ZuoraAPI.Payment zuoraPayment, Zuora__Payment__c sfPayment) {
        PaymentReturnResult paymentReturnResult = new PaymentReturnResult();
        try {
            List<ZuoraAPI.DebitMemo> debitMemos = convertPaymentToDebitMemos(zuoraPayment);
            if (ZuoraAPIHelper.getCalloutsRemaining() < 2*debitMemos.size() + 1) {
                throw new Util.FatalBWException('Not enough callouts remaining to create and post debit memos and mark ' +
                    'the payment as returned: ' + JSON.serialize(debitMemos));
            }
            ZuoraCreditDebitMemoService.createAndPostDebitMemos(debitMemos);
            markPaymentReturned(sfPayment.Zuora__EXT_ID__c);
            paymentReturnResult.debitMemos = debitMemos;
            paymentReturnResult.success = true;
            removePaymentMethodFromAccount(sfPayment);
        } catch (Exception e) {
            String message = 'Failed reversing payment ' + sfPayment.Id + ':\n' + e.getMessage() + '\n' + e.getStackTraceString();
            Logger.logLater(
                'ZuoraController',
                'reverseReturnedPayment',
                message,
                Logger.ERROR
            );
            paymentReturnResult.message = message;
            paymentReturnResult.success = false;
        }
        return paymentReturnResult;
    }

    public class PaymentReturnResult {
        @AuraEnabled
        public List<ZuoraAPI.DebitMemo> debitMemos;
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String message;
    }
}