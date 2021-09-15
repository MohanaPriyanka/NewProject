/**
 * @description Convenience methods to convert a Payment into a number of debit memos, intended to be used by
 * the ZuoraReturnedPaymentService
 * Tested By: ZuoraReturnedPaymentServiceTest
 */
public with sharing class ZuoraDebitMemoGenerator {
    private static ZuoraPaymentMethodSelector paymentMethodSelector = new ZuoraPaymentMethodSelector();
    /**
     * @description Converts each payment part items of a single payment into debit memos that can then be created and posted in Zuora
     * @param payment the payment for which debit memos should be created
     * @return List of DebitMemos that can be created and posted in Zuora
     */
    public List<ZuoraAPI.DebitMemo> convertPaymentToDebitMemos(ZuoraAPI.Payment payment) {
        HttpResponse response;
        response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/payments/' + payment.id + '/parts', null, false);
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
                    debitMemos.add(getDebitMemoFromInvoiceItem(paymentPartItem, payment));
                }
                if (paymentPartItem.debitMemoItemId != null) {
                    debitMemos.add(getDebitMemoFromDebitMemoItem(paymentPart.debitMemoId, paymentPartItem, payment));
                }
            }
        }
        return debitMemos;
    }

    private ZuoraAPI.DebitMemo getDebitMemoFromDebitMemoItem(String debitMemoId, ZuoraAPI.PaymentPartItem paymentPartItem, ZuoraAPI.Payment payment) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/debitmemos/' + debitMemoId, null, false);
        ZuoraAPI.ZuoraDebitMemo appliedDebitMemo = (ZuoraAPI.ZuoraDebitMemo) JSON.deserialize(ZuoraAPIHelper.cleanJSON(response.getBody()), ZuoraAPI.ZuoraDebitMemo.class);
        ZuoraAPI.DebitMemo debitMemo = getDebitMemoTemplateFromPayment(paymentPartItem, payment, appliedDebitMemo.Project_Zcustom, appliedDebitMemo.ClientOwner_Zcustom);
        return debitMemo;
    }

    // Uses up to seven callouts, invoice-item, rate-plan-charge, and then to associate the DM to an old invoice item
    private ZuoraAPI.DebitMemo getDebitMemoFromInvoiceItem(ZuoraAPI.PaymentPartItem paymentPartItem, ZuoraAPI.Payment payment) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/object/invoice-item/' + paymentPartItem.invoiceItemId, null, false);
        ZuoraAPI.InvoiceItem invoiceItem = (ZuoraAPI.InvoiceItem) JSON.deserialize(response.getBody(), ZuoraAPI.InvoiceItem.class);
        response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/object/rate-plan-charge/' + invoiceItem.RatePlanChargeId + '?fields=Project__c,ClientOwner__c', null, false);
        ZuoraAPI.RatePlanCharge ratePlanCharge =
            (ZuoraAPI.RatePlanCharge) JSON.deserialize(ZuoraAPIHelper.cleanJSON(response.getBody()), ZuoraAPI.RatePlanCharge.class);
        ZuoraAPI.DebitMemo debitMemo = getDebitMemoTemplateFromPayment(paymentPartItem, payment, ratePlanCharge.Project_Zcustom, ratePlanCharge.ClientOwner_Zcustom);
        return debitMemo;
    }

    private ZuoraAPI.DebitMemo getDebitMemoTemplateFromPayment(ZuoraAPI.PaymentPartItem paymentPartItem, ZuoraAPI.Payment payment, String project, String client) {
        Map<String, String> gatewayNameFromIdMap = gatewayNameFromGatewayIdMap();

        ZuoraAPI.DebitMemo debitMemo = new ZuoraAPI.DebitMemo();
        debitMemo.effectiveDate = System.today();
        debitMemo.Project_Zcustom = project;
        debitMemo.ClientOwner_Zcustom = client;
        debitMemo.CRM_ID_Zcustom = payment.number_Zreserved;
        ZuoraAPI.DebitMemoItem debitMemoItem = new ZuoraAPI.DebitMemoItem();
        debitMemoItem.amount = paymentPartItem.amount;
        debitMemoItem.skuName = 'Utility Credit';
        debitMemo.items = new List<ZuoraAPI.DebitMemoItem>{
            debitMemoItem
        };
        ZuoraCreditDebitMemoService.setDebitMemoInvoiceItem(payment.accountId, debitMemo);
        debitMemo.reasonCode = 'Returned Payment';
        debitMemo.comment = 'Original Payment ' + payment.id + ', PaymentPartItem ' + paymentPartItem.id;
        // Stamp payment values for later use in GL download:
        debitMemo.ArchivedChargentData_Zcustom = payment.ArchivedChargentData_Zcustom;
        debitMemo.Gateway_Zcustom = gatewayNameFromIdMap.get(payment.gatewayId);
        debitMemo.Lockbox_Zcustom = payment.Lockbox_zcustom;

        Zuora__PaymentMethod__c payMethod = paymentMethodSelector.getSFRecordFromZuoraId(payment.paymentMethodId);
        debitMemo.PaymentMethod_Zcustom = payMethod?.Zuora__Type__c;
        return debitMemo;
    }

    private Map<String, String> gatewayNameFromGatewayIdMap() {
        Map<String, String> gatewayIdNameMap = new Map<String, String>();
        GatewaySelector gatewaySelector = new GatewaySelector();
        List<Zuora__PaymentGateway__c> zuoraGateways = gatewaySelector.getAllZuoraGateways();

        for (Zuora__PaymentGateway__c zuoraGateway : zuoraGateways) {
            gatewayIdNameMap.put(
                zuoraGateway.Zuora__External_Id__c,
                zuoraGateway.Name
            );
        }
        return gatewayIdNameMap;
    }
}