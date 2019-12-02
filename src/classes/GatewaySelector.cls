/**
 * Created by PeterYao on 10/9/2019.
 * Tested By: BatchAuthNetReturnedTransactionsTest, GatewaySelectorTest
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

    public List<Zuora__PaymentGateway__c> getAllZuoraGateways() {
        return [
            SELECT Id, Name,
                Zuora__External_Id__c,
                Client_Owner__r.Account_Number__c
            FROM Zuora__PaymentGateway__c
        ];
    }
}