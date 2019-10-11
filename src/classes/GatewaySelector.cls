/**
 * Created by PeterYao on 10/9/2019.
 * Tested By: BatchAuthNetReturnedTransactionsTest
 */
// Since this should run as system
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class GatewaySelector {
    public List<ChargentBase__Gateway__c> getGatewaysForAuthentication() {
        return [
            SELECT Id, ChargentBase__Merchant_ID__c, ChargentBase__Security_Key__c
            FROM ChargentBase__Gateway__c
            WHERE ChargentBase__Active__c = TRUE
            AND RecordType.Name = 'Authorize.net'
        ];
    }
}