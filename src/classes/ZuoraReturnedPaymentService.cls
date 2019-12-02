/**
 * Created by PeterYao on 8/26/2019.
 * Tested by: ZuoraReturnedPaymentServiceTest
 */

public with sharing class ZuoraReturnedPaymentService {
    public Zuora__PaymentMethod__c payMethod;

    // Used to reverse payments that are found to be returned by leaving the payment as applied, but creating a new
    // debit memo with the current effective date. Will affect aging, since the original payment is left applied.
    public List<ZuoraAPI.DebitMemo> convertPaymentToDebitMemos(String paymentId) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/payments/' + paymentId, null, false);
        ZuoraAPI.Payment payment = (ZuoraAPI.Payment) JSON.deserialize(ZuoraAPIHelper.cleanJSON(response.getBody()), ZuoraAPI.Payment.class);
        // Response status can be Approved, Declined, Error, RETURNED, Voided for history, or blank for payments just coming from Zuora
        // So the Zuora Payment should have a response status of blank or Approved to be returned
        if (!String.isBlank(payment.ResponseStatus_Zcustom) && !(payment.ResponseStatus_Zcustom == 'Approved')) {
            throw new Util.FatalBWException('This payment is already marked as returned: ' + payment);
        }

        ZuoraAPI.OrderBySubscriptionOwner subscription =
            ZuoraSubscriptionService.getOrderBySubscriptionOwner(payment.accountId);

        response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/payments/'+ paymentId +'/parts', null, false);
        ZuoraAPI.PaymentParts paymentParts =
            (ZuoraAPI.PaymentParts) JSON.deserialize(response.getBody(), ZuoraAPI.PaymentParts.class);

        List<ZuoraAPI.DebitMemo> debitMemos = new List<ZuoraAPI.DebitMemo>();
        for (ZuoraAPI.PaymentPart paymentPart : paymentParts.parts) {
            response = ZuoraAPIHelper.callJsonEndpoint(
                'GET',
                '/v1/payments/' + paymentId + '/parts/' + paymentPart.id + '/itemparts',
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
        String productRatePlanChargeId =
            subscription.getProductRatePlanChargeId(appliedDebitMemo.ClientOwner_Zcustom, appliedDebitMemo.Project_Zcustom);

        ZuoraAPI.DebitMemo debitMemo = getDebitMemoTemplateFromPayment(paymentPartItem, productRatePlanChargeId, payment);
        debitMemo.Project_Zcustom = appliedDebitMemo.Project_Zcustom;
        debitMemo.ClientOwner_Zcustom = appliedDebitMemo.ClientOwner_Zcustom;
        return debitMemo;
    }

    private ZuoraAPI.DebitMemo getDebitMemoFromInvoiceItem(ZuoraAPI.PaymentPartItem paymentPartItem, ZuoraAPI.OrderBySubscriptionOwner subscription, ZuoraAPI.Payment payment) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/object/invoice-item/' + paymentPartItem.invoiceItemId, null, false);
        ZuoraAPI.InvoiceItem invoiceItem = (ZuoraAPI.InvoiceItem) JSON.deserialize(response.getBody(), ZuoraAPI.InvoiceItem.class);
        response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/object/rate-plan-charge/' + invoiceItem.RatePlanChargeId + '?fields=Project__c,ClientOwner__c', null, false);
        ZuoraAPI.RatePlanCharge ratePlanCharge =
            (ZuoraAPI.RatePlanCharge) JSON.deserialize(ZuoraAPIHelper.cleanJSON(response.getBody()), ZuoraAPI.RatePlanCharge.class);

        String productRatePlanChargeId =
            subscription.getProductRatePlanChargeId(ratePlanCharge.ClientOwner_Zcustom, ratePlanCharge.Project_Zcustom);

        ZuoraAPI.DebitMemo debitMemo = getDebitMemoTemplateFromPayment(paymentPartItem, productRatePlanChargeId, payment);
        debitMemo.Project_Zcustom = ratePlanCharge.Project_Zcustom;
        debitMemo.ClientOwner_Zcustom = ratePlanCharge.ClientOwner_Zcustom;
        return debitMemo;
    }

    private ZuoraAPI.DebitMemo getDebitMemoTemplateFromPayment(ZuoraAPI.PaymentPartItem paymentPartItem, String productRatePlanChargeId, ZuoraAPI.Payment payment) {
        ZuoraAPI.DebitMemoCharge debitCharge = new ZuoraAPI.DebitMemoCharge();
        debitCharge.amount = paymentPartItem.amount;
        debitCharge.chargeId = productRatePlanChargeId;

        ZuoraAPI.DebitMemo debitMemo = new ZuoraAPI.DebitMemo();
        debitMemo.accountId = payment.accountId;
        debitMemo.effectiveDate = System.today();
        debitMemo.charges = new List<ZuoraAPI.DebitMemoCharge>{debitCharge};
        debitMemo.reasonCode = 'Returned Payment';
        debitMemo.comment = 'Original Payment ' + payment.id + ', PaymentPartItem ' + paymentPartItem.id;
        // Stamp payment values for later use in GL download:
        debitMemo.ArchivedChargentData_Zcustom = payment.ArchivedChargentData_Zcustom;
        debitMemo.Gateway_Zcustom = payment.gatewayId;
        debitMemo.Lockbox_Zcustom = payment.Lockbox_Zcustom;

        List<Zuora__PaymentMethod__c> methods = ZuoraPaymentMethodSelector.getSFRecordFromZuoraId(new List<String>{payment.PaymentMethodId});
        if (methods.size() > 0){
            payMethod = methods[0];
            debitMemo.PaymentMethod_Zcustom = payMethod.Zuora__Type__c;
        }
        return debitMemo;
    }

    public void markPaymentReturned(String paymentId) {
        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        payment.ResponseStatus_Zcustom = 'Returned';
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('PUT', '/v1/payments/' + paymentId, payment, false);
        ZuoraAPI.GenericResponse genericResponse = (ZuoraAPI.GenericResponse) JSON.deserialize(response.getBody(), ZuoraAPI.GenericResponse.class);
        if (!genericResponse.success) {
            throw new Util.BWException('Did not mark payment ' + paymentId + 'as Returned:\n' + response.getBody());
        }
    }

    public Boolean removePaymentMethodFromAccount(Zuora__Payment__c returnedPayment) {
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

    public Case createCaseForReturns(Zuora__Payment__c zuoraPayment) {
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
        if (payMethod != null){
            newCase.Zuora_Payment_Method__c = payMethod.Id;
        } else {
            Logger.logNow('ZuoraController','getPaymentMethod',String.valueOf(zuoraPayment));
        }

        return newCase;
    }
}