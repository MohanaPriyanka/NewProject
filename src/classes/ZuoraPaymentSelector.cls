/**
 * Created by PeterYao on 8/27/2019.
 * Tested By: ZuoraPaymentSelectorTest
 */

public with sharing class ZuoraPaymentSelector {
    public List<Zuora__Payment__c> selectById(Set<Id> ids) {
        if (!Schema.sObjectType.Zuora__Payment__c.isQueryable() ||
            !Schema.sObjectType.Zuora__Payment__c.fields.Zuora__EXT_ID__c.isAccessible()) {
            throw new Util.FatalBWException('Insufficient permissions');
        }
        return [
            SELECT Id, Zuora__EXT_ID__c,
                Zuora__BillingAccount__c,
                Zuora__BillingAccount__r.Zuora__Zuora_Id__c,
                Zuora__BillingAccount__r.Zuora__Account__c,
                Zuora__PaymentMethodId__c
            FROM Zuora__Payment__c
            WHERE Id IN :ids
        ];
    }

    public static List<Zuora__Payment__c> selectByAccount(List<Id> propertyAccountIds) {
        List<Zuora__Payment__c> zuoraPayments = [
            SELECT Id, Name,
                Zuora__Amount__c,
                Zuora__BillingAccount__r.Zuora__Account__r.Id,
                Zuora__GatewayResponse__c,
                Zuora__PaymentMethod__c,
                Zuora__Status__c,
                Zuora__Type__c,
                Zuora__Effective_Date__c,
                Zuora__BillingAccount__r.Zuora__PaymentGateway__r.Name,
                Zuora__BillingAccount__r.Zuora__AutoPay__c
            FROM Zuora__Payment__c
            WHERE Zuora__BillingAccount__r.Zuora__Account__r.Id IN :propertyAccountIds
            ORDER BY Zuora__Effective_Date__c DESC
        ];
        return zuoraPayments;
    }
}