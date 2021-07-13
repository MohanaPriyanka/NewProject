/**
 * Tested By: ZuoraGatewayAssignerTest
 */

public with sharing class ZuoraGatewayAssigner {
    private ZuoraAccountSelector zuoraAccountSelector = new ZuoraAccountSelector();
    private static Id defaultGatewayId;
    static {
        List<Zuora__PaymentGateway__c> allGateways = new GatewaySelector().getAllZuoraGateways();
        for (Zuora__PaymentGateway__c gateway : allGateways) {
            if (gateway.Zuora__IsDefault__c == 'true') {
                defaultGatewayId = gateway.Id;
            }
        }
    }

    public void setGatewayOnPayment(List<Zuora__Payment__c> newPayments) {
        MultiMap paymentsByBillingAccount = CollectionUtil.multiMapByField(newPayments, Zuora__Payment__c.Zuora__BillingAccount__c);
        Set<Id> billingAccountIds = CollectionUtil.toIds(paymentsByBillingAccount.keySet());
        Map<Id, Zuora__CustomerAccount__c> billingAccountsById =
            new Map<Id, Zuora__CustomerAccount__c>(zuoraAccountSelector.getBillingAccountsById(billingAccountIds));
        for (Zuora__Payment__c payment : newPayments) {
            if (payment.Zuora__Type__c == 'Electronic') {
                payment.Payment_Gateway__c = billingAccountsById.get(payment.Zuora__BillingAccount__c).Zuora__PaymentGateway__c;
                if (payment.Payment_Gateway__c == null) {
                    payment.Payment_Gateway__c = defaultGatewayId;
                }
            }
        }
    }
}