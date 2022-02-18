/**
 * Created by PeterYao on 7/7/2021.
 */

trigger ZuoraPaymentTrigger on Zuora__Payment__c (before insert) {
    if (Util.isDisabled('Disable_ZuoraPaymentTrigger__c')) {
        return;
    }
    ZuoraGatewayAssigner zuoraGatewayAssigner = new ZuoraGatewayAssigner();
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            zuoraGatewayAssigner.setGatewayOnPayment(Trigger.new);
        }
    }
}