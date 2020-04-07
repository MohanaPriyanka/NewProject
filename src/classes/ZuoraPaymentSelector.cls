/**
 * Created by PeterYao on 8/27/2019.
 * Tested By: ZuoraPaymentSelectorTest
 */

public with sharing class ZuoraPaymentSelector {
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<Zuora__Payment__c> selectById(Set<Id> ids) {
        if (!Schema.SObjectType.Zuora__Payment__c.isQueryable() ||
            !Schema.SObjectType.Zuora__Payment__c.fields.Zuora__EXT_ID__c.isAccessible()) {
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

    public static String getFailedPaymentRunPaymentsFromLastDay(Datetime endDatetime) {
        Datetime startDatetime = endDatetime - 1;
        return 'SELECT p.Id, p.Status, p.AccountId, p.PaymentMethodId, p.GatewayResponse, a.CrmId, pr.ExecutedDate ' +
            ' FROM Payment p ' +
            'INNER JOIN PaymentRun pr on pr.PaymentRunNumber = p.SourceName ' +
            'INNER JOIN Account a on p.AccountId = a.Id ' +
            'WHERE p.Source = \'PaymentRun\' ' +
            'AND p.Status != \'Processed\' ' +
            'AND pr.ExecutedDate > TIMESTAMP \'' + startDatetime.formatGmt('yyyy-MM-dd HH:mm:ss') + '\'' +
            'AND pr.ExecutedDate < TIMESTAMP \'' + endDatetime.formatGmt('yyyy-MM-dd HH:mm:ss') + '\'';
    }

    public static String selectPaymentsNotMarkedAsReturned(List<String> gatewayIds) {
        String fields = 'Id, Amount, ResponseStatus__c, ReferenceId, ArchivedChargentData__c';
        String tables = 'Payment';
        String gatewayConditions = '';
        for (Integer i = 0; i < gatewayIds.size(); i++) {
            String gatewayId = gatewayIds[i];
            gatewayConditions += 'ReferenceId = \''+gatewayId +'\' OR ArchivedChargentData__c LIKE \'%'+gatewayId+'%\'\n';
            if (i < gatewayIds.size() - 1) {
                gatewayConditions += ' OR ';
            }
        }
        String conditions = '(ResponseStatus__c != \'Returned\' OR ResponseStatus__c IS NULL) \nAND (' + gatewayConditions + ')';

        String result = 'SELECT ' + fields + ' \n' +
            'FROM ' + tables + ' \n' +
            'WHERE ' + conditions;
        return result;
    }

    public static String selectElectronicPaymentsFromDate(Datetime startDate) {
        return 'SELECT Id FROM Payment WHERE Type = \'Electronic\' AND EffectiveDate > ' + startDate.format('yyyy-MM-dd');
    }
}