/**
 * Created by PeterYao on 7/24/2019.
 * Tested by: ZuoraHistoricalApplicationTest
 */

public with sharing class ChargentTransactionSelector {
    public List<ChargentOrders__Transaction__c> selectForZuoraHistory(String zuoraAccountId) {
        return [
            SELECT Id,  ChargentOrders__Type__c, ChargentOrders__Amount__c, ChargentOrders__Payment_Method__c,
                ChargentOrders__Gateway_Date__c, Client__r.Account_Number__c, ChargentOrders__Order__r.Entity__c,
                ChargentOrders__Order__r.Entity__r.Name, CreatedDate,
                ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Zuora_Id__c
            FROM ChargentOrders__Transaction__c
            WHERE ChargentOrders__Gateway__r.Name != 'SREC'
            AND ChargentOrders__Response_Status__c != 'Error'
            AND ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Zuora_Id__c =: zuoraAccountId
            AND ChargentOrders__Response_Status__c != 'Returned'
            ORDER BY Date_of_Transaction__c
        ];
    }
}