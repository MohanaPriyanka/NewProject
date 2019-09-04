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
            SELECT Id, Zuora__EXT_ID__c
            FROM Zuora__Payment__c
            WHERE Id IN :ids
        ];
    }
}